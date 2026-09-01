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

#include "server/utils/BlurHashEncoder.hpp"
#include "server/utils/ImageUtils.hpp"
#include "server/utils/Crypto.hpp"

#include <cassert>
#include <chrono>
#include <filesystem>
#include <iostream>
#include <vector>

using namespace server::utils;

static void testReferenceVectors() {
  std::cout << "[TEST] Running reference vectors test..." << std::endl;

  // 1. Solid Black 4x4 RGBA
  {
    std::vector<uint8_t> black(4 * 4 * 4, 0);
    for (size_t i = 3; i < black.size(); i += 4) black[i] = 255;
    std::string hash = encodeBlurHash(black.data(), 4, 4, 4, 3);
    std::cout << "  Solid Black: " << hash << std::endl;
    assert(hash == "L00000fQfQfQfQfQfQfQfQfQfQfQ");
    assert(hash.length() == 28);
    assert(isValidBlurHash(hash));
  }

  // 2. Solid White 4x4 RGBA
  {
    std::vector<uint8_t> white(4 * 4 * 4, 255);
    std::string hash = encodeBlurHash(white.data(), 4, 4, 4, 3);
    std::cout << "  Solid White: " << hash << std::endl;
    assert(hash == "L~TSUA~qfQ~q~q%MfQ%MfQfQfQfQ");
    assert(hash.length() == 28);
    assert(isValidBlurHash(hash));
  }

  // 3. Pure Red 4x4 RGBA
  {
    std::vector<uint8_t> red(4 * 4 * 4, 0);
    for (size_t i = 0; i < red.size(); i += 4) {
      red[i] = 255;      // R
      red[i + 1] = 0;    // G
      red[i + 2] = 0;    // B
      red[i + 3] = 255;  // A
    }
    std::string hash = encodeBlurHash(red.data(), 4, 4, 4, 3);
    std::cout << "  Pure Red: " << hash << std::endl;
    assert(hash == "L~TI:j|cfQ|c|c$5fQ$5fQfQfQfQ");
    assert(hash.length() == 28);
    assert(isValidBlurHash(hash));
  }

  // 4. Pure Blue 4x4 RGBA
  {
    std::vector<uint8_t> blue(4 * 4 * 4, 0);
    for (size_t i = 0; i < blue.size(); i += 4) {
      blue[i] = 0;        // R
      blue[i + 1] = 0;    // G
      blue[i + 2] = 255;  // B
      blue[i + 3] = 255;  // A
    }
    std::string hash = encodeBlurHash(blue.data(), 4, 4, 4, 3);
    std::cout << "  Pure Blue: " << hash << std::endl;
    assert(hash == "L~0036fZfQfZfZfVfQfVfQfQfQfQ");
    assert(hash.length() == 28);
    assert(isValidBlurHash(hash));
  }

  std::cout << "  [PASS] Reference vectors test passed." << std::endl;
}

static void testInvalidInputsAndEdgeCases() {
  std::cout << "[TEST] Running invalid inputs and edge cases test..." << std::endl;

  // Null pointer
  assert(encodeBlurHash(nullptr, 100, 100, 4, 3).empty());

  // Zero / negative dimensions
  std::vector<uint8_t> dummy(64, 255);
  assert(encodeBlurHash(dummy.data(), 0, 100, 4, 3).empty());
  assert(encodeBlurHash(dummy.data(), 100, 0, 4, 3).empty());
  assert(encodeBlurHash(dummy.data(), -1, 10, 4, 3).empty());

  // Invalid components
  assert(encodeBlurHash(dummy.data(), 4, 4, 0, 3).empty());
  assert(encodeBlurHash(dummy.data(), 4, 4, 10, 3).empty());
  assert(encodeBlurHash(dummy.data(), 4, 4, 4, 0).empty());
  assert(encodeBlurHash(dummy.data(), 4, 4, 4, 10).empty());

  // isValidBlurHash edge cases
  assert(!isValidBlurHash(""));
  assert(!isValidBlurHash("abc"));
  assert(!isValidBlurHash("L00000fQfQfQfQfQfQfQfQfQfQf"));    // length 27
  assert(!isValidBlurHash("L00000fQfQfQfQfQfQfQfQfQfQfQQ"));  // length 29
  assert(!isValidBlurHash("L 0000fQfQfQfQfQfQfQfQfQfQfQ"));   // contains space
  assert(!isValidBlurHash("L!0000fQfQfQfQfQfQfQfQfQfQfQ"));   // '!' not in Base83

  std::cout << "  [PASS] Invalid inputs test passed." << std::endl;
}

