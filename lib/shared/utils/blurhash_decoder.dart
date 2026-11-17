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

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Pure Dart zero-dependency BlurHash decoder.
///
/// Features:
/// - Base83 decoding using an O(1) integer lookup table.
/// - Pre-calculated sRGB <-> Linear color space conversion tables.
/// - Inverse Discrete Cosine Transform (IDCT) image synthesis.
/// - Synchronous 32-bit BMP header construction (top-down BGRA format) for instant frame-0 rendering.
/// - Bounded in-memory LRU cache of 500 entries.
class BlurHashDecoder {
  BlurHashDecoder._();

  static const String _base83Chars =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#\$%*+,-.:;=?@[]^_{|}~';

  static final Int16List _base83Map = () {
    final map = Int16List(256)..fillRange(0, 256, -1);
    for (int i = 0; i < _base83Chars.length; i++) {
      map[_base83Chars.codeUnitAt(i)] = i;
    }
    return map;
  }();

  static final Float32List _srgbToLinear = () {
    final lut = Float32List(256);
    for (int i = 0; i < 256; i++) {
      final v = i / 255.0;
      lut[i] = v <= 0.04045
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }
    return lut;
  }();

  static int _linearToSrgb(double value) {
    final v = value.clamp(0.0, 1.0);
    if (v <= 0.0031308) {
      return (v * 12.92 * 255.0).round().clamp(0, 255);
    }
    return ((1.055 * math.pow(v, 1.0 / 2.4) - 0.055) * 255.0).round().clamp(
      0,
      255,
    );
  }

  static double _signPow(double val, double exp) {
    if (val == 0.0) return 0.0;
    return val.sign * math.pow(val.abs(), exp);
  }

  static int _decodeBase83(String str, int start, int end) {
    int val = 0;
    for (int i = start; i < end; i++) {
      final code = str.codeUnitAt(i);
      if (code >= 256) return -1;
      final digit = _base83Map[code];
      if (digit == -1) return -1;
      val = val * 83 + digit;
    }
    return val;
  }

  /// Validates whether a given string is a syntactically valid BlurHash.
  static bool isValid(String? blurhash) {
    if (blurhash == null || blurhash.length < 6) return false;
    for (int i = 0; i < blurhash.length; i++) {
      final code = blurhash.codeUnitAt(i);
      if (code >= 256 || _base83Map[code] == -1) return false;
    }
    final sizeFlag = _decodeBase83(blurhash, 0, 1);
    if (sizeFlag < 0) return false;
    final numY = (sizeFlag ~/ 9) + 1;
    final numX = (sizeFlag % 9) + 1;
    if (numX < 1 || numX > 9 || numY < 1 || numY > 9) return false;
    return blurhash.length == 4 + 2 * numX * numY;
  }

  static final Map<String, Uint8List> _bmpCache = {};
  static final List<String> _bmpCacheOrder = [];
  static const int _maxCacheSize = 500;

  /// Current number of decoded BMPs stored in the LRU cache.
  static int get cacheSize => _bmpCache.length;

  /// Clears the in-memory LRU BMP cache.
  static void clearCache() {
    _bmpCache.clear();
    _bmpCacheOrder.clear();
  }

