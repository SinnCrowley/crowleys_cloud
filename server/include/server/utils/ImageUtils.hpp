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

#pragma once

#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <vector>

namespace server::utils {

struct ImageDimensions {
  int width{0};
  int height{0};
};

struct DecodedImage {
  int width{0};
  int height{0};
  int channels{0};
  std::vector<uint8_t> rgba;
};

/**
 * Calculates aspect-ratio-preserving dimensions scaled to fit within maxDimension.
 * Ensures target width and height are strictly >= 1 and does not upscale smaller images.
 */
ImageDimensions calculateAspectRatioFit(int origW, int origH, int maxDimension);

/**
 * Decodes an image from memory buffer (JPEG, PNG, GIF, BMP, WebP) into RGBA8888.
 */
std::optional<DecodedImage> decodeImageToRgba(const uint8_t *data, std::size_t size);

/**
 * Resizes an RGBA8888 image buffer to target dimensions using bilinear filtering.
 */
std::vector<uint8_t> resizeRgba(const uint8_t *srcRgba, int srcW, int srcH, int dstW, int dstH);

/**
 * Encodes an RGBA8888 image buffer into WebP format at given quality (0.0 - 100.0).
 */
std::vector<uint8_t> encodeRgbaToWebP(const uint8_t *rgba, int width, int height, float quality = 80.0f);

/**
 * End-to-end in-memory thumbnail pipeline:
 * Decodes image -> aspect-ratio downscales -> encodes to WebP.
 * Optionally populates outOriginal with the decoded source image.
 */
std::optional<std::vector<uint8_t>> generateThumbnailWebP(const uint8_t *imageData,
                                                          std::size_t imageSize,
                                                          int maxDimension = 256,
                                                          float quality = 80.0f,
                                                          DecodedImage *outOriginal = nullptr,
                                                          std::string *outBlurHash = nullptr);

inline std::optional<std::vector<uint8_t>> generateThumbnailWebP(const std::vector<uint8_t> &imageBuffer,
                                                                int maxDimension = 256,
                                                                float quality = 80.0f,
                                                                DecodedImage *outOriginal = nullptr,
                                                                std::string *outBlurHash = nullptr) {
  return generateThumbnailWebP(imageBuffer.data(), imageBuffer.size(), maxDimension, quality, outOriginal, outBlurHash);
}

/**
 * Atomically saves a buffer to a file on disk (writing to a unique temporary cache file and renaming).
 */
bool saveBufferAtomically(const std::filesystem::path &destPath, const std::vector<uint8_t> &buffer);

/**
 * Generates .webp thumbnail from unencrypted local file on disk.
 */
bool generateThumbnailFromFile(const std::filesystem::path &sourcePath,
                               const std::filesystem::path &destWebpPath,
                               int maxDimension = 256,
                               float quality = 80.0f,
                               DecodedImage *outOriginal = nullptr,
                               std::string *outBlurHash = nullptr);

/**
 * Generates .webp thumbnail from AES-256 encrypted file directly in RAM with zero intermediate disk temp files.
 */
bool generateThumbnailFromEncryptedFile(const std::filesystem::path &encryptedPath,
                                        const std::string &encryptionKey,
                                        const std::filesystem::path &destWebpPath,
                                        int maxDimension = 256,
                                        float quality = 80.0f,
                                        DecodedImage *outOriginal = nullptr,
                                        std::string *outBlurHash = nullptr);

}  // namespace server::utils
