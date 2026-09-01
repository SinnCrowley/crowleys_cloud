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
import 'package:flutter_test/flutter_test.dart';
import 'package:crowleys_cloud/shared/utils/blurhash_decoder.dart';

void main() {
  setUp(() {
    BlurHashDecoder.clearCache();
  });

  group('BlurHashDecoder Adversarial: Fuzzing & Malformed Inputs', () {
    test('Zero unhandled exceptions on 10,000 randomized corrupt strings', () {
      final rand = math.Random(42);
      const alphabet =
          '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#\$%*+,-.:;=?@[]^_{|}~'
          ' \t\r\n\x00\x01\x1F\x7F\xFF\u00A0\u200B\uFEFF😀🚀⚡中文Русский';

      for (int i = 0; i < 10000; i++) {
        final length = rand.nextInt(40);
        final buffer = StringBuffer();
        for (int j = 0; j < length; j++) {
          buffer.write(alphabet[rand.nextInt(alphabet.length)]);
        }
        final fuzzStr = buffer.toString();

        // 1. Validation must never throw
        final isValid = BlurHashDecoder.isValid(fuzzStr);

        // 2. decodeToBmp must never throw
        final bmp = BlurHashDecoder.decodeToBmp(fuzzStr, width: 16, height: 16);
        if (!isValid) {
          expect(bmp, isNull);
        }

        // 3. decodeRgba must never throw
        final rgba = BlurHashDecoder.decodeRgba(fuzzStr, width: 16, height: 16);
        if (!isValid) {
          expect(rgba, isNull);
        }
      }
    });

    test('Rejects all invalid lengths below minimum requirement', () {
      expect(BlurHashDecoder.isValid(null), isFalse);
      expect(BlurHashDecoder.isValid(''), isFalse);
      expect(BlurHashDecoder.isValid('0'), isFalse);
      expect(BlurHashDecoder.isValid('00'), isFalse);
      expect(BlurHashDecoder.isValid('000'), isFalse);
      expect(BlurHashDecoder.isValid('0000'), isFalse);
      expect(BlurHashDecoder.isValid('00000'), isFalse);
    });

    test('Non-Base83 boundary ASCII characters are strictly rejected', () {
      // Base83 chars are: 0-9, A-Z, a-z, #, $, %, *, +, ,, -, ., :, ;, =, ?, @, [, ], ^, _, {, |, }, ~
      // Forbidden ASCII chars include: space, !, ", &, ', (, ), /, <, >, \, `, etc.
      final forbidden = [
        ' ', '!', '"', '&', "'", '(', ')', '/', '<', '>', '\\', '`', '\n', '\t'
      ];
      for (final char in forbidden) {
        final testHash = 'L6Pj0^jE.AyE_3t7t7R**0o#DgR$char';
        expect(
          BlurHashDecoder.isValid(testHash),
          isFalse,
          reason: 'Character "$char" (code ${char.codeUnitAt(0)}) must be rejected',
        );
      }
    });

    test('Unicode characters with code unit >= 256 are safely handled and rejected', () {
      final highCodes = ['\u0100', '\u0430', '\u4E2D', '\u{1F600}'];
      for (final char in highCodes) {
        final testHash = 'L6Pj0^jE.AyE_3t7t7R**0o#DgR$char';
        expect(BlurHashDecoder.isValid(testHash), isFalse);
        expect(BlurHashDecoder.decodeToBmp(testHash), isNull);
        expect(BlurHashDecoder.decodeRgba(testHash), isNull);
      }
    });
  });

  group('BlurHashDecoder Adversarial: Component Flags & Boundary Configurations', () {
    test('1x1 component minimum valid BlurHash (6 chars)', () {
      // sizeFlag '0' = (0/9)+1 x (0%9)+1 = 1x1 components
      // quantisedMax '0'
      // DC value '0000' = black
      const hash1x1 = '000000';
      expect(BlurHashDecoder.isValid(hash1x1), isTrue);

      final bmp = BlurHashDecoder.decodeToBmp(hash1x1, width: 8, height: 8);
      expect(bmp, isNotNull);
      expect(bmp!.length, equals(54 + 8 * 8 * 4));
    });

    test('9x9 component maximum valid component configuration', () {
      // sizeFlag for 9x9: numX=9, numY=9 -> sizeFlag = (8 * 9) + 8 = 80 -> Base83 char index 80 = '|'
      // Total length required: 4 + 2 * (9 * 9) = 4 + 162 = 166 chars
      final buffer = StringBuffer('|');
      for (int i = 1; i < 166; i++) {
        buffer.write('0');
      }
      final hash9x9 = buffer.toString();
      expect(hash9x9.length, equals(166));
      expect(BlurHashDecoder.isValid(hash9x9), isTrue);

      final bmp = BlurHashDecoder.decodeToBmp(hash9x9, width: 16, height: 16);
      expect(bmp, isNotNull);
      expect(bmp!.length, equals(54 + 16 * 16 * 4));
    });

    test('Rejects sizeFlag >= 81 where components exceed 9x9', () {
      // Base83 chars at index 81 ('}') and 82 ('~')
      // For index 81: (81 ~/ 9) + 1 = 10 -> numY = 10 (exceeds 9)
      final buf81 = StringBuffer('}');
      for (int i = 1; i < 200; i++) {
        buf81.write('0');
      }
      expect(BlurHashDecoder.isValid(buf81.toString()), isFalse);
      expect(BlurHashDecoder.decodeToBmp(buf81.toString()), isNull);
    });

    test('1x9 and 9x1 asymmetric component counts', () {
      // 9x1 components: numX=9, numY=1 -> sizeFlag = 0*9 + 8 = 8 -> char '8'
      // length = 4 + 2 * 9 = 22
      final buf9x1 = StringBuffer('8');
      for (int i = 1; i < 22; i++) {
        buf9x1.write('0');
      }
      final hash9x1 = buf9x1.toString();
      expect(BlurHashDecoder.isValid(hash9x1), isTrue);
      expect(BlurHashDecoder.decodeToBmp(hash9x1, width: 16, height: 16), isNotNull);

      // 1x9 components: numX=1, numY=9 -> sizeFlag = 8*9 + 0 = 72 -> char at index 72 = '='
      // length = 4 + 2 * 9 = 22
      final buf1x9 = StringBuffer('=');
      for (int i = 1; i < 22; i++) {
        buf1x9.write('0');
      }
      final hash1x9 = buf1x9.toString();
      expect(BlurHashDecoder.isValid(hash1x9), isTrue);
      expect(BlurHashDecoder.decodeToBmp(hash1x9, width: 16, height: 16), isNotNull);
    });
  });

  group('BlurHashDecoder Adversarial: Punch & Mathematical Edge Cases', () {
    const sampleBlurHash = 'L6Pj0^jE.AyE_3t7t7R**0o#DgR4';

    test('Handles negative, zero, and extreme punch values without overflow or crash', () {
      final punches = [
        -1000.0,
        -10.0,
        -1.0,
        -0.0001,
        0.0,
        0.0001,
        1.0,
        10.0,
        100.0,
        10000.0,
      ];

      for (final punch in punches) {
        final bmp = BlurHashDecoder.decodeToBmp(
          sampleBlurHash,
          width: 8,
          height: 8,
          punch: punch,
        );
        expect(bmp, isNotNull);
        expect(bmp!.length, equals(54 + 8 * 8 * 4));

        // Every color byte must be within [0, 255] and alpha must be 255
        for (int i = 54; i < bmp.length; i += 4) {
          final b = bmp[i];
          final g = bmp[i + 1];
          final r = bmp[i + 2];
          final a = bmp[i + 3];
          expect(b >= 0 && b <= 255, isTrue);
          expect(g >= 0 && g <= 255, isTrue);
          expect(r >= 0 && r <= 255, isTrue);
          expect(a, equals(255));
        }
      }
    });

    test('Handles punch with NaN / Infinite values gracefully', () {
      final bmpNan = BlurHashDecoder.decodeToBmp(
        sampleBlurHash,
        width: 8,
        height: 8,
        punch: double.nan,
      );
      // Even with NaN punch, should not throw uncaught exception
      if (bmpNan != null) {
        expect(bmpNan.length, equals(54 + 8 * 8 * 4));
      }

      final bmpInf = BlurHashDecoder.decodeToBmp(
        sampleBlurHash,
        width: 8,
        height: 8,
        punch: double.infinity,
      );
      if (bmpInf != null) {
        expect(bmpInf.length, equals(54 + 8 * 8 * 4));
      }
    });
  });

  group('BlurHashDecoder Adversarial: Dimension Boundary Stress', () {
    const sampleBlurHash = 'L6Pj0^jE.AyE_3t7t7R**0o#DgR4';

    test('1x1 single pixel BMP synthesis produces valid 58-byte BMP', () {
      final bmp = BlurHashDecoder.decodeToBmp(sampleBlurHash, width: 1, height: 1);
      expect(bmp, isNotNull);
      expect(bmp!.length, equals(58)); // 54 header + 4 BGRA

      final byteData = ByteData.sublistView(bmp);
      expect(bmp[0], equals(0x42));
      expect(bmp[1], equals(0x4D));
      expect(byteData.getUint32(2, Endian.little), equals(58));
      expect(byteData.getInt32(18, Endian.little), equals(1));
      expect(byteData.getInt32(22, Endian.little), equals(-1));
      expect(byteData.getUint32(34, Endian.little), equals(4));
    });

    test('Extreme aspect ratio dimensions (1x256 and 256x1)', () {
      final bmpTall = BlurHashDecoder.decodeToBmp(sampleBlurHash, width: 1, height: 256);
      expect(bmpTall, isNotNull);
      expect(bmpTall!.length, equals(54 + 1 * 256 * 4));

      final bmpWide = BlurHashDecoder.decodeToBmp(sampleBlurHash, width: 256, height: 1);
      expect(bmpWide, isNotNull);
      expect(bmpWide!.length, equals(54 + 256 * 1 * 4));
    });

    test('Negative, zero, and degenerate dimensions return null', () {
      expect(BlurHashDecoder.decodeToBmp(sampleBlurHash, width: 0, height: 0), isNull);
      expect(BlurHashDecoder.decodeToBmp(sampleBlurHash, width: -1, height: 32), isNull);
      expect(BlurHashDecoder.decodeToBmp(sampleBlurHash, width: 32, height: -1), isNull);
      expect(BlurHashDecoder.decodeToBmp(sampleBlurHash, width: -100, height: -100), isNull);

      expect(BlurHashDecoder.decodeRgba(sampleBlurHash, width: 0, height: 0), isNull);
      expect(BlurHashDecoder.decodeRgba(sampleBlurHash, width: -5, height: 10), isNull);
    });
  });

  group('BlurHashDecoder Adversarial: BMP Header & Color Accuracy Oracle', () {
    test('Solid black BlurHash (000000) decodes to pure black RGB(0,0,0,255)', () {
      const blackHash = '000000';
      final bmp = BlurHashDecoder.decodeToBmp(blackHash, width: 4, height: 4);
      expect(bmp, isNotNull);

      for (int i = 54; i < bmp!.length; i += 4) {
        expect(bmp[i], equals(0));     // Blue
        expect(bmp[i + 1], equals(0)); // Green
        expect(bmp[i + 2], equals(0)); // Red
        expect(bmp[i + 3], equals(255)); // Alpha
      }
    });

    test('Solid white BlurHash (00TSUA) decodes to pure white RGB(255,255,255,255)', () {
      // 1x1 component with max 24-bit sRGB DC value (0xFFFFFF = 16777215 -> 'TSUA' in Base83)
      const whiteHash = '00TSUA';
      expect(BlurHashDecoder.isValid(whiteHash), isTrue);

      final bmp = BlurHashDecoder.decodeToBmp(whiteHash, width: 4, height: 4);
      expect(bmp, isNotNull);

      for (int i = 54; i < bmp!.length; i += 4) {
        expect(bmp[i], equals(255));     // Blue
        expect(bmp[i + 1], equals(255)); // Green
        expect(bmp[i + 2], equals(255)); // Red
        expect(bmp[i + 3], equals(255)); // Alpha
      }
    });

    test('BMP Header Oracle checks all 54 bytes for compliance with Windows DIB standard', () {
      const width = 24;
      const height = 18;
      const expectedSize = 54 + width * height * 4;

      final bmp = BlurHashDecoder.decodeToBmp(
        'L6Pj0^jE.AyE_3t7t7R**0o#DgR4',
        width: width,
        height: height,
      )!;

      final bd = ByteData.sublistView(bmp);

      // BITMAPFILEHEADER
      expect(String.fromCharCode(bmp[0]) + String.fromCharCode(bmp[1]), equals('BM'));
      expect(bd.getUint32(2, Endian.little), equals(expectedSize));
      expect(bd.getUint16(6, Endian.little), equals(0));
      expect(bd.getUint16(8, Endian.little), equals(0));
      expect(bd.getUint32(10, Endian.little), equals(54));

      // BITMAPINFOHEADER
      expect(bd.getUint32(14, Endian.little), equals(40)); // biSize
      expect(bd.getInt32(18, Endian.little), equals(width)); // biWidth
      expect(bd.getInt32(22, Endian.little), equals(-height)); // biHeight (top-down)
      expect(bd.getUint16(26, Endian.little), equals(1)); // biPlanes
      expect(bd.getUint16(28, Endian.little), equals(32)); // biBitCount
      expect(bd.getUint32(30, Endian.little), equals(0)); // biCompression (BI_RGB)
      expect(bd.getUint32(34, Endian.little), equals(width * height * 4)); // biSizeImage
      expect(bd.getInt32(38, Endian.little), equals(0)); // biXPelsPerMeter
      expect(bd.getInt32(42, Endian.little), equals(0)); // biYPelsPerMeter
      expect(bd.getUint32(46, Endian.little), equals(0)); // biClrUsed
      expect(bd.getUint32(50, Endian.little), equals(0)); // biClrImportant
    });
  });

  group('BlurHashDecoder Adversarial: LRU Cache Eviction & Boundary Behavior', () {
    test('LRU cache strictly caps at 500 entries across 1,200 unique insertions', () {
      expect(BlurHashDecoder.cacheSize, equals(0));

      for (int i = 0; i < 1200; i++) {
        BlurHashDecoder.decodeToBmp(
          '000000',
          punch: 1.0 + (i * 0.0001),
        );
        expect(
          BlurHashDecoder.cacheSize <= 500,
          isTrue,
          reason: 'Cache size must never exceed 500, current: ${BlurHashDecoder.cacheSize}',
        );
      }

      expect(BlurHashDecoder.cacheSize, equals(500));
    });

    test('LRU cache preserves most recently accessed items and evicts oldest', () {
      // 1. Insert item 0
      BlurHashDecoder.decodeToBmp('000000', punch: 0.0);

      // 2. Insert items 1 to 499 (cache is now full with 500 items)
      for (int i = 1; i < 500; i++) {
        BlurHashDecoder.decodeToBmp('000000', punch: i.toDouble());
      }
      expect(BlurHashDecoder.cacheSize, equals(500));

      // 3. Touch item 0 to promote it to MRU
      final item0Promoted = BlurHashDecoder.decodeToBmp('000000', punch: 0.0);
      expect(item0Promoted, isNotNull);

      // 4. Insert item 500 (this should evict item 1, NOT item 0)
      BlurHashDecoder.decodeToBmp('000000', punch: 500.0);
      expect(BlurHashDecoder.cacheSize, equals(500));

      // 5. Access item 0 again and ensure it's still cached in memory
      final item0Again = BlurHashDecoder.decodeToBmp('000000', punch: 0.0);
      expect(identical(item0Promoted, item0Again), isTrue);
    });
  });
}
