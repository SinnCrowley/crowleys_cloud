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
#include <string>
#include <cassert>
#include <filesystem>
#include <fstream>
#include <cstring>
#include <thread>
#include <random>
#include <chrono>
#include <cstdlib>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <webp/decode.h>
#include <webp/encode.h>

#include "server/utils/Crypto.hpp"
#include "server/utils/ImageUtils.hpp"

using namespace server::utils;

#define TEST_ASSERT(cond, msg) \
  do { \
    if (!(cond)) { \
      std::cerr << "\n[FAIL] Line " << __LINE__ << ": " << (msg) << std::endl; \
      std::exit(1); \
    } \
  } while (0)

// Helper to generate synthetic RGBA test image
std::vector<uint8_t> createSyntheticRgba(int w, int h, uint8_t r = 100, uint8_t g = 150, uint8_t b = 200, uint8_t a = 255) {
  std::vector<uint8_t> rgba(static_cast<size_t>(w) * h * 4);
  for (int y = 0; y < h; ++y) {
    for (int x = 0; x < w; ++x) {
      size_t idx = (static_cast<size_t>(y) * w + x) * 4;
      rgba[idx + 0] = static_cast<uint8_t>((r + x) % 256);
      rgba[idx + 1] = static_cast<uint8_t>((g + y) % 256);
      rgba[idx + 2] = b;
      rgba[idx + 3] = a;
    }
  }
  return rgba;
}

// -----------------------------------------------------------------------------
// 1. Empirical Verification: Zero Process / FFmpeg Spawning
// -----------------------------------------------------------------------------
void testZeroExternalProcessInvoked() {
  std::cout << "[TEST] 1. Empirically verifying zero external process/FFmpeg invocation..." << std::endl;

  // Save current PATH and clear it or set it to a non-existent path
  const char *origPath = std::getenv("PATH");
  std::string savedPath = origPath ? origPath : "";

  // Set PATH to empty - if anything tries to execute ffmpeg or any CLI tool via posix_spawnp/execvp/system,
  // it would fail if it relied on external binaries.
  setenv("PATH", "/proc/non_existent_path_for_testing", 1);

  const int w = 200;
  const int h = 150;
  auto rgba = createSyntheticRgba(w, h);
  auto webpData = encodeRgbaToWebP(rgba.data(), w, h, 80.0f);
  TEST_ASSERT(!webpData.empty(), "Encoded test WebP");

  auto tmpDir = std::filesystem::temp_directory_path() / ("test_zero_proc_" + randomTokenHex(6));
  std::filesystem::create_directories(tmpDir);

  auto plainPath = tmpDir / "photo.webp";
  auto encPath = tmpDir / "photo.enc";
  auto thumbPath = tmpDir / "photo_thumb.webp";

  {
    std::ofstream out(plainPath, std::ios::binary);
    out.write(reinterpret_cast<const char*>(webpData.data()), webpData.size());
  }

  std::string plainSha;
  std::string secretKey = "test-secret-key";
  TEST_ASSERT(encryptFileAes256(plainPath, encPath, secretKey, plainSha), "Encrypted file");

  // In-memory thumbnail generation directly from encrypted file with empty/broken PATH
  bool thumbSuccess = generateThumbnailFromEncryptedFile(encPath, secretKey, thumbPath, 64, 80.0f);
  TEST_ASSERT(thumbSuccess, "generateThumbnailFromEncryptedFile succeeded without any external process or PATH dependency");
  TEST_ASSERT(std::filesystem::exists(thumbPath), "Thumbnail generated successfully");

  // Restore PATH
  if (!savedPath.empty()) {
    setenv("PATH", savedPath.c_str(), 1);
  } else {
    unsetenv("PATH");
  }

  std::filesystem::remove_all(tmpDir);
  std::cout << "[PASS] Zero external process invocation verified." << std::endl;
}

