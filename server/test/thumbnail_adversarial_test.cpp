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
#include "server/db/Database.hpp"
#include "server/services/FileService.hpp"
#include "server/services/FileIndexService.hpp"
#include "server/utils/Crypto.hpp"
#include "server/utils/ImageUtils.hpp"
#include <webp/encode.h>

#include <atomic>
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <mutex>
#include <set>
#include <thread>
#include <unordered_set>
#include <vector>

#if defined(__linux__) || defined(__unix__) || defined(__posix) || defined(__APPLE__)
#include <sys/resource.h>
#include <unistd.h>
#endif

#define TEST_ASSERT(cond) \
  do { \
    if (!(cond)) { \
      std::cerr << "\n[ADVERSARIAL ASSERTION FAILED] " #cond " at " << __FILE__ << ":" << __LINE__ << std::endl; \
      std::abort(); \
    } \
  } while (0)

using namespace server;
using namespace server::services;

static std::filesystem::path createTempDir(const std::string &prefix) {
  auto tmpDir = std::filesystem::temp_directory_path() / (prefix + "_" + utils::randomTokenHex(8));
  std::filesystem::create_directories(tmpDir);
  return tmpDir;
}

// =============================================================================
// CHALLENGE 1: High Concurrency Burst (2,000 Tasks across 20 Threads)
// =============================================================================
static void testHighConcurrencyBurst() {
  std::cout << "\n=======================================================" << std::endl;
  std::cout << "[CHALLENGE 1] High Concurrency Burst (2,000 Tasks / 20 Threads)" << std::endl;
  std::cout << "=======================================================" << std::endl;

  // Part A: DropNewest Load Shedding under heavy burst
  {
    const size_t queueCapacity = 256;
    const int numThreads = 20;
    const int tasksPerThread = 100; // 2,000 tasks total
    std::atomic<size_t> enqueuedCount{0};
    std::atomic<size_t> droppedCount{0};
    std::atomic<size_t> processedCount{0};
    std::atomic<int> maxActiveWorkers{0};
    std::atomic<int> currentActiveWorkers{0};

    ThumbnailQueue queue(queueCapacity, 2, OverflowPolicy::DropNewest);
    queue.setTaskProcessor([&](const ThumbnailTask &) {
      int cur = currentActiveWorkers.fetch_add(1) + 1;
      int prevMax = maxActiveWorkers.load();
      while (cur > prevMax && !maxActiveWorkers.compare_exchange_weak(prevMax, cur)) {}

      // Simulate realistic thumbnail resize/encode workload (100–300 microseconds)
      std::this_thread::sleep_for(std::chrono::microseconds(150));

      currentActiveWorkers.fetch_sub(1);
      processedCount.fetch_add(1, std::memory_order_relaxed);
    });

    queue.start();

    std::vector<std::thread> producers;
    producers.reserve(numThreads);

    auto startTime = std::chrono::steady_clock::now();

    for (int t = 0; t < numThreads; ++t) {
      producers.emplace_back([&, t]() {
        for (int i = 0; i < tasksPerThread; ++i) {
          ThumbnailTask task;
          task.key = "burst_user_" + std::to_string(t) + "_task_" + std::to_string(i);
          task.thumbSize = 256;

          if (queue.enqueue(task)) {
            enqueuedCount.fetch_add(1, std::memory_order_relaxed);
          } else {
            droppedCount.fetch_add(1, std::memory_order_relaxed);
          }

          // Periodic invariant checks during execution
          TEST_ASSERT(queue.size() <= queueCapacity);
        }
      });
    }

    for (auto &p : producers) {
      p.join();
    }

    auto producerElapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                               std::chrono::steady_clock::now() - startTime)
                               .count();

    std::cout << "  [INFO] Producers finished in " << producerElapsed << " ms." << std::endl;
    std::cout << "  [INFO] Enqueued: " << enqueuedCount.load()
              << ", Dropped (Load Shed): " << droppedCount.load()
              << ", Total Attempts: " << (enqueuedCount.load() + droppedCount.load()) << std::endl;

    TEST_ASSERT(enqueuedCount.load() + droppedCount.load() == static_cast<size_t>(numThreads * tasksPerThread));
    TEST_ASSERT(enqueuedCount.load() > 0);
    TEST_ASSERT(maxActiveWorkers.load() <= 2);

    // Wait for all enqueued tasks to be fully drained
    for (int i = 0; i < 300; ++i) {
      if (queue.size() == 0 && queue.activeCount() == 0) break;
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }

    queue.stop();

    std::cout << "  [INFO] Total Processed: " << processedCount.load()
              << ", Remaining Queue Size: " << queue.size()
              << ", In-Flight: " << queue.inFlightCount() << std::endl;

    TEST_ASSERT(processedCount.load() == enqueuedCount.load());
    TEST_ASSERT(queue.size() == 0);
    TEST_ASSERT(queue.activeCount() == 0);
    TEST_ASSERT(queue.inFlightCount() == 0);
    TEST_ASSERT(queue.empty());
  }

  // Part B: DropOldest Head-Drop Under Concurrency Burst
  {
    const size_t queueCapacity = 50;
    const int numThreads = 20;
    const int tasksPerThread = 50; // 1,000 tasks total

    ThumbnailQueue queue(queueCapacity, 0, OverflowPolicy::DropOldest); // 0 workers to hold queue

    std::vector<std::thread> producers;
    producers.reserve(numThreads);

    for (int t = 0; t < numThreads; ++t) {
      producers.emplace_back([&, t]() {
        for (int i = 0; i < tasksPerThread; ++i) {
          ThumbnailTask task;
          task.key = "head_drop_t" + std::to_string(t) + "_i" + std::to_string(i);
          queue.enqueue(task);
        }
      });
    }

    for (auto &p : producers) {
      p.join();
    }

    TEST_ASSERT(queue.size() == queueCapacity);
    TEST_ASSERT(queue.full());
    TEST_ASSERT(queue.inFlightCount() == queueCapacity);

    // Drain all tasks and verify exactly queueCapacity items are popped
    size_t poppedCount = 0;
    while (auto item = queue.popWithTimeout(std::chrono::milliseconds(5))) {
      poppedCount++;
      queue.finishTask(item->key);
    }

    TEST_ASSERT(poppedCount == queueCapacity);
    TEST_ASSERT(queue.empty());
    TEST_ASSERT(queue.inFlightCount() == 0);
  }

  std::cout << "  [PASS] CHALLENGE 1: High Concurrency Burst & Load Shedding passed!" << std::endl;
}

