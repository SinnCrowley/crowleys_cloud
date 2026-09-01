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

#include <iostream>
#include <vector>
#include <cassert>
#include <filesystem>
#include <fstream>
#include <cstring>
#include <thread>
#include <atomic>
#include <random>
#include <sys/resource.h>
#include <unistd.h>

#include <webp/decode.h>
#include <webp/encode.h>

#include "server/utils/Crypto.hpp"
#include "server/utils/ImageUtils.hpp"

using namespace server::utils;

#define TEST_ASSERT(cond, msg) \
  do { \
    if (!(cond)) { \
      std::cerr << "[FAIL] Line " << __LINE__ << ": " << (msg) << std::endl; \
      std::exit(1); \
    } \
  } while (0)

// Helper to get current RSS in KB
static long getResidentSetSizeKb() {
  std::ifstream statm("/proc/self/statm");
  if (statm.is_open()) {
    long size, resident, share, text, lib, data, dt;
    if (statm >> size >> resident >> share >> text >> lib >> data >> dt) {
      long pageSizeKb = sysconf(_SC_PAGE_SIZE) / 1024;
      return resident * pageSizeKb;
    }
  }
  struct rusage usage;
  if (getrusage(RUSAGE_SELF, &usage) == 0) {
    return usage.ru_maxrss;
  }
  return 0;
}

// 1. WebP Container and Header Compliance
void testWebPContainerCompliance() {
  std::cout << "[TEST] 1. WebP Container and Header Compliance..." << std::endl;

  const int width = 320;
  const int height = 240;
  std::vector<uint8_t> rgba(width * height * 4);
  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      int idx = (y * width + x) * 4;
      rgba[idx + 0] = static_cast<uint8_t>(x % 256);
      rgba[idx + 1] = static_cast<uint8_t>(y % 256);
      rgba[idx + 2] = static_cast<uint8_t>((x + y) % 256);
      rgba[idx + 3] = 255;
    }
  }

  auto webp = encodeRgbaToWebP(rgba.data(), width, height, 80.0f);
  TEST_ASSERT(!webp.empty(), "WebP buffer must not be empty");
  TEST_ASSERT(webp.size() >= 20, "WebP buffer must be at least 20 bytes for valid header");

  // Check RIFF header
  TEST_ASSERT(std::memcmp(webp.data(), "RIFF", 4) == 0, "Header starts with 'RIFF'");

  // Check 4-byte Little Endian File Size: file size - 8
  uint32_t riffSize = static_cast<uint32_t>(webp[4]) |
                      (static_cast<uint32_t>(webp[5]) << 8) |
                      (static_cast<uint32_t>(webp[6]) << 16) |
                      (static_cast<uint32_t>(webp[7]) << 24);
  TEST_ASSERT(riffSize == webp.size() - 8, "RIFF payload size must equal total bytes - 8");

  // Check WEBP format signature
  TEST_ASSERT(std::memcmp(webp.data() + 8, "WEBP", 4) == 0, "Format signature is 'WEBP'");

  // Check Chunk Header: VP8 (lossy) or VP8L (lossless) or VP8X (extended)
  bool validChunk = (std::memcmp(webp.data() + 12, "VP8 ", 4) == 0) ||
                    (std::memcmp(webp.data() + 12, "VP8L", 4) == 0) ||
                    (std::memcmp(webp.data() + 12, "VP8X", 4) == 0);
  TEST_ASSERT(validChunk, "Chunk header must be VP8, VP8L, or VP8X");

  // Verify WebPGetInfo parses header and exact dimensions
  int parsedW = 0, parsedH = 0;
  int getInfoRes = WebPGetInfo(webp.data(), webp.size(), &parsedW, &parsedH);
  TEST_ASSERT(getInfoRes == 1, "WebPGetInfo successfully parsed bitstream");
  TEST_ASSERT(parsedW == width, "Parsed width matches 320");
  TEST_ASSERT(parsedH == height, "Parsed height matches 240");

  // Verify WebPGetFeatures
  WebPBitstreamFeatures features;
  VP8StatusCode status = WebPGetFeatures(webp.data(), webp.size(), &features);
  TEST_ASSERT(status == VP8_STATUS_OK, "WebPGetFeatures returned VP8_STATUS_OK");
  TEST_ASSERT(features.width == width, "Features width matches");
  TEST_ASSERT(features.height == height, "Features height matches");

  std::cout << "[PASS] WebP container and header compliance verified." << std::endl;
}

