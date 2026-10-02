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

void testAspectRatioFitting() {
  std::cout << "[TEST] Running testAspectRatioFitting..." << std::endl;
  {
    // Landscape 800x600, target 256
    auto dims = calculateAspectRatioFit(800, 600, 256);
    TEST_ASSERT(dims.width == 256, "Landscape width");
    TEST_ASSERT(dims.height == 192, "Landscape height (600*256/800 = 192)");
  }
  {
    // Portrait 600x800, target 256
    auto dims = calculateAspectRatioFit(600, 800, 256);
    TEST_ASSERT(dims.width == 192, "Portrait width (600*256/800 = 192)");
    TEST_ASSERT(dims.height == 256, "Portrait height");
  }
  {
    // Square 500x500, target 256
    auto dims = calculateAspectRatioFit(500, 500, 256);
    TEST_ASSERT(dims.width == 256, "Square width");
    TEST_ASSERT(dims.height == 256, "Square height");
  }
  {
    // Smaller than target 100x80, target 256 (should not upscale)
    auto dims = calculateAspectRatioFit(100, 80, 256);
    TEST_ASSERT(dims.width == 100, "Small width preserved");
    TEST_ASSERT(dims.height == 80, "Small height preserved");
  }
  {
    // Edge case 1x1000, target 256
    auto dims = calculateAspectRatioFit(1, 1000, 256);
    TEST_ASSERT(dims.height == 256, "Extreme tall height");
    TEST_ASSERT(dims.width >= 1, "Extreme tall width clamped to >= 1");
  }
  std::cout << "[PASS] testAspectRatioFitting passed." << std::endl;
}

void testWebpEncodeDecode() {
  std::cout << "[TEST] Running testWebpEncodeDecode..." << std::endl;
  const int w = 64;
  const int h = 64;
  std::vector<uint8_t> testRgba(w * h * 4);
  for (int y = 0; y < h; ++y) {
    for (int x = 0; x < w; ++x) {
      int idx = (y * w + x) * 4;
      testRgba[idx + 0] = static_cast<uint8_t>(x * 4);
      testRgba[idx + 1] = static_cast<uint8_t>(y * 4);
      testRgba[idx + 2] = 128;
      testRgba[idx + 3] = 255;
    }
  }

  // 1. Encode to WebP
  auto webp = encodeRgbaToWebP(testRgba.data(), w, h, 80.0f);
  TEST_ASSERT(!webp.empty(), "WebP encoding produced non-empty buffer");
  TEST_ASSERT(webp.size() >= 12, "WebP header length");
  TEST_ASSERT(std::memcmp(webp.data(), "RIFF", 4) == 0, "RIFF magic");
  TEST_ASSERT(std::memcmp(webp.data() + 8, "WEBP", 4) == 0, "WEBP magic");

  // 2. Decode from WebP
  auto decoded = decodeImageToRgba(webp.data(), webp.size());
  TEST_ASSERT(decoded.has_value(), "WebP decoding succeeded");
  TEST_ASSERT(decoded->width == w, "Decoded width matches");
  TEST_ASSERT(decoded->height == h, "Decoded height matches");
  TEST_ASSERT(decoded->channels == 4, "Decoded channels 4");
  TEST_ASSERT(decoded->rgba.size() == w * h * 4, "Decoded buffer size");

  std::cout << "[PASS] testWebpEncodeDecode passed." << std::endl;
}

void testResizeAndThumbnail() {
  std::cout << "[TEST] Running testResizeAndThumbnail..." << std::endl;
  const int srcW = 200;
  const int srcH = 100;
  std::vector<uint8_t> testRgba(srcW * srcH * 4, 200);

  // Resize
  auto resized = resizeRgba(testRgba.data(), srcW, srcH, 100, 50);
  TEST_ASSERT(resized.size() == 100 * 50 * 4, "Resized buffer size");

  // WebP thumbnail pipeline
  auto srcWebp = encodeRgbaToWebP(testRgba.data(), srcW, srcH, 80.0f);
  TEST_ASSERT(!srcWebp.empty(), "Source WebP encoded");

  DecodedImage orig;
  auto thumbWebp = generateThumbnailWebP(srcWebp.data(), srcWebp.size(), 64, 80.0f, &orig);
  TEST_ASSERT(thumbWebp.has_value(), "Thumbnail WebP generated");
  TEST_ASSERT(orig.width == srcW, "Original width captured in DecodedImage");
  TEST_ASSERT(orig.height == srcH, "Original height captured in DecodedImage");

  int thumbW = 0, thumbH = 0;
  TEST_ASSERT(WebPGetInfo(thumbWebp->data(), thumbWebp->size(), &thumbW, &thumbH) == 1, "WebPGetInfo valid on thumbnail");
  TEST_ASSERT(thumbW == 64, "Thumbnail width matches aspect fit");
  TEST_ASSERT(thumbH == 32, "Thumbnail height matches aspect fit (100*64/200 = 32)");

  std::cout << "[PASS] testResizeAndThumbnail passed." << std::endl;
}

