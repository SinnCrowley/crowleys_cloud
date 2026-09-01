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

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crowleys_cloud/shared/utils/blurhash_decoder.dart';

void main() {
  const sampleBlurHash =
      'L6Pj0^jE.AyE_3t7t7R**0o#DgR4'; // 4x3 components (length 28)
  const solidBlurHash = '000000'; // 1x1 component (length 6)

  setUp(() {
    BlurHashDecoder.clearCache();
  });

  group('BlurHashDecoder Validation', () {
    test('validates standard 4x3 BlurHash', () {
      expect(BlurHashDecoder.isValid(sampleBlurHash), isTrue);
    });

    test('validates 1x1 BlurHash', () {
      expect(BlurHashDecoder.isValid(solidBlurHash), isTrue);
    });

    test('rejects null, empty, and short strings', () {
      expect(BlurHashDecoder.isValid(null), isFalse);
      expect(BlurHashDecoder.isValid(''), isFalse);
      expect(BlurHashDecoder.isValid('12345'), isFalse);
    });

    test('rejects invalid characters not in Base83', () {
      expect(
        BlurHashDecoder.isValid('L6Pj0^jE.AyE_3t7t7R**0o#DgR!'),
        isFalse,
      ); // '!' is not in Base83
      expect(
        BlurHashDecoder.isValid('L6Pj0^jE.AyE_3t7t7R**0o#DgR '),
        isFalse,
      ); // space is not in Base83
    });

    test('rejects mismatched length for component count', () {
      // sampleBlurHash has 4x3 components -> requires 4 + 2*12 = 28 chars.
      // Truncated to 27 or extended to 29 must fail:
      expect(BlurHashDecoder.isValid(sampleBlurHash.substring(0, 27)), isFalse);
      expect(BlurHashDecoder.isValid('${sampleBlurHash}0'), isFalse);
    });
  });

  group('BlurHashDecoder BMP Synthesis', () {
    test('synthesizes valid 32-bit top-down BMP bytes with 54-byte header', () {
      const width = 32;
      const height = 32;
      final bmp = BlurHashDecoder.decodeToBmp(
        sampleBlurHash,
        width: width,
        height: height,
      );

      expect(bmp, isNotNull);
      final bytes = bmp!;
      const expectedFileSize = 54 + width * height * 4;
      expect(bytes.length, equals(expectedFileSize));

      // BITMAPFILEHEADER (14 bytes)
      expect(bytes[0], equals(0x42)); // 'B'
      expect(bytes[1], equals(0x4D)); // 'M'
      final byteData = ByteData.sublistView(bytes);
      expect(byteData.getUint32(2, Endian.little), equals(expectedFileSize));
      expect(byteData.getUint32(6, Endian.little), equals(0));
      expect(
        byteData.getUint32(10, Endian.little),
        equals(54),
      ); // Pixel array offset

      // BITMAPINFOHEADER (40 bytes)
      expect(byteData.getUint32(14, Endian.little), equals(40)); // Header size
      expect(byteData.getInt32(18, Endian.little), equals(width));
      expect(
        byteData.getInt32(22, Endian.little),
        equals(-height),
      ); // Negative height for top-down
      expect(byteData.getUint16(26, Endian.little), equals(1)); // Planes
      expect(
        byteData.getUint16(28, Endian.little),
        equals(32),
      ); // 32 bits per pixel
      expect(
        byteData.getUint32(30, Endian.little),
        equals(0),
      ); // BI_RGB (uncompressed)
      expect(byteData.getUint32(34, Endian.little), equals(width * height * 4));

      // Check pixel data alpha channel is 255
      for (int i = 54; i < bytes.length; i += 4) {
        expect(bytes[i + 3], equals(255)); // Alpha
      }
    });

    test('decodes RGBA bytes correctly', () {
      const width = 16;
      const height = 16;
      final rgba = BlurHashDecoder.decodeRgba(
        sampleBlurHash,
        width: width,
        height: height,
      );
      expect(rgba, isNotNull);
      expect(rgba!.length, equals(width * height * 4));
      for (int i = 0; i < rgba.length; i += 4) {
        expect(rgba[i + 3], equals(255)); // Alpha
      }
    });

    test('returns null for invalid dimensions or blurhash', () {
      expect(
        BlurHashDecoder.decodeToBmp('invalid', width: 32, height: 32),
        isNull,
      );
      expect(
        BlurHashDecoder.decodeToBmp(sampleBlurHash, width: 0, height: 32),
        isNull,
      );
      expect(
        BlurHashDecoder.decodeToBmp(sampleBlurHash, width: 32, height: -5),
        isNull,
      );
    });
  });

  group('BlurHashDecoder In-Memory LRU Cache', () {
    test('caches decoded BMP and reuses identical buffer', () {
      expect(BlurHashDecoder.cacheSize, equals(0));

      final first = BlurHashDecoder.decodeToBmp(sampleBlurHash);
      expect(first, isNotNull);
      expect(BlurHashDecoder.cacheSize, equals(1));

      final second = BlurHashDecoder.decodeToBmp(sampleBlurHash);
      expect(identical(first, second), isTrue);
      expect(BlurHashDecoder.cacheSize, equals(1));
    });

    test('evicts oldest entries when cache exceeds capacity', () {
      // Decode 505 unique items
      for (int i = 0; i < 505; i++) {
        // Vary punch or dimensions to produce distinct cache keys
        BlurHashDecoder.decodeToBmp(sampleBlurHash, punch: 1.0 + (i * 0.001));
      }

      expect(BlurHashDecoder.cacheSize, equals(500));
    });

    test('clearCache resets cache', () {
      BlurHashDecoder.decodeToBmp(sampleBlurHash);
      expect(BlurHashDecoder.cacheSize, equals(1));

      BlurHashDecoder.clearCache();
      expect(BlurHashDecoder.cacheSize, equals(0));
    });
  });

  group('BlurHashWidget', () {
    testWidgets('renders Image.memory when blurhash is valid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlurHashWidget(
              blurhash: sampleBlurHash,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders SizedBox when blurhash is invalid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlurHashWidget(
              blurhash: 'invalid_blurhash',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
