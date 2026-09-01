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

#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <thread>
#include <vector>

#if defined(__linux__) || defined(__unix__) || defined(__posix) || defined(__APPLE__)
#include <sys/resource.h>
#include <unistd.h>
#endif

#define TEST_ASSERT(cond) \
  do { \
    if (!(cond)) { \
      std::cerr << "\n[ASSERTION FAILED] " #cond " at " << __FILE__ << ":" << __LINE__ << std::endl; \
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

// 1. Basic Enqueue & Pop (FIFO ordering, bounds, empty/full)
static void testBasicEnqueueAndPop() {
  std::cout << "[TEST] Running Basic Enqueue & Pop test..." << std::endl;
  ThumbnailQueue queue(10, 0); // 0 workers for synchronous testing

  TEST_ASSERT(queue.empty());
  TEST_ASSERT(!queue.full());
  TEST_ASSERT(queue.size() == 0);
  TEST_ASSERT(queue.inFlightCount() == 0);

  ThumbnailTask t1;
  t1.key = "user1:file1:256";
  t1.thumbSize = 256;

  ThumbnailTask t2;
  t2.key = "user1:file2:256";
  t2.thumbSize = 256;

  TEST_ASSERT(queue.enqueue(t1));
  TEST_ASSERT(queue.size() == 1);
  TEST_ASSERT(queue.isKeyInFlight("user1:file1:256"));
  TEST_ASSERT(!queue.empty());

  TEST_ASSERT(queue.enqueue(t2));
  TEST_ASSERT(queue.size() == 2);
  TEST_ASSERT(queue.isKeyInFlight("user1:file2:256"));

  // Pop FIFO
  auto popped1 = queue.pop();
  TEST_ASSERT(popped1.has_value());
  TEST_ASSERT(popped1->key == "user1:file1:256");
  TEST_ASSERT(queue.size() == 1);
  TEST_ASSERT(queue.activeCount() == 1);
  TEST_ASSERT(queue.isKeyInFlight("user1:file1:256"));

  auto popped2 = queue.pop();
  TEST_ASSERT(popped2.has_value());
  TEST_ASSERT(popped2->key == "user1:file2:256");
  TEST_ASSERT(queue.size() == 0);
  TEST_ASSERT(queue.activeCount() == 2);

  queue.finishTask("user1:file1:256");
  TEST_ASSERT(queue.activeCount() == 1);
  TEST_ASSERT(!queue.isKeyInFlight("user1:file1:256"));

  queue.finishTask("user1:file2:256");
  TEST_ASSERT(queue.activeCount() == 0);
  TEST_ASSERT(!queue.isKeyInFlight("user1:file2:256"));
  TEST_ASSERT(queue.inFlightCount() == 0);

  std::cout << "  [PASS] Basic Enqueue & Pop passed." << std::endl;
}

// 2. Dual-Set Deduplication: Pending & Active
static void testDeduplication() {
  std::cout << "[TEST] Running Dual-Set Deduplication test..." << std::endl;
  ThumbnailQueue queue(10, 0);

  ThumbnailTask task;
  task.key = "user1:photo.jpg:256";
  task.thumbSize = 256;

  // First enqueue succeeds
  TEST_ASSERT(queue.enqueue(task));
  TEST_ASSERT(queue.size() == 1);

  // Second enqueue while pending fails (O(1) rejection)
  TEST_ASSERT(!queue.enqueue(task));
  TEST_ASSERT(queue.size() == 1);
  TEST_ASSERT(queue.inFlightCount() == 1);

  // Pop moves to active
  auto popped = queue.pop();
  TEST_ASSERT(popped.has_value());
  TEST_ASSERT(queue.size() == 0);
  TEST_ASSERT(queue.activeCount() == 1);

  // Third enqueue while active fails
  TEST_ASSERT(!queue.enqueue(task));
  TEST_ASSERT(queue.size() == 0);
  TEST_ASSERT(queue.activeCount() == 1);

  // Finish task clears active key
  queue.finishTask(task.key);
  TEST_ASSERT(queue.activeCount() == 0);
  TEST_ASSERT(!queue.isKeyInFlight(task.key));

  // Fourth enqueue now succeeds
  TEST_ASSERT(queue.enqueue(task));
  TEST_ASSERT(queue.size() == 1);

  std::cout << "  [PASS] Dual-Set Deduplication passed." << std::endl;
}

// 3. Bounded Capacity & Overflow Policies
static void testBoundedCapacityPolicies() {
  std::cout << "[TEST] Running Bounded Capacity Policies test..." << std::endl;

  // DropNewest policy
  {
    ThumbnailQueue queue(3, 0, OverflowPolicy::DropNewest);
    for (int i = 1; i <= 3; ++i) {
      ThumbnailTask t;
      t.key = "k" + std::to_string(i);
      TEST_ASSERT(queue.enqueue(t));
    }
    TEST_ASSERT(queue.full());
    TEST_ASSERT(queue.size() == 3);

    // 4th task dropped
    ThumbnailTask t4;
    t4.key = "k4";
    TEST_ASSERT(!queue.enqueue(t4));
    TEST_ASSERT(queue.size() == 3);
    TEST_ASSERT(!queue.isKeyInFlight("k4"));
  }

  // DropOldest policy
  {
    ThumbnailQueue queue(3, 0, OverflowPolicy::DropOldest);
    for (int i = 1; i <= 3; ++i) {
      ThumbnailTask t;
      t.key = "k" + std::to_string(i);
      TEST_ASSERT(queue.enqueue(t));
    }
    TEST_ASSERT(queue.full());

    // 4th task evicts oldest (k1)
    ThumbnailTask t4;
    t4.key = "k4";
    TEST_ASSERT(queue.enqueue(t4));
    TEST_ASSERT(queue.size() == 3);
    TEST_ASSERT(!queue.isKeyInFlight("k1"));
    TEST_ASSERT(queue.isKeyInFlight("k2"));
    TEST_ASSERT(queue.isKeyInFlight("k3"));
    TEST_ASSERT(queue.isKeyInFlight("k4"));

    auto pop1 = queue.pop();
    TEST_ASSERT(pop1->key == "k2");
    auto pop2 = queue.pop();
    TEST_ASSERT(pop2->key == "k3");
    auto pop3 = queue.pop();
    TEST_ASSERT(pop3->key == "k4");
  }

  std::cout << "  [PASS] Bounded Capacity Policies passed." << std::endl;
}

// 4. Worker Pool Limits (Strictly 1–2 threads clamped)
static void testWorkerLimits() {
  std::cout << "[TEST] Running Worker Limits & Clamping test..." << std::endl;

  ThumbnailQueue q0(100, 0);
  TEST_ASSERT(q0.workerCount() == 0);

  ThumbnailQueue q1(100, 1);
  TEST_ASSERT(q1.workerCount() == 1);

  ThumbnailQueue q2(100, 2);
  TEST_ASSERT(q2.workerCount() == 2);

  // Clamped to 2 max
  ThumbnailQueue q8(100, 8);
  TEST_ASSERT(q8.workerCount() == 2);

  ThumbnailQueue q16(100, 16);
  TEST_ASSERT(q16.workerCount() == 2);

  std::cout << "  [PASS] Worker Limits & Clamping passed." << std::endl;
}

// 5. Worker Low Priority (nice 10 / setpriority)
static void testWorkerLowPriority() {
  std::cout << "[TEST] Running Worker Low Priority test..." << std::endl;

  std::atomic<int> workerNiceValue{-999};
  std::atomic<bool> executed{false};

  ThumbnailQueue queue(10, 1);
  queue.setTaskProcessor([&](const ThumbnailTask &) {
#if defined(__linux__) || defined(__unix__) || defined(__posix) || defined(__APPLE__)
    errno = 0;
    int p = getpriority(PRIO_PROCESS, 0);
    workerNiceValue = p;
#else
    workerNiceValue = 10;
#endif
    executed = true;
  });

  queue.start();

  ThumbnailTask task;
  task.key = "priority_test";
  queue.enqueue(task);

  for (int i = 0; i < 50 && !executed; ++i) {
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }

  queue.stop();

  TEST_ASSERT(executed);
#if defined(__linux__) || defined(__unix__) || defined(__posix) || defined(__APPLE__)
  std::cout << "  [INFO] Worker thread nice level observed: " << workerNiceValue << std::endl;
  TEST_ASSERT(workerNiceValue >= 10);
#endif

  std::cout << "  [PASS] Worker Low Priority passed." << std::endl;
}

// 6. Graceful Shutdown & Unblock
static void testGracefulShutdown() {
  std::cout << "[TEST] Running Graceful Shutdown test..." << std::endl;

  ThumbnailQueue queue(10, 2);
  queue.start();

  TEST_ASSERT(queue.isRunning());
  TEST_ASSERT(!queue.isStopped());

  auto start = std::chrono::steady_clock::now();
  queue.stop();
  auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - start).count();

  TEST_ASSERT(queue.isStopped());
  TEST_ASSERT(!queue.isRunning());
  TEST_ASSERT(elapsed < 500); // Must unblock and join almost immediately

  // After stop, enqueue returns false
  ThumbnailTask task;
  task.key = "after_stop";
  TEST_ASSERT(!queue.enqueue(task));

  std::cout << "  [PASS] Graceful Shutdown passed." << std::endl;
}

// 7. Concurrent Multi-threaded Producer/Consumer Stress Test
static void testConcurrentStress() {
  std::cout << "[TEST] Running Concurrent Multi-threaded Stress test..." << std::endl;

  const size_t totalTasks = 2000;
  std::atomic<size_t> processedTasks{0};

  ThumbnailQueue queue(500, 2, OverflowPolicy::DropNewest);
  queue.setTaskProcessor([&](const ThumbnailTask &) {
    processedTasks.fetch_add(1, std::memory_order_relaxed);
    std::this_thread::yield();
  });

  queue.start();

  const int numProducers = 4;
  std::vector<std::thread> producers;
  std::atomic<size_t> enqueuedCount{0};

  for (int p = 0; p < numProducers; ++p) {
    producers.emplace_back([&, p]() {
      for (size_t i = 0; i < totalTasks / numProducers; ++i) {
        ThumbnailTask t;
        // Intentionally create duplicate collisions
        t.key = "task_" + std::to_string(p * 10000 + (i % 200));
        if (queue.enqueue(t)) {
          enqueuedCount.fetch_add(1, std::memory_order_relaxed);
        }
        if (i % 20 == 0) {
          std::this_thread::yield();
        }
      }
    });
  }

  for (auto &t : producers) {
    t.join();
  }

  // Wait for queue to drain
  for (int i = 0; i < 150; ++i) {
    if (queue.size() == 0 && queue.activeCount() == 0) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  queue.stop();

  std::cout << "  [INFO] Enqueued: " << enqueuedCount << ", Processed: " << processedTasks << std::endl;
  TEST_ASSERT(processedTasks > 0);
  TEST_ASSERT(queue.size() == 0);
  TEST_ASSERT(queue.activeCount() == 0);
  TEST_ASSERT(queue.inFlightCount() == 0);

  std::cout << "  [PASS] Concurrent Multi-threaded Stress passed." << std::endl;
}

// 8. End-to-End In-Memory Photo WebP + BlurHash Pipeline with SQLite Integration
static void testPhotoWebPAndBlurHashPipeline() {
  std::cout << "[TEST] Running End-to-End Photo WebP + BlurHash Pipeline test..." << std::endl;

  auto tempDir = createTempDir("thumb_pipeline_test");
  auto dbPath = tempDir / "test.db";
  auto sourceImage = tempDir / "test_photo.webp";
  auto thumbWebp = tempDir / "test_thumb.webp";

  // Create SQLite DB
  db::Database db(dbPath.string());
  db.migrate();

  utils::Config config;
  config.storageRoot = tempDir.string();
  config.dbPath = dbPath.string();

  FileService fileService(config);
  FileIndexService fileIndexService(db, fileService);

  // Generate a test uncompressed RGBA image and save as WebP
  const int w = 128, h = 128;
  std::vector<uint8_t> rgba(w * h * 4);
  for (int y = 0; y < h; ++y) {
    for (int x = 0; x < w; ++x) {
      int idx = (y * w + x) * 4;
      rgba[idx] = static_cast<uint8_t>((x * 255) / w);
      rgba[idx + 1] = static_cast<uint8_t>((y * 255) / h);
      rgba[idx + 2] = 128;
      rgba[idx + 3] = 255;
    }
  }

  uint8_t *webpData = nullptr;
  size_t webpSize = WebPEncodeRGBA(rgba.data(), w, h, w * 4, 90.0f, &webpData);
  TEST_ASSERT(webpSize > 0 && webpData != nullptr);
  std::ofstream out(sourceImage, std::ios::binary);
  out.write(reinterpret_cast<const char *>(webpData), webpSize);
  out.close();
  WebPFree(webpData);

  // Upsert file into SQLite index
  std::string sha256 = utils::sha256Hex(std::string(reinterpret_cast<char *>(rgba.data()), rgba.size()));
  fileIndexService.upsertFileExplicit(1, StorageScope::Private, "photos/test.webp", "test.webp", webpSize, 123456789, "photo", "image/webp", 1, sha256);

  // Initialize ThumbnailQueue with genuine services and 1 worker
  ThumbnailQueue queue(config, &fileService, &fileIndexService, 100, 1);
  queue.start();

  TEST_ASSERT(queue.scheduleThumbnail(1, 1, StorageScope::Private, "photos/test.webp", sourceImage, "photo", sha256, 64, false, "", false, 0, thumbWebp));

  // Wait for worker to finish
  for (int i = 0; i < 100; ++i) {
    if (std::filesystem::exists(thumbWebp) && queue.inFlightCount() == 0) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  queue.stop();

  // Verify WebP thumbnail exists
  TEST_ASSERT(std::filesystem::exists(thumbWebp));
  TEST_ASSERT(std::filesystem::file_size(thumbWebp) > 0);

  // Verify WebP header
  std::ifstream thumbIn(thumbWebp, std::ios::binary);
  char header[12];
  thumbIn.read(header, 12);
  TEST_ASSERT(std::string_view(header, 4) == "RIFF");
  TEST_ASSERT(std::string_view(header + 8, 4) == "WEBP");

  // Verify SQLite file_index has blurhash column populated
  ListIndexQuery q;
  q.ownerUserId = 1;
  q.scope = StorageScope::Private;
  q.currentPath = "photos";
  auto entries = fileIndexService.listDirectory(q);
  TEST_ASSERT(!entries.empty());
  bool foundBlurHash = false;
  for (const auto &entry : entries) {
    if (entry.name == "test.webp") {
      TEST_ASSERT(!entry.blurhash.empty());
      std::cout << "  [INFO] Computed BlurHash: " << entry.blurhash << std::endl;
      foundBlurHash = true;
      break;
    }
  }
  TEST_ASSERT(foundBlurHash);

  std::filesystem::remove_all(tempDir);
  std::cout << "  [PASS] End-to-End Photo WebP + BlurHash Pipeline passed." << std::endl;
}

// 9. Corrupted Image Resilience
static void testCorruptedImageResilience() {
  std::cout << "[TEST] Running Corrupted Image Resilience test..." << std::endl;

  auto tempDir = createTempDir("corrupt_test");
  auto corruptFile = tempDir / "corrupt.jpg";
  auto validFile = tempDir / "valid.webp";
  auto thumbCorrupt = tempDir / "corrupt.webp";
  auto thumbValid = tempDir / "valid.webp";

  // Write garbage to corrupt file
  {
    std::ofstream out(corruptFile, std::ios::binary);
    out << "NOT_A_VALID_IMAGE_DATA_CORRUPT_BYTES_0123456789";
  }

  // Write valid WebP image
  {
    const int w = 32, h = 32;
    std::vector<uint8_t> rgba(w * h * 4, 200);
    uint8_t *webpData = nullptr;
    size_t webpSize = WebPEncodeRGBA(rgba.data(), w, h, w * 4, 90.0f, &webpData);
    std::ofstream out(validFile, std::ios::binary);
    out.write(reinterpret_cast<const char *>(webpData), webpSize);
    WebPFree(webpData);
  }

  utils::Config config;
  config.storageRoot = tempDir.string();

  ThumbnailQueue queue(config, nullptr, nullptr, 100, 1);
  queue.start();

  // Enqueue corrupt task
  TEST_ASSERT(queue.scheduleThumbnail(1, 1, StorageScope::Private, "corrupt.jpg", corruptFile, "photo", "sha_corrupt", 64, false, "", false, 0, thumbCorrupt));

  // Enqueue valid task
  TEST_ASSERT(queue.scheduleThumbnail(1, 1, StorageScope::Private, "valid.webp", validFile, "photo", "sha_valid", 64, false, "", false, 0, thumbValid));

  // Wait for completion
  for (int i = 0; i < 100; ++i) {
    if (std::filesystem::exists(thumbValid) && queue.inFlightCount() == 0) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  queue.stop();

  // Valid thumbnail succeeded despite corrupted image processed before it
  TEST_ASSERT(std::filesystem::exists(thumbValid));
  TEST_ASSERT(queue.inFlightCount() == 0);

  std::filesystem::remove_all(tempDir);
  std::cout << "  [PASS] Corrupted Image Resilience passed." << std::endl;
}

int main() {
  std::cout << "==================================================" << std::endl;
  std::cout << "Starting ThumbnailQueue & Worker Pool Test Suite" << std::endl;
  std::cout << "==================================================" << std::endl;

  testBasicEnqueueAndPop();
  testDeduplication();
  testBoundedCapacityPolicies();
  testWorkerLimits();
  testWorkerLowPriority();
  testGracefulShutdown();
  testConcurrentStress();
  testPhotoWebPAndBlurHashPipeline();
  testCorruptedImageResilience();

  std::cout << "==================================================" << std::endl;
  std::cout << "ALL 9 TEST SUITES PASSED SUCCESSFULLY!" << std::endl;
  std::cout << "==================================================" << std::endl;
  return 0;
}
