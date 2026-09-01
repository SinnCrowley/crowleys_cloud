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

#include <algorithm>
#include <array>
#include <cmath>
#include <numbers>
#include <string_view>
#include <vector>

namespace server::utils {

namespace {

constexpr std::string_view kBase83Chars =
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~";

const auto kSrgbToLinearLut = []() {
  std::array<float, 256> lut{};
  for (int i = 0; i < 256; ++i) {
    float v = static_cast<float>(i) / 255.0f;
    if (v <= 0.04045f) {
      lut[i] = v / 12.92f;
    } else {
      lut[i] = std::pow((v + 0.055f) / 1.055f, 2.4f);
    }
  }
  return lut;
}();

inline int linearToSrgb(float value) {
  float v = std::clamp(value, 0.0f, 1.0f);
  if (v <= 0.0031308f) {
    return std::clamp(static_cast<int>(std::round(v * 12.92f * 255.0f)), 0, 255);
  }
  return std::clamp(static_cast<int>(std::round((1.055f * std::pow(v, 1.0f / 2.4f) - 0.055f) * 255.0f)), 0, 255);
}

inline float signPow(float val, float exp) {
  return std::copysign(std::pow(std::abs(val), exp), val);
}

std::string encodeBase83(uint32_t value, int length) {
  std::string result(length, '0');
  for (int i = 1; i <= length; ++i) {
    uint32_t divisor = 1;
    for (int p = 0; p < length - i; ++p) {
      divisor *= 83;
    }
    uint32_t digit = (value / divisor) % 83;
    result[i - 1] = kBase83Chars[digit];
  }
  return result;
}

int decodeBase83(std::string_view str) {
  int value = 0;
  for (char c : str) {
    auto pos = kBase83Chars.find(c);
    if (pos == std::string_view::npos) {
      return -1;
    }
    value = value * 83 + static_cast<int>(pos);
  }
  return value;
}

struct ColorTriplet {
  float r{0.0f};
  float g{0.0f};
  float b{0.0f};
};

}  // namespace

std::string encodeBlurHash(const uint8_t *rgba,
                           int width,
                           int height,
                           int xComponents,
                           int yComponents) {
  if (!rgba || width <= 0 || height <= 0 ||
      xComponents < 1 || xComponents > 9 ||
      yComponents < 1 || yComponents > 9) {
    return "";
  }

  const int totalComponents = xComponents * yComponents;
  std::vector<ColorTriplet> factors(totalComponents);

  // Precompute cosine tables for performance
  std::vector<std::vector<float>> cosX(xComponents, std::vector<float>(width));
  for (int i = 0; i < xComponents; ++i) {
    for (int x = 0; x < width; ++x) {
      cosX[i][x] = static_cast<float>(std::cos(std::numbers::pi * i * x / width));
    }
  }

  std::vector<std::vector<float>> cosY(yComponents, std::vector<float>(height));
  for (int j = 0; j < yComponents; ++j) {
    for (int y = 0; y < height; ++y) {
      cosY[j][y] = static_cast<float>(std::cos(std::numbers::pi * j * y / height));
    }
  }

  // Discrete Cosine Transform (DCT)
  for (int j = 0; j < yComponents; ++j) {
    for (int i = 0; i < xComponents; ++i) {
      const float normalisation = (i == 0 && j == 0) ? 1.0f : 2.0f;
      float rAcc = 0.0f;
      float gAcc = 0.0f;
      float bAcc = 0.0f;

      for (int y = 0; y < height; ++y) {
        const float cy = cosY[j][y];
        const int rowOffset = y * width * 4;
        for (int x = 0; x < width; ++x) {
          const float basis = cosX[i][x] * cy;
          const int pixelIdx = rowOffset + x * 4;
          rAcc += basis * kSrgbToLinearLut[rgba[pixelIdx]];
          gAcc += basis * kSrgbToLinearLut[rgba[pixelIdx + 1]];
          bAcc += basis * kSrgbToLinearLut[rgba[pixelIdx + 2]];
        }
      }

      const float scale = normalisation / static_cast<float>(width * height);
      factors[j * xComponents + i] = ColorTriplet{
          .r = rAcc * scale,
          .g = gAcc * scale,
          .b = bAcc * scale,
      };
    }
  }

  std::string blurHash;
  blurHash.reserve(4 + 2 * totalComponents);

  // 1. Size flag (1 char)
  const int sizeFlag = (xComponents - 1) + (yComponents - 1) * 9;
  blurHash += encodeBase83(static_cast<uint32_t>(sizeFlag), 1);

  // 2. Maximum AC component amplitude quantization
  float maximumValue = 1.0f;
  if (totalComponents > 1) {
    float actualMaximumValue = 0.0f;
    for (int k = 1; k < totalComponents; ++k) {
      actualMaximumValue = std::max(actualMaximumValue, std::abs(factors[k].r));
      actualMaximumValue = std::max(actualMaximumValue, std::abs(factors[k].g));
      actualMaximumValue = std::max(actualMaximumValue, std::abs(factors[k].b));
    }
    const int quantisedMaximumValue = std::clamp(
        static_cast<int>(std::floor(actualMaximumValue * 166.0f - 0.5f)), 0, 82);
    blurHash += encodeBase83(static_cast<uint32_t>(quantisedMaximumValue), 1);
    maximumValue = static_cast<float>(quantisedMaximumValue + 1) / 166.0f;
  } else {
    blurHash += encodeBase83(0, 1);
  }

  // 3. DC component (4 chars)
  const int dcR = linearToSrgb(factors[0].r);
  const int dcG = linearToSrgb(factors[0].g);
  const int dcB = linearToSrgb(factors[0].b);
  const uint32_t dcVal = (static_cast<uint32_t>(dcR) << 16) |
                         (static_cast<uint32_t>(dcG) << 8) |
                         static_cast<uint32_t>(dcB);
  blurHash += encodeBase83(dcVal, 4);

  // 4. AC components (2 chars each)
  for (int k = 1; k < totalComponents; ++k) {
    const int qR = std::clamp(
        static_cast<int>(std::floor(signPow(factors[k].r / maximumValue, 0.5f) * 9.0f + 9.5f)), 0, 18);
    const int qG = std::clamp(
        static_cast<int>(std::floor(signPow(factors[k].g / maximumValue, 0.5f) * 9.0f + 9.5f)), 0, 18);
    const int qB = std::clamp(
        static_cast<int>(std::floor(signPow(factors[k].b / maximumValue, 0.5f) * 9.0f + 9.5f)), 0, 18);
    const uint32_t acVal = static_cast<uint32_t>(qR * 19 * 19 + qG * 19 + qB);
    blurHash += encodeBase83(acVal, 2);
  }

  return blurHash;
}

bool isValidBlurHash(const std::string &blurhash) {
  if (blurhash.size() < 6) {
    return false;
  }

  for (char c : blurhash) {
    if (kBase83Chars.find(c) == std::string_view::npos) {
      return false;
    }
  }

  const int sizeFlag = decodeBase83(blurhash.substr(0, 1));
  if (sizeFlag < 0) {
    return false;
  }

  const int numY = (sizeFlag / 9) + 1;
  const int numX = (sizeFlag % 9) + 1;
  if (numX < 1 || numX > 9 || numY < 1 || numY > 9) {
    return false;
  }

  const size_t expectedLength = static_cast<size_t>(4 + 2 * numX * numY);
  return blurhash.size() == expectedLength;
}

}  // namespace server::utils