void testInMemoryCryptoAndThumbnailing() {
  std::cout << "[TEST] Running testInMemoryCryptoAndThumbnailing..." << std::endl;
  const std::string key = "test-secret-key-12345";

  // Create a synthetic image and encode to WebP
  const int w = 120;
  const int h = 90;
  std::vector<uint8_t> testRgba(w * h * 4, 150);
  auto webpData = encodeRgbaToWebP(testRgba.data(), w, h, 85.0f);
  TEST_ASSERT(!webpData.empty(), "Synthetic WebP created");

  auto tmpDir = std::filesystem::temp_directory_path() / "crowleys_test_m2";
  std::filesystem::create_directories(tmpDir);

  auto plainPath = tmpDir / "plain_photo.webp";
  auto encPath = tmpDir / "enc_photo.bin";
  auto thumbPath = tmpDir / "thumb_photo.webp";

  {
    std::ofstream out(plainPath, std::ios::binary);
    out.write(reinterpret_cast<const char*>(webpData.data()), webpData.size());
  }

  // Encrypt file on disk
  std::string plainSha;
  TEST_ASSERT(encryptFileAes256(plainPath, encPath, key, plainSha), "encryptFileAes256 succeeded");

  // Decrypt to RAM memory buffer (0 disk files!)
  std::vector<uint8_t> decryptedRam;
  TEST_ASSERT(decryptFileToMemory(encPath, key, decryptedRam), "decryptFileToMemory succeeded");
  TEST_ASSERT(decryptedRam.size() == webpData.size(), "Decrypted RAM size matches original");
  TEST_ASSERT(std::memcmp(decryptedRam.data(), webpData.data(), webpData.size()) == 0, "Decrypted RAM data matches bit-for-bit");

  // Generate thumbnail directly from encrypted file
  TEST_ASSERT(generateThumbnailFromEncryptedFile(encPath, key, thumbPath, 60, 80.0f), "generateThumbnailFromEncryptedFile succeeded");
  TEST_ASSERT(std::filesystem::exists(thumbPath), "Thumbnail file exists on disk");
  TEST_ASSERT(std::filesystem::file_size(thumbPath) > 0, "Thumbnail file non-empty");

  int tW = 0, tH = 0;
  std::vector<uint8_t> thumbBytes(std::filesystem::file_size(thumbPath));
  {
    std::ifstream in(thumbPath, std::ios::binary);
    in.read(reinterpret_cast<char*>(thumbBytes.data()), thumbBytes.size());
  }
  TEST_ASSERT(WebPGetInfo(thumbBytes.data(), thumbBytes.size(), &tW, &tH) == 1, "WebPGetInfo on generated thumbnail");
  TEST_ASSERT(tW == 60, "Thumbnail width 60");
  TEST_ASSERT(tH == 45, "Thumbnail height 45 (90*60/120 = 45)");

  // Clean up
  std::error_code ec;
  std::filesystem::remove_all(tmpDir, ec);

  std::cout << "[PASS] testInMemoryCryptoAndThumbnailing passed." << std::endl;
}

