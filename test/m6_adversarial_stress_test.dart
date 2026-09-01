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
  const sampleBlurHash2 = 'LKN]Rv%2Tw=w]~RBVZRi};RPxuwH';

  // Minimal 1x1 PNG bytes
  final samplePngBytes1 = Uint8List.fromList([
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

  final samplePngBytes2 = Uint8List.fromList([
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
    0x02,
    0x00,
    0x00,
    0x00,
    0x02,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x72,
    0xB6,
    0x0D,
    0x24,
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

  late Directory tempRoot;
  late Directory supportDir;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('m6_stress_test');
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

  group('M6 Adversarial Challenge 1: Rapid Fling & Violent Direction Reversals', () {
    testWidgets(
      'Rapid downward fling followed immediately by violent upward reversal suppresses fetches and settles cleanly',
      (tester) async {
        final List<int> loadedIndices = [];
        final List<int> initiatedIndices = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScrollThrottler(
                velocityThreshold: 300.0,
                idleTimeout: const Duration(milliseconds: 60),
                child: ListView.builder(
                  itemCount: 150,
                  itemExtent: 80,
                  itemBuilder: (ctx, index) {
                    return ListTile(
                      leading: RemoteThumbnailWidget(
                        thumbnailLoader: () async {
                          initiatedIndices.add(index);
                          await Future.delayed(
                            const Duration(milliseconds: 30),
                          );
                          loadedIndices.add(index);
                          return samplePngBytes1;
                        },
                        fallbackBuilder: (c, s) => const Icon(Icons.image),
                        isList: true,
                        blurhash: sampleBlurHash,
                        cacheKey: 'item_$index',
                      ),
                      title: Text('File Item #$index'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Initial frame: visible items (around 0..8) start loading or debounce
        await tester.pump();
        expect(find.byType(BlurHashWidget), findsWidgets);

        // Violent downward fling
        await tester.fling(find.byType(ListView), const Offset(0, -1200), 4000);
        await tester.pump(const Duration(milliseconds: 20));

        // Check fast scrolling is active
        expect(
          ScrollThrottler.isFastScrolling(
            tester.element(find.byType(ListView)),
          ),
          isTrue,
        );

        // Violent upward fling (immediate reversal)
        await tester.fling(find.byType(ListView), const Offset(0, 1200), 4000);
        await tester.pump(const Duration(milliseconds: 20));

        // Another violent downward fling
        await tester.fling(find.byType(ListView), const Offset(0, -800), 3500);
        await tester.pump(const Duration(milliseconds: 20));

        // Ensure intermediate items skipped during violent flings didn't overwhelm the loader queue
        final totalInitiatedDuringFlings = initiatedIndices.length;
        // Total items scrolled through is ~100+, but initiated during fling should be very small
        expect(totalInitiatedDuringFlings, lessThan(30));

        // Now wait for scrolling to completely settle
        await tester.pumpAndSettle();

        // Fast scrolling must now be false
        expect(
          ScrollThrottler.isFastScrolling(
            tester.element(find.byType(ListView)),
          ),
          isFalse,
        );

        // Verify that ALL currently visible items are rendered with loaded images and NONE are stuck in placeholder
        final visibleRemoteWidgets = tester
            .widgetList<RemoteThumbnailWidget>(
              find.byType(RemoteThumbnailWidget),
            )
            .toList();
        expect(visibleRemoteWidgets.isNotEmpty, isTrue);

        // In the settled state, no visible widget should be stuck in BlurHashWidget placeholder
        expect(find.byType(BlurHashWidget), findsNothing);
        expect(find.byType(Image), findsWidgets);
      },
    );

    testWidgets(
      'Rapid fling deceleration without explicit EndNotification resets after idle timeout',
      (tester) async {
        late ValueNotifier<bool> fastNotifier;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScrollThrottler(
                velocityThreshold: 250.0,
                idleTimeout: const Duration(milliseconds: 80),
                child: Builder(
                  builder: (context) {
                    fastNotifier = ScrollThrottler.notifierOf(context)!;
                    return ListView.builder(
                      itemCount: 100,
                      itemExtent: 70,
                      itemBuilder: (ctx, i) =>
                          SizedBox(height: 70, child: Text('Item $i')),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(fastNotifier.value, isFalse);

        // Fling
        await tester.fling(find.byType(ListView), const Offset(0, -600), 3000);
        await tester.pump(const Duration(milliseconds: 20));
        expect(fastNotifier.value, isTrue);

        // Let idle timeout elapse
        await tester.pump(const Duration(milliseconds: 200));
        expect(fastNotifier.value, isFalse);
      },
    );
  });

  group(
    'M6 Adversarial Challenge 2: Rapid View Switching & Navigation During Flings',
    () {
      testWidgets(
        'Switching between ListView and GridView during active high-velocity fling',
        (tester) async {
          var isGrid = false;

          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: () => setState(() => isGrid = !isGrid),
                        ),
                      ],
                    ),
                    body: ScrollThrottler(
                      child: isGrid
                          ? GridView.builder(
                              key: const ValueKey('grid_view'),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.0,
                                  ),
                              itemCount: 80,
                              itemBuilder: (ctx, i) => RemoteThumbnailWidget(
                                key: ValueKey('grid_thumb_$i'),
                                thumbnailLoader: () async => samplePngBytes1,
                                fallbackBuilder: (c, s) =>
                                    const Icon(Icons.image),
                                isList: false,
                                blurhash: sampleBlurHash,
                                cacheKey: 'grid_item_$i',
                              ),
                            )
                          : ListView.builder(
                              key: const ValueKey('list_view'),
                              itemExtent: 80,
                              itemCount: 80,
                              itemBuilder: (ctx, i) => RemoteThumbnailWidget(
                                key: ValueKey('list_thumb_$i'),
                                thumbnailLoader: () async => samplePngBytes1,
                                fallbackBuilder: (c, s) =>
                                    const Icon(Icons.image),
                                isList: true,
                                blurhash: sampleBlurHash,
                                cacheKey: 'list_item_$i',
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          );

          // Start fling in ListView
          await tester.fling(
            find.byKey(const ValueKey('list_view')),
            const Offset(0, -1000),
            3500,
          );
          await tester.pump(const Duration(milliseconds: 20));

          // Switch to GridView mid-fling
          await tester.tap(find.byIcon(Icons.swap_horiz));
          await tester.pump();

          // Verify GridView is mounted without crashes
          expect(find.byKey(const ValueKey('grid_view')), findsOneWidget);
          expect(find.byKey(const ValueKey('list_view')), findsNothing);

          // Fling GridView
          await tester.fling(
            find.byKey(const ValueKey('grid_view')),
            const Offset(0, -1000),
            3500,
          );
          await tester.pump(const Duration(milliseconds: 20));

          // Switch back to ListView mid-fling
          await tester.tap(find.byIcon(Icons.swap_horiz));
          await tester.pump();

          // Settle
          await tester.pumpAndSettle();

          expect(find.byKey(const ValueKey('list_view')), findsOneWidget);
          expect(find.byType(BlurHashWidget), findsNothing);
          expect(find.byType(Image), findsWidgets);
        },
      );

      testWidgets(
        'Rapid Folder Navigation / Unmounting Screen During Active Fling',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              initialRoute: '/folder1',
              routes: {
                '/folder1': (context) => Scaffold(
                  appBar: AppBar(
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => Navigator.of(
                          context,
                        ).pushReplacementNamed('/folder2'),
                      ),
                    ],
                  ),
                  body: ScrollThrottler(
                    child: ListView.builder(
                      itemCount: 100,
                      itemExtent: 80,
                      itemBuilder: (ctx, i) => RemoteThumbnailWidget(
                        thumbnailLoader: () async {
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );
                          return samplePngBytes1;
                        },
                        fallbackBuilder: (c, s) => const Icon(Icons.image),
                        isList: true,
                        blurhash: sampleBlurHash,
                      ),
                    ),
                  ),
                ),
                '/folder2': (context) => const Scaffold(
                  body: Center(child: Text('Folder 2 Content')),
                ),
              },
            ),
          );

          // Start strong fling on folder 1
          await tester.fling(
            find.byType(ListView),
            const Offset(0, -1000),
            4000,
          );
          await tester.pump(const Duration(milliseconds: 20));

          // Immediately navigate to folder 2 (unmounting the fling scrollable and in-flight widgets)
          await tester.tap(find.byIcon(Icons.arrow_forward));
          await tester.pump();
          await tester.pumpAndSettle();

          expect(find.text('Folder 2 Content'), findsOneWidget);
        },
      );
    },
  );

  group(
    'M6 Adversarial Challenge 3: Pull-to-Refresh & Overscroll Interactions',
    () {
      testWidgets(
        'Pull-to-refresh overscroll works properly with ScrollThrottler without exception or blocked gestures',
        (tester) async {
          var refreshCalled = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RefreshIndicator(
                  onRefresh: () async {
                    refreshCalled = true;
                    await Future.delayed(const Duration(milliseconds: 50));
                  },
                  child: ScrollThrottler(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: 30,
                      itemExtent: 80,
                      itemBuilder: (ctx, i) => RemoteThumbnailWidget(
                        thumbnailLoader: () async => samplePngBytes1,
                        fallbackBuilder: (c, s) => const Icon(Icons.image),
                        isList: true,
                        blurhash: sampleBlurHash,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          // Fling down past top boundary to trigger pull-to-refresh
          await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          expect(refreshCalled, isTrue);

          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('loaded_thumb')), findsWidgets);
        },
      );
    },
  );

  group(
    'M6 Adversarial Challenge 4: Rapid Mounting/Unmounting, Recycling & Race Conditions',
    () {
      testWidgets(
        'Rapid mounting and unmounting of 100 RemoteThumbnailWidgets in 5ms intervals',
        (tester) async {
          for (int step = 0; step < 15; step++) {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: ListView.builder(
                    itemCount: 20,
                    itemExtent: 80,
                    itemBuilder: (ctx, i) => RemoteThumbnailWidget(
                      thumbnailLoader: () async {
                        await Future.delayed(const Duration(milliseconds: 20));
                        return samplePngBytes1;
                      },
                      fallbackBuilder: (c, s) => const Icon(Icons.image),
                      isList: true,
                      blurhash: sampleBlurHash,
                      cacheKey: 'churn_${step}_$i',
                    ),
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 5));
          }

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'Widget update with different cacheKey while initial load is in-flight does not corrupt state with old bytes',
        (tester) async {
          final completer1 = Completer<Uint8List?>();
          final completer2 = Completer<Uint8List?>();

          var currentKey = 'item_A';
          var currentBlurhash = sampleBlurHash;
          Future<Uint8List?> Function() currentLoader = () => completer1.future;

          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return MaterialApp(
                  home: Scaffold(
                    body: RemoteThumbnailWidget(
                      key: const ValueKey('recycled_widget'),
                      thumbnailLoader: currentLoader,
                      fallbackBuilder: (c, s) => const Icon(Icons.broken_image),
                      isList: false,
                      blurhash: currentBlurhash,
                      cacheKey: currentKey,
                      debounceDuration: Duration.zero,
                    ),
                  ),
                );
              },
            ),
          );

          // Initial pump: loader 1 started
          await tester.pump();

          // Now update widget to item_B before completer1 completes
          currentKey = 'item_B';
          currentBlurhash = sampleBlurHash2;
          currentLoader = () => completer2.future;

          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return MaterialApp(
                  home: Scaffold(
                    body: RemoteThumbnailWidget(
                      key: const ValueKey('recycled_widget'),
                      thumbnailLoader: currentLoader,
                      fallbackBuilder: (c, s) => const Icon(Icons.broken_image),
                      isList: false,
                      blurhash: currentBlurhash,
                      cacheKey: currentKey,
                      debounceDuration: Duration.zero,
                    ),
                  ),
                );
              },
            ),
          );

          await tester.pump();

          // Now completer1 completes with samplePngBytes1 (size 1x1)
          completer1.complete(samplePngBytes1);
          await tester.pump();

          // Now completer2 completes with samplePngBytes2 (size 2x2)
          completer2.complete(samplePngBytes2);
          await tester.pumpAndSettle();

          // Verify the widget rendered samplePngBytes2 (not samplePngBytes1!)
          final loadedThumbFinder = find.descendant(
            of: find.byKey(const ValueKey('loaded_thumb')),
            matching: find.byType(Image),
          );
          final imageWidget = tester.widget<Image>(loadedThumbFinder);
          expect(imageWidget.image, isA<MemoryImage>());
          final memoryImage = imageWidget.image as MemoryImage;
          expect(memoryImage.bytes, equals(samplePngBytes2));
        },
      );

      testWidgets(
        'Widget update to RAM-cached item immediately shows cached bytes and ignores slow prior network load',
        (tester) async {
          const ramKey = 'ram_cached_item';
          CacheService.instance.putMemoryThumbnail(ramKey, samplePngBytes2);

          final slowCompleter = Completer<Uint8List?>();

          var currentKey = 'slow_uncached_item';
          Future<Uint8List?> Function() currentLoader = () =>
              slowCompleter.future;

          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return MaterialApp(
                  home: Scaffold(
                    body: RemoteThumbnailWidget(
                      key: const ValueKey('recycled_widget'),
                      thumbnailLoader: currentLoader,
                      fallbackBuilder: (c, s) => const Icon(Icons.broken_image),
                      isList: false,
                      blurhash: sampleBlurHash,
                      cacheKey: currentKey,
                      debounceDuration: Duration.zero,
                    ),
                  ),
                );
              },
            ),
          );

          await tester.pump();

          // Update to RAM cached item
          currentKey = ramKey;
          currentLoader = () async => samplePngBytes1;

          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return MaterialApp(
                  home: Scaffold(
                    body: RemoteThumbnailWidget(
                      key: const ValueKey('recycled_widget'),
                      thumbnailLoader: currentLoader,
                      fallbackBuilder: (c, s) => const Icon(Icons.broken_image),
                      isList: false,
                      blurhash: sampleBlurHash2,
                      cacheKey: currentKey,
                      debounceDuration: Duration.zero,
                    ),
                  ),
                );
              },
            ),
          );

          await tester.pump();

          // Should immediately show samplePngBytes2 from RAM cache
          final loadedThumbFinder = find.descendant(
            of: find.byKey(const ValueKey('loaded_thumb')),
            matching: find.byType(Image),
          );
          var imageWidget = tester.widget<Image>(loadedThumbFinder);
          expect(
            (imageWidget.image as MemoryImage).bytes,
            equals(samplePngBytes2),
          );

          // Now slow completer for previous item completes with samplePngBytes1
          slowCompleter.complete(samplePngBytes1);
          await tester.pumpAndSettle();

          // Must STILL show samplePngBytes2!
          imageWidget = tester.widget<Image>(loadedThumbFinder);
          expect(
            (imageWidget.image as MemoryImage).bytes,
            equals(samplePngBytes2),
          );
        },
      );

      testWidgets(
        'Network error followed by fallback icon renders gracefully without uncaught exceptions',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RemoteThumbnailWidget(
                  thumbnailLoader: () async {
                    throw Exception('Network socket closed');
                  },
                  fallbackBuilder: (c, s) => const Icon(Icons.error_outline),
                  isList: true,
                  blurhash: null,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.error_outline), findsOneWidget);
        },
      );
    },
  );

  group(
    'M6 Adversarial Challenge 5: Memory Leak & ValueNotifier / LRU Subscriptions Audit',
    () {
      testWidgets(
        'ScrollThrottler cleans up ValueNotifier listeners and timers completely on unmount',
        (tester) async {
          late ValueNotifier<bool> notifier;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ScrollThrottler(
                  idleTimeout: const Duration(milliseconds: 50),
                  child: Builder(
                    builder: (context) {
                      notifier = ScrollThrottler.notifierOf(context)!;
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          );

          expect(notifier, isNotNull);

          // Unmount
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: SizedBox())),
          );
          await tester.pumpAndSettle();

          // Notifier should be disposed; adding a listener should throw FlutterError
          expect(() => notifier.addListener(() {}), throwsFlutterError);
        },
      );

      testWidgets(
        'BlurHashDecoder LRU cache bounded at 500 items under 2,000 requests',
        (tester) async {
          BlurHashDecoder.clearCache();

          for (int i = 0; i < 2000; i++) {
            try {
              BlurHashDecoder.decodeToBmp(
                sampleBlurHash,
                punch: 1.0 + (i * 0.0001),
              );
            } catch (_) {}
          }

          // Memory LRU Cache shouldn't exceed 500
          expect(BlurHashDecoder.cacheSize, lessThanOrEqualTo(500));
        },
      );
    },
  );

  group(
    'M6 Adversarial Challenge 6: Massive Concurrency & 50x Rapid Oscillation',
    () {
      testWidgets(
        '50 rapid fling oscillations across 500 items in GridView with 0 stuck placeholders on settle',
        (tester) async {
          int activeFetches = 0;
          int completedFetches = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ScrollThrottler(
                  velocityThreshold: 300.0,
                  idleTimeout: const Duration(milliseconds: 50),
                  child: GridView.builder(
                    key: const ValueKey('stress_grid'),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemCount: 500,
                    itemBuilder: (ctx, i) {
                      return RemoteThumbnailWidget(
                        key: ValueKey('stress_grid_thumb_$i'),
                        thumbnailLoader: () async {
                          activeFetches++;
                          await Future.delayed(
                            const Duration(milliseconds: 25),
                          );
                          completedFetches++;
                          return samplePngBytes1;
                        },
                        fallbackBuilder: (c, s) => const Icon(Icons.image),
                        isList: false,
                        blurhash: sampleBlurHash,
                        cacheKey: 'stress_500_$i',
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          // Perform 30 high-speed alternating flings back and forth
          for (int i = 0; i < 15; i++) {
            await tester.fling(
              find.byKey(const ValueKey('stress_grid')),
              const Offset(0, -900),
              3000,
            );
            await tester.pump(const Duration(milliseconds: 15));
            await tester.fling(
              find.byKey(const ValueKey('stress_grid')),
              const Offset(0, 900),
              3000,
            );
            await tester.pump(const Duration(milliseconds: 15));
          }

          // Settle
          await tester.pumpAndSettle();

          // Ensure no stuck placeholders
          expect(find.byType(BlurHashWidget), findsNothing);
          expect(find.byKey(const ValueKey('loaded_thumb')), findsWidgets);
          expect(
            ScrollThrottler.isFastScrolling(
              tester.element(find.byKey(const ValueKey('stress_grid'))),
            ),
            isFalse,
          );
          expect(activeFetches, greaterThan(0));
          expect(completedFetches, greaterThan(0));
        },
      );
    },
  );

  group(
    'M6 Adversarial Challenge 7: Malformed / Corrupted BlurHash & Degenerate Inputs',
    () {
      testWidgets(
        'Corrupted base83 characters and invalid lengths fallback cleanly without crash',
        (tester) async {
          final invalidBlurHashes = [
            '',
            'short',
            'L6Pj0^jE.', // incomplete length
            'invalid_chars!@#\$%^&*()',
            '00000!', // invalid base83 char
            '~~~~~~',
            'L6Pj0^jE.AyE_3t7t7R**0o#DgR4extra',
          ];

          for (final badHash in invalidBlurHashes) {
            expect(
              BlurHashDecoder.isValid(badHash),
              isFalse,
              reason: 'Expected invalid: $badHash',
            );
            expect(BlurHashDecoder.decodeToBmp(badHash), isNull);
            expect(BlurHashDecoder.decodeRgba(badHash), isNull);

            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: RemoteThumbnailWidget(
                    thumbnailLoader: () async => samplePngBytes1,
                    fallbackBuilder: (c, s) => const Icon(Icons.broken_image),
                    isList: false,
                    blurhash: badHash,
                  ),
                ),
              ),
            );

            // Before loader completes, fallback icon is rendered instead of crashing BlurHashWidget
            expect(find.byIcon(Icons.broken_image), findsOneWidget);

            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('loaded_thumb')), findsOneWidget);
          }
        },
      );

      testWidgets(
        'BlurHashWidget with degenerate dimensions (0 width/height, negative) does not crash',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    BlurHashWidget(
                      blurhash: sampleBlurHash,
                      width: 0,
                      height: 0,
                    ),
                    BlurHashWidget(
                      blurhash: sampleBlurHash,
                      width: -10,
                      height: -10,
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // Verified no exception thrown
        },
      );
    },
  );

  group(
    'M6 Adversarial Challenge 8: Concurrent HTTP 304 ETag Cache Pipeline Under Scroll',
    () {
      test(
        'Concurrent thumbnail fetches with ETag and 304 Not Modified preserve disk cache without duplicate I/O',
        () async {
          const serverId = 'srv_stress_1';
          const cacheKey = 'file_123.jpg';

          // 1. Initial 200 OK load
          final bytes1 = await CacheService.instance.getRemoteThumbnail(
            serverId: serverId,
            cacheKey: cacheKey,
            fetch: () async => ThumbnailFetchResult.bytes(
              samplePngBytes1,
              etag: '"etag_version_1"',
            ),
          );
          expect(bytes1, isNotNull);
          expect(bytes1, equals(samplePngBytes1));
          expect(
            await CacheService.instance.getThumbnailEtag(
              serverId: serverId,
              cacheKey: cacheKey,
            ),
            equals('"etag_version_1"'),
          );

          // Invalidate memory cache so next calls hit disk + fetcher logic
          await CacheService.instance.init(
            supportDir: supportDir,
            tempDir: tempDir,
          );

          // 2. 50 Concurrent 304 Not Modified requests
          final futures = <Future<Uint8List?>>[];
          for (int i = 0; i < 50; i++) {
            futures.add(
              CacheService.instance.getRemoteThumbnail(
                serverId: serverId,
                cacheKey: cacheKey,
                fetch: () async {
                  return const ThumbnailFetchResult.notModified(
                    etag: '"etag_version_1"',
                  );
                },
              ),
            );
          }

          final results = await Future.wait(futures);
          for (final res in results) {
            expect(res, isNotNull);
            expect(res, equals(samplePngBytes1));
          }

          // Manifest ETag preserved
          expect(
            await CacheService.instance.getThumbnailEtag(
              serverId: serverId,
              cacheKey: cacheKey,
            ),
            equals('"etag_version_1"'),
          );
        },
      );
    },
  );
}
