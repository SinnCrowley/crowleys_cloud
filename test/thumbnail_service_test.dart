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

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail_plus/video_thumbnail_plus.dart';
import 'package:video_thumbnail_plus/video_thumbnail_plus_platform_interface.dart';
import 'package:crowleys_cloud/thumbnail_service.dart';

class MockVideoThumbnailPlusPlatform extends VideoThumbnailPlusPlatform {
  Uint8List? mockBytes;
  Duration? delay;
  bool shouldThrow = false;
  int callCount = 0;

  @override
  Future<Uint8List?> thumbnailData({
    required String video,
    Map<String, String>? headers,
    ImageFormat imageFormat = ImageFormat.PNG,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 100,
  }) async {
    callCount++;
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (shouldThrow) {
      throw PlatformException(code: 'DECODE_ERROR', message: 'Codec failure');
    }
    return mockBytes;
  }

  @override
  Future<String?> thumbnailFile({
    required String video,
    Map<String, String>? headers,
    String? thumbnailPath,
    ImageFormat imageFormat = ImageFormat.PNG,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 100,
  }) async => null;
}

Uint8List createTestPng(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, 100, 50));
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List createTestWebP(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(100, 150, 200));
  return img.encodeWebP(image, lossless: false, quality: 80);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoThumbnailPlusPlatform originalPlatform;
  late MockVideoThumbnailPlusPlatform mockPlatform;
  late Directory tempDir;
  late File sampleVideoFile;

  setUp(() async {
    originalPlatform = VideoThumbnailPlusPlatform.instance;
    mockPlatform = MockVideoThumbnailPlusPlatform();
    VideoThumbnailPlusPlatform.instance = mockPlatform;

    tempDir = await Directory.systemTemp.createTemp('thumb_service_test');
    sampleVideoFile = File('${tempDir.path}/test_video.mp4');
    await sampleVideoFile.writeAsString('video data');
  });

  tearDown(() async {
    VideoThumbnailPlusPlatform.instance = originalPlatform;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ThumbnailService.extractVideoPoster', () {
    group('WebP Encoding & Magic Bytes', () {
      test('outputs valid WebP with RIFF, WEBP, and VP8 headers', () async {
        mockPlatform.mockBytes = createTestPng(640, 480);

        final result = await ThumbnailService.instance.extractVideoPoster(
          sampleVideoFile.path,
        );

        expect(result, isNotNull);
        final bytes = result!;
        expect(bytes.length, greaterThanOrEqualTo(16));

        // Byte 0-3: RIFF (0x52, 0x49, 0x46, 0x46)
        expect(String.fromCharCodes(bytes.sublist(0, 4)), equals('RIFF'));
        // Byte 8-11: WEBP (0x57, 0x45, 0x42, 0x50)
        expect(String.fromCharCodes(bytes.sublist(8, 12)), equals('WEBP'));
        // Byte 12-15: VP8 / VP8L chunk
        final chunkHeader = String.fromCharCodes(bytes.sublist(12, 15));
        expect(chunkHeader.startsWith('VP8'), isTrue);

        // Verify valid image decoding
        final decoded = img.decodeImage(bytes);
        expect(decoded, isNotNull);
      });

      test(
        'converts iOS PNG platform fallback bytes into valid WebP container',
        () async {
          mockPlatform.mockBytes = createTestPng(400, 300);

          final result = await ThumbnailService.instance.extractVideoPoster(
            sampleVideoFile.path,
          );

          expect(result, isNotNull);
          // Verify format is WebP, NOT PNG
          expect(String.fromCharCodes(result!.sublist(0, 4)), equals('RIFF'));
          expect(String.fromCharCodes(result.sublist(8, 12)), equals('WEBP'));
        },
      );

      test(
        'passes through Android native lossy WebP within dimension budget directly',
        () async {
          final nativeWebP = createTestWebP(400, 300);
          mockPlatform.mockBytes = nativeWebP;

          final result = await ThumbnailService.instance.extractVideoPoster(
            sampleVideoFile.path,
          );

          expect(result, isNotNull);
          expect(result, equals(nativeWebP));
        },
      );
    });

    group('Dimension Clamping (<= 512px)', () {
      test(
        'clamps landscape image exceeding 512px to 512 width maintaining aspect ratio',
        () async {
          mockPlatform.mockBytes = createTestPng(1920, 1080);

          final result = await ThumbnailService.instance.extractVideoPoster(
            sampleVideoFile.path,
          );

          expect(result, isNotNull);
          final decoded = img.decodeImage(result!)!;
          expect(decoded.width, equals(512));
          expect(decoded.height, equals((1080 * 512 / 1920).round())); // 288
        },
      );

      test(
        'clamps portrait image exceeding 512px to 512 height maintaining aspect ratio',
        () async {
          mockPlatform.mockBytes = createTestPng(1080, 1920);

          final result = await ThumbnailService.instance.extractVideoPoster(
            sampleVideoFile.path,
          );

          expect(result, isNotNull);
          final decoded = img.decodeImage(result!)!;
          expect(decoded.height, equals(512));
          expect(decoded.width, equals((1080 * 512 / 1920).round())); // 288
        },
      );

      test(
        'preserves dimensions when image is smaller than 512px without upscaling',
        () async {
          mockPlatform.mockBytes = createTestPng(320, 240);

          final result = await ThumbnailService.instance.extractVideoPoster(
            sampleVideoFile.path,
          );

          expect(result, isNotNull);
          final decoded = img.decodeImage(result!)!;
          expect(decoded.width, equals(320));
          expect(decoded.height, equals(240));
        },
      );

      test('clamps square image 800x800 to exactly 512x512', () async {
        mockPlatform.mockBytes = createTestPng(800, 800);

        final result = await ThumbnailService.instance.extractVideoPoster(
          sampleVideoFile.path,
        );

        expect(result, isNotNull);
        final decoded = img.decodeImage(result!)!;
        expect(decoded.width, equals(512));
        expect(decoded.height, equals(512));
      });

      test('clamps oversized WebP to <= 512px', () async {
        mockPlatform.mockBytes = createTestWebP(1280, 720);

        final result = await ThumbnailService.instance.extractVideoPoster(
          sampleVideoFile.path,
        );

        expect(result, isNotNull);
        final decoded = img.decodeImage(result!)!;
        expect(decoded.width, equals(512));
        expect(decoded.height, equals((720 * 512 / 1280).round())); // 288
      });
    });

    group('Error Resilience & Timeouts', () {
      test('returns null when file is not a video extension', () async {
        final textFile = File('${tempDir.path}/notes.txt');
        await textFile.writeAsString('not a video');

        final result = await ThumbnailService.instance.extractVideoPoster(
          textFile.path,
        );

        expect(result, isNull);
        expect(mockPlatform.callCount, equals(0));
      });

      test('returns null when video file does not exist on disk', () async {
        final result = await ThumbnailService.instance.extractVideoPoster(
          '${tempDir.path}/non_existent.mp4',
        );

        expect(result, isNull);
        expect(mockPlatform.callCount, equals(0));
      });

      test('returns null when platform channel returns null', () async {
        mockPlatform.mockBytes = null;

        final result = await ThumbnailService.instance.extractVideoPoster(
          sampleVideoFile.path,
        );

        expect(result, isNull);
      });

      test(
        'returns null gracefully when platform channel throws PlatformException',
        () async {
          mockPlatform.shouldThrow = true;

          final result = await ThumbnailService.instance.extractVideoPoster(
            sampleVideoFile.path,
          );

          expect(result, isNull);
        },
      );

      test(
        'returns null when platform returns corrupted or unparseable bytes',
        () async {
          mockPlatform.mockBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

          final result = await ThumbnailService.instance.extractVideoPoster(
            sampleVideoFile.path,
          );

          expect(result, isNull);
        },
      );

      test('returns null when extraction times out', () async {
        mockPlatform.delay = const Duration(milliseconds: 200);

        final result = await ThumbnailService.instance.extractVideoPoster(
          sampleVideoFile.path,
          timeout: const Duration(milliseconds: 50),
        );

        expect(result, isNull);
      });
    });
  });
}
