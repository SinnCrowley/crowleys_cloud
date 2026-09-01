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

#include "server/services/ThumbnailQueue.hpp"
#include "server/utils/ImageUtils.hpp"
#include "server/utils/PlatformUtils.hpp"
#include "server/utils/Crypto.hpp"

#include <trantor/utils/Logger.h>
#include <algorithm>

#if defined(_WIN32)
#include <windows.h>
#elif defined(__APPLE__)
#include <sys/resource.h>
#elif defined(__linux__) || defined(__unix__) || defined(__posix)
#include <sys/resource.h>
#include <unistd.h>
#endif

namespace server::services {

static void setWorkerThreadPriorityLow() {
#if defined(_WIN32)
  SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_BELOW_NORMAL);
#elif defined(__APPLE__) || defined(__linux__) || defined(__unix__) || defined(__posix)
  int ret = setpriority(PRIO_PROCESS, 0, 10);
  if (ret != 0) {
    nice(10);
  }
#endif
}

ThumbnailQueue::ThumbnailQueue(size_t maxCapacity, size_t numWorkers, OverflowPolicy defaultPolicy)
    : capacity_(std::max<size_t>(1, maxCapacity)),
      defaultPolicy_(defaultPolicy),
      numWorkers_(numWorkers == 0 ? 0 : std::clamp<size_t>(numWorkers, 1, 2)) {}

ThumbnailQueue::ThumbnailQueue(const utils::Config &config,
                               FileService *fileService,
                               FileIndexService *fileIndexService,
                               size_t maxCapacity,
                               size_t numWorkers,
                               OverflowPolicy defaultPolicy)
    : config_(config),
      fileService_(fileService),
      fileIndexService_(fileIndexService),
      capacity_(std::max<size_t>(1, maxCapacity)),
      defaultPolicy_(defaultPolicy),
      numWorkers_(numWorkers == 0 ? 0 : std::clamp<size_t>(numWorkers, 1, 2)) {}

ThumbnailQueue::~ThumbnailQueue() {
  stop();
}

void ThumbnailQueue::start() {
  if (running_.exchange(true)) {
    return;
  }
  if (numWorkers_ == 0) return;

  workers_.reserve(numWorkers_);
  for (size_t i = 0; i < numWorkers_; ++i) {
    workers_.emplace_back(&ThumbnailQueue::workerLoop, this, i + 1);
  }
  LOG_INFO << "ThumbnailQueue worker pool started with " << numWorkers_ << " thread(s) @ nice(10).";
}

void ThumbnailQueue::stop() {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (stopped_) return;
    stopped_ = true;
  }
  cvNotEmpty_.notify_all();

  for (auto &w : workers_) {
    if (w.joinable()) {
      w.join();
    }
  }
  workers_.clear();
  running_ = false;
  LOG_INFO << "ThumbnailQueue worker pool stopped cleanly.";
}

bool ThumbnailQueue::enqueue(const ThumbnailTask &task, std::optional<OverflowPolicy> policy) {
  ThumbnailTask copy = task;
  return enqueueInternal(std::move(copy), policy.value_or(defaultPolicy_));
}

bool ThumbnailQueue::enqueue(ThumbnailTask &&task, std::optional<OverflowPolicy> policy) {
  return enqueueInternal(std::move(task), policy.value_or(defaultPolicy_));
}

bool ThumbnailQueue::enqueueInternal(ThumbnailTask &&task, OverflowPolicy policy) {
  if (task.key.empty()) {
    const auto effectiveUserId = (task.cacheUserId > 0) ? task.cacheUserId : task.ownerUserId;
    const auto identifier = task.sha256.empty() ? task.sourcePath.generic_string() : task.sha256;
    task.key = ThumbnailTask::makeKey(effectiveUserId, identifier, task.thumbSize);
  }

  std::unique_lock<std::mutex> lock(mutex_);
  if (stopped_) {
    return false;
  }

  // 1. Dual-set in-flight deduplication check
  if (pendingKeys_.count(task.key) > 0 || activeKeys_.count(task.key) > 0) {
    return false;
  }

  // 2. Bounded capacity check
  if (queue_.size() >= capacity_) {
    if (policy == OverflowPolicy::DropNewest) {
      return false;
    } else if (policy == OverflowPolicy::DropOldest) {
      if (!queue_.empty()) {
        const auto oldestKey = queue_.front().key;
        pendingKeys_.erase(oldestKey);
        queue_.pop_front();
      }
    }
  }

  // 3. Insert task into queue and track pending key
  const auto key = task.key;
  queue_.push_back(std::move(task));
  pendingKeys_.insert(key);

  lock.unlock();
  cvNotEmpty_.notify_one();
  return true;
}

