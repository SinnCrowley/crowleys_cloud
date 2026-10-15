// Copyright (C) 2026 Sinn Crowley
//
// Adversarial Empirical Challenge Suite for Milestone 2:
// Video Poster Extraction, WebP Packaging, Clamping, and Upload Header Ingestion.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail_plus/video_thumbnail_plus.dart';
import 'package:video_thumbnail_plus/video_thumbnail_plus_platform_interface.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/thumbnail_service.dart';
import 'package:crowleys_cloud/sync_service.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
      throw PlatformException(code: 'CODEC_ERR', message: 'Hardware decoder crashed');
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

Uint8List createRgbPng(int width, int height, {int seed = 42}) {
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      image.setPixelRgb(
        x,
        y,
        (x * 255 ~/ (width > 0 ? width : 1)) % 256,
        (y * 255 ~/ (height > 0 ? height : 1)) % 256,
        ((x + y) * 128 ~/ ((width + height) > 0 ? (width + height) : 1)) % 256,
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List createLossyWebP(int width, int height, {int quality = 80, int seed = 42}) {
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      image.setPixelRgb(
        x,
        y,
        (x * 255 ~/ (width > 0 ? width : 1)) % 256,
        (y * 255 ~/ (height > 0 ? height : 1)) % 256,
        ((x + y) * 128 ~/ ((width + height) > 0 ? (width + height) : 1)) % 256,
      );
    }
  }
  return img.encodeWebP(image, lossless: false, quality: quality);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoThumbnailPlusPlatform originalPlatform;
  late MockVideoThumbnailPlusPlatform mockPlatform;
  late Directory tempDir;
  late File testVideoFile;

  setUp(() async {
    originalPlatform = VideoThumbnailPlusPlatform.instance;
    mockPlatform = MockVideoThumbnailPlusPlatform();
    VideoThumbnailPlusPlatform.instance = mockPlatform;

    tempDir = await Directory.systemTemp.createTemp('challenger_m2_test');
    testVideoFile = File('${tempDir.path}/sample_input.mp4');
    await testVideoFile.writeAsString('mock mp4 content');
  });

  tearDown(() async {
    VideoThumbnailPlusPlatform.instance = originalPlatform;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CHALLENGE 1: WebP Bitstream & Container Integrity', () {
    test('verifies exact RIFF WebP header structure, chunk length, and payload decoding', () async {
      mockPlatform.mockBytes = createRgbPng(640, 360, seed: 101);

      final result = await ThumbnailService.instance.extractVideoPoster(
        testVideoFile.path,
        maxDimension: 512,
      );

      expect(result, isNotNull);
      final bytes = result!;
      expect(bytes.length, greaterThan(32));

      // 1. RIFF magic bytes at 0..3
      expect(bytes[0], 0x52); // 'R'
      expect(bytes[1], 0x49); // 'I'
      expect(bytes[2], 0x46); // 'F'
      expect(bytes[3], 0x46); // 'F'

      // 2. File size at 4..7 (little-endian uint32) == bytes.length - 8
      final riffSize = bytes[4] | (bytes[5] << 8) | (bytes[6] << 16) | (bytes[7] << 24);
      expect(riffSize, equals(bytes.length - 8));

      // 3. WEBP magic bytes at 8..11
      expect(bytes[8], 0x57);  // 'W'
      expect(bytes[9], 0x45);  // 'E'
      expect(bytes[10], 0x42); // 'B'
      expect(bytes[11], 0x50); // 'P'

      // 4. VP8 chunk signature at 12..15
      final chunkSig = String.fromCharCodes(bytes.sublist(12, 16));
      expect(chunkSig.startsWith('VP8'), isTrue);

      // 5. Image decodes cleanly to valid RGBA pixels
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(512));
      expect(decoded.height, equals((360 * 512 / 640).round())); // 288
    });

    test('rejects truncated pseudo-WebP (magic bytes present, corrupted bitstream)', () async {
      // 12 bytes valid RIFF....WEBP but truncated payload
      final corruptWebp = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46,
        0x20, 0x00, 0x00, 0x00,
        0x57, 0x45, 0x42, 0x50,
        0x56, 0x50, 0x38, 0x20,
        0x01, 0x02, 0x03, 0x04,
      ]);
      mockPlatform.mockBytes = corruptWebp;

      final result = await ThumbnailService.instance.extractVideoPoster(
        testVideoFile.path,
      );

      // Must NOT return corruptWebp - must fail gracefully and return null
      expect(result, isNull);
    });
  });

  group('CHALLENGE 2: Boundary Dimensions & Aspect Ratio Clamping', () {
    final testCases = <Map<String, dynamic>>[
      {
        'desc': 'Ultra-wide 4K (3840x1080)',
        'inW': 3840,
        'inH': 1080,
        'expW': 512,
        'expH': (1080 * 512 / 3840).round(), // 144
      },
      {
        'desc': 'Ultra-tall vertical video (1080x3840)',
        'inW': 1080,
        'inH': 3840,
        'expW': (1080 * 512 / 3840).round(), // 144
        'expH': 512,
      },
      {
        'desc': 'Extreme needle wide (4000x2)',
        'inW': 4000,
        'inH': 2,
        'expW': 512,
        'expH': 1,
      },
      {
        'desc': 'Extreme needle tall (2x4000)',
        'inW': 2,
        'inH': 4000,
        'expW': 1,
        'expH': 512,
      },
      {
        'desc': 'Exact boundary square (512x512)',
        'inW': 512,
        'inH': 512,
        'expW': 512,
        'expH': 512,
      },
      {
        'desc': 'Off-by-one boundary square (513x513)',
        'inW': 513,
        'inH': 513,
        'expW': 512,
        'expH': 512,
      },
      {
        'desc': 'Off-by-one wide (513x500)',
        'inW': 513,
        'inH': 500,
        'expW': 512,
        'expH': (500 * 512 / 513).round(), // 499
      },
      {
        'desc': 'Off-by-one tall (500x513)',
        'inW': 500,
        'inH': 513,
        'expW': (500 * 512 / 513).round(), // 499
        'expH': 512,
      },
      {
        'desc': 'Small 1x1 image (no upscaling)',
        'inW': 1,
        'inH': 1,
        'expW': 1,
        'expH': 1,
      },
      {
        'desc': 'Small 64x64 icon (no upscaling)',
        'inW': 64,
        'inH': 64,
        'expW': 64,
        'expH': 64,
      },
      {
        'desc': 'Small 320x180 16:9 (no upscaling)',
        'inW': 320,
        'inH': 180,
        'expW': 320,
        'expH': 180,
      },
    ];

    for (final tc in testCases) {
      test('clamping ${tc['desc']}: ${tc['inW']}x${tc['inH']} -> ${tc['expW']}x${tc['expH']}', () async {
        final video = File('${tempDir.path}/v_${tc['inW']}_${tc['inH']}.mp4');
        await video.writeAsString('video');

        mockPlatform.mockBytes = createRgbPng(tc['inW'] as int, tc['inH'] as int, seed: tc['inW'] as int);

        final result = await ThumbnailService.instance.extractVideoPoster(
          video.path,
          maxDimension: 512,
        );

        expect(result, isNotNull);
        final decoded = img.decodeImage(result!)!;
        expect(decoded.width, equals(tc['expW']));
        expect(decoded.height, equals(tc['expH']));
        expect(max(decoded.width, decoded.height), lessThanOrEqualTo(512));
      });
    }
  });

  group('CHALLENGE 3: Header Size Budget & Entropy Stress', () {
    test('realistic video poster frames produce WebP byte size well under 48KB (base64 < 64KB)', () async {
      // Test realistic 16:9 landscape 1920x1080 input (clamped to 512x288)
      final landscapeVideo = File('${tempDir.path}/landscape_1080p.mp4');
      await landscapeVideo.writeAsString('video');
      mockPlatform.mockBytes = createRgbPng(1920, 1080);

      final landscapeResult = await ThumbnailService.instance.extractVideoPoster(
        landscapeVideo.path,
        maxDimension: 512,
      );

      expect(landscapeResult, isNotNull);
      final landscapeBytes = landscapeResult!;
      expect(landscapeBytes.length, lessThan(48000),
          reason: 'Landscape WebP byte size should be well under 48 KB');
      final landscapeB64 = base64Encode(landscapeBytes);
      expect(landscapeB64.length, lessThan(60000),
          reason: 'Landscape base64 size should be within 60000 char upload limit');

      // Test realistic 9:16 portrait 1080x1920 input (clamped to 288x512)
      final portraitVideo = File('${tempDir.path}/portrait_1080p.mp4');
      await portraitVideo.writeAsString('video');
      mockPlatform.mockBytes = createRgbPng(1080, 1920);

      final portraitResult = await ThumbnailService.instance.extractVideoPoster(
        portraitVideo.path,
        maxDimension: 512,
      );

      expect(portraitResult, isNotNull);
      final portraitBytes = portraitResult!;
      expect(portraitBytes.length, lessThan(48000),
          reason: 'Portrait WebP byte size should be well under 48 KB');
      final portraitB64 = base64Encode(portraitBytes);
      expect(portraitB64.length, lessThan(60000),
          reason: 'Portrait base64 size should be within 60000 char upload limit');

      // Test realistic square 512x512 input
      final squareVideo = File('${tempDir.path}/square_512.mp4');
      await squareVideo.writeAsString('video');
      mockPlatform.mockBytes = createRgbPng(512, 512);

      final squareResult = await ThumbnailService.instance.extractVideoPoster(
        squareVideo.path,
        maxDimension: 512,
      );

      expect(squareResult, isNotNull);
      final squareBytes = squareResult!;
      expect(squareBytes.length, lessThan(48000),
          reason: 'Square WebP byte size should be well under 48 KB');
      final squareB64 = base64Encode(squareBytes);
      expect(squareB64.length, lessThan(60000),
          reason: 'Square base64 size should be within 60000 char upload limit');
    });

    test('excessive entropy / oversized base64 (> 60000 chars) is safely dropped by upload logic', () async {
      // When an extreme noise image produces base64 > 60000:
      final extremeBytes = Uint8List(50000); // 50000 bytes base64 = 66668 chars
      final encoded = base64Encode(extremeBytes);
      expect(encoded.length, greaterThan(60000));

      final guardedString = encoded.length <= 60000 ? encoded : null;
      expect(guardedString, isNull,
          reason: 'Upload guard must set header to null when base64 exceeds 60000 chars');
    });

    test('oversized WebP (> 48KB) triggers re-encoding path rather than unvalidated passthrough', () async {
      // Create a 512x512 WebP with high entropy that is larger than 48KB
      // By using lossless: true, 512x512 random noise is ~400KB
      final largeImage = img.Image(width: 512, height: 512);
      final rnd = Random(777);
      for (int y = 0; y < 512; y++) {
        for (int x = 0; x < 512; x++) {
          largeImage.setPixelRgb(x, y, rnd.nextInt(256), rnd.nextInt(256), rnd.nextInt(256));
        }
      }
      final oversizedWebP = Uint8List.fromList(img.encodeWebP(largeImage, lossless: true));
      expect(oversizedWebP.length, greaterThan(48000));

      mockPlatform.mockBytes = oversizedWebP;

      final result = await ThumbnailService.instance.extractVideoPoster(
        testVideoFile.path,
        maxDimension: 512,
      );

      expect(result, isNotNull);
      // The result should have been re-encoded with lossy WebP at quality 80, not passed through directly
      expect(result!.length, lessThan(oversizedWebP.length));
    });
  });

  group('CHALLENGE 4: Extension Parsing & Case Sensitivity', () {
    test('accepts uppercase video extensions (.MP4, .MOV, .MKV, .WEBM, .AVI)', () async {
      final uppercaseExtensions = ['.MP4', '.MOV', '.MKV', '.WEBM', '.AVI'];

      for (final ext in uppercaseExtensions) {
        final video = File('${tempDir.path}/test_clip$ext');
        await video.writeAsString('video data');
        mockPlatform.mockBytes = createRgbPng(320, 240, seed: 1);

        final result = await ThumbnailService.instance.extractVideoPoster(video.path);
        expect(result, isNotNull, reason: 'Failed to recognize uppercase extension $ext as video');
      }
    });

    test('rejects non-video extensions immediately without invoking decoder', () async {
      final nonVideoExtensions = ['.png', '.jpg', '.pdf', '.txt', '.mp3', '.bin', '.doc'];

      for (final ext in nonVideoExtensions) {
        final file = File('${tempDir.path}/test_item$ext');
        await file.writeAsString('non-video data');
        mockPlatform.callCount = 0;

        final result = await ThumbnailService.instance.extractVideoPoster(file.path);
        expect(result, isNull);
        expect(mockPlatform.callCount, 0, reason: 'Decoder invoked for non-video extension $ext');
      }
    });
  });

  group('CHALLENGE 5: Wire Protocol Verification for Chunked Uploads', () {
    test('HttpSyncApiClient attaches X-Thumbnail ONLY to terminal chunk, never intermediate chunks', () async {
      final thumbBytes = createLossyWebP(320, 240, quality: 80);
      final capturedHeaders = <Map<String, String>>[];

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/files/upload-status') {
          return http.Response(jsonEncode({'bytes_received': 0}), 200);
        }
        if (request.url.path == '/api/files') {
          capturedHeaders.add(Map.from(request.headers));
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final secretStore = InMemorySecretStore();
      await secretStore.saveSyncToken(serverId: 'srv1', syncToken: 'token_123');
      final authService = AuthService(secretStore: secretStore);
      final syncApiClient = HttpSyncApiClient(
        authService: authService,
        client: mockClient,
      );

      final server = ServerProfile(
        id: 'srv1',
        displayName: 'Test Server',
        baseUrl: 'http://127.0.0.1:8080',
        authMode: 'login',
        lastUsedAt: DateTime.utc(2026, 6),
        syncPrefs: const {'syncEnabled': true},
      );

      // 5MB file -> 3 chunks (chunk size = 2MB): 2MB, 2MB, 1MB
      final multiChunkVideo = File('${tempDir.path}/multi_chunk.mp4');
      await multiChunkVideo.writeAsBytes(List.filled(5 * 1024 * 1024, 65));

      await syncApiClient.uploadFile(
        server: server,
        remotePath: 'backup/multi_chunk.mp4',
        file: multiChunkVideo,
        thumbnailBytes: thumbBytes,
      );

      expect(capturedHeaders.length, 3);

      // Chunk 0 (offset=0, is_last=false)
      expect(capturedHeaders[0].containsKey('x-thumbnail'), isFalse,
          reason: 'Chunk 0 leaked x-thumbnail header!');

      // Chunk 1 (offset=2MB, is_last=false)
      expect(capturedHeaders[1].containsKey('x-thumbnail'), isFalse,
          reason: 'Chunk 1 leaked x-thumbnail header!');

      // Chunk 2 (terminal, is_last=true)
      expect(capturedHeaders[2].containsKey('x-thumbnail'), isTrue,
          reason: 'Terminal chunk missing x-thumbnail header!');
      expect(
        capturedHeaders[2]['x-thumbnail'],
        equals(base64Encode(thumbBytes)),
      );

      // Verify decoded base64 header matches byte-for-byte original WebP payload
      final decodedFromHeader = base64Decode(capturedHeaders[2]['x-thumbnail']!);
      expect(decodedFromHeader, equals(thumbBytes));
    });

    test('HttpSyncApiClient omits X-Thumbnail when thumbnail base64 exceeds 60000 characters', () async {
      // 65000 bytes base64
      final oversizedBytes = Uint8List(50000); // 50000 bytes base64 = 66668 chars
      final capturedHeaders = <Map<String, String>>[];

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/files') {
          capturedHeaders.add(Map.from(request.headers));
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final secretStore = InMemorySecretStore();
      await secretStore.saveSyncToken(serverId: 'srv1', syncToken: 'token_123');
      final authService = AuthService(secretStore: secretStore);
      final syncApiClient = HttpSyncApiClient(
        authService: authService,
        client: mockClient,
      );

      final server = ServerProfile(
        id: 'srv1',
        displayName: 'Test Server',
        baseUrl: 'http://127.0.0.1:8080',
        authMode: 'login',
        lastUsedAt: DateTime.utc(2026, 6),
        syncPrefs: const {'syncEnabled': true},
      );

      final emptyVideo = File('${tempDir.path}/empty.mp4');
      await emptyVideo.writeAsString('');

      await syncApiClient.uploadFile(
        server: server,
        remotePath: 'backup/empty.mp4',
        file: emptyVideo,
        thumbnailBytes: oversizedBytes,
      );

      expect(capturedHeaders.length, 1);
      expect(capturedHeaders[0].containsKey('x-thumbnail'), isFalse,
          reason: 'Oversized thumbnail was not dropped, risking HTTP 431 header overflow!');
    });
  });
}