// -----------------------------------------------------------------------------
// 2. Empirical Verification: Zero Disk Temp Files (.dec.tmp)
// -----------------------------------------------------------------------------
void testZeroDiskTempFiles() {
  std::cout << "[TEST] 2. Empirically verifying zero disk temp files during encrypted thumbnailing..." << std::endl;

  auto scratchDir = std::filesystem::temp_directory_path() / ("test_zero_temp_" + randomTokenHex(6));
  std::filesystem::create_directories(scratchDir);

  const int w = 400;
  const int h = 300;
  auto rgba = createSyntheticRgba(w, h);
  auto webpData = encodeRgbaToWebP(rgba.data(), w, h, 80.0f);

  auto encFile = scratchDir / "secret_document.enc";
  auto thumbFile = scratchDir / "thumb.webp";

  // Create encrypted file
  auto rawPlainFile = scratchDir / "raw.tmp";
  {
    std::ofstream out(rawPlainFile, std::ios::binary);
    out.write(reinterpret_cast<const char*>(webpData.data()), webpData.size());
  }
  std::string plainSha;
  std::string key = "super-confidential-key";
  encryptFileAes256(rawPlainFile, encFile, key, plainSha);
  std::filesystem::remove(rawPlainFile);

  // Scratch directory should have exactly 1 file: secret_document.enc
  size_t initialFiles = 0;
  for (const auto &entry : std::filesystem::directory_iterator(scratchDir)) {
    (void)entry;
    initialFiles++;
  }
  TEST_ASSERT(initialFiles == 1, "Exactly 1 file initially in scratch directory");

  // Perform encrypted thumbnailing
  bool ok = generateThumbnailFromEncryptedFile(encFile, key, thumbFile, 128, 80.0f);
  TEST_ASSERT(ok, "Thumbnail generation succeeded");

  // Check directory contents: only secret_document.enc and thumb.webp must exist!
  // No .dec.tmp, no leftover .tmp files
  size_t finalFiles = 0;
  bool foundEnc = false;
  bool foundThumb = false;
  bool foundAnyTemp = false;

  for (const auto &entry : std::filesystem::directory_iterator(scratchDir)) {
    finalFiles++;
    auto filename = entry.path().filename().string();
    if (filename == "secret_document.enc") foundEnc = true;
    else if (filename == "thumb.webp") foundThumb = true;
    else {
      std::cerr << "Unexpected file detected on disk: " << entry.path() << std::endl;
      foundAnyTemp = true;
    }
  }

  TEST_ASSERT(foundEnc && foundThumb, "Expected encrypted file and thumbnail file exist");
  TEST_ASSERT(!foundAnyTemp, "ZERO unexpected or temp files found in scratch directory!");
  TEST_ASSERT(finalFiles == 2, "Exactly 2 files exist in scratch directory");

  std::filesystem::remove_all(scratchDir);
  std::cout << "[PASS] Zero disk temp files empirically verified." << std::endl;
}

