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

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/shared/utils/blurhash_decoder.dart';
import 'package:crowleys_cloud/shared/utils/scroll_throttler.dart';
import 'package:crowleys_cloud/shared/widgets/remote_thumbnail_widget.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const sampleBlurHash = 'L6Pj0^jE.AyE_3t7t7R**0o#DgR4';
  late Directory tempRoot;
  late Directory supportDir;
  late Directory tempDir;

  // Minimal 1x1 transparent PNG bytes for testing Image.memory
  final samplePngBytes = Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('remote_thumb_test');
    supportDir = Directory(p.join(tempRoot.path, 'support'));
    tempDir = Directory(p.join(tempRoot.path, 'temp'));
    await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);
    BlurHashDecoder.clearCache();
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('RemoteThumbnailWidget', () {
    testWidgets(
      'renders BlurHash placeholder immediately on initial frame when blurhash is valid',
      (tester) async {
        final completer = Completer<Uint8List?>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RemoteThumbnailWidget(
                thumbnailLoader: () => completer.future,
                fallbackBuilder: (ctx, size) =>
                    const Icon(Icons.image_not_supported),
                isList: false,
                blurhash: sampleBlurHash,
              ),
            ),
          ),
        );

        // On initial pump before completer resolves, BlurHashWidget should be visible
        expect(find.byType(BlurHashWidget), findsOneWidget);
        expect(find.byType(Image), findsOneWidget); // BlurHash BMP image
        expect(find.byIcon(Icons.image_not_supported), findsNothing);

        // Now complete the future and settle
        completer.complete(samplePngBytes);
        await tester.pumpAndSettle();

        // Now loaded image is shown
        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets(
      'falls back to fallbackBuilder when blurhash is null or invalid',
      (tester) async {
        final completer = Completer<Uint8List?>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RemoteThumbnailWidget(
                thumbnailLoader: () => completer.future,
                fallbackBuilder: (ctx, size) => const Icon(Icons.broken_image),
                isList: false,
                blurhash: null,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.broken_image), findsOneWidget);
        expect(find.byType(BlurHashWidget), findsNothing);

        completer.complete(samplePngBytes);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.broken_image), findsNothing);
        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets('instant RAM cache hit renders loaded image on first frame', (
      tester,
    ) async {
      const cacheKey = 'cached_thumb_key';
      CacheService.instance.putMemoryThumbnail(cacheKey, samplePngBytes);

      var loaderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteThumbnailWidget(
              thumbnailLoader: () async {
                loaderCalled = true;
                return samplePngBytes;
              },
              fallbackBuilder: (ctx, size) =>
                  const Icon(Icons.image_not_supported),
              isList: false,
              cacheKey: cacheKey,
              blurhash: sampleBlurHash,
            ),
          ),
        ),
      );

      // Rendered immediately from RAM
      expect(find.byType(Image), findsOneWidget);
      expect(loaderCalled, isFalse);
    });

    testWidgets(
      'defers loading during fast fling and starts when scroll settles',
      (tester) async {
        final fastNotifier = ValueNotifier<bool>(true);
        var loaderCalls = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScrollThrottlerScope(
                notifier: fastNotifier,
                child: RemoteThumbnailWidget(
                  thumbnailLoader: () async {
                    loaderCalls++;
                    return samplePngBytes;
                  },
                  fallbackBuilder: (ctx, size) =>
                      const Icon(Icons.image_not_supported),
                  isList: false,
                  blurhash: sampleBlurHash,
                ),
              ),
            ),
          ),
        );

        // Fast scrolling is active -> loader should NOT be called
        await tester.pump(const Duration(milliseconds: 100));
        expect(loaderCalls, equals(0));
        expect(find.byType(BlurHashWidget), findsOneWidget);

        // Scroll settles
        fastNotifier.value = false;
        await tester.pump();
        await tester.pumpAndSettle();

        expect(loaderCalls, equals(1));
        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets('cancels pending debounce timer when unmounted before firing', (
      tester,
    ) async {
      var loaderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteThumbnailWidget(
              thumbnailLoader: () async {
                loaderCalled = true;
                return samplePngBytes;
              },
              fallbackBuilder: (ctx, size) =>
                  const Icon(Icons.image_not_supported),
              isList: false,
              blurhash: sampleBlurHash,
              debounceDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Unmount before 100ms debounce completes
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(loaderCalled, isFalse);
    });
  });
}