  /// Decodes a BlurHash string into raw RGBA pixel bytes (width * height * 4).
  static Uint8List? decodeRgba(
    String blurhash, {
    int width = 32,
    int height = 32,
    double punch = 1.0,
  }) {
    if (!isValid(blurhash) || width <= 0 || height <= 0) return null;

    final sizeFlag = _decodeBase83(blurhash, 0, 1);
    final numY = (sizeFlag ~/ 9) + 1;
    final numX = (sizeFlag % 9) + 1;

    final quantisedMax = _decodeBase83(blurhash, 1, 2);
    final maxValue = (quantisedMax + 1) / 166.0;

    final totalComponents = numX * numY;
    final factorsR = Float32List(totalComponents);
    final factorsG = Float32List(totalComponents);
    final factorsB = Float32List(totalComponents);

    final dcVal = _decodeBase83(blurhash, 2, 6);
    factorsR[0] = _srgbToLinear[(dcVal >> 16) & 255];
    factorsG[0] = _srgbToLinear[(dcVal >> 8) & 255];
    factorsB[0] = _srgbToLinear[dcVal & 255];

    for (int k = 1; k < totalComponents; k++) {
      final acVal = _decodeBase83(blurhash, 4 + 2 * k, 6 + 2 * k);
      final qR = acVal ~/ (19 * 19);
      final qG = (acVal ~/ 19) % 19;
      final qB = acVal % 19;

      factorsR[k] = _signPow((qR - 9) / 9.0, 2.0) * maxValue * punch;
      factorsG[k] = _signPow((qG - 9) / 9.0, 2.0) * maxValue * punch;
      factorsB[k] = _signPow((qB - 9) / 9.0, 2.0) * maxValue * punch;
    }

    final cosX = Float32List(numX * width);
    for (int i = 0; i < numX; i++) {
      final freq = math.pi * i / width;
      for (int x = 0; x < width; x++) {
        cosX[i * width + x] = math.cos(freq * x);
      }
    }

    final cosY = Float32List(numY * height);
    for (int j = 0; j < numY; j++) {
      final freq = math.pi * j / height;
      for (int y = 0; y < height; y++) {
        cosY[j * height + y] = math.cos(freq * y);
      }
    }

    final rgba = Uint8List(width * height * 4);
    int offset = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double r = 0.0;
        double g = 0.0;
        double b = 0.0;

        for (int j = 0; j < numY; j++) {
          final cy = cosY[j * height + y];
          final factorOffset = j * numX;
          for (int i = 0; i < numX; i++) {
            final basis = cosX[i * width + x] * cy;
            final idx = factorOffset + i;
            r += factorsR[idx] * basis;
            g += factorsG[idx] * basis;
            b += factorsB[idx] * basis;
          }
        }

        rgba[offset++] = _linearToSrgb(r);
        rgba[offset++] = _linearToSrgb(g);
        rgba[offset++] = _linearToSrgb(b);
        rgba[offset++] = 255;
      }
    }

    return rgba;
  }

  /// Decodes a BlurHash string into an uncompressed 32-bit BMP image byte array in RAM.
  ///
  /// The returned byte array can be passed directly to [Image.memory] for instantaneous,
  /// synchronous display on the first frame. Decoded results are cached in an LRU memory cache.
  static Uint8List? decodeToBmp(
    String blurhash, {
    int width = 32,
    int height = 32,
    double punch = 1.0,
  }) {
    if (!isValid(blurhash) || width <= 0 || height <= 0) return null;

    final cacheKey = '$blurhash:$width:$height:$punch';
    final cached = _bmpCache[cacheKey];
    if (cached != null) {
      _bmpCacheOrder.remove(cacheKey);
      _bmpCacheOrder.add(cacheKey);
      return cached;
    }

    final sizeFlag = _decodeBase83(blurhash, 0, 1);
    final numY = (sizeFlag ~/ 9) + 1;
    final numX = (sizeFlag % 9) + 1;

    final quantisedMax = _decodeBase83(blurhash, 1, 2);
    final maxValue = (quantisedMax + 1) / 166.0;

    final totalComponents = numX * numY;
    final factorsR = Float32List(totalComponents);
    final factorsG = Float32List(totalComponents);
    final factorsB = Float32List(totalComponents);

    final dcVal = _decodeBase83(blurhash, 2, 6);
    factorsR[0] = _srgbToLinear[(dcVal >> 16) & 255];
    factorsG[0] = _srgbToLinear[(dcVal >> 8) & 255];
    factorsB[0] = _srgbToLinear[dcVal & 255];

    for (int k = 1; k < totalComponents; k++) {
      final acVal = _decodeBase83(blurhash, 4 + 2 * k, 6 + 2 * k);
      final qR = acVal ~/ (19 * 19);
      final qG = (acVal ~/ 19) % 19;
      final qB = acVal % 19;

      factorsR[k] = _signPow((qR - 9) / 9.0, 2.0) * maxValue * punch;
      factorsG[k] = _signPow((qG - 9) / 9.0, 2.0) * maxValue * punch;
      factorsB[k] = _signPow((qB - 9) / 9.0, 2.0) * maxValue * punch;
    }

    final cosX = Float32List(numX * width);
    for (int i = 0; i < numX; i++) {
      final freq = math.pi * i / width;
      for (int x = 0; x < width; x++) {
        cosX[i * width + x] = math.cos(freq * x);
      }
    }

    final cosY = Float32List(numY * height);
    for (int j = 0; j < numY; j++) {
      final freq = math.pi * j / height;
      for (int y = 0; y < height; y++) {
        cosY[j * height + y] = math.cos(freq * y);
      }
    }

    // 54-byte BMP Header + pixel data in BGRA format
    final pixelBytesCount = width * height * 4;
    final totalFileSize = 54 + pixelBytesCount;
    final bmp = Uint8List(totalFileSize);
    final byteData = ByteData.sublistView(bmp);

    // BITMAPFILEHEADER (14 bytes)
    bmp[0] = 0x42; // 'B'
    bmp[1] = 0x4D; // 'M'
    byteData.setUint32(2, totalFileSize, Endian.little);
    byteData.setUint32(6, 0, Endian.little);
    byteData.setUint32(10, 54, Endian.little); // offset to pixel array

    // BITMAPINFOHEADER (40 bytes)
    byteData.setUint32(14, 40, Endian.little); // header size
    byteData.setInt32(18, width, Endian.little);
    byteData.setInt32(
      22,
      -height,
      Endian.little,
    ); // negative height for top-down raster
    byteData.setUint16(26, 1, Endian.little); // planes
    byteData.setUint16(28, 32, Endian.little); // bpp
    byteData.setUint32(30, 0, Endian.little); // BI_RGB (uncompressed)
    byteData.setUint32(34, pixelBytesCount, Endian.little);
    byteData.setInt32(38, 0, Endian.little);
    byteData.setInt32(42, 0, Endian.little);
    byteData.setUint32(46, 0, Endian.little);
    byteData.setUint32(50, 0, Endian.little);

    int pixelOffset = 54;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double r = 0.0;
        double g = 0.0;
        double b = 0.0;

        for (int j = 0; j < numY; j++) {
          final cy = cosY[j * height + y];
          final factorOffset = j * numX;
          for (int i = 0; i < numX; i++) {
            final basis = cosX[i * width + x] * cy;
            final idx = factorOffset + i;
            r += factorsR[idx] * basis;
            g += factorsG[idx] * basis;
            b += factorsB[idx] * basis;
          }
        }

        bmp[pixelOffset++] = _linearToSrgb(b); // Blue
        bmp[pixelOffset++] = _linearToSrgb(g); // Green
        bmp[pixelOffset++] = _linearToSrgb(r); // Red
        bmp[pixelOffset++] = 255; // Alpha
      }
    }

    if (_bmpCache.length >= _maxCacheSize) {
      final oldestKey = _bmpCacheOrder.removeAt(0);
      _bmpCache.remove(oldestKey);
    }
    _bmpCache[cacheKey] = bmp;
    _bmpCacheOrder.add(cacheKey);

    return bmp;
  }
}

/// Instantaneous, smooth placeholder widget that renders a decoded BlurHash BMP in RAM.
class BlurHashWidget extends StatelessWidget {
  const BlurHashWidget({
    super.key,
    required this.blurhash,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.punch = 1.0,
  });

  final String blurhash;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double punch;

  @override
  Widget build(BuildContext context) {
    final bmp = BlurHashDecoder.decodeToBmp(blurhash, punch: punch);
    if (bmp == null) {
      return SizedBox(width: width, height: height);
    }
    return Image.memory(
      bmp,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}