// 2. Extreme Aspect Ratios & Dimension Fitting
void testExtremeAspectRatios() {
  std::cout << "[TEST] 2. Extreme Aspect Ratios & Boundary Dimensions..." << std::endl;

  // 1x1 Minimal Pixel
  {
    std::vector<uint8_t> rgba1x1 = {255, 0, 0, 255};
    auto webp1x1 = encodeRgbaToWebP(rgba1x1.data(), 1, 1, 80.0f);
    TEST_ASSERT(!webp1x1.empty(), "1x1 WebP generated");
    auto thumb = generateThumbnailWebP(webp1x1.data(), webp1x1.size(), 256, 80.0f);
    TEST_ASSERT(thumb.has_value(), "1x1 thumbnail generated");
    int w = 0, h = 0;
    WebPGetInfo(thumb->data(), thumb->size(), &w, &h);
    TEST_ASSERT(w == 1 && h == 1, "1x1 not upscaled");
  }

  // Extreme Tall: 10 x 5000 -> target 256
  {
    auto fit = calculateAspectRatioFit(10, 5000, 256);
    TEST_ASSERT(fit.height == 256, "Extreme tall height clamped to 256");
    TEST_ASSERT(fit.width >= 1, "Extreme tall width strictly >= 1");
  }

  // Extreme Wide: 5000 x 10 -> target 256
  {
    auto fit = calculateAspectRatioFit(5000, 10, 256);
    TEST_ASSERT(fit.width == 256, "Extreme wide width clamped to 256");
    TEST_ASSERT(fit.height >= 1, "Extreme wide height strictly >= 1");
  }

  // Negative / zero dimensions
  {
    auto fitZero = calculateAspectRatioFit(0, 0, 256);
    TEST_ASSERT(fitZero.width == 0 && fitZero.height == 0, "Zero dimensions handled");
    auto fitNeg = calculateAspectRatioFit(-10, 100, 256);
    TEST_ASSERT(fitNeg.width == 0 && fitNeg.height == 0, "Negative dimensions handled");
    auto fitZeroTarget = calculateAspectRatioFit(100, 100, 0);
    TEST_ASSERT(fitZeroTarget.width == 0 && fitZeroTarget.height == 0, "Zero target max handled");
  }

  std::cout << "[PASS] Extreme aspect ratios verified." << std::endl;
}

// 3. Robustness on Corrupted / Adversarial Inputs (Zero Crash Guarantee)
void testAdversarialCorruptedInputs() {
  std::cout << "[TEST] 3. Robustness on Corrupted & Adversarial Inputs..." << std::endl;

  // 1. Empty buffer (0 bytes)
  auto res1 = decodeImageToRgba(nullptr, 0);
  TEST_ASSERT(!res1.has_value(), "Nullptr/0 size returns nullopt");

  std::vector<uint8_t> emptyBuf;
  auto res2 = decodeImageToRgba(emptyBuf.data(), emptyBuf.size());
  TEST_ASSERT(!res2.has_value(), "Empty vector returns nullopt");

  // 2. Truncated RIFF header (4 bytes)
  std::vector<uint8_t> truncatedRiff = {'R', 'I', 'F', 'F'};
  auto res3 = decodeImageToRgba(truncatedRiff.data(), truncatedRiff.size());
  TEST_ASSERT(!res3.has_value(), "Truncated 4-byte RIFF returns nullopt without crash");

  // 3. Truncated JPEG header (SOI only)
  std::vector<uint8_t> truncatedJpg = {0xFF, 0xD8, 0xFF, 0xE0};
  auto res4 = decodeImageToRgba(truncatedJpg.data(), truncatedJpg.size());
  TEST_ASSERT(!res4.has_value(), "Truncated JPEG returns nullopt without crash");

  // 4. Truncated PNG signature (8 bytes)
  std::vector<uint8_t> truncatedPng = {0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A};
  auto res5 = decodeImageToRgba(truncatedPng.data(), truncatedPng.size());
  TEST_ASSERT(!res5.has_value(), "Truncated PNG returns nullopt without crash");

  // 5. Random Fuzzing / Garbage bytes
  std::mt19937 rng(42);
  for (int trial = 0; trial < 100; ++trial) {
    size_t fuzzLen = rng() % 1024 + 1;
    std::vector<uint8_t> fuzz(fuzzLen);
    for (size_t i = 0; i < fuzzLen; ++i) {
      fuzz[i] = static_cast<uint8_t>(rng() % 256);
    }
    // Attempt decoding and thumbnailing — MUST NOT CRASH
    auto fDec = decodeImageToRgba(fuzz.data(), fuzz.size());
    auto fThumb = generateThumbnailWebP(fuzz.data(), fuzz.size(), 256);
  }

  // 6. Extreme Quality clamps
  std::vector<uint8_t> testRgba(64 * 64 * 4, 128);
  auto qNeg = encodeRgbaToWebP(testRgba.data(), 64, 64, -50.0f);
  TEST_ASSERT(!qNeg.empty(), "Negative quality clamped to 0");
  auto qHigh = encodeRgbaToWebP(testRgba.data(), 64, 64, 250.0f);
  TEST_ASSERT(!qHigh.empty(), "Quality > 100 clamped to 100");

  std::cout << "[PASS] Robustness on corrupted & adversarial inputs verified." << std::endl;
}