bool ThumbnailQueue::scheduleThumbnail(std::int64_t ownerUserId,
                                       std::int64_t cacheUserId,
                                       StorageScope scope,
                                       const std::string &relPath,
                                       const std::filesystem::path &sourcePath,
                                       const std::string &fileType,
                                       const std::string &sha256,
                                       int thumbSize,
                                       bool isEncrypted,
                                       const std::string &encryptionKey,
                                       bool isTrash,
                                       std::int64_t trashId,
                                       const std::filesystem::path &destWebpPath) {
  if (fileType != "photo" && fileType != "video") return false;
  if (fileType == "video" && !config_.videoThumbsEnabled) return false;

  const int clampedSize = std::clamp(thumbSize, 64, 1024);
  const auto effectiveUserId = (cacheUserId > 0) ? cacheUserId : ownerUserId;
  const auto identifier = sha256.empty() ? sourcePath.generic_string() : sha256;
  const auto key = ThumbnailTask::makeKey(effectiveUserId, identifier, clampedSize);

  std::filesystem::path finalDestWebp = destWebpPath;
  std::filesystem::path tempBasePath;
  if (finalDestWebp.empty()) {
    const auto thumbRoot = std::filesystem::path(config_.storageRoot) / ".thumbs" / std::to_string(effectiveUserId);
    std::error_code ec;
    std::filesystem::create_directories(thumbRoot, ec);
    tempBasePath = thumbRoot / std::to_string(std::hash<std::string>{}(key));
    finalDestWebp = std::filesystem::path(tempBasePath.string() + ".webp");
  } else {
    tempBasePath = finalDestWebp.parent_path() / finalDestWebp.stem();
  }

  ThumbnailTask task;
  task.key = key;
  task.ownerUserId = ownerUserId;
  task.cacheUserId = effectiveUserId;
  task.scope = scope;
  task.relPath = relPath;
  task.sourcePath = sourcePath;
  task.destWebpPath = finalDestWebp;
  task.tempBasePath = tempBasePath;
  task.sha256 = sha256;
  task.fileType = fileType;
  task.thumbSize = clampedSize;
  task.isEncrypted = isEncrypted;
  task.encryptionKey = encryptionKey.empty() ? config_.encryptionKey : encryptionKey;
  task.isTrash = isTrash;
  task.trashId = trashId;

  return enqueue(std::move(task));
}

bool ThumbnailQueue::scheduleThumbnail(std::int64_t userId,
                                       StorageScope scope,
                                       const std::string &relPath,
                                       const std::filesystem::path &sourcePath,
                                       const std::string &fileType,
                                       const std::string &sha256,
                                       int thumbSize,
                                       bool isEncrypted,
                                       bool isTrash,
                                       std::int64_t trashId) {
  return scheduleThumbnail(userId, userId, scope, relPath, sourcePath, fileType, sha256, thumbSize, isEncrypted, "", isTrash, trashId);
}

std::optional<ThumbnailTask> ThumbnailQueue::pop() {
  std::unique_lock<std::mutex> lock(mutex_);
  cvNotEmpty_.wait(lock, [this] { return stopped_ || !queue_.empty(); });

  if (queue_.empty()) {
    return std::nullopt;
  }

  ThumbnailTask task = std::move(queue_.front());
  queue_.pop_front();

  pendingKeys_.erase(task.key);
  activeKeys_.insert(task.key);

  return task;
}

std::optional<ThumbnailTask> ThumbnailQueue::popWithTimeout(std::chrono::milliseconds timeout) {
  std::unique_lock<std::mutex> lock(mutex_);
  if (!cvNotEmpty_.wait_for(lock, timeout, [this] { return stopped_ || !queue_.empty(); })) {
    return std::nullopt;
  }

  if (queue_.empty()) {
    return std::nullopt;
  }

  ThumbnailTask task = std::move(queue_.front());
  queue_.pop_front();

  pendingKeys_.erase(task.key);
  activeKeys_.insert(task.key);

  return task;
}

void ThumbnailQueue::finishTask(const std::string &key) {
  std::lock_guard<std::mutex> lock(mutex_);
  activeKeys_.erase(key);
}

void ThumbnailQueue::clear() {
  std::lock_guard<std::mutex> lock(mutex_);
  queue_.clear();
  pendingKeys_.clear();
}

size_t ThumbnailQueue::size() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return queue_.size();
}

size_t ThumbnailQueue::activeCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return activeKeys_.size();
}

size_t ThumbnailQueue::inFlightCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return pendingKeys_.size() + activeKeys_.size();
}

