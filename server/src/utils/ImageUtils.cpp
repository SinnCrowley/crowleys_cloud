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

#include "server/utils/ImageUtils.hpp"
#include "server/utils/BlurHashEncoder.hpp"
#include "server/utils/Crypto.hpp"

#include <webp/decode.h>
#include <webp/encode.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb/stb_image.h"

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb/stb_image_resize2.h"

#include <algorithm>
#include <cmath>
#include <fstream>

namespace server::utils {

ImageDimensions calculateAspectRatioFit(int origW, int origH, int maxDimension) {
  if (origW <= 0 || origH <= 0 || maxDimension <= 0) {
    return {0, 0};
  }

  if (origW <= maxDimension && origH <= maxDimension) {
    return {origW, origH};
  }

  int targetW = origW;
  int targetH = origH;

  if (origW >= origH) {
    targetW = maxDimension;
    targetH = std::max(1, static_cast<int>(std::round(static_cast<double>(origH) * maxDimension / origW)));
  } else {
    targetH = maxDimension;
    targetW = std::max(1, static_cast<int>(std::round(static_cast<double>(origW) * maxDimension / origH)));
  }

  return {targetW, targetH};
}

std::optional<DecodedImage> decodeImageToRgba(const uint8_t *data, std::size_t size) {
  if (!data || size == 0) {
    return std::nullopt;
  }

  int w = 0, h = 0;
  // 1. Try decoding with libwebp first if it is WebP format
  if (WebPGetInfo(data, size, &w, &h)) {
    uint8_t *rgba = WebPDecodeRGBA(data, size, &w, &h);
    if (rgba && w > 0 && h > 0) {
      DecodedImage img;
      img.width = w;
      img.height = h;
      img.channels = 4;
      img.rgba.assign(rgba, rgba + (static_cast<size_t>(w) * h * 4));
      WebPFree(rgba);
      return img;
    }
    if (rgba) {
      WebPFree(rgba);
    }
  }

  // 2. Decode with stb_image (JPEG, PNG, GIF, BMP, TGA, etc.)
  int channelsInFile = 0;
  unsigned char *pixels = stbi_load_from_memory(
      data, static_cast<int>(size), &w, &h, &channelsInFile, 4);

  if (!pixels || w <= 0 || h <= 0) {
    if (pixels) {
      stbi_image_free(pixels);
    }
    return std::nullopt;
  }

  DecodedImage img;
  img.width = w;
  img.height = h;
  img.channels = 4;
  img.rgba.assign(pixels, pixels + (static_cast<size_t>(w) * h * 4));
  stbi_image_free(pixels);
  return img;
}

std::vector<uint8_t> resizeRgba(const uint8_t *srcRgba, int srcW, int srcH, int dstW, int dstH) {
  if (!srcRgba || srcW <= 0 || srcH <= 0 || dstW <= 0 || dstH <= 0) {
    return {};
  }

  if (srcW == dstW && srcH == dstH) {
    return std::vector<uint8_t>(srcRgba, srcRgba + (static_cast<size_t>(srcW) * srcH * 4));
  }

  std::vector<uint8_t> dstRgba(static_cast<size_t>(dstW) * dstH * 4);
  unsigned char *res = stbir_resize_uint8_linear(
      srcRgba, srcW, srcH, 0,
      dstRgba.data(), dstW, dstH, 0,
      STBIR_RGBA);

  if (!res) {
    return {};
  }

  return dstRgba;
}

std::vector<uint8_t> encodeRgbaToWebP(const uint8_t *rgba, int width, int height, float quality) {
  if (!rgba || width <= 0 || height <= 0) {
    return {};
  }

  float q = std::clamp(quality, 0.0f, 100.0f);
  uint8_t *output = nullptr;
  size_t outSize = WebPEncodeRGBA(rgba, width, height, width * 4, q, &output);

  if (outSize == 0 || !output) {
    if (output) {
      WebPFree(output);
    }
    return {};
  }

  std::vector<uint8_t> webpBytes(output, output + outSize);
  WebPFree(output);
  return webpBytes;
}

std::optional<std::vector<uint8_t>> generateThumbnailWebP(const uint8_t *imageData,
                                                          std::size_t imageSize,
                                                          int maxDimension,
                                                          float quality,
                                                          DecodedImage *outOriginal,
                                                          std::string *outBlurHash) {
  auto decodedOpt = decodeImageToRgba(imageData, imageSize);
  if (!decodedOpt) {
    return std::nullopt;
  }

  auto &decoded = *decodedOpt;
  if (outBlurHash) {
    *outBlurHash = encodeBlurHash(decoded.rgba.data(), decoded.width, decoded.height, 4, 3);
  }

  auto targetDims = calculateAspectRatioFit(decoded.width, decoded.height, maxDimension);
  if (targetDims.width <= 0 || targetDims.height <= 0) {
    return std::nullopt;
  }

  auto resizedRgba = resizeRgba(decoded.rgba.data(), decoded.width, decoded.height, targetDims.width, targetDims.height);
  if (resizedRgba.empty()) {
    return std::nullopt;
  }

  auto webpBytes = encodeRgbaToWebP(resizedRgba.data(), targetDims.width, targetDims.height, quality);
  if (webpBytes.empty()) {
    return std::nullopt;
  }

  if (outOriginal) {
    *outOriginal = std::move(decoded);
  }

  return webpBytes;
}

bool saveBufferAtomically(const std::filesystem::path &destPath, const std::vector<uint8_t> &buffer) {
  if (buffer.empty()) {
    return false;
  }

  std::error_code ec;
  auto parentDir = destPath.parent_path();
  if (!parentDir.empty()) {
    std::filesystem::create_directories(parentDir, ec);
  }

  // Generate a unique temporary filename in the same directory for atomic rename
  std::string randSuffix = randomTokenHex(8);
  auto tmpPath = destPath.string() + ".tmp." + randSuffix;

  {
    std::ofstream out(tmpPath, std::ios::binary | std::ios::trunc);
    if (!out) {
      return false;
    }
    out.write(reinterpret_cast<const char*>(buffer.data()), buffer.size());
    if (!out.good()) {
      std::filesystem::remove(tmpPath, ec);
      return false;
    }
  }

  std::filesystem::rename(tmpPath, destPath, ec);
  if (ec) {
    std::filesystem::remove(tmpPath, ec);
    return false;
  }

  return true;
}

bool generateThumbnailFromFile(const std::filesystem::path &sourcePath,
                               const std::filesystem::path &destWebpPath,
                               int maxDimension,
                               float quality,
                               DecodedImage *outOriginal,
                               std::string *outBlurHash) {
  std::error_code ec;
  const auto sz = std::filesystem::file_size(sourcePath, ec);
  if (ec || sz == 0) {
    return false;
  }

  std::ifstream in(sourcePath, std::ios::binary);
  if (!in) {
    return false;
  }

  std::vector<uint8_t> buffer(sz);
  if (!in.read(reinterpret_cast<char*>(buffer.data()), sz)) {
    return false;
  }
  in.close();

  auto webpOpt = generateThumbnailWebP(buffer.data(), buffer.size(), maxDimension, quality, outOriginal, outBlurHash);
  if (!webpOpt) {
    return false;
  }

  return saveBufferAtomically(destWebpPath, *webpOpt);
}

bool generateThumbnailFromEncryptedFile(const std::filesystem::path &encryptedPath,
                                        const std::string &encryptionKey,
                                        const std::filesystem::path &destWebpPath,
                                        int maxDimension,
                                        float quality,
                                        DecodedImage *outOriginal,
                                        std::string *outBlurHash) {
  std::vector<uint8_t> decryptedBuffer;
  if (!decryptFileToMemory(encryptedPath, encryptionKey, decryptedBuffer)) {
    return false;
  }

  auto webpOpt = generateThumbnailWebP(decryptedBuffer.data(), decryptedBuffer.size(), maxDimension, quality, outOriginal, outBlurHash);
  if (!webpOpt) {
    return false;
  }

  return saveBufferAtomically(destWebpPath, *webpOpt);
}

}  // namespace server::utils