static void testImageUtilsIntegration() {
  std::cout << "[TEST] Running ImageUtils integration test..." << std::endl;

  // Create a 64x64 test image with a color gradient
  const int w = 64;
  const int h = 64;
  std::vector<uint8_t> gradientRgba(w * h * 4);
  for (int y = 0; y < h; ++y) {
    for (int x = 0; x < w; ++x) {
      const int idx = (y * w + x) * 4;
      gradientRgba[idx] = static_cast<uint8_t>((x * 255) / w);      // R
      gradientRgba[idx + 1] = static_cast<uint8_t>((y * 255) / h);  // G
      gradientRgba[idx + 2] = 128;                                  // B
      gradientRgba[idx + 3] = 255;                                  // A
    }
  }

  // Encode to WebP buffer
  auto originalWebp = encodeRgbaToWebP(gradientRgba.data(), w, h, 90.0f);
  assert(!originalWebp.empty());

  // Test generateThumbnailWebP with outBlurHash
  std::string blurHash;
  auto thumbOpt = generateThumbnailWebP(originalWebp.data(), originalWebp.size(), 32, 80.0f, nullptr, &blurHash);
  assert(thumbOpt.has_value());
  assert(!thumbOpt->empty());
  assert(!blurHash.empty());
  assert(blurHash.length() == 28);
  assert(isValidBlurHash(blurHash));
  std::cout << "  Gradient BlurHash: " << blurHash << std::endl;

  // Test generateThumbnailFromFile & generateThumbnailFromEncryptedFile
  auto tmpDir = std::filesystem::temp_directory_path() / ("blurhash_test_" + randomTokenHex(8));
  std::filesystem::create_directories(tmpDir);

  auto srcPath = tmpDir / "test.webp";
  auto dstPath = tmpDir / "test_thumb.webp";
  auto encPath = tmpDir / "test.enc";
  auto encDstPath = tmpDir / "test_enc_thumb.webp";

  // Save webp
  assert(saveBufferAtomically(srcPath, originalWebp));

  // File test
  std::string fileBlurHash;
  assert(generateThumbnailFromFile(srcPath, dstPath, 32, 80.0f, nullptr, &fileBlurHash));
  assert(fileBlurHash == blurHash);
  assert(std::filesystem::exists(dstPath));

  // Encrypted file test
  const std::string key = "blurhash_secret_key_1234567890123";
  std::string outSha;
  assert(encryptFileAes256(srcPath, encPath, key, outSha));

  std::string encBlurHash;
  assert(generateThumbnailFromEncryptedFile(encPath, key, encDstPath, 32, 80.0f, nullptr, &encBlurHash));
  assert(encBlurHash == blurHash);
  assert(std::filesystem::exists(encDstPath));

  std::filesystem::remove_all(tmpDir);
  std::cout << "  [PASS] ImageUtils integration test passed." << std::endl;
}

static void testPerformanceBenchmark() {
  std::cout << "[TEST] Running BlurHash performance benchmark..." << std::endl;

  const int w = 256;
  const int h = 256;
  std::vector<uint8_t> rgba(w * h * 4, 180);
  for (int y = 0; y < h; ++y) {
    for (int x = 0; x < w; ++x) {
      const int idx = (y * w + x) * 4;
      rgba[idx] = static_cast<uint8_t>((x * 255) / w);
      rgba[idx + 1] = static_cast<uint8_t>((y * 255) / h);
      rgba[idx + 2] = static_cast<uint8_t>((x + y) % 256);
      rgba[idx + 3] = 255;
    }
  }

  const int iterations = 100;
  const auto start = std::chrono::high_resolution_clock::now();
  for (int i = 0; i < iterations; ++i) {
    std::string hash = encodeBlurHash(rgba.data(), w, h, 4, 3);
    assert(hash.length() == 28);
  }
  const auto end = std::chrono::high_resolution_clock::now();
  const auto elapsedUs = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();
  const double avgMs = static_cast<double>(elapsedUs) / (iterations * 1000.0);

  std::cout << "  256x256 BlurHash average execution time: " << avgMs << " ms per image (" << iterations << " runs)" << std::endl;
  assert(avgMs < 10.0); // Safety threshold for debug builds
  std::cout << "  [PASS] Performance benchmark passed." << std::endl;
}

int main() {
  std::cout << "========================================" << std::endl;
  std::cout << "   BlurHashEncoder C++ Test Suite       " << std::endl;
  std::cout << "========================================" << std::endl;

  testReferenceVectors();
  testInvalidInputsAndEdgeCases();
  testImageUtilsIntegration();
  testPerformanceBenchmark();

  std::cout << "========================================" << std::endl;
  std::cout << " [ALL PASS] All BlurHash tests passed!  " << std::endl;
  std::cout << "========================================" << std::endl;
  return 0;
}