bool ThumbnailQueue::empty() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return queue_.empty();
}

bool ThumbnailQueue::full() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return queue_.size() >= capacity_;
}

bool ThumbnailQueue::isStopped() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return stopped_;
}

bool ThumbnailQueue::isKeyInFlight(const std::string &key) const {
  std::lock_guard<std::mutex> lock(mutex_);
  return pendingKeys_.count(key) > 0 || activeKeys_.count(key) > 0;
}

size_t ThumbnailQueue::capacity() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return capacity_;
}

void ThumbnailQueue::setCapacity(size_t newCapacity) {
  std::lock_guard<std::mutex> lock(mutex_);
  capacity_ = std::max<size_t>(1, newCapacity);
}

size_t ThumbnailQueue::workerCount() const {
  return numWorkers_;
}

bool ThumbnailQueue::isRunning() const {
  return running_;
}

void ThumbnailQueue::setTaskProcessor(std::function<void(const ThumbnailTask &)> processor) {
  customProcessor_ = std::move(processor);
}

void ThumbnailQueue::workerLoop(size_t workerId) {
  setWorkerThreadPriorityLow();

  while (running_ && !stopped_) {
    auto taskOpt = pop();
    if (!taskOpt.has_value()) {
      break;
    }

    const auto &task = *taskOpt;
    try {
      processTask(task);
    } catch (const std::exception &e) {
      LOG_WARN << "Thumbnail worker #" << workerId << " exception on " << task.relPath << ": " << e.what();
    } catch (...) {
      LOG_WARN << "Thumbnail worker #" << workerId << " unknown exception on " << task.relPath;
    }

    finishTask(task.key);
  }
}

void ThumbnailQueue::processTask(const ThumbnailTask &task) {
  if (task.customHandler) {
    task.customHandler(task);
    return;
  }
  if (customProcessor_) {
    customProcessor_(task);
    return;
  }

  if (task.fileType == "photo") {
    std::string blurHash;
    bool success = false;
    const std::string encKey = task.encryptionKey.empty() ? config_.encryptionKey : task.encryptionKey;

    if (task.isEncrypted) {
      success = utils::generateThumbnailFromEncryptedFile(
          task.sourcePath, encKey, task.destWebpPath,
          task.thumbSize, 80.0f, nullptr, &blurHash);
    } else {
      success = utils::generateThumbnailFromFile(
          task.sourcePath, task.destWebpPath,
          task.thumbSize, 80.0f, nullptr, &blurHash);
    }

    if (success && !blurHash.empty() && fileIndexService_ != nullptr) {
      if (!task.sha256.empty()) {
        fileIndexService_->updateBlurHashBySha256(task.sha256, blurHash);
      }
      if (!task.relPath.empty()) {
        fileIndexService_->updateBlurHash(task.ownerUserId, task.scope, task.relPath, blurHash);
      }
    }
  } else if (task.fileType == "video" && config_.videoThumbsEnabled) {
    std::filesystem::path actualSource = task.sourcePath;
    std::filesystem::path decryptedVideoTmp;
    const std::string encKey = task.encryptionKey.empty() ? config_.encryptionKey : task.encryptionKey;

    if (task.isEncrypted) {
      decryptedVideoTmp = task.tempBasePath.empty()
                              ? (task.destWebpPath.string() + ".video.dec.tmp")
                              : (task.tempBasePath.string() + ".video.dec.tmp");
      if (utils::decryptFileAes256(task.sourcePath, decryptedVideoTmp, encKey)) {
        actualSource = decryptedVideoTmp;
      } else {
        std::error_code ec;
        std::filesystem::remove(decryptedVideoTmp, ec);
        return;
      }
    }

    struct TempGuard {
      std::filesystem::path p;
      ~TempGuard() {
        if (!p.empty()) {
          std::error_code ec;
          std::filesystem::remove(p, ec);
        }
      }
    } guard{decryptedVideoTmp};

    if (!actualSource.empty() && std::filesystem::exists(actualSource)) {
      const std::string ffmpeg = config_.ffmpegBinary.empty() ? "ffmpeg" : config_.ffmpegBinary;
      std::vector<std::string> args = {
          ffmpeg,
          "-hide_banner",
          "-loglevel",
          "error",
          "-y",
          "-ss",
          "00:00:01",
          "-i",
          actualSource.string(),
          "-frames:v",
          "1",
          "-vf",
          "scale=" + std::to_string(task.thumbSize) + ":-1:force_original_aspect_ratio=decrease",
          "-c:v",
          "libwebp",
          "-quality",
          "80",
          task.destWebpPath.string()};
      utils::runProcess(args);
    }
  }
}

}  // namespace server::services