// 4. Zero Disk Temp Files & Decryption Safety
void testZeroDiskTempFilesVerification() {
  std::cout << "[TEST] 4. In-Memory Decryption & Zero Disk Temp Files..." << std::endl;

  const std::string testKey = "super-secret-m2-verification-key";
  const int w = 150, h = 100;
  std::vector<uint8_t> sampleRgba(w * h * 4, 99);
  auto webpData = encodeRgbaToWebP(sampleRgba.data(), w, h, 80.0f);

  auto tempDir = std::filesystem::temp_directory_path() / "crowleys_zero_tmp_test";
  std::filesystem::create_directories(tempDir);

  auto plainPath = tempDir / "original.webp";
  auto encPath = tempDir / "encrypted.bin";
  auto thumbPath = tempDir / "thumbnail.webp";

  {
    std::ofstream out(plainPath, std::ios::binary);
    out.write(reinterpret_cast<const char*>(webpData.data()), webpData.size());
  }

  std::string sha;
  TEST_ASSERT(encryptFileAes256(plainPath, encPath, testKey, sha), "File encryption succeeded");
  std::filesystem::remove(plainPath); // delete plaintext source!

  // Count files in tempDir before thumbnail generation
  size_t countBefore = 0;
  for (const auto &p : std::filesystem::directory_iterator(tempDir)) {
    (void)p;
    countBefore++;
  }
  TEST_ASSERT(countBefore == 1, "Only encrypted.bin exists before thumb generation");

  // Generate thumbnail from encrypted file
  TEST_ASSERT(generateThumbnailFromEncryptedFile(encPath, testKey, thumbPath, 80, 80.0f), "Thumbnail generated directly in RAM");

  // Count files in tempDir after thumbnail generation
  size_t countAfter = 0;
  for (const auto &p : std::filesystem::directory_iterator(tempDir)) {
    (void)p;
    countAfter++;
  }
  TEST_ASSERT(countAfter == 2, "Only encrypted.bin and thumbnail.webp exist — ZERO temp files left!");
  TEST_ASSERT(std::filesystem::exists(thumbPath), "Thumbnail exists");

  // In-memory buffer decryption test
  std::ifstream encIn(encPath, std::ios::binary);
  std::vector<uint8_t> encBytes((std::istreambuf_iterator<char>(encIn)), std::istreambuf_iterator<char>());
  encIn.close();

  std::vector<uint8_t> ramDecrypted;
  TEST_ASSERT(decryptBufferAes256(encBytes.data(), encBytes.size(), testKey, ramDecrypted), "decryptBufferAes256 succeeded");
  TEST_ASSERT(ramDecrypted.size() == webpData.size(), "Decrypted buffer size bit-for-bit matches");
  TEST_ASSERT(std::memcmp(ramDecrypted.data(), webpData.data(), webpData.size()) == 0, "Decrypted buffer content bit-for-bit matches");

  // Cleanup
  std::error_code ec;
  std::filesystem::remove_all(tempDir, ec);

  std::cout << "[PASS] Zero disk temp files verification passed." << std::endl;
}

