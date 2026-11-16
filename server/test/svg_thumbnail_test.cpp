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

#include "server/utils/Crypto.hpp"
#include "server/utils/ImageUtils.hpp"
#include "server/utils/BlurHashEncoder.hpp"

using namespace server::utils;

#define TEST_ASSERT(cond, msg) \
  do { \
    if (!(cond)) { \
      std::cerr << "[FAIL] Line " << __LINE__ << ": " << (msg) << std::endl; \
      std::exit(1); \
    } \
  } while (0)

void testSvgDecodeStandard() {
  std::cout << "[TEST] Running testSvgDecodeStandard..." << std::endl;
  const std::string svg = "<svg width=\"200\" height=\"100\" xmlns=\"http://www.w3.org/2000/svg\">"
                          "<rect width=\"200\" height=\"100\" fill=\"red\"/>"
                          "</svg>";
  auto decoded = decodeImageToRgba(reinterpret_cast<const uint8_t *>(svg.data()), svg.size());
  TEST_ASSERT(decoded.has_value(), "SVG decode returned value");
  TEST_ASSERT(decoded->width == 200, "SVG width 200");
  TEST_ASSERT(decoded->height == 100, "SVG height 100");
  TEST_ASSERT(decoded->channels == 4, "SVG channels 4");
  TEST_ASSERT(!decoded->rgba.empty(), "SVG rgba not empty");

  // First pixel should be red (255, 0, 0, 255)
  TEST_ASSERT(decoded->rgba[0] >= 250, "Red channel high");
  TEST_ASSERT(decoded->rgba[1] <= 5, "Green channel low");
  TEST_ASSERT(decoded->rgba[2] <= 5, "Blue channel low");
  TEST_ASSERT(decoded->rgba[3] >= 250, "Alpha channel high");
  std::cout << "  Passed!" << std::endl;
}

void testSvgDecodeViewBoxOnly() {
  std::cout << "[TEST] Running testSvgDecodeViewBoxOnly..." << std::endl;
  const std::string svg = "<svg viewBox=\"0 0 300 150\" xmlns=\"http://www.w3.org/2000/svg\">"
                          "<circle cx=\"50\" cy=\"50\" r=\"50\" fill=\"blue\"/>"
                          "</svg>";
  auto decoded = decodeImageToRgba(reinterpret_cast<const uint8_t *>(svg.data()), svg.size());
  TEST_ASSERT(decoded.has_value(), "SVG decode returned value");
  TEST_ASSERT(decoded->width == 300, "SVG viewBox width 300");
  TEST_ASSERT(decoded->height == 150, "SVG viewBox height 150");
  TEST_ASSERT(decoded->channels == 4, "SVG channels 4");
  std::cout << "  Passed!" << std::endl;
}

void testSvgDecodeXmlPrologue() {
  std::cout << "[TEST] Running testSvgDecodeXmlPrologue..." << std::endl;
  const std::string svg = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                          "<!-- Just a comment -->\n"
                          "<svg width=\"50\" height=\"50\" xmlns=\"http://www.w3.org/2000/svg\">\n"
                          "<rect width=\"50\" height=\"50\" fill=\"#00FF00\"/>\n"
                          "</svg>";
  auto decoded = decodeImageToRgba(reinterpret_cast<const uint8_t *>(svg.data()), svg.size());
  TEST_ASSERT(decoded.has_value(), "SVG decode returned value");
  TEST_ASSERT(decoded->width == 50, "SVG width 50");
  TEST_ASSERT(decoded->height == 50, "SVG height 50");
  // Pixel should be green
  TEST_ASSERT(decoded->rgba[0] <= 5, "Red channel low");
  TEST_ASSERT(decoded->rgba[1] >= 250, "Green channel high");
  TEST_ASSERT(decoded->rgba[2] <= 5, "Blue channel low");
  TEST_ASSERT(decoded->rgba[3] >= 250, "Alpha channel high");
  std::cout << "  Passed!" << std::endl;
}

void testSvgThumbnailGeneration() {
  std::cout << "[TEST] Running testSvgThumbnailGeneration..." << std::endl;
  namespace fs = std::filesystem;
  const auto tempDir = fs::temp_directory_path() / "crowleys_cloud_svg_test";
  fs::create_directories(tempDir);

  const auto svgPath = tempDir / "test_icon.svg";
  const auto thumbPath = tempDir / "test_icon_thumb.webp";

  {
    std::ofstream out(svgPath);
    out << "<svg width=\"400\" height=\"200\" xmlns=\"http://www.w3.org/2000/svg\">"
        << "<rect width=\"400\" height=\"200\" fill=\"purple\"/>"
        << "<circle cx=\"200\" cy=\"100\" r=\"80\" fill=\"yellow\"/>"
        << "</svg>";
  }

  std::string blurHash;
  bool ok = generateThumbnailFromFile(svgPath, thumbPath, 128, 80.0f, nullptr, &blurHash);
  TEST_ASSERT(ok, "generateThumbnailFromFile succeeded for SVG");
  TEST_ASSERT(fs::exists(thumbPath), "Thumbnail webp file exists");
  TEST_ASSERT(fs::file_size(thumbPath) > 0, "Thumbnail file size > 0");
  TEST_ASSERT(!blurHash.empty(), "BlurHash was computed");
  std::cout << "  Computed BlurHash: " << blurHash << std::endl;

  // Validate the generated WebP file
  std::ifstream webpFile(thumbPath, std::ios::binary | std::ios::ate);
  auto webpSize = webpFile.tellg();
  webpFile.seekg(0, std::ios::beg);
  std::vector<uint8_t> webpData(webpSize);
  webpFile.read(reinterpret_cast<char *>(webpData.data()), webpSize);

  int outW = 0, outH = 0;
  TEST_ASSERT(WebPGetInfo(webpData.data(), webpData.size(), &outW, &outH), "WebP header valid");
  TEST_ASSERT(outW == 128, "Thumbnail width clamped to 128");
  TEST_ASSERT(outH == 64, "Thumbnail height maintains 2:1 aspect ratio (64)");

  fs::remove_all(tempDir);
  std::cout << "  Passed!" << std::endl;
}

void testSvgMalformedGraceful() {
  std::cout << "[TEST] Running testSvgMalformedGraceful..." << std::endl;
  const std::string malformed = "<svg width=\"100\" height=\"100\" xmlns=\"http://www.w3.org/2000/svg\"><unclosed";
  auto decoded = decodeImageToRgba(reinterpret_cast<const uint8_t *>(malformed.data()), malformed.size());
  // Should handle gracefully (either nullopt or empty without crash)
  std::cout << "  Malformed handled gracefully without crashing." << std::endl;
}

int main() {
  std::cout << "=== SVG Thumbnail & Decoding Tests ===" << std::endl;
  testSvgDecodeStandard();
  testSvgDecodeViewBoxOnly();
  testSvgDecodeXmlPrologue();
  testSvgThumbnailGeneration();
  testSvgMalformedGraceful();
  std::cout << "=== All SVG Tests Passed! ===" << std::endl;
  return 0;
}