// =============================================================================
// CHALLENGE 2: Rapid Concurrent Deduplication Stress
// =============================================================================
static void testRapidDeduplicationStress() {
  std::cout << "\n=======================================================" << std::endl;
  std::cout << "[CHALLENGE 2] Rapid Concurrent Deduplication Stress" << std::endl;
  std::cout << "=======================================================" << std::endl;

  const int numThreads = 30;
  const int iterations = 300;
  const int numUniqueKeys = 10;

  std::atomic<size_t> totalAttempts{0};
  std::atomic<size_t> acceptedCount{0};
  std::atomic<size_t> rejectedCount{0};
  std::atomic<size_t> executedCount{0};

  std::mutex activeMutex;
  std::unordered_set<std::string> currentlyProcessingKeys;

  ThumbnailQueue queue(500, 2);
  queue.setTaskProcessor([&](const ThumbnailTask &task) {
    {
      std::lock_guard<std::mutex> lock(activeMutex);
      // Invariant: No two workers can ever process the same task key concurrently!
      TEST_ASSERT(currentlyProcessingKeys.count(task.key) == 0);
      currentlyProcessingKeys.insert(task.key);
    }

    // Simulate work with thread yield and small sleep
    std::this_thread::sleep_for(std::chrono::microseconds(200));

    {
      std::lock_guard<std::mutex> lock(activeMutex);
      currentlyProcessingKeys.erase(task.key);
    }
    executedCount.fetch_add(1, std::memory_order_relaxed);
  });

  queue.start();

  std::vector<std::thread> threads;
  threads.reserve(numThreads);

  for (int t = 0; t < numThreads; ++t) {
    threads.emplace_back([&]() {
      for (int i = 0; i < iterations; ++i) {
        ThumbnailTask task;
        int keyIndex = (i + t) % numUniqueKeys;
        task.key = "dedup_key_" + std::to_string(keyIndex);

        totalAttempts.fetch_add(1, std::memory_order_relaxed);
        if (queue.enqueue(task)) {
          acceptedCount.fetch_add(1, std::memory_order_relaxed);
        } else {
          rejectedCount.fetch_add(1, std::memory_order_relaxed);
        }
      }
    });
  }

  for (auto &t : threads) {
    t.join();
  }

  std::cout << "  [INFO] Total Attempts: " << totalAttempts.load()
            << ", Accepted: " << acceptedCount.load()
            << ", Deduplicated (Rejected): " << rejectedCount.load() << std::endl;

  TEST_ASSERT(totalAttempts.load() == static_cast<size_t>(numThreads * iterations));
  TEST_ASSERT(acceptedCount.load() + rejectedCount.load() == totalAttempts.load());
  TEST_ASSERT(rejectedCount.load() > acceptedCount.load()); // Most should be deduplicated

  // Drain remaining
  for (int i = 0; i < 200; ++i) {
    if (queue.size() == 0 && queue.activeCount() == 0) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }

  queue.stop();

  TEST_ASSERT(executedCount.load() == acceptedCount.load());
  TEST_ASSERT(queue.inFlightCount() == 0);

  std::cout << "  [PASS] CHALLENGE 2: Rapid Concurrent Deduplication Stress passed!" << std::endl;
}