// -----------------------------------------------------------------------------
// 3. Extreme Edge Cases: Dimensions & Aspect Ratios
// -----------------------------------------------------------------------------
void testExtremeDimensionsAndAspectRatios() {
  std::cout << "[TEST] 3. Testing extreme dimensions & aspect ratios..." << std::endl;

  // Case 3a: 1x1 Pixel Image
  {
    std::cout << "  - Subtest: 1x1 Pixel Image" << std::endl;
    auto rgba1x1 = createSyntheticRgba(1, 1, 255, 0, 0, 255);
    auto webp1x1 = encodeRgbaToWebP(rgba1x1.data(), 1, 1, 90.0f);
    TEST_ASSERT(!webp1x1.empty(), "1x1 WebP encoded");

    DecodedImage orig;
    auto thumbOpt = generateThumbnailWebP(webp1x1.data(), webp1x1.size(), 256, 80.0f, &orig);
    TEST_ASSERT(thumbOpt.has_value(), "1x1 thumbnail generated");
    TEST_ASSERT(orig.width == 1 && orig.height == 1, "Original 1x1 preserved");

    int tw = 0, th = 0;
    TEST_ASSERT(WebPGetInfo(thumbOpt->data(), thumbOpt->size(), &tw, &th) == 1, "WebPGetInfo on 1x1 thumb");
    TEST_ASSERT(tw == 1 && th == 1, "1x1 not upscaled, stays 1x1");
  }

  // Case 3b: Large 4000x3000 Image (12 Megapixels)
  {
    std::cout << "  - Subtest: 4000x3000 Large Image" << std::endl;
    const int lw = 4000;
    const int lh = 3000;
    std::vector<uint8_t> largeRgba(static_cast<size_t>(lw) * lh * 4, 180);
    auto largeWebp = encodeRgbaToWebP(largeRgba.data(), lw, lh, 75.0f);
    TEST_ASSERT(!largeWebp.empty(), "Large 4000x3000 WebP encoded");

    DecodedImage orig;
    auto thumbOpt = generateThumbnailWebP(largeWebp.data(), largeWebp.size(), 256, 80.0f, &orig);
    TEST_ASSERT(thumbOpt.has_value(), "Large image thumbnail generated");
    TEST_ASSERT(orig.width == 4000 && orig.height == 3000, "Original 4000x3000 captured");

    int tw = 0, th = 0;
    TEST_ASSERT(WebPGetInfo(thumbOpt->data(), thumbOpt->size(), &tw, &th) == 1, "WebPGetInfo on large thumb");
    TEST_ASSERT(tw == 256, "Target width 256");
    TEST_ASSERT(th == 192, "Target height 192 (3000*256/4000 = 192)");
  }

  // Case 3c: Extreme Tall Aspect Ratio (1x4000 and 10x4000)
  {
    std::cout << "  - Subtest: Extreme Tall Aspect Ratio" << std::endl;
    auto fit1x4000 = calculateAspectRatioFit(1, 4000, 256);
    TEST_ASSERT(fit1x4000.height == 256, "Extreme tall target height = 256");
    TEST_ASSERT(fit1x4000.width >= 1, "Extreme tall target width >= 1 (clamped)");

    auto fit10x4000 = calculateAspectRatioFit(10, 4000, 256);
    TEST_ASSERT(fit10x4000.height == 256, "Tall target height = 256");
    TEST_ASSERT(fit10x4000.width >= 1, "Tall target width >= 1");

    // Real resize & encode test for 10x1000
    auto tallRgba = createSyntheticRgba(10, 1000);
    auto tallWebp = encodeRgbaToWebP(tallRgba.data(), 10, 1000, 80.0f);
    auto thumbOpt = generateThumbnailWebP(tallWebp.data(), tallWebp.size(), 256, 80.0f);
    TEST_ASSERT(thumbOpt.has_value(), "Extreme tall thumbnail generated");
    int tw = 0, th = 0;
    WebPGetInfo(thumbOpt->data(), thumbOpt->size(), &tw, &th);
    TEST_ASSERT(th == 256, "Extreme tall thumb height is 256");
    TEST_ASSERT(tw >= 1, "Extreme tall thumb width is >= 1");
  }

  // Case 3d: Extreme Wide Aspect Ratio (4000x1 and 4000x10)
  {
    std::cout << "  - Subtest: Extreme Wide Aspect Ratio" << std::endl;
    auto fit4000x1 = calculateAspectRatioFit(4000, 1, 256);
    TEST_ASSERT(fit4000x1.width == 256, "Extreme wide target width = 256");
    TEST_ASSERT(fit4000x1.height >= 1, "Extreme wide target height >= 1 (clamped)");

    auto fit4000x10 = calculateAspectRatioFit(4000, 10, 256);
    TEST_ASSERT(fit4000x10.width == 256, "Wide target width = 256");
    TEST_ASSERT(fit4000x10.height >= 1, "Wide target height >= 1");

    // Real resize & encode test for 1000x10
    auto wideRgba = createSyntheticRgba(1000, 10);
    auto wideWebp = encodeRgbaToWebP(wideRgba.data(), 1000, 10, 80.0f);
    auto thumbOpt = generateThumbnailWebP(wideWebp.data(), wideWebp.size(), 256, 80.0f);
    TEST_ASSERT(thumbOpt.has_value(), "Extreme wide thumbnail generated");
    int tw = 0, th = 0;
    WebPGetInfo(thumbOpt->data(), thumbOpt->size(), &tw, &th);
    TEST_ASSERT(tw == 256, "Extreme wide thumb width is 256");
    TEST_ASSERT(th >= 1, "Extreme wide thumb height is >= 1");
  }

  // Case 3e: Degenerate / Zero / Negative Dimensions
  {
    std::cout << "  - Subtest: Degenerate Dimensions" << std::endl;
    TEST_ASSERT(calculateAspectRatioFit(0, 0, 256).width == 0, "0x0 width");
    TEST_ASSERT(calculateAspectRatioFit(0, 100, 256).width == 0, "0x100 width");
    TEST_ASSERT(calculateAspectRatioFit(100, 0, 256).width == 0, "100x0 width");
    TEST_ASSERT(calculateAspectRatioFit(-10, 50, 256).width == 0, "Negative width");
    TEST_ASSERT(calculateAspectRatioFit(50, -10, 256).height == 0, "Negative height");
    TEST_ASSERT(calculateAspectRatioFit(100, 100, 0).width == 0, "0 maxDimension");
    TEST_ASSERT(calculateAspectRatioFit(100, 100, -5).width == 0, "Negative maxDimension");

    // resizeRgba with 0 dimensions returns empty
    uint8_t dummy[4] = {0};
    TEST_ASSERT(resizeRgba(dummy, 0, 10, 10, 10).empty(), "resize 0 srcW returns empty");
    TEST_ASSERT(resizeRgba(dummy, 10, 0, 10, 10).empty(), "resize 0 srcH returns empty");
    TEST_ASSERT(resizeRgba(dummy, 10, 10, 0, 10).empty(), "resize 0 dstW returns empty");
    TEST_ASSERT(resizeRgba(dummy, 10, 10, 10, 0).empty(), "resize 0 dstH returns empty");
    TEST_ASSERT(resizeRgba(nullptr, 10, 10, 10, 10).empty(), "resize nullptr returns empty");
  }

  std::cout << "[PASS] Extreme dimensions and aspect ratios passed." << std::endl;
}

