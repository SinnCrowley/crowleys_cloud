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

#ifdef CROWLEYS_CLOUD_HAS_LIBHEIF
#include <libheif/heif.h>
#endif

#define STB_IMAGE_IMPLEMENTATION
#include "stb/stb_image.h"

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb/stb_image_resize2.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <fstream>
#include <memory>

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

static int parseTiffOrientation(const uint8_t *data, size_t size) {
  if (!data || size < 8) return 1;

  bool littleEndian = false;
  if (data[0] == 'I' && data[1] == 'I') {
    littleEndian = true;
  } else if (data[0] == 'M' && data[1] == 'M') {
    littleEndian = false;
  } else {
    return 1;
  }

  auto read16 = [data, littleEndian](size_t offset) -> uint16_t {
    if (littleEndian) {
      return static_cast<uint16_t>(data[offset]) | (static_cast<uint16_t>(data[offset + 1]) << 8);
    } else {
      return (static_cast<uint16_t>(data[offset]) << 8) | static_cast<uint16_t>(data[offset + 1]);
    }
  };

  auto read32 = [data, littleEndian](size_t offset) -> uint32_t {
    if (littleEndian) {
      return static_cast<uint32_t>(data[offset]) |
             (static_cast<uint32_t>(data[offset + 1]) << 8) |
             (static_cast<uint32_t>(data[offset + 2]) << 16) |
             (static_cast<uint32_t>(data[offset + 3]) << 24);
    } else {
      return (static_cast<uint32_t>(data[offset]) << 24) |
             (static_cast<uint32_t>(data[offset + 1]) << 16) |
             (static_cast<uint32_t>(data[offset + 2]) << 8) |
             static_cast<uint32_t>(data[offset + 3]);
    }
  };

  uint16_t magic = read16(2);
  if (magic != 42 && magic != 0x2A) return 1;

  uint32_t ifd0Offset = read32(4);
  if (ifd0Offset > size || ifd0Offset + 2 > size) return 1;

  uint16_t numEntries = read16(ifd0Offset);
  size_t cur = ifd0Offset + 2;

  for (uint16_t i = 0; i < numEntries; ++i) {
    if (cur + 12 > size) break;
    uint16_t tag = read16(cur);
    if (tag == 0x0112) {  // Orientation tag
      uint16_t type = read16(cur + 2);
      uint32_t count = read32(cur + 4);
      if ((type == 3 || type == 4) && count >= 1) {  // SHORT or LONG
        uint16_t val = read16(cur + 8);
        if (val >= 1 && val <= 8) {
          return val;
        }
      }
    }
    cur += 12;
  }
  return 1;
}

static int parseJpegOrientation(const uint8_t *data, size_t size) {
  if (!data || size < 4) return 1;
  if (data[0] != 0xFF || data[1] != 0xD8) return 1;  // Not JPEG SOI

  size_t pos = 2;
  while (pos + 4 <= size) {
    if (data[pos] != 0xFF) {
      pos++;
      continue;
    }
    while (pos < size && data[pos] == 0xFF) {
      pos++;
    }
    if (pos >= size) break;

    uint8_t marker = data[pos++];
    if (marker == 0xDA || marker == 0xD9) {  // SOS or EOI
      break;
    }
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
      continue;  // Standalone markers without length
    }

    if (pos + 2 > size) break;
    uint16_t len = (static_cast<uint16_t>(data[pos]) << 8) | static_cast<uint16_t>(data[pos + 1]);
    if (len < 2 || pos + len > size) break;

    if (marker == 0xE1) {  // APP1
      // Check for "Exif\0\0"
      if (len >= 8 && std::memcmp(data + pos + 2, "Exif\0\0", 6) == 0) {
        int ori = parseTiffOrientation(data + pos + 8, len - 8);
        if (ori >= 1 && ori <= 8) {
          return ori;
        }
      }
    }
    pos += len;
  }
  return 1;
}

