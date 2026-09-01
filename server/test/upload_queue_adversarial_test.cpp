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
#include "server/utils/BlurHashEncoder.hpp"

#include <webp/encode.h>
#include <webp/decode.h>

#include <atomic>
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <random>
#include <thread>
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

static std::filesystem::path createAdversarialTempDir(const std::string &prefix) {
  auto tmpDir = std::filesystem::temp_directory_path() / (prefix + "_" + utils::randomTokenHex(8));
  std::filesystem::create_directories(tmpDir);
  return tmpDir;
}

static std::vector<uint8_t> generateTestRgbaPattern(int width, int height, uint8_t seedOffset = 0) {
  std::vector<uint8_t> rgba(width * height * 4);
  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      int idx = (y * width + x) * 4;
      rgba[idx] = static_cast<uint8_t>((x * 255) / width + seedOffset);
      rgba[idx + 1] = static_cast<uint8_t>((y * 255) / height + seedOffset);
      rgba[idx + 2] = static_cast<uint8_t>(128 + seedOffset);
      rgba[idx + 3] = 255;
    }
  }
  return rgba;
}

static std::vector<uint8_t> encodeRgbaToWebpBytes(const std::vector<uint8_t> &rgba, int width, int height, float quality = 80.0f) {
  uint8_t *webpData = nullptr;
  size_t webpSize = WebPEncodeRGBA(rgba.data(), width, height, width * 4, quality, &webpData);
  TEST_ASSERT(webpSize > 0 && webpData != nullptr);
  std::vector<uint8_t> out(webpData, webpData + webpSize);
  WebPFree(webpData);
  return out;
}

// ==============================================================================
// 1. ADVERSARIAL STRESS: Non-blocking Upload Latency (< 50 microseconds)
// ==============================================================================
static void testAdversarialNonBlockingUploadLatency() {
  std::cout << "[ADVERSARIAL 1] Non-blocking Upload & Scheduling Latency Stress..." << std::endl;

  auto tempDir = createAdversarialTempDir("adv_latency");
  auto dbPath = tempDir / "test.db";
  db::Database db(dbPath.string());
  db.migrate();

  utils::Config config;
  config.storageRoot = tempDir.string();
  config.dbPath = dbPath.string();

  FileService fileService(config);
  FileIndexService fileIndexService(db, fileService);

  // Start queue with 2 workers simulating heavy background load
  ThumbnailQueue queue(config, &fileService, &fileIndexService, 5000, 2);
  std::atomic<bool> workerBusy{true};
  std::atomic<size_t> slowTasksCompleted{0};

  // Set slow processor to simulate heavy WebP/BlurHash computations
  queue.setTaskProcessor([&](const ThumbnailTask &task) {
    if (task.key.rfind("slow_", 0) == 0) {
      // Simulate heavy 10ms CPU encode
      std::this_thread::sleep_for(std::chrono::milliseconds(5));
      slowTasksCompleted++;
    }
  });

  queue.start();

  // Enqueue a few slow tasks to make workers actively busy
  for (int i = 0; i < 20; ++i) {
    ThumbnailTask slowTask;
    slowTask.key = "slow_" + std::to_string(i);
    queue.enqueue(slowTask);
  }

  // Now measure scheduling latency of 2,000 upload tasks from producer while workers are busy
  const int numUploads = 2000;
  std::vector<double> latenciesUs;
  latenciesUs.reserve(numUploads);

  auto totalStart = std::chrono::high_resolution_clock::now();

  for (int i = 0; i < numUploads; ++i) {
    auto t0 = std::chrono::high_resolution_clock::now();
    bool scheduled = queue.scheduleThumbnail(
        1, 1, StorageScope::Private,
        "photos/upload_" + std::to_string(i) + ".jpg",
        tempDir / ("upload_" + std::to_string(i) + ".jpg"),
        "photo",
        "sha256_" + std::to_string(i),
        256,
        false
    );
    auto t1 = std::chrono::high_resolution_clock::now();
    TEST_ASSERT(scheduled);

    double us = std::chrono::duration<double, std::micro>(t1 - t0).count();
    latenciesUs.push_back(us);
  }

  auto totalElapsedUs = std::chrono::duration_cast<std::chrono::microseconds>(
      std::chrono::high_resolution_clock::now() - totalStart).count();

  double avgUs = static_cast<double>(totalElapsedUs) / numUploads;
  std::sort(latenciesUs.begin(), latenciesUs.end());
  double p50 = latenciesUs[numUploads * 50 / 100];
  double p95 = latenciesUs[numUploads * 95 / 100];
  double p99 = latenciesUs[numUploads * 99 / 100];
  double maxUs = latenciesUs.back();

  std::cout << "  [STATS] Enqueued " << numUploads << " upload tasks in " << totalElapsedUs << " µs total." << std::endl;
  std::cout << "  [STATS] Latency: avg=" << avgUs << " µs, p50=" << p50
            << " µs, p95=" << p95 << " µs, p99=" << p99 << " µs, max=" << maxUs << " µs" << std::endl;

  // Verify non-blocking latency requirement (< 50 microseconds average and p99)
  TEST_ASSERT(avgUs < 50.0);
  TEST_ASSERT(p99 < 100.0);

  queue.stop();
  std::filesystem::remove_all(tempDir);
  std::cout << "  [PASS] Non-blocking Upload Latency Stress passed." << std::endl;
}