// =============================================================================
// CHALLENGE 3: Shutdown Under Heavy Contention & Active Execution
// =============================================================================
static void testShutdownUnderContention() {
  std::cout << "\n=======================================================" << std::endl;
  std::cout << "[CHALLENGE 3] Shutdown Under Heavy Contention" << std::endl;
  std::cout << "=======================================================" << std::endl;

  // Run 15 rapid lifecycle stop() cycles under intense concurrent enqueueing
  for (int cycle = 0; cycle < 15; ++cycle) {
    ThumbnailQueue queue(100, 2);
    std::atomic<bool> stopProducers{false};
    std::atomic<size_t> enqueuedDuringCycle{0};

    queue.setTaskProcessor([&](const ThumbnailTask &) {
      std::this_thread::sleep_for(std::chrono::microseconds(500));
    });

    queue.start();

    const int numProducers = 8;
    std::vector<std::thread> producers;
    producers.reserve(numProducers);

    for (int p = 0; p < numProducers; ++p) {
      producers.emplace_back([&, p]() {
        size_t counter = 0;
        while (!stopProducers.load(std::memory_order_relaxed)) {
          ThumbnailTask task;
          task.key = "cycle_" + std::to_string(cycle) + "_p_" + std::to_string(p) + "_" + std::to_string(counter++);
          if (queue.enqueue(task)) {
            enqueuedDuringCycle.fetch_add(1, std::memory_order_relaxed);
          }
          std::this_thread::yield();
        }
      });
    }

    // Let producers run for 5-10ms
    std::this_thread::sleep_for(std::chrono::milliseconds(5 + (cycle % 5)));

    // Abruptly invoke stop() while threads are actively pushing and workers are executing
    auto stopStart = std::chrono::steady_clock::now();
    queue.stop();
    auto stopElapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                           std::chrono::steady_clock::now() - stopStart)
                           .count();

    // Signal producers to finish
    stopProducers = true;
    for (auto &p : producers) {
      p.join();
    }

    // Verify stop timing: must never hang or deadlock
    TEST_ASSERT(stopElapsed < 500);
    TEST_ASSERT(queue.isStopped());
    TEST_ASSERT(!queue.isRunning());

    // Verify idempotent stop
    queue.stop();
    TEST_ASSERT(queue.isStopped());

    // After stop, enqueue must always reject
    ThumbnailTask postTask;
    postTask.key = "post_stop_task";
    TEST_ASSERT(!queue.enqueue(postTask));
  }

  std::cout << "  [PASS] CHALLENGE 3: Shutdown Under Heavy Contention passed 15/15 cycles!" << std::endl;
}

