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

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:crowleys_cloud/shared/utils/blurhash_decoder.dart';

void main() {
  group('Cross-Ecosystem BlurHash Mathematical Parity Tests', () {
    test(
      'Empirically verifies identical pixel decoding across Dart and JS implementations',
      () async {
        // Run node verification script to get exact JS decoded pixels
        final result = await Process.run('node', [
          'tool/verify_cross_ecosystem_blurhash.mjs',
        ]);
        expect(
          result.exitCode,
          equals(0),
          reason: 'JS decode script failed: ${result.stderr}',
        );

        final Map<String, dynamic> jsResults =
            jsonDecode(result.stdout as String) as Map<String, dynamic>;

        final testVectors = [
          {'name': 'Solid Black', 'hash': r'L00000fQfQfQfQfQfQfQfQfQfQfQ'},
          {'name': 'Solid White', 'hash': r'L~TSUA~qfQ~q~q%MfQ%MfQfQfQfQ'},
          {'name': 'Pure Red', 'hash': r'L~TI:j|cfQ|c|c$5fQ$5fQfQfQfQ'},
          {'name': 'Pure Blue', 'hash': r'L~0036fZfQfZfZfVfQfVfQfQfQfQ'},
          {'name': 'Sunset Flower', 'hash': r'LEHV6nWB2yk8pyo0adR*.7kCMdnj'},
          {
            'name': 'Encrypted Photo Hash',
            'hash': r'LeHVA2B92F]Ti6a|a|jtdLfQfQfQ',
          },
        ];

        for (final vec in testVectors) {
          final name = vec['name']!;
          final hash = vec['hash']!;
          final jsData = jsResults[name] as Map<String, dynamic>;
          final jsBytes = (jsData['allBytes'] as List).cast<int>();

          final dartRgba = BlurHashDecoder.decodeRgba(
            hash,
            width: 32,
            height: 32,
          );
          expect(dartRgba, isNotNull, reason: 'Dart decoding failed for $name');
          expect(
            dartRgba!.length,
            equals(jsBytes.length),
            reason: 'Buffer length mismatch for $name',
          );

          // Check each of the 4096 bytes (32x32x4)
          int maxDiff = 0;
          for (int i = 0; i < dartRgba.length; i++) {
            final diff = (dartRgba[i] - jsBytes[i]).abs();
            if (diff > maxDiff) maxDiff = diff;
          }

          // Mathematical parity: must match within +/- 1 unit due to floating point roundings
          expect(
            maxDiff <= 1,
            isTrue,
            reason:
                '$name has max pixel difference of $maxDiff (> 1) between Dart and JS',
          );

          // Solid black and white should match with exactly 0 diff
          if (name == 'Solid Black' || name == 'Solid White') {
            expect(
              maxDiff,
              equals(0),
              reason: '$name must have 0 diff between Dart and JS',
            );
          }
        }
      },
    );

    test(
      'Empirically verifies BMP output matches RGBA output byte-for-byte in BGRA channel order',
      () {
        const hash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
        final rgba = BlurHashDecoder.decodeRgba(hash, width: 16, height: 16)!;
        final bmp = BlurHashDecoder.decodeToBmp(hash, width: 16, height: 16)!;

        expect(bmp.length, equals(54 + 16 * 16 * 4));

        for (int i = 0; i < 16 * 16; i++) {
          final rRgba = rgba[i * 4];
          final gRgba = rgba[i * 4 + 1];
          final bRgba = rgba[i * 4 + 2];
          final aRgba = rgba[i * 4 + 3];

          final bBmp = bmp[54 + i * 4];
          final gBmp = bmp[54 + i * 4 + 1];
          final rBmp = bmp[54 + i * 4 + 2];
          final aBmp = bmp[54 + i * 4 + 3];

          expect(rBmp, equals(rRgba));
          expect(gBmp, equals(gRgba));
          expect(bBmp, equals(bRgba));
          expect(aBmp, equals(aRgba));
        }
      },
    );
  });
}