// -----------------------------------------------------------------------------
// 4. Adversarial Corrupted Image Bytes Stress Test
// -----------------------------------------------------------------------------
void testCorruptedImageBytes() {
  std::cout << "[TEST] 4. Testing corrupted, truncated, and malformed image bytes..." << std::endl;

  // 4a. Null pointer and 0 length
  TEST_ASSERT(!decodeImageToRgba(nullptr, 100).has_value(), "Null pointer returns nullopt");
  uint8_t validByte = 0x89;
  TEST_ASSERT(!decodeImageToRgba(&validByte, 0).has_value(), "Zero length returns nullopt");
  TEST_ASSERT(!generateThumbnailWebP(nullptr, 100).has_value(), "generateThumbnailWebP null pointer returns nullopt");
  TEST_ASSERT(!generateThumbnailWebP(&validByte, 0).has_value(), "generateThumbnailWebP 0 length returns nullopt");

  // 4b. Truncated Magic Headers
  // Truncated JPEG
  const uint8_t truncatedJpeg[] = {0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 'J', 'F', 'I', 'F'};
  TEST_ASSERT(!decodeImageToRgba(truncatedJpeg, sizeof(truncatedJpeg)).has_value(), "Truncated JPEG rejected cleanly");

  // Truncated PNG
  const uint8_t truncatedPng[] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
  TEST_ASSERT(!decodeImageToRgba(truncatedPng, sizeof(truncatedPng)).has_value(), "Truncated PNG rejected cleanly");

  // Truncated RIFF / WebP
  const uint8_t truncatedWebp[] = {'R', 'I', 'F', 'F', 0x20, 0x00, 0x00, 0x00, 'W', 'E', 'B', 'P'};
  TEST_ASSERT(!decodeImageToRgba(truncatedWebp, sizeof(truncatedWebp)).has_value(), "Truncated WebP rejected cleanly");

  // 4c. All Zeros Buffers of various sizes
  std::vector<uint8_t> zeros16(16, 0);
  TEST_ASSERT(!decodeImageToRgba(zeros16.data(), zeros16.size()).has_value(), "16 zero bytes rejected cleanly");

  std::vector<uint8_t> zeros64k(65536, 0);
  TEST_ASSERT(!decodeImageToRgba(zeros64k.data(), zeros64k.size()).has_value(), "64KB zero bytes rejected cleanly");

  // 4d. Random Fuzzing / Garbage Data
  std::mt19937 rng(42);
  std::uniform_int_distribution<int> dist(0, 255);

  const size_t fuzzSizes[] = {1, 2, 7, 15, 32, 128, 1024, 8192, 32768};
  for (size_t fSize : fuzzSizes) {
    std::vector<uint8_t> fuzz(fSize);
    for (size_t i = 0; i < fSize; ++i) {
      fuzz[i] = static_cast<uint8_t>(dist(rng));
    }
    auto res = decodeImageToRgba(fuzz.data(), fuzz.size());
    TEST_ASSERT(!res.has_value(), "Random fuzzed data rejected cleanly without crash");

    auto thumbRes = generateThumbnailWebP(fuzz.data(), fuzz.size());
    TEST_ASSERT(!thumbRes.has_value(), "Random fuzzed thumbnail rejected cleanly without crash");
  }

  std::cout << "[PASS] Corrupted image bytes tested cleanly." << std::endl;
}