void testExifOrientationAndRotation() {
  std::cout << "[TEST] Running testExifOrientationAndRotation..." << std::endl;

  // 1. Test applyOrientation with 2x3 image
  // Row 0: Red, Green
  // Row 1: Blue, Yellow
  // Row 2: Cyan, Magenta
  DecodedImage orig;
  orig.width = 2;
  orig.height = 3;
  orig.channels = 4;
  orig.rgba = {
    255, 0, 0, 255,     0, 255, 0, 255,      // Row 0: Red, Green
    0, 0, 255, 255,     255, 255, 0, 255,    // Row 1: Blue, Yellow
    0, 255, 255, 255,   255, 0, 255, 255     // Row 2: Cyan, Magenta
  };

  // Orientation 6: Rotate 90 CW. Dimensions become 3x2.
  // New Row 0: Cyan, Blue, Red
  // New Row 1: Magenta, Yellow, Green
  auto rot6 = applyOrientation(orig, 6);
  TEST_ASSERT(rot6.width == 3, "Rotated 90 CW width should be 3");
  TEST_ASSERT(rot6.height == 2, "Rotated 90 CW height should be 2");

  // Check top-left (new Row 0, Col 0) == Cyan (orig 0, 2)
  TEST_ASSERT(rot6.rgba[0] == 0 && rot6.rgba[1] == 255 && rot6.rgba[2] == 255, "Top-left is Cyan");
  // Check top-right (new Row 0, Col 2) == Red (orig 0, 0)
  TEST_ASSERT(rot6.rgba[8] == 255 && rot6.rgba[9] == 0 && rot6.rgba[10] == 0, "Top-right is Red");
  // Check bottom-left (new Row 1, Col 0) == Magenta (orig 1, 2)
  TEST_ASSERT(rot6.rgba[12] == 255 && rot6.rgba[13] == 0 && rot6.rgba[14] == 255, "Bottom-left is Magenta");
  // Check bottom-right (new Row 1, Col 2) == Green (orig 1, 0)
  TEST_ASSERT(rot6.rgba[20] == 0 && rot6.rgba[21] == 255 && rot6.rgba[22] == 0, "Bottom-right is Green");

  // Orientation 8: Rotate 270 CW. Dimensions become 3x2.
  auto rot8 = applyOrientation(orig, 8);
  TEST_ASSERT(rot8.width == 3, "Rotated 270 CW width should be 3");
  TEST_ASSERT(rot8.height == 2, "Rotated 270 CW height should be 2");
  // Check top-left == Green
  TEST_ASSERT(rot8.rgba[0] == 0 && rot8.rgba[1] == 255 && rot8.rgba[2] == 0, "Top-left is Green");
  // Check bottom-right == Cyan
  TEST_ASSERT(rot8.rgba[20] == 0 && rot8.rgba[21] == 255 && rot8.rgba[22] == 255, "Bottom-right is Cyan");

  // Orientation 3: Rotate 180. Dimensions remain 2x3.
  auto rot3 = applyOrientation(orig, 3);
  TEST_ASSERT(rot3.width == 2, "Rotated 180 width should be 2");
  TEST_ASSERT(rot3.height == 3, "Rotated 180 height should be 3");
  // Check top-left == Magenta
  TEST_ASSERT(rot3.rgba[0] == 255 && rot3.rgba[1] == 0 && rot3.rgba[2] == 255, "Top-left is Magenta");

  // 2. Test parseExifOrientation with synthetic JPEG EXIF
  std::vector<uint8_t> jpegWithExif = {
    0xFF, 0xD8, // SOI
    0xFF, 0xE1, // APP1
    0x00, 0x1E, // Length = 30 bytes
    'E', 'x', 'i', 'f', 0x00, 0x00, // "Exif\0\0"
    'I', 'I',   // Little endian TIFF
    0x2A, 0x00, // TIFF magic 42
    0x08, 0x00, 0x00, 0x00, // Offset to IFD0 = 8
    0x01, 0x00, // 1 entry in IFD0
    0x12, 0x01, // Tag = 0x0112 (Orientation)
    0x03, 0x00, // Type = 3 (SHORT)
    0x01, 0x00, 0x00, 0x00, // Count = 1
    0x06, 0x00, 0x00, 0x00, // Value = 6 (Rotate 90 CW)
    0xFF, 0xD9  // EOI
  };

  int parsedOri = parseExifOrientation(jpegWithExif.data(), jpegWithExif.size());
  TEST_ASSERT(parsedOri == 6, "parseExifOrientation must extract orientation 6");

  // Change orientation value to 8
  jpegWithExif[30] = 0x08;
  parsedOri = parseExifOrientation(jpegWithExif.data(), jpegWithExif.size());
  TEST_ASSERT(parsedOri == 8, "parseExifOrientation must extract orientation 8");

  // Plain non-exif buffer should return 1
  std::vector<uint8_t> emptyJpeg = { 0xFF, 0xD8, 0xFF, 0xD9 };
  TEST_ASSERT(parseExifOrientation(emptyJpeg.data(), emptyJpeg.size()) == 1, "Non-exif JPEG returns 1");

  std::cout << "[PASS] testExifOrientationAndRotation passed." << std::endl;
}

int main() {
  std::cout << "=========================================================" << std::endl;
  std::cout << "Starting In-Memory WebP & Zero Disk Temp Files Test Suite" << std::endl;
  std::cout << "=========================================================" << std::endl;

  testAspectRatioFitting();
  testWebpEncodeDecode();
  testResizeAndThumbnail();
  testInMemoryCryptoAndThumbnailing();
  testExifOrientationAndRotation();

  std::cout << "=========================================================" << std::endl;
  std::cout << "ALL IN-MEMORY WEBP & CRYPTO TESTS PASSED CLEANLY!" << std::endl;
  std::cout << "=========================================================" << std::endl;
  return 0;
}