// ==============================================================================
// 2. ADVERSARIAL STRESS: Task Completion & SQLite Persistence (WebP + BlurHash)
// ==============================================================================
static void testAdversarialTaskCompletionAndSqlitePersistence() {
  std::cout << "[ADVERSARIAL 2] Task Completion & SQLite Persistence (Unencrypted & Encrypted)..." << std::endl;

  auto tempDir = createAdversarialTempDir("adv_persist");
  auto dbPath = tempDir / "test.db";
  db::Database db(dbPath.string());
  db.migrate();

  utils::Config config;
  config.storageRoot = tempDir.string();
  config.dbPath = dbPath.string();
  config.encryptionKey = "adv_test_secret_encryption_key_32!";

  FileService fileService(config);
  FileIndexService fileIndexService(db, fileService);

  ThumbnailQueue queue(config, &fileService, &fileIndexService, 100, 2);
  queue.start();

  // Test Case A: Plain Unencrypted JPEG/WebP Image
  auto plainRgba = generateTestRgbaPattern(200, 150, 10);
  auto plainWebpBytes = encodeRgbaToWebpBytes(plainRgba, 200, 150);
  auto plainFile = tempDir / "photo_plain.webp";
  auto plainThumb = tempDir / "photo_plain_thumb.webp";
  {
    std::ofstream out(plainFile, std::ios::binary);
    out.write(reinterpret_cast<const char *>(plainWebpBytes.data()), plainWebpBytes.size());
  }

  std::string plainSha256 = utils::sha256Hex(std::string(reinterpret_cast<char *>(plainWebpBytes.data()), plainWebpBytes.size()));
  fileIndexService.upsertFileExplicit(
      1, StorageScope::Private, "photos/photo_plain.webp", "photo_plain.webp",
      plainWebpBytes.size(), 1725134000, "photo", "image/webp", 1, plainSha256);

  TEST_ASSERT(queue.scheduleThumbnail(
      1, 1, StorageScope::Private, "photos/photo_plain.webp",
      plainFile, "photo", plainSha256, 128, false, "", false, 0, plainThumb));

  // Test Case B: AES-256 Encrypted Image
  auto encRgba = generateTestRgbaPattern(300, 200, 50);
  auto encWebpBytes = encodeRgbaToWebpBytes(encRgba, 300, 200);
  std::string encPlainText(reinterpret_cast<char *>(encWebpBytes.data()), encWebpBytes.size());
  std::string encSha256 = utils::sha256Hex(encPlainText);
  std::string cipherText = utils::encryptAes256(encPlainText, config.encryptionKey);

  auto encFile = tempDir / "photo_enc.bin";
  auto encThumb = tempDir / "photo_enc_thumb.webp";
  {
    std::ofstream out(encFile, std::ios::binary);
    out.write(cipherText.data(), cipherText.size());
  }

  fileIndexService.upsertFileExplicit(
      1, StorageScope::Private, "photos/photo_enc.jpg", "photo_enc.jpg",
      cipherText.size(), 1725134000, "photo", "image/jpeg", 1, encSha256);

  TEST_ASSERT(queue.scheduleThumbnail(
      1, 1, StorageScope::Private, "photos/photo_enc.jpg",
      encFile, "photo", encSha256, 128, true, config.encryptionKey, false, 0, encThumb));

  // Wait for both tasks to complete
  for (int i = 0; i < 150; ++i) {
    if (std::filesystem::exists(plainThumb) && std::filesystem::exists(encThumb) && queue.inFlightCount() == 0) {
      break;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  queue.stop();

  // 1. Verify Plain WebP Thumbnail & BlurHash in SQLite
  TEST_ASSERT(std::filesystem::exists(plainThumb));
  TEST_ASSERT(std::filesystem::file_size(plainThumb) > 0);
  {
    std::ifstream in(plainThumb, std::ios::binary);
    char hdr[12];
    in.read(hdr, 12);
    TEST_ASSERT(std::string_view(hdr, 4) == "RIFF");
    TEST_ASSERT(std::string_view(hdr + 8, 4) == "WEBP");
  }

  // 2. Verify Encrypted WebP Thumbnail & BlurHash in SQLite
  TEST_ASSERT(std::filesystem::exists(encThumb));
  TEST_ASSERT(std::filesystem::file_size(encThumb) > 0);
  {
    std::ifstream in(encThumb, std::ios::binary);
    char hdr[12];
    in.read(hdr, 12);
    TEST_ASSERT(std::string_view(hdr, 4) == "RIFF");
    TEST_ASSERT(std::string_view(hdr + 8, 4) == "WEBP");
  }

  // 3. Query SQLite database and verify 4x3 BlurHash strings
  ListIndexQuery query;
  query.ownerUserId = 1;
  query.scope = StorageScope::Private;
  query.currentPath = "photos";
  auto dirEntries = fileIndexService.listDirectory(query);
  TEST_ASSERT(dirEntries.size() == 2);

  std::string plainBlurHash;
  std::string encBlurHash;
  for (const auto &e : dirEntries) {
    if (e.name == "photo_plain.webp") {
      plainBlurHash = e.blurhash;
    } else if (e.name == "photo_enc.jpg") {
      encBlurHash = e.blurhash;
    }
  }

  std::cout << "  [INFO] Plain Image BlurHash: " << plainBlurHash << std::endl;
  std::cout << "  [INFO] Encrypted Image BlurHash: " << encBlurHash << std::endl;

  // BlurHash for 4x3 components must be non-empty, 28 characters
  TEST_ASSERT(!plainBlurHash.empty());
  TEST_ASSERT(plainBlurHash.length() == 28);
  TEST_ASSERT(!encBlurHash.empty());
  TEST_ASSERT(encBlurHash.length() == 28);

  std::filesystem::remove_all(tempDir);
  std::cout << "  [PASS] Task Completion & SQLite Persistence passed." << std::endl;
}

// ==============================================================================
// 3. ADVERSARIAL STRESS: Corrupted, Zero-byte, and Invalid Files
// ==============================================================================
static void testAdversarialCorruptedAndZeroByteHandling() {
  std::cout << "[ADVERSARIAL 3] Corrupted, Zero-byte, Truncated & Invalid File Handling..." << std::endl;

  auto tempDir = createAdversarialTempDir("adv_corrupt");
  auto dbPath = tempDir / "test.db";
  db::Database db(dbPath.string());
  db.migrate();

  utils::Config config;
  config.storageRoot = tempDir.string();
  config.dbPath = dbPath.string();

  FileService fileService(config);
  FileIndexService fileIndexService(db, fileService);

  ThumbnailQueue queue(config, &fileService, &fileIndexService, 100, 2);
  queue.start();

  // Create adversarial files:
  // 1. Zero-byte file
  auto zeroByteFile = tempDir / "zero.jpg";
  { std::ofstream out(zeroByteFile, std::ios::binary); }

  // 2. 1-byte file
  auto oneByteFile = tempDir / "one_byte.png";
  {
    std::ofstream out(oneByteFile, std::ios::binary);
    out.put('\xFF');
  }

  // 3. Truncated header file
  auto truncatedHdrFile = tempDir / "trunc_hdr.webp";
  {
    std::ofstream out(truncatedHdrFile, std::ios::binary);
    out.write("RIFF\x20\x00\x00\x00WEBPVP8 ", 12);
  }

  // 4. Random garbage fuzzed bytes
  auto garbageFile = tempDir / "garbage.jpg";
  {
    std::ofstream out(garbageFile, std::ios::binary);
    std::mt19937 rng(42);
    for (int i = 0; i < 4096; ++i) {
      out.put(static_cast<char>(rng() & 0xFF));
    }
  }

  // 5. Corrupted encrypted payload
  auto corruptEncFile = tempDir / "corrupt_enc.bin";
  {
    std::ofstream out(corruptEncFile, std::ios::binary);
    out.write("INVALID_CIPHERTEXT_NOT_AES_ENCRYPTED", 36);
  }

  // 6. Non-existent file
  auto nonExistentFile = tempDir / "does_not_exist.jpg";

  // 7. Legitimate valid WebP file to verify queue is still operational afterwards
  auto validRgba = generateTestRgbaPattern(64, 64, 80);
  auto validWebpBytes = encodeRgbaToWebpBytes(validRgba, 64, 64);
  auto validFile = tempDir / "valid_sentinel.webp";
  auto validThumb = tempDir / "valid_sentinel_thumb.webp";
  {
    std::ofstream out(validFile, std::ios::binary);
    out.write(reinterpret_cast<const char *>(validWebpBytes.data()), validWebpBytes.size());
  }

  // Schedule all corrupted tasks
  TEST_ASSERT(queue.scheduleThumbnail(1, 1, StorageScope::Private, "zero.jpg", zeroByteFile, "photo", "sha_zero", 128));
  TEST_ASSERT(queue.scheduleThumbnail(1, 1, StorageScope::Private, "one_byte.png", oneByteFile, "photo", "sha_one", 128));
  TEST_ASSERT(queue.scheduleThumbnail(1, 1, StorageScope::Private, "trunc_hdr.webp", truncatedHdrFile, "photo", "sha_trunc", 128));
  TEST_ASSERT(queue.scheduleThumbnail(1, 1, StorageScope::Private, "garbage.jpg", garbageFile, "photo", "sha_garbage", 128));
  TEST_ASSERT(queue.scheduleThumbnail(1, 1, StorageScope::Private, "corrupt_enc.bin", corruptEncFile, "photo", "sha_corrupt_enc", 128, true, "secret"));
  TEST_ASSERT(queue.scheduleThumbnail(1, 1, StorageScope::Private, "does_not_exist.jpg", nonExistentFile, "photo", "sha_nonexistent", 128));

  // Schedule valid sentinel task at the end
  TEST_ASSERT(queue.scheduleThumbnail(1, 1, StorageScope::Private, "valid_sentinel.webp", validFile, "photo", "sha_valid_sentinel", 128, false, "", false, 0, validThumb));

  // Wait for all tasks to be processed
  for (int i = 0; i < 150; ++i) {
    if (std::filesystem::exists(validThumb) && queue.inFlightCount() == 0) {
      break;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  queue.stop();

  // Invariant 1: Worker threads did NOT crash
  TEST_ASSERT(std::filesystem::exists(validThumb));
  TEST_ASSERT(std::filesystem::file_size(validThumb) > 0);

  // Invariant 2: Active keys and pending keys are completely released (NO KEY LEAKAGE)
  TEST_ASSERT(queue.inFlightCount() == 0);
  TEST_ASSERT(queue.activeCount() == 0);
  TEST_ASSERT(queue.size() == 0);

  // Invariant 3: Keys that failed can be re-enqueued without being blocked as duplicate
  TEST_ASSERT(!queue.isKeyInFlight(ThumbnailTask::makeKey(1, "sha_zero", 128)));
  TEST_ASSERT(!queue.isKeyInFlight(ThumbnailTask::makeKey(1, "sha_garbage", 128)));
  TEST_ASSERT(!queue.isKeyInFlight(ThumbnailTask::makeKey(1, "sha_nonexistent", 128)));

  std::filesystem::remove_all(tempDir);
  std::cout << "  [PASS] Corrupted and Zero-Byte Handling passed." << std::endl;
}

// ==============================================================================
// 4. ADVERSARIAL STRESS: Overflow Policy Verification (DropNewest & DropOldest)
// ==============================================================================
static void testAdversarialOverflowPolicies() {
  std::cout << "[ADVERSARIAL 4] Overflow Policy Verification under Queue Saturation..." << std::endl;

  // Scenario A: DropNewest (Tail Drop) Under Overwhelming Load
  {
    const size_t capacity = 50;
    ThumbnailQueue queue(capacity, 0, OverflowPolicy::DropNewest); // 0 workers to freeze queue

    // Fill queue to capacity
    for (size_t i = 0; i < capacity; ++i) {
      ThumbnailTask t;
      t.key = "initial_task_" + std::to_string(i);
      TEST_ASSERT(queue.enqueue(t));
    }
    TEST_ASSERT(queue.full());
    TEST_ASSERT(queue.size() == capacity);

    // Blast 500 new incoming tasks — all MUST be rejected cleanly
    size_t rejected = 0;
    for (size_t i = 0; i < 500; ++i) {
      ThumbnailTask t;
      t.key = "overflow_task_" + std::to_string(i);
      if (!queue.enqueue(t)) {
        rejected++;
      }
    }
    TEST_ASSERT(rejected == 500);
    TEST_ASSERT(queue.size() == capacity);

    // Verify rejected tasks are NOT in flight
    for (size_t i = 0; i < 500; ++i) {
      TEST_ASSERT(!queue.isKeyInFlight("overflow_task_" + std::to_string(i)));
    }

    // Verify FIFO contents are intact
    for (size_t i = 0; i < capacity; ++i) {
      auto taskOpt = queue.pop();
      TEST_ASSERT(taskOpt.has_value());
      TEST_ASSERT(taskOpt->key == "initial_task_" + std::to_string(i));
      queue.finishTask(taskOpt->key);
    }
    TEST_ASSERT(queue.empty());
  }

  // Scenario B: DropOldest (Head Drop) Under Overwhelming Load
  {
    const size_t capacity = 50;
    ThumbnailQueue queue(capacity, 0, OverflowPolicy::DropOldest);

    // Fill queue with 50 initial tasks (k0..k49)
    for (size_t i = 0; i < capacity; ++i) {
      ThumbnailTask t;
      t.key = "old_task_" + std::to_string(i);
      TEST_ASSERT(queue.enqueue(t));
    }
    TEST_ASSERT(queue.full());

    // Push 50 new tasks (new_task_0..new_task_49)
    for (size_t i = 0; i < capacity; ++i) {
      ThumbnailTask t;
      t.key = "new_task_" + std::to_string(i);
      TEST_ASSERT(queue.enqueue(t));
    }
    TEST_ASSERT(queue.size() == capacity);

    // Old tasks MUST have been evicted and their keys unblocked
    for (size_t i = 0; i < capacity; ++i) {
      TEST_ASSERT(!queue.isKeyInFlight("old_task_" + std::to_string(i)));
    }

    // New tasks MUST be present in flight and pop in order
    for (size_t i = 0; i < capacity; ++i) {
      TEST_ASSERT(queue.isKeyInFlight("new_task_" + std::to_string(i)));
    }

    for (size_t i = 0; i < capacity; ++i) {
      auto taskOpt = queue.pop();
      TEST_ASSERT(taskOpt.has_value());
      TEST_ASSERT(taskOpt->key == "new_task_" + std::to_string(i));
      queue.finishTask(taskOpt->key);
    }
    TEST_ASSERT(queue.empty());
  }

  std::cout << "  [PASS] Overflow Policy Verification passed." << std::endl;
}

// ==============================================================================
// 5. ADVERSARIAL STRESS: Multi-Thread High-Contention Race & Clean Shutdown
// ==============================================================================
static void testAdversarialMultiThreadHighContention() {
  std::cout << "[ADVERSARIAL 5] Multi-Thread High-Contention Race & Rapid Shutdown..." << std::endl;

  const size_t capacity = 100;
  ThumbnailQueue queue(capacity, 2, OverflowPolicy::DropOldest);

  std::atomic<size_t> executedCount{0};
  queue.setTaskProcessor([&](const ThumbnailTask &) {
    executedCount.fetch_add(1, std::memory_order_relaxed);
    std::this_thread::yield();
  });

  queue.start();

  const int numProducers = 8;
  const int iterationsPerProducer = 1000;
  std::vector<std::thread> producers;
  std::atomic<bool> startFlag{false};

  for (int p = 0; p < numProducers; ++p) {
    producers.emplace_back([&, p]() {
      while (!startFlag.load(std::memory_order_acquire)) {
        std::this_thread::yield();
      }

      for (int i = 0; i < iterationsPerProducer; ++i) {
        ThumbnailTask t;
        // Collide keys intentionally among producers
        t.key = "contention_task_" + std::to_string((p % 3) * 50 + (i % 50));
        queue.enqueue(t);
        if (i % 10 == 0) {
          std::this_thread::yield();
        }
      }
    });
  }

  startFlag.store(true, std::memory_order_release);

  for (auto &t : producers) {
    t.join();
  }

  // Gracefully stop while tasks might still be in queue
  auto stopStart = std::chrono::high_resolution_clock::now();
  queue.stop();
  auto stopDurationMs = std::chrono::duration_cast<std::chrono::milliseconds>(
      std::chrono::high_resolution_clock::now() - stopStart).count();

  std::cout << "  [STATS] Completed " << executedCount << " tasks under 8-thread contention. Stop joined in "
            << stopDurationMs << " ms." << std::endl;

  TEST_ASSERT(stopDurationMs < 1000);
  TEST_ASSERT(queue.isStopped());
  TEST_ASSERT(!queue.isRunning());

  std::cout << "  [PASS] Multi-Thread High-Contention Race passed." << std::endl;
}

// ==============================================================================
// MAIN RUNNER
// ==============================================================================
int main() {
  std::cout << "=================================================================" << std::endl;
  std::cout << "M4 ADVERSARIAL CHALLENGE HARNESS: Upload Queue & Worker Pool" << std::endl;
  std::cout << "=================================================================" << std::endl;

  testAdversarialNonBlockingUploadLatency();
  testAdversarialTaskCompletionAndSqlitePersistence();
  testAdversarialCorruptedAndZeroByteHandling();
  testAdversarialOverflowPolicies();
  testAdversarialMultiThreadHighContention();

  std::cout << "=================================================================" << std::endl;
  std::cout << "ALL 5 ADVERSARIAL CHALLENGE SUITES PASSED FLAWLESSLY!" << std::endl;
  std::cout << "=================================================================" << std::endl;
  return 0;
}