static int parseWebpOrientation(const uint8_t *data, size_t size) {
  if (!data || size < 12) return 1;
  if (std::memcmp(data, "RIFF", 4) != 0 || std::memcmp(data + 8, "WEBP", 4) != 0) {
    return 1;
  }
  size_t pos = 12;
  while (pos + 8 <= size) {
    const char *fourcc = reinterpret_cast<const char *>(data + pos);
    uint32_t chunkSize = static_cast<uint32_t>(data[pos + 4]) |
                         (static_cast<uint32_t>(data[pos + 5]) << 8) |
                         (static_cast<uint32_t>(data[pos + 6]) << 16) |
                         (static_cast<uint32_t>(data[pos + 7]) << 24);
    pos += 8;
    if (pos + chunkSize > size) break;

    if (std::memcmp(fourcc, "EXIF", 4) == 0) {
      if (chunkSize >= 6 && std::memcmp(data + pos, "Exif\0\0", 6) == 0) {
        return parseTiffOrientation(data + pos + 6, chunkSize - 6);
      }
      return parseTiffOrientation(data + pos, chunkSize);
    }
    pos += chunkSize + (chunkSize & 1);  // Pad to even byte
  }
  return 1;
}

int parseExifOrientation(const uint8_t *data, std::size_t size) {
  if (!data || size < 4) return 1;

  if (data[0] == 0xFF && data[1] == 0xD8) {
    return parseJpegOrientation(data, size);
  }
  if (size >= 12 && std::memcmp(data, "RIFF", 4) == 0 && std::memcmp(data + 8, "WEBP", 4) == 0) {
    return parseWebpOrientation(data, size);
  }
  if ((data[0] == 'I' && data[1] == 'I') || (data[0] == 'M' && data[1] == 'M')) {
    return parseTiffOrientation(data, size);
  }
  if (size >= 6 && std::memcmp(data, "Exif\0\0", 6) == 0) {
    return parseTiffOrientation(data + 6, size - 6);
  }
  return 1;
}

DecodedImage applyOrientation(DecodedImage img, int orientation) {
  if (orientation <= 1 || orientation > 8) {
    return img;
  }

  const int w = img.width;
  const int h = img.height;
  if (w <= 0 || h <= 0 || img.rgba.size() < static_cast<size_t>(w) * h * 4) {
    return img;
  }

  DecodedImage rotated;
  rotated.channels = 4;
  if (orientation == 5 || orientation == 6 || orientation == 7 || orientation == 8) {
    rotated.width = h;
    rotated.height = w;
  } else {
    rotated.width = w;
    rotated.height = h;
  }
  rotated.rgba.resize(static_cast<size_t>(rotated.width) * rotated.height * 4);

  const auto *src32 = reinterpret_cast<const uint32_t *>(img.rgba.data());
  auto *dst32 = reinterpret_cast<uint32_t *>(rotated.rgba.data());

  switch (orientation) {
    case 2:  // Flip horizontal
      for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
          dst32[y * w + (w - 1 - x)] = src32[y * w + x];
        }
      }
      break;
    case 3:  // Rotate 180
      for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
          dst32[(h - 1 - y) * w + (w - 1 - x)] = src32[y * w + x];
        }
      }
      break;
    case 4:  // Flip vertical
      for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
          dst32[(h - 1 - y) * w + x] = src32[y * w + x];
        }
      }
      break;
    case 5:  // Transpose (flip horizontal + rotate 270 CW)
      for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
          dst32[x * h + y] = src32[y * w + x];
        }
      }
      break;
    case 6:  // Rotate 90 CW
      for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
          dst32[x * h + (h - 1 - y)] = src32[y * w + x];
        }
      }
      break;
    case 7:  // Transverse (flip horizontal + rotate 90 CW)
      for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
          dst32[(w - 1 - x) * h + (h - 1 - y)] = src32[y * w + x];
        }
      }
      break;
    case 8:  // Rotate 270 CW / 90 CCW
      for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
          dst32[(w - 1 - x) * h + y] = src32[y * w + x];
        }
      }
      break;
    default:
      return img;
  }

  return rotated;
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
      int orientation = parseExifOrientation(data, size);
      return applyOrientation(std::move(img), orientation);
    }
    if (rgba) {
      WebPFree(rgba);
    }
  }