// =============================================================================
// CHALLENGE 4: Worker Thread Count & POSIX Nice Priority Invariant
// =============================================================================
static void testWorkerCountAndPriority() {
  std::cout << "\n=======================================================" << std::endl;
  std::cout << "[CHALLENGE 4] Worker Count Limits & nice(10) Priority" << std::endl;
  std::cout << "=======================================================" << std::endl;

  // 1. Worker count clamping
  {
    ThumbnailQueue q0(50, 0);
    TEST_ASSERT(q0.workerCount() == 0);

    ThumbnailQueue q1(50, 1);
    TEST_ASSERT(q1.workerCount() == 1);

    ThumbnailQueue q2(50, 2);
    TEST_ASSERT(q2.workerCount() == 2);

    ThumbnailQueue q3(50, 3);
    TEST_ASSERT(q3.workerCount() == 2); // Clamped to 2

    ThumbnailQueue q64(50, 64);
    TEST_ASSERT(q64.workerCount() == 2); // Clamped to 2
  }

  // 2. Active workers never exceed 2
  {
    std::atomic<int> concurrentWorkers{0};
    std::atomic<int> peakConcurrentWorkers{0};
    std::atomic<size_t> finishedTasks{0};

    ThumbnailQueue queue(200, 2);
    queue.setTaskProcessor([&](const ThumbnailTask &) {
      int cur = concurrentWorkers.fetch_add(1) + 1;
      int prevPeak = peakConcurrentWorkers.load();
      while (cur > prevPeak && !peakConcurrentWorkers.compare_exchange_weak(prevPeak, cur)) {}

      std::this_thread::sleep_for(std::chrono::milliseconds(5));

      concurrentWorkers.fetch_sub(1);
      finishedTasks.fetch_add(1, std::memory_order_relaxed);
    });

    queue.start();

    for (int i = 0; i < 50; ++i) {
      ThumbnailTask t;
      t.key = "worker_limit_" + std::to_string(i);
      TEST_ASSERT(queue.enqueue(t));
    }

    for (int i = 0; i < 100; ++i) {
      if (finishedTasks == 50) break;
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }

    queue.stop();

    std::cout << "  [INFO] Peak concurrent worker threads observed: " << peakConcurrentWorkers.load() << std::endl;
    TEST_ASSERT(peakConcurrentWorkers.load() <= 2);
    TEST_ASSERT(peakConcurrentWorkers.load() >= 1);
  }

  // 3. Thread nice level priority verification
  {
    std::atomic<int> workerNiceLevel{-999};
    std::atomic<bool> ran{false};

    ThumbnailQueue queue(10, 1);
    queue.setTaskProcessor([&](const ThumbnailTask &) {
#if defined(__linux__) || defined(__unix__) || defined(__posix) || defined(__APPLE__)
      errno = 0;
      workerNiceLevel = getpriority(PRIO_PROCESS, 0);
#else
      workerNiceLevel = 10;
#endif
      ran = true;
    });

    queue.start();
    ThumbnailTask t;
    t.key = "prio_check";
    queue.enqueue(t);

    for (int i = 0; i < 50 && !ran; ++i) {
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }

    queue.stop();

    TEST_ASSERT(ran);
#if defined(__linux__) || defined(__unix__) || defined(__posix) || defined(__APPLE__)
    std::cout << "  [INFO] Observed worker nice level: " << workerNiceLevel.load() << std::endl;
    TEST_ASSERT(workerNiceLevel.load() >= 10);
#endif
  }

  std::cout << "  [PASS] CHALLENGE 4: Worker Count & Priority passed!" << std::endl;
}