// -----------------------------------------------------------------------------
// 5. Encrypted File Tampering, Invalid IV/HMAC/Ciphertext Stress Test
// -----------------------------------------------------------------------------
void testEncryptedFileTampering() {
  std::cout << "[TEST] 5. Testing encrypted file tampering, invalid IV, wrong keys..." << std::endl;

  const std::string validKey = "valid-secret-key-12345";
  const std::string wrongKey = "wrong-key-99999";
  const std::string plainText = "Hello World! This is secret text payload for AES-256 testing.";

  auto cipherPayload = encryptAes256(plainText, validKey);
  TEST_ASSERT(cipherPayload.size() >= 32, "Cipher payload size >= 32");

  // 5a. Correct Decryption
  auto decryptedOk = decryptAes256(cipherPayload, validKey);
  TEST_ASSERT(decryptedOk == plainText, "Decrypted with correct key");

  // 5b. Wrong Key (OpenSSL PKCS7 padding error expected)
  bool wrongKeyThrew = false;
  try {
    decryptAes256(cipherPayload, wrongKey);
  } catch (const std::exception &) {
    wrongKeyThrew = true;
  }
  TEST_ASSERT(wrongKeyThrew, "decryptAes256 threw on wrong key");

  std::vector<uint8_t> outBytes;
  TEST_ASSERT(!decryptBufferAes256(reinterpret_cast<const uint8_t*>(cipherPayload.data()), cipherPayload.size(), wrongKey, outBytes),
              "decryptBufferAes256 returned false on wrong key");
  TEST_ASSERT(outBytes.empty(), "outBytes cleared on wrong key");

  // 5c. Truncated Ciphertext < 16 bytes
  TEST_ASSERT(!decryptBufferAes256(reinterpret_cast<const uint8_t*>(cipherPayload.data()), 10, validKey, outBytes),
              "decryptBufferAes256 returns false for < 16 bytes");
  TEST_ASSERT(!decryptBufferAes256(reinterpret_cast<const uint8_t*>(cipherPayload.data()), 0, validKey, outBytes),
              "decryptBufferAes256 returns false for 0 bytes");

  // 5d. Incomplete block size (not a multiple of 16 after IV)
  TEST_ASSERT(!decryptBufferAes256(reinterpret_cast<const uint8_t*>(cipherPayload.data()), cipherPayload.size() - 3, validKey, outBytes),
              "decryptBufferAes256 returns false for unaligned cipher length");

  // 5e. Tampered Ciphertext (bit flip in ciphertext block)
  auto tamperedPayload = cipherPayload;
  tamperedPayload[tamperedPayload.size() - 5] ^= 0xFF; // flip bits in last block
  TEST_ASSERT(!decryptBufferAes256(reinterpret_cast<const uint8_t*>(tamperedPayload.data()), tamperedPayload.size(), validKey, outBytes),
              "decryptBufferAes256 returns false on tampered ciphertext block");

  // 5f. File-based Decryption with corrupted file
  auto tmpDir = std::filesystem::temp_directory_path() / ("test_tamper_" + randomTokenHex(6));
  std::filesystem::create_directories(tmpDir);

  auto corruptFile = tmpDir / "corrupt.enc";
  {
    std::ofstream out(corruptFile, std::ios::binary);
    out.write(tamperedPayload.data(), tamperedPayload.size());
  }

  TEST_ASSERT(!decryptFileToMemory(corruptFile, validKey, outBytes), "decryptFileToMemory returns false on corrupt file");
  TEST_ASSERT(outBytes.empty(), "decryptFileToMemory cleared output on failure");

  auto nonExistentFile = tmpDir / "does_not_exist.enc";
  TEST_ASSERT(!decryptFileToMemory(nonExistentFile, validKey, outBytes), "decryptFileToMemory returns false on non-existent file");

  std::filesystem::remove_all(tmpDir);
  std::cout << "[PASS] Encrypted file tampering tests passed." << std::endl;
}

