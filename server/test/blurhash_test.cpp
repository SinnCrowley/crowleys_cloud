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

// 407-byte valid 64x64 solid red HEIC sample
static const uint8_t kTestSampleHeic[] = {
  0x00, 0x00, 0x00, 0x1c, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63,
  0x00, 0x00, 0x00, 0x00, 0x6d, 0x69, 0x66, 0x31, 0x68, 0x65, 0x69, 0x63,
  0x6d, 0x69, 0x61, 0x66, 0x00, 0x00, 0x01, 0x56, 0x6d, 0x65, 0x74, 0x61,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x21, 0x68, 0x64, 0x6c, 0x72,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x70, 0x69, 0x63, 0x74,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x22, 0x69, 0x6c, 0x6f, 0x63, 0x00, 0x00, 0x00,
  0x00, 0x44, 0x40, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01,
  0x7a, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1d, 0x00,
  0x00, 0x00, 0x23, 0x69, 0x69, 0x6e, 0x66, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x00, 0x00, 0x15, 0x69, 0x6e, 0x66, 0x65, 0x02, 0x00, 0x00,
  0x00, 0x00, 0x01, 0x00, 0x00, 0x68, 0x76, 0x63, 0x31, 0x00, 0x00, 0x00,
  0x00, 0x0e, 0x70, 0x69, 0x74, 0x6d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
  0x00, 0x00, 0x00, 0xd6, 0x69, 0x70, 0x72, 0x70, 0x00, 0x00, 0x00, 0xb7,
  0x69, 0x70, 0x63, 0x6f, 0x00, 0x00, 0x00, 0x78, 0x68, 0x76, 0x63, 0x43,
  0x01, 0x03, 0x70, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x1e, 0xf0, 0x00, 0xfc, 0xfd, 0xf8, 0xf8, 0x00, 0x00, 0x0f, 0x03, 0x60,
  0x00, 0x01, 0x00, 0x18, 0x40, 0x01, 0x0c, 0x01, 0xff, 0xff, 0x03, 0x70,
  0x00, 0x00, 0x03, 0x00, 0x90, 0x00, 0x00, 0x03, 0x00, 0x00, 0x03, 0x00,
  0x1e, 0xba, 0x02, 0x40, 0x61, 0x00, 0x01, 0x00, 0x2b, 0x42, 0x01, 0x01,
  0x03, 0x70, 0x00, 0x00, 0x03, 0x00, 0x90, 0x00, 0x00, 0x03, 0x00, 0x00,
  0x03, 0x00, 0x1e, 0xa0, 0x20, 0x81, 0x05, 0x96, 0xea, 0x49, 0x29, 0xae,
  0x6e, 0x02, 0x1a, 0x0c, 0x08, 0x00, 0x00, 0x03, 0x00, 0xc8, 0x00, 0x00,
  0x03, 0x00, 0x08, 0x40, 0x62, 0x00, 0x01, 0x00, 0x07, 0x44, 0x01, 0xc1,
  0x72, 0xb0, 0x22, 0x40, 0x00, 0x00, 0x00, 0x13, 0x63, 0x6f, 0x6c, 0x72,
  0x6e, 0x63, 0x6c, 0x78, 0x00, 0x01, 0x00, 0x0d, 0x00, 0x06, 0x80, 0x00,
  0x00, 0x00, 0x14, 0x69, 0x73, 0x70, 0x65, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x10, 0x70,
  0x69, 0x78, 0x69, 0x00, 0x00, 0x00, 0x00, 0x03, 0x08, 0x08, 0x08, 0x00,
  0x00, 0x00, 0x17, 0x69, 0x70, 0x6d, 0x61, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x01, 0x00, 0x01, 0x04, 0x81, 0x02, 0x03, 0x04, 0x00, 0x00,
  0x00, 0x25, 0x6d, 0x64, 0x61, 0x74, 0x00, 0x00, 0x00, 0x19, 0x28, 0x01,
  0xaf, 0x13, 0x80, 0xe6, 0xa8, 0x70, 0xd3, 0xff, 0xfe, 0x26, 0x94, 0x7f,
  0xfd, 0x3a, 0xe7, 0x87, 0xe9, 0xe5, 0xd2, 0xd2, 0x79, 0xbf, 0x7c,
};