#ifdef CROWLEYS_CLOUD_HAS_LIBHEIF
  // 2. Try HEIF/HEIC decoding via libheif
  if (size >= 12 && heif_check_filetype(data, static_cast<int>(std::min(size, static_cast<size_t>(64)))) != heif_filetype_no) {
    heif_context *rawCtx = heif_context_alloc();
    if (rawCtx) {
      std::unique_ptr<heif_context, decltype(&heif_context_free)> ctx(rawCtx, &heif_context_free);
      heif_error err = heif_context_read_from_memory_without_copy(ctx.get(), data, size, nullptr);
      if (err.code == heif_error_Ok) {
        heif_image_handle *rawHandle = nullptr;
        err = heif_context_get_primary_image_handle(ctx.get(), &rawHandle);
        if (err.code == heif_error_Ok && rawHandle) {
          std::unique_ptr<heif_image_handle, decltype(&heif_image_handle_release)> handle(rawHandle, &heif_image_handle_release);
          heif_image *rawImg = nullptr;
          err = heif_decode_image(handle.get(), &rawImg, heif_colorspace_RGB, heif_chroma_interleaved_RGBA, nullptr);
          if (err.code == heif_error_Ok && rawImg) {
            std::unique_ptr<heif_image, decltype(&heif_image_release)> img(rawImg, &heif_image_release);
            int imgW = heif_image_get_width(img.get(), heif_channel_interleaved);
            int imgH = heif_image_get_height(img.get(), heif_channel_interleaved);
            size_t stride = 0;
            const uint8_t *plane = heif_image_get_plane_readonly2(img.get(), heif_channel_interleaved, &stride);
            if (plane && imgW > 0 && imgH > 0 && stride >= static_cast<size_t>(imgW * 4)) {
              DecodedImage decoded;
              decoded.width = imgW;
              decoded.height = imgH;
              decoded.channels = 4;
              decoded.rgba.resize(static_cast<size_t>(imgW) * imgH * 4);
              for (int y = 0; y < imgH; ++y) {
                std::memcpy(decoded.rgba.data() + (static_cast<size_t>(y) * imgW * 4),
                            plane + (static_cast<size_t>(y) * stride),
                            static_cast<size_t>(imgW * 4));
              }

              // Check if HEIF has an EXIF metadata block with orientation
              int numBlocks = heif_image_handle_get_number_of_metadata_blocks(handle.get(), "Exif");
              if (numBlocks > 0) {
                std::vector<heif_item_id> blockIds(numBlocks);
                heif_image_handle_get_list_of_metadata_block_IDs(handle.get(), "Exif", blockIds.data(), numBlocks);
                size_t metaSize = heif_image_handle_get_metadata_size(handle.get(), blockIds[0]);
                if (metaSize > 8) {
                  std::vector<uint8_t> metaBuf(metaSize);
                  heif_image_handle_get_metadata(handle.get(), blockIds[0], metaBuf.data());
                  int ori = 1;
                  for (size_t off = 0; off + 8 <= metaSize && off < 32; ++off) {
                    if ((metaBuf[off] == 'I' && metaBuf[off + 1] == 'I') ||
                        (metaBuf[off] == 'M' && metaBuf[off + 1] == 'M')) {
                      ori = parseTiffOrientation(metaBuf.data() + off, metaSize - off);
                      break;
                    }
                  }
                  if (ori > 1 && ori <= 8) {
                    return applyOrientation(std::move(decoded), ori);
                  }
                }
              }
              return decoded;
            }
          }
        }
      }
    }
  }
#endif

  // 3. Decode with stb_image (JPEG, PNG, GIF, BMP, TGA, etc.)
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

  int orientation = parseExifOrientation(data, size);
  return applyOrientation(std::move(img), orientation);
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