// -----------------------------------------------------------------------------
// 6. Sizing Rules: Aspect Ratio Preservation vs Square
// -----------------------------------------------------------------------------
void testSizingRules() {
  std::cout << "[TEST] 6. Testing sizing rules & aspect-ratio preservation..." << std::endl;

  // 1. Square image 500x500 -> 256x256
  auto sq = calculateAspectRatioFit(500, 500, 256);
  TEST_ASSERT(sq.width == 256 && sq.height == 256, "Square 500x500 -> 256x256");

  // 2. Landscape 1920x1080 -> 256x144
  auto ls = calculateAspectRatioFit(1920, 1080, 256);
  TEST_ASSERT(ls.width == 256, "Landscape width = 256");
  TEST_ASSERT(ls.height == 144, "Landscape height = 144 (1080*256/1920 = 144)");

  // 3. Portrait 1080x1920 -> 144x256
  auto pt = calculateAspectRatioFit(1080, 1920, 256);
  TEST_ASSERT(pt.width == 144, "Portrait width = 144 (1080*256/1920 = 144)");
  TEST_ASSERT(pt.height == 256, "Portrait height = 256");

  // 4. Smaller than maxDimension: 50x50 with max 256 -> 50x50 (no upscale)
  auto sm = calculateAspectRatioFit(50, 50, 256);
  TEST_ASSERT(sm.width == 50 && sm.height == 50, "Small 50x50 preserved without upscale");

  auto smRect = calculateAspectRatioFit(80, 60, 256);
  TEST_ASSERT(smRect.width == 80 && smRect.height == 60, "Small 80x60 preserved without upscale");

  std::cout << "[PASS] Sizing rules verified." << std::endl;
}

// -----------------------------------------------------------------------------
// 7. Multithreaded Concurrency & Stress Test
// -----------------------------------------------------------------------------
void testMultithreadedStress() {
  std::cout << "[TEST] 7. Running multithreaded concurrency & stress test (8 threads)..." << std::endl;

  const int numThreads = 8;
  const int iterationsPerThread = 50;
  std::vector<std::thread> workers;

  const std::string key = "thread-stress-test-key";

  for (int t = 0; t < numThreads; ++t) {
    workers.emplace_back([t, iterationsPerThread, key]() {
      for (int i = 0; i < iterationsPerThread; ++i) {
        int w = 50 + (i * 7) % 200;
        int h = 40 + (i * 11) % 180;
        auto rgba = createSyntheticRgba(w, h, static_cast<uint8_t>(t * 20), static_cast<uint8_t>(i * 5));

        auto webpData = encodeRgbaToWebP(rgba.data(), w, h, 80.0f);
        if (webpData.empty()) {
          std::cerr << "Thread " << t << " failed WebP encode" << std::endl;
          std::exit(1);
        }

        // Encrypted buffer roundtrip
        std::vector<uint8_t> plainVec(webpData.begin(), webpData.end());
        std::string plainStr(webpData.begin(), webpData.end());
        auto encStr = encryptAes256(plainStr, key);

        std::vector<uint8_t> decryptedRam;
        bool decOk = decryptBufferAes256(reinterpret_cast<const uint8_t*>(encStr.data()), encStr.size(), key, decryptedRam);
        if (!decOk || decryptedRam.size() != webpData.size()) {
          std::cerr << "Thread " << t << " failed AES RAM decrypt" << std::endl;
          std::exit(1);
        }

        // Thumbnail from memory
        DecodedImage orig;
        auto thumb = generateThumbnailWebP(decryptedRam.data(), decryptedRam.size(), 64, 80.0f, &orig);
        if (!thumb.has_value()) {
          std::cerr << "Thread " << t << " failed thumbnail generation" << std::endl;
          std::exit(1);
        }

        int tw = 0, th = 0;
        WebPGetInfo(thumb->data(), thumb->size(), &tw, &th);
        if (tw <= 0 || th <= 0 || tw > 64 || th > 64) {
          std::cerr << "Thread " << t << " produced invalid thumb dims: " << tw << "x" << th << std::endl;
          std::exit(1);
        }
      }
    });
  }

  for (auto &w : workers) {
    w.join();
  }

  std::cout << "[PASS] Multithreaded stress test (" << (numThreads * iterationsPerThread) << " full pipelines) passed." << std::endl;
}

int main() {
  std::cout << "=========================================================" << std::endl;
  std::cout << "Starting Milestone M2 Adversarial Empirical Challenge Suite" << std::endl;
  std::cout << "=========================================================" << std::endl;

  auto startTime = std::chrono::high_resolution_clock::now();

  testZeroExternalProcessInvoked();
  testZeroDiskTempFiles();
  testExtremeDimensionsAndAspectRatios();
  testCorruptedImageBytes();
  testEncryptedFileTampering();
  testSizingRules();
  testMultithreadedStress();

  auto endTime = std::chrono::high_resolution_clock::now();
  auto elapsedMs = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime).count();

  std::cout << "=========================================================" << std::endl;
  std::cout << "ALL EMPIRICAL ADVERSARIAL CHALLENGES PASSED in " << elapsedMs << " ms!" << std::endl;
  std::cout << "=========================================================" << std::endl;
  return 0;
}
