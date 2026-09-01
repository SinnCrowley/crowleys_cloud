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

const BASE83_CHARS =
  '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~';

const BASE83_MAP = new Int16Array(256);
BASE83_MAP.fill(-1);
for (let i = 0; i < BASE83_CHARS.length; i++) {
  BASE83_MAP[BASE83_CHARS.charCodeAt(i)] = i;
}

function decodeBase83(str, start, end) {
  let val = 0;
  for (let i = start; i < end; i++) {
    const code = str.charCodeAt(i);
    if (code >= 256) return -1;
    const digit = BASE83_MAP[code];
    if (digit === -1) return -1;
    val = val * 83 + digit;
  }
  return val;
}

const SRGB_TO_LINEAR = new Float32Array(256);
for (let i = 0; i < 256; i++) {
  const v = i / 255.0;
  SRGB_TO_LINEAR[i] = v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
}

function linearToSrgb(value) {
  const v = Math.max(0.0, Math.min(1.0, value));
  if (v <= 0.0031308) {
    return Math.max(0, Math.min(255, Math.round(v * 12.92 * 255.0)));
  }
  return Math.max(0, Math.min(255, Math.round((1.055 * Math.pow(v, 1.0 / 2.4) - 0.055) * 255.0)));
}

function signPow(val, exp) {
  return Math.sign(val) * Math.pow(Math.abs(val), exp);
}

/**
 * Validates a BlurHash string syntax and length.
 * @param {string} blurhash
 * @returns {boolean}
 */
export function isValidBlurHash(blurhash) {
  if (!blurhash || typeof blurhash !== 'string' || blurhash.length < 6) {
    return false;
  }

  for (let i = 0; i < blurhash.length; i++) {
    const code = blurhash.charCodeAt(i);
    if (code >= 256 || BASE83_MAP[code] === -1) {
      return false;
    }
  }

  const sizeFlag = decodeBase83(blurhash, 0, 1);
  if (sizeFlag < 0) {
    return false;
  }

  const numY = Math.floor(sizeFlag / 9) + 1;
  const numX = (sizeFlag % 9) + 1;
  if (numX < 1 || numX > 9 || numY < 1 || numY > 9) {
    return false;
  }

  const expectedLength = 4 + 2 * numX * numY;
  return blurhash.length === expectedLength;
}

// Bounded LRU cache for decoded ImageData (max 500 entries)
const DECODE_CACHE = new Map();
const MAX_CACHE_SIZE = 500;

/**
 * Decodes a BlurHash string into an ImageData object of specified dimensions.
 * @param {string} blurhash - Base83 encoded BlurHash string.
 * @param {number} width - Output width (default 32).
 * @param {number} height - Output height (default 32).
 * @param {number} punch - Contrast multiplier (default 1.0).
 * @returns {ImageData|null}
 */
export function decodeBlurHashToImageData(blurhash, width = 32, height = 32, punch = 1.0) {
  if (!isValidBlurHash(blurhash) || width <= 0 || height <= 0) {
    return null;
  }

  const cacheKey = `${blurhash}:${width}:${height}:${punch}`;
  if (DECODE_CACHE.has(cacheKey)) {
    const cached = DECODE_CACHE.get(cacheKey);
    // Refresh LRU order
    DECODE_CACHE.delete(cacheKey);
    DECODE_CACHE.set(cacheKey, cached);
    return cached;
  }

  const sizeFlag = decodeBase83(blurhash, 0, 1);
  const numY = Math.floor(sizeFlag / 9) + 1;
  const numX = (sizeFlag % 9) + 1;

  const quantisedMax = decodeBase83(blurhash, 1, 2);
  const maxValue = (quantisedMax + 1) / 166.0;

  const totalComponents = numX * numY;
  const factorsR = new Float32Array(totalComponents);
  const factorsG = new Float32Array(totalComponents);
  const factorsB = new Float32Array(totalComponents);

  // DC component
  const dcVal = decodeBase83(blurhash, 2, 6);
  factorsR[0] = SRGB_TO_LINEAR[(dcVal >> 16) & 255];
  factorsG[0] = SRGB_TO_LINEAR[(dcVal >> 8) & 255];
  factorsB[0] = SRGB_TO_LINEAR[dcVal & 255];

  // AC components
  for (let k = 1; k < totalComponents; k++) {
    const acVal = decodeBase83(blurhash, 4 + 2 * k, 6 + 2 * k);
    const qR = Math.floor(acVal / (19 * 19));
    const qG = Math.floor(acVal / 19) % 19;
    const qB = acVal % 19;

    factorsR[k] = signPow((qR - 9) / 9.0, 2.0) * maxValue * punch;
    factorsG[k] = signPow((qG - 9) / 9.0, 2.0) * maxValue * punch;
    factorsB[k] = signPow((qB - 9) / 9.0, 2.0) * maxValue * punch;
  }

  // Precompute Cosine lookup tables for current dimensions
  const cosX = new Float32Array(numX * width);
  for (let i = 0; i < numX; i++) {
    const freq = (Math.PI * i) / width;
    for (let x = 0; x < width; x++) {
      cosX[i * width + x] = Math.cos(freq * x);
    }
  }

  const cosY = new Float32Array(numY * height);
  for (let j = 0; j < numY; j++) {
    const freq = (Math.PI * j) / height;
    for (let y = 0; y < height; y++) {
      cosY[j * height + y] = Math.cos(freq * y);
    }
  }

  const pixels = new Uint8ClampedArray(width * height * 4);
  let pixelIndex = 0;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      let r = 0;
      let g = 0;
      let b = 0;

      for (let j = 0; j < numY; j++) {
        const cy = cosY[j * height + y];
        const factorOffset = j * numX;
        for (let i = 0; i < numX; i++) {
          const basis = cosX[i * width + x] * cy;
          const idx = factorOffset + i;
          r += factorsR[idx] * basis;
          g += factorsG[idx] * basis;
          b += factorsB[idx] * basis;
        }
      }

      pixels[pixelIndex++] = linearToSrgb(r);
      pixels[pixelIndex++] = linearToSrgb(g);
      pixels[pixelIndex++] = linearToSrgb(b);
      pixels[pixelIndex++] = 255;
    }
  }

  let imageData;
  if (typeof ImageData !== 'undefined') {
    imageData = new ImageData(pixels, width, height);
  } else {
    imageData = { data: pixels, width, height };
  }

  // Store in LRU cache
  if (DECODE_CACHE.size >= MAX_CACHE_SIZE) {
    const oldestKey = DECODE_CACHE.keys().next().value;
    DECODE_CACHE.delete(oldestKey);
  }
  DECODE_CACHE.set(cacheKey, imageData);

  return imageData;
}

/**
 * Decodes a BlurHash string into a raw RGBA Uint8ClampedArray.
 * @param {string} blurhash - Base83 encoded BlurHash string.
 * @param {number} width - Output width (default 32).
 * @param {number} height - Output height (default 32).
 * @param {number} punch - Contrast multiplier (default 1.0).
 * @returns {Uint8ClampedArray|null}
 */
export function decodeBlurHash(blurhash, width = 32, height = 32, punch = 1.0) {
  const imgData = decodeBlurHashToImageData(blurhash, width, height, punch);
  return imgData ? imgData.data : null;
}