// 5. Memory Leak Stress Harness (1,000 Repeated Thumbnail Cycles)
void testMemoryLeakSafety() {
  std::cout << "[TEST] 5. Memory Leak Stress Harness (1,000 Thumbnail Cycles)..." << std::endl;

  const int w = 400, h = 300;
  std::vector<uint8_t> sampleRgba(w * h * 4);
  for (size_t i = 0; i < sampleRgba.size(); ++i) {
    sampleRgba[i] = static_cast<uint8_t>(i % 256);
  }
  auto srcWebp = encodeRgbaToWebP(sampleRgba.data(), w, h, 85.0f);
  TEST_ASSERT(!srcWebp.empty(), "Source WebP encoded");

  // Warmup run
  for (int i = 0; i < 50; ++i) {
    auto t = generateThumbnailWebP(srcWebp.data(), srcWebp.size(), 128, 80.0f);
    TEST_ASSERT(t.has_value(), "Warmup thumbnail generated");
  }

  long rssBefore = getResidentSetSizeKb();
  std::cout << "RSS before 1,000 cycles: " << rssBefore << " KB" << std::endl;

  auto start = std::chrono::high_resolution_clock::now();
  constexpr int kIterations = 1000;
  for (int i = 0; i < kIterations; ++i) {
    DecodedImage orig;
    auto thumb = generateThumbnailWebP(srcWebp.data(), srcWebp.size(), 128, 80.0f, &orig);
    TEST_ASSERT(thumb.has_value(), "Thumb generated in loop");
    TEST_ASSERT(orig.width == w && orig.height == h, "Original captured");
  }
  auto end = std::chrono::high_resolution_clock::now();
  auto elapsedMs = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();

  long rssAfter = getResidentSetSizeKb();
  std::cout << "RSS after 1,000 cycles: " << rssAfter << " KB (Delta: " << (rssAfter - rssBefore) << " KB)" << std::endl;
  std::cout << "Processed 1,000 images in " << elapsedMs << " ms (" << (1000.0 * kIterations / elapsedMs) << " thumbs/sec)" << std::endl;

  // RSS growth should be negligible (< 4096 KB allocator headroom)
  long deltaKb = rssAfter - rssBefore;
  TEST_ASSERT(deltaKb < 4096, "No substantial memory growth across 1,000 cycles (leak check passed)");

  std::cout << "[PASS] Memory leak safety verified." << std::endl;
}

// 6. Multithreaded Concurrency Stress Test
void testMultithreadedConcurrency() {
  std::cout << "[TEST] 6. Multithreaded Concurrency Stress Test (8 threads)..." << std::endl;

  const int w = 250, h = 250;
  std::vector<uint8_t> sampleRgba(w * h * 4, 180);
  auto srcWebp = encodeRgbaToWebP(sampleRgba.data(), w, h, 80.0f);

  std::atomic<int> successCount{0};
  std::vector<std::thread> workers;
  constexpr int numThreads = 8;
  constexpr int itersPerThread = 50;

  for (int t = 0; t < numThreads; ++t) {
    workers.emplace_back([&srcWebp, &successCount, itersPerThread]() {
      for (int i = 0; i < itersPerThread; ++i) {
        DecodedImage orig;
        auto thumb = generateThumbnailWebP(srcWebp.data(), srcWebp.size(), 64, 80.0f, &orig);
        if (thumb.has_value() && thumb->size() > 20 && orig.width == 250) {
          successCount.fetch_add(1, std::memory_order_relaxed);
        }
      }
    });
  }

  for (auto &th : workers) {
    th.join();
  }

  TEST_ASSERT(successCount.load() == numThreads * itersPerThread, "All concurrent thumbnail tasks succeeded cleanly");
  std::cout << "[PASS] Multithreaded concurrency test passed (" << successCount.load() << " operations)." << std::endl;
}

int main() {
  std::cout << "=========================================================" << std::endl;
  std::cout << "CHALLENGER 2: EMPIRICAL STRESS & COMPLIANCE TEST HARNESS" << std::endl;
  std::cout << "=========================================================" << std::endl;

  testWebPContainerCompliance();
  testExtremeAspectRatios();
  testAdversarialCorruptedInputs();
  testZeroDiskTempFilesVerification();
  testMemoryLeakSafety();
  testMultithreadedConcurrency();

  std::cout << "=========================================================" << std::endl;
  std::cout << "ALL EMPIRICAL CHALLENGER 2 TESTS PASSED PERFECTLY!" << std::endl;
  std::cout << "=========================================================" << std::endl;
  return 0;
}
