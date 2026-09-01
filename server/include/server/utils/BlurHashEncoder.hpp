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
#include <string>
#include <vector>

namespace server::utils {

/**
 * Encodes an RGBA8888 pixel buffer into a standard Base83 BlurHash string.
 * Default components: x = 4, y = 3 yielding a 28-character hash string.
 *
 * @param rgba Pointer to contiguous RGBA8888 pixel data (size = width * height * 4).
 * @param width Image width in pixels (> 0).
 * @param height Image height in pixels (> 0).
 * @param xComponents Number of horizontal DCT components (1 to 9, default 4).
 * @param yComponents Number of vertical DCT components (1 to 9, default 3).
 * @return 28-character Base83 BlurHash string on success, or empty string on invalid parameters.
 */
std::string encodeBlurHash(const uint8_t *rgba,
                           int width,
                           int height,
                           int xComponents = 4,
                           int yComponents = 3);

/**
 * Convenience overload for std::vector<uint8_t> RGBA pixel buffer.
 */
inline std::string encodeBlurHash(const std::vector<uint8_t> &rgba,
                                  int width,
                                  int height,
                                  int xComponents = 4,
                                  int yComponents = 3) {
  return encodeBlurHash(rgba.data(), width, height, xComponents, yComponents);
}

/**
 * Validates whether a given string is a syntactically valid BlurHash.
 * Checks Base83 alphabet, component count bounds, and matching length.
 */
bool isValidBlurHash(const std::string &blurhash);

}  // namespace server::utils
