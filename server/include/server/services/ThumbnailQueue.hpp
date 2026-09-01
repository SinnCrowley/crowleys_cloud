// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

#pragma once

#include "server/services/FileService.hpp"
#include "server/services/FileIndexService.hpp"
#include "server/utils/Config.hpp"

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <filesystem>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <unordered_set>
#include <vector>

namespace server::services {

enum class ThumbnailPriority : uint8_t {
  Low = 0,      // Background re-indexing or batch migration
  Normal = 1,   // Background file upload
  High = 2      // Interactive user request (cache miss on /api/thumb)
};

enum class OverflowPolicy : uint8_t {
  DropNewest = 0, // Reject incoming task when queue is full (tail drop - load shedding)
  DropOldest = 1  // Evict oldest pending task to favor newest requests (head drop)
};

struct ThumbnailTask {
  std::string key;                           // Deduplication key: "<userId>:<identifier>:<thumbSize>"
  std::int64_t ownerUserId{0};               // File owner user ID
  std::int64_t cacheUserId{0};               // Cache partition user ID
  StorageScope scope{StorageScope::Private}; // Scope (Private or Shared)
  std::string relPath;                       // Relative virtual path (e.g. "photos/pic.jpg")
  std::filesystem::path sourcePath;          // Disk filesystem path of source file
  std::filesystem::path destWebpPath;        // Destination .webp thumbnail file path
  std::filesystem::path tempBasePath;        // Base path prefix for temporary artifacts
  std::string sha256;                        // Plaintext SHA-256 hash (if available)
  std::string fileType;                      // "photo" or "video"
  int thumbSize{256};                        // Target max dimension (64, 128, 256, 512, 1024)
  bool isEncrypted{false};                   // True if source is AES-256 encrypted
  std::string encryptionKey;                 // Encryption key (if AES encrypted)
  bool isTrash{false};                       // True if item belongs to trash
  std::int64_t trashId{0};                   // Trash ID if isTrash is true
  ThumbnailPriority priority{ThumbnailPriority::Normal};
  std::function<void(const ThumbnailTask &)> customHandler;

  /**
   * Helper factory to generate a canonical deduplication key.
   * Format: "<userId>:<identifier>:<thumbSize>"
   */
  static std::string makeKey(std::int64_t userId, const std::string &identifier, int size) {
    return std::to_string(userId) + ":" + identifier + ":" + std::to_string(size);
  }
};

/**
 * Thread-safe, bounded task queue with dual-set deduplication of in-flight jobs
 * and an integrated background worker pool strictly bounded to 1–2 threads @ nice(10) priority.
 * Prevents memory exhaustion (OOM) under burst traffic and eliminates redundant thumbnail generation.
 */
class ThumbnailQueue {
 public:
  explicit ThumbnailQueue(size_t maxCapacity = 512,
                          size_t numWorkers = 2,
                          OverflowPolicy defaultPolicy = OverflowPolicy::DropNewest);

  ThumbnailQueue(const utils::Config &config,
                 FileService *fileService,
                 FileIndexService *fileIndexService,
                 size_t maxCapacity = 512,
                 size_t numWorkers = 2,
                 OverflowPolicy defaultPolicy = OverflowPolicy::DropNewest);

  ~ThumbnailQueue();

  ThumbnailQueue(const ThumbnailQueue &) = delete;
  ThumbnailQueue &operator=(const ThumbnailQueue &) = delete;
  ThumbnailQueue(ThumbnailQueue &&) = delete;
  ThumbnailQueue &operator=(ThumbnailQueue &&) = delete;

  /**
   * Starts the background worker thread pool (strictly clamped to 1–2 threads @ nice 10).
   */
  void start();

  /**
   * Signals the queue and workers to stop, waking up all waiting threads and joining cleanly.
   */
  void stop();

  /**
   * Enqueues a task into the queue. Non-blocking.
   * Returns true if task was successfully added.
   * Returns false if task is a duplicate (pending or active), queue is stopped,
   * or queue is full under DropNewest policy.
   */
  bool enqueue(const ThumbnailTask &task, std::optional<OverflowPolicy> policy = std::nullopt);
  bool enqueue(ThumbnailTask &&task, std::optional<OverflowPolicy> policy = std::nullopt);

  /**
   * Convenience helper to construct and schedule a thumbnail task.
   */
  bool scheduleThumbnail(std::int64_t ownerUserId,
                         std::int64_t cacheUserId,
                         StorageScope scope,
                         const std::string &relPath,
                         const std::filesystem::path &sourcePath,
                         const std::string &fileType,
                         const std::string &sha256 = "",
                         int thumbSize = 256,
                         bool isEncrypted = false,
                         const std::string &encryptionKey = "",
                         bool isTrash = false,
                         std::int64_t trashId = 0,
                         const std::filesystem::path &destWebpPath = "");

  bool scheduleThumbnail(std::int64_t userId,
                         StorageScope scope,
                         const std::string &relPath,
                         const std::filesystem::path &sourcePath,
                         const std::string &fileType,
                         const std::string &sha256 = "",
                         int thumbSize = 256,
                         bool isEncrypted = false,
                         bool isTrash = false,
                         std::int64_t trashId = 0);

  /**
   * Pops the next available task from the queue.
   * Blocks until a task becomes available or the queue is stopped.
   * Atomically moves task key from pendingKeys_ to activeKeys_.
   * Returns std::nullopt if the queue is stopped and empty.
   */
  std::optional<ThumbnailTask> pop();

  /**
   * Pops the next available task from the queue with a timeout.
   */
  std::optional<ThumbnailTask> popWithTimeout(std::chrono::milliseconds timeout);

  /**
   * Marks a task as finished, releasing its key from activeKeys_.
   * Must be called when task processing completes.
   */
  void finishTask(const std::string &key);

  /**
   * Clears pending tasks from the queue and resets pendingKeys_.
   * Does not affect active tasks running in workers.
   */
  void clear();

  size_t size() const;
  size_t activeCount() const;
  size_t inFlightCount() const;
  bool empty() const;
  bool full() const;
  bool isStopped() const;
  bool isKeyInFlight(const std::string &key) const;
  size_t capacity() const;
  void setCapacity(size_t newCapacity);
  size_t workerCount() const;
  bool isRunning() const;

  /**
   * Sets custom task processor callback (useful for testing and instrumentation).
   */
  void setTaskProcessor(std::function<void(const ThumbnailTask &)> processor);

  /**
   * Executes task processing logic (RAM WebP + BlurHash for photos; low-priority FFmpeg for videos).
   */
  void processTask(const ThumbnailTask &task);

 private:
  bool enqueueInternal(ThumbnailTask &&task, OverflowPolicy policy);
  void workerLoop(size_t workerId);

  utils::Config config_;
  FileService *fileService_{nullptr};
  FileIndexService *fileIndexService_{nullptr};

  mutable std::mutex mutex_;
  std::condition_variable cvNotEmpty_;
  std::deque<ThumbnailTask> queue_;
  std::unordered_set<std::string> pendingKeys_;
  std::unordered_set<std::string> activeKeys_;
  size_t capacity_{512};
  OverflowPolicy defaultPolicy_{OverflowPolicy::DropNewest};
  size_t numWorkers_{2};
  std::vector<std::thread> workers_;
  std::atomic<bool> running_{false};
  bool stopped_{false};
  std::function<void(const ThumbnailTask &)> customProcessor_;
};

}  // namespace server::services