// =============================================================================
// CHALLENGE 5: Pathological Task Payloads & Exception Resilience
// =============================================================================
static void testPathologicalPayloads() {
  std::cout << "\n=======================================================" << std::endl;
  std::cout << "[CHALLENGE 5] Pathological Payloads & Resilience" << std::endl;
  std::cout << "=======================================================" << std::endl;

  auto tempDir = createTempDir("pathological_test");
  utils::Config config;
  config.storageRoot = tempDir.string();

  ThumbnailQueue queue(config, nullptr, nullptr, 100, 2);
  queue.start();

  // 1. Task with non-existent source
  {
    ThumbnailTask t1;
    t1.key = "non_existent";
    t1.sourcePath = tempDir / "does_not_exist.jpg";
    t1.destWebpPath = tempDir / "thumb1.webp";
    t1.fileType = "photo";
    TEST_ASSERT(queue.enqueue(t1));
  }

  // 2. Task throwing custom exception in processor
  {
    ThumbnailTask t2;
    t2.key = "throwing_task";
    t2.customHandler = [](const ThumbnailTask &) {
      throw std::runtime_error("Simulated catastrophic task failure");
    };
    TEST_ASSERT(queue.enqueue(t2));
  }

  // 3. Task with empty key (should auto-generate)
  {
    ThumbnailTask t3;
    t3.ownerUserId = 42;
    t3.sha256 = "abc123sha";
    t3.thumbSize = 128;
    TEST_ASSERT(queue.enqueue(t3));
  }

  // 4. Task with extremely long key (32KB string)
  {
    ThumbnailTask t4;
    t4.key = std::string(32768, 'X');
    TEST_ASSERT(queue.enqueue(t4));
  }

  // 5. Valid task after all pathological tasks to verify queue health
  auto validPhoto = tempDir / "valid.webp";
  auto validThumb = tempDir / "valid_thumb.webp";
  {
    const int w = 16, h = 16;
    std::vector<uint8_t> rgba(w * h * 4, 150);
    uint8_t *webpData = nullptr;
    size_t webpSize = WebPEncodeRGBA(rgba.data(), w, h, w * 4, 80.0f, &webpData);
    std::ofstream out(validPhoto, std::ios::binary);
    out.write(reinterpret_cast<const char *>(webpData), webpSize);
    WebPFree(webpData);
  }

  ThumbnailTask tValid;
  tValid.key = "valid_after_chaos";
  tValid.sourcePath = validPhoto;
  tValid.destWebpPath = validThumb;
  tValid.fileType = "photo";
  tValid.thumbSize = 16;
  TEST_ASSERT(queue.enqueue(tValid));

  // Wait for queue to process everything
  for (int i = 0; i < 100; ++i) {
    if (std::filesystem::exists(validThumb) && queue.inFlightCount() == 0) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  queue.stop();

  TEST_ASSERT(std::filesystem::exists(validThumb));
  TEST_ASSERT(queue.inFlightCount() == 0);
  TEST_ASSERT(queue.activeCount() == 0);

  std::filesystem::remove_all(tempDir);
  std::cout << "  [PASS] CHALLENGE 5: Pathological Payloads & Resilience passed!" << std::endl;
}

// =============================================================================
// CHALLENGE 6: Concurrent Multi-User Upload Pipeline Simulation
// =============================================================================
static void testConcurrentMultiUserUploadPipeline() {
  std::cout << "\n=======================================================" << std::endl;
  std::cout << "[CHALLENGE 6] Multi-User Non-Blocking Upload Simulation" << std::endl;
  std::cout << "=======================================================" << std::endl;

  auto tempDir = createTempDir("multiuser_upload_test");
  auto dbPath = tempDir / "cloud.db";

  db::Database db(dbPath.string());
  db.migrate();

  utils::Config config;
  config.storageRoot = tempDir.string();
  config.dbPath = dbPath.string();
  config.encryptionKey = "adversarial_secret_key_12345678";

  FileService fileService(config);
  FileIndexService fileIndexService(db, fileService);

  ThumbnailQueue queue(config, &fileService, &fileIndexService, 500, 2);
  queue.start();

  const int numUsers = 5;
  const int photosPerUser = 10;
  std::vector<std::thread> userUploadThreads;
  userUploadThreads.reserve(numUsers);

  std::atomic<size_t> totalUploadsScheduled{0};

  for (int u = 1; u <= numUsers; ++u) {
    userUploadThreads.emplace_back([&, u]() {
      for (int p = 0; p < photosPerUser; ++p) {
        // 1. Create a dummy photo
        const int w = 32, h = 32;
        std::vector<uint8_t> rgba(w * h * 4, static_cast<uint8_t>((u * 30 + p * 10) % 255));
        uint8_t *webpData = nullptr;
        size_t webpSize = WebPEncodeRGBA(rgba.data(), w, h, w * 4, 80.0f, &webpData);

        std::string plainData(reinterpret_cast<char *>(webpData), webpSize);
        std::string sha256 = utils::sha256Hex(plainData);
        std::string cipherData = utils::encryptAes256(plainData, config.encryptionKey);
        WebPFree(webpData);

        auto userDir = tempDir / "data" / std::to_string(u);
        std::filesystem::create_directories(userDir);
        auto physicalFile = userDir / sha256;

        std::ofstream out(physicalFile, std::ios::binary);
        out.write(cipherData.data(), cipherData.size());
        out.close();

        std::string relPath = "photos/img_" + std::to_string(p) + ".webp";
        fileIndexService.upsertFileExplicit(
            u, StorageScope::Private, relPath, "img_" + std::to_string(p) + ".webp",
            webpSize, 12345678, "photo", "image/webp", u, sha256);

        // 2. Non-blocking thumbnail enqueue
        auto thumbDest = tempDir / ".thumbs" / std::to_string(u) / (sha256 + "_256.webp");
        bool scheduled = queue.scheduleThumbnail(
            u, u, StorageScope::Private, relPath, physicalFile, "photo", sha256, 256,
            true, config.encryptionKey, false, 0, thumbDest);

        TEST_ASSERT(scheduled);
        totalUploadsScheduled.fetch_add(1, std::memory_order_relaxed);
      }
    });
  }

  for (auto &t : userUploadThreads) {
    t.join();
  }

  std::cout << "  [INFO] Scheduled " << totalUploadsScheduled.load() << " encrypted uploads across " << numUsers << " users." << std::endl;

  // Wait for workers to finish all thumbnails
  for (int i = 0; i < 300; ++i) {
    if (queue.inFlightCount() == 0) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  queue.stop();

  TEST_ASSERT(queue.inFlightCount() == 0);

  // Verify all photos in SQLite have blurhash populated
  for (int u = 1; u <= numUsers; ++u) {
    ListIndexQuery q;
    q.ownerUserId = u;
    q.scope = StorageScope::Private;
    q.currentPath = "photos";
    auto entries = fileIndexService.listDirectory(q);
    TEST_ASSERT(entries.size() == static_cast<size_t>(photosPerUser));
    for (const auto &entry : entries) {
      TEST_ASSERT(!entry.blurhash.empty());
      TEST_ASSERT(entry.blurhash.length() >= 10);
    }
  }

  std::filesystem::remove_all(tempDir);
  std::cout << "  [PASS] CHALLENGE 6: Multi-User Non-Blocking Upload Simulation passed!" << std::endl;
}

// =============================================================================
// MAIN ENTRY POINT
// =============================================================================
int main() {
  std::cout << "=======================================================" << std::endl;
  std::cout << "M4 ADVERSARIAL STRESS TEST & CHALLENGE SUITE" << std::endl;
  std::cout << "=======================================================" << std::endl;

  testHighConcurrencyBurst();
  testRapidDeduplicationStress();
  testShutdownUnderContention();
  testWorkerCountAndPriority();
  testPathologicalPayloads();
  testConcurrentMultiUserUploadPipeline();

  std::cout << "\n=======================================================" << std::endl;
  std::cout << "ALL 6 ADVERSARIAL CHALLENGES PASSED EMPIRICALLY WITH ZERO DEFECTS!" << std::endl;
  std::cout << "=======================================================" << std::endl;
  return 0;
}