static void testHeicDecodingAndBlurHash() {
  std::cout << "[TEST] Running HEIC decoding and BlurHash test..." << std::endl;

#ifdef CROWLEYS_CLOUD_HAS_LIBHEIF
  // 1. Direct decodeImageToRgba
  auto decodedOpt = decodeImageToRgba(kTestSampleHeic, sizeof(kTestSampleHeic));
  assert(decodedOpt.has_value());
  assert(decodedOpt->width == 64);
  assert(decodedOpt->height == 64);
  assert(decodedOpt->channels == 4);
  assert(decodedOpt->rgba.size() == 64 * 64 * 4);
  // Red channel of solid red image should be predominant
  assert(decodedOpt->rgba[0] > 180);
  assert(decodedOpt->rgba[1] < 80);
  assert(decodedOpt->rgba[2] < 80);
  assert(decodedOpt->rgba[3] == 255);

  // 2. generateThumbnailWebP and BlurHash computation
  std::string blurHash;
  auto thumbOpt = generateThumbnailWebP(kTestSampleHeic, sizeof(kTestSampleHeic), 32, 80.0f, nullptr, &blurHash);
  assert(thumbOpt.has_value());
  assert(!thumbOpt->empty());
  assert(!blurHash.empty());
  assert(blurHash.length() == 28);
  assert(isValidBlurHash(blurHash));
  std::cout << "  HEIC Thumbnail size: " << thumbOpt->size() << " bytes, BlurHash: " << blurHash << std::endl;

  // 3. File and encrypted file pipeline
  auto tmpDir = std::filesystem::temp_directory_path() / ("heic_blurhash_test_" + randomTokenHex(8));
  std::filesystem::create_directories(tmpDir);

  auto srcPath = tmpDir / "sample.heic";
  auto dstPath = tmpDir / "sample_thumb.webp";
  auto encPath = tmpDir / "sample.heic.enc";
  auto encDstPath = tmpDir / "sample_enc_thumb.webp";

  std::vector<uint8_t> heicVec(kTestSampleHeic, kTestSampleHeic + sizeof(kTestSampleHeic));
  assert(saveBufferAtomically(srcPath, heicVec));

  std::string fileBlurHash;
  assert(generateThumbnailFromFile(srcPath, dstPath, 32, 80.0f, nullptr, &fileBlurHash));
  assert(fileBlurHash == blurHash);
  assert(std::filesystem::exists(dstPath));

  const std::string key = "heic_secret_key_1234567890123456";
  std::string outSha;
  assert(encryptFileAes256(srcPath, encPath, key, outSha));

  std::string encBlurHash;
  assert(generateThumbnailFromEncryptedFile(encPath, key, encDstPath, 32, 80.0f, nullptr, &encBlurHash));
  assert(encBlurHash == blurHash);
  assert(std::filesystem::exists(encDstPath));

  std::filesystem::remove_all(tmpDir);
  std::cout << "  [PASS] HEIC decoding and BlurHash test passed." << std::endl;
#else
  std::cout << "  [SKIP] libheif not enabled at compile time." << std::endl;
#endif
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
  assert(avgMs < 25.0); // Safety threshold for debug builds under test load
  std::cout << "  [PASS] Performance benchmark passed." << std::endl;
}

int main() {
  std::cout << "========================================" << std::endl;
  std::cout << "   BlurHashEncoder C++ Test Suite       " << std::endl;
  std::cout << "========================================" << std::endl;

  testReferenceVectors();
  testInvalidInputsAndEdgeCases();
  testImageUtilsIntegration();
  testHeicDecodingAndBlurHash();
  testPerformanceBenchmark();

  std::cout << "========================================" << std::endl;
  std::cout << " [ALL PASS] All BlurHash tests passed!  " << std::endl;
  std::cout << "========================================" << std::endl;
  return 0;
}
