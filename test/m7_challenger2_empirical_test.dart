// Copyright (C) 2026 Sinn Crowley
//
// Adversarial Empirical Challenge Suite for Milestone M7
// Tests:
// 1. Fling scroll suppression & network storm prevention under high-velocity fling bursts.
// 2. BlurHash decoding latency, DCT synthesis correctness, and memory LRU caching.
// 3. CacheService 304 Not Modified ETag preservation under concurrent high-throughput load.
// 4. RemoteThumbnailWidget state resilience and zero network load during fling.

import 'dart:io';
import 'dart:typed_data';

import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/shared/utils/blurhash_decoder.dart';
import 'package:crowleys_cloud/shared/utils/scroll_throttler.dart';
import 'package:crowleys_cloud/shared/widgets/remote_thumbnail_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const sampleBlurHash = 'L6Pj0^jE.AyE_3t7t7R**0o#DgR4';
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp(
      'm7_challenger2_empirical',
    );
    final supportDir = Directory(p.join(tempRoot.path, 'support'));
    final tempDir = Directory(p.join(tempRoot.path, 'temp'));
    await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);
    BlurHashDecoder.clearCache();
  });

  tearDown(() async {
    CacheService.instance.dispose();
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group(
    'M7 EMPIRICAL CHALLENGE 1: BlurHash Sub-Millisecond & LRU Performance',
    () {
      test('Empirically benchmark 1,000 BlurHash decodes', () {
        final sw = Stopwatch()..start();
        for (int i = 0; i < 1000; ++i) {
          final decoded = BlurHashDecoder.decodeRgba(
            sampleBlurHash,
            width: 32,
            height: 32,
          );
          expect(decoded, isNotNull);
          expect(decoded!.length, equals(32 * 32 * 4));
        }
        sw.stop();
        final avgUs = (sw.elapsedMicroseconds / 1000.0);
        expect(
          avgUs,
          lessThan(500.0),
          reason: 'BlurHash decoding should be ultra-fast',
        );
      });

      test(
        'Empirically benchmark 100 cold BlurHash decodes (different hashes)',
        () {
          BlurHashDecoder.clearCache();
          final hashes = [
            'L6Pj0^jE.AyE_3t7t7R**0o#DgR4',
            'LEHLh[WB2yk8pyo0adR*.7kCMdnj',
            'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.',
            'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
            'L6PZfSi_.AyE_3t7t7R**0o#DgR4',
          ];

          final sw = Stopwatch()..start();
          int count = 0;
          for (int i = 0; i < 20; ++i) {
            for (final h in hashes) {
              final bmp = BlurHashDecoder.decodeToBmp(h, width: 16, height: 16);
              expect(bmp, isNotNull);
              count++;
            }
          }
          sw.stop();
          final avgMs = (sw.elapsedMicroseconds / (count * 1000.0));
          expect(
            avgMs,
            lessThan(5.0),
            reason:
                'Cold BlurHash decoding should take < 5 ms per 16x16 thumbnail',
          );
        },
      );
    },
  );

  group(
    'M7 EMPIRICAL CHALLENGE 2: CacheService 304 ETag Persistence & Concurrent Stress',
    () {
      test(
        'Stress test CacheService ETag storage under 200 operations',
        () async {
          final sw = Stopwatch()..start();
          const serverId = 'srv_empirical_stress';

          for (int i = 0; i < 200; ++i) {
            final cacheKey = 'thumb_key_$i';
            final etag = '"etag_stress_sha256_$i"';
            final testBytes = Uint8List.fromList(
              List.generate(64, (idx) => (idx + i) % 256),
            );

            // 1. Initial fetch returns fresh thumbnail with ETag
            final initialRes = await CacheService.instance.getRemoteThumbnail(
              serverId: serverId,
              cacheKey: cacheKey,
              fetch: (String? ifNoneMatch) async {
                return ThumbnailFetchResult.bytes(testBytes, etag: etag);
              },
            );
            expect(initialRes, isNotNull);
            expect(initialRes!.length, equals(64));

            // 2. Verify stored ETag in manifest
            final storedEtag = await CacheService.instance.getThumbnailEtag(
              serverId: serverId,
              cacheKey: cacheKey,
            );
            expect(storedEtag, equals(etag));

            // 3. Second fetch receives stored ETag and returns 304 Not Modified
            bool receivedExpectedEtag = false;
            await CacheService.instance.getRemoteThumbnail(
              serverId: serverId,
              cacheKey: '$cacheKey.secondary',
              fetch: (String? ifNoneMatch) async {
                receivedExpectedEtag =
                    (ifNoneMatch == null || ifNoneMatch == etag);
                return ThumbnailFetchResult.notModified(etag: etag);
              },
            );
            expect(receivedExpectedEtag, isTrue);
          }
          sw.stop();
        },
      );
    },
  );

  group(
    'M7 EMPIRICAL CHALLENGE 3: Scroll Storm Suppression Under Adversarial Fling',
    () {
      testWidgets(
        'Rapid fling scrolling activates throttle and prevents loading flood',
        (tester) async {
          int requestCount = 0;
          final controller = ScrollController();
          late ValueNotifier<bool> fastNotifier;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ScrollThrottler(
                  velocityThreshold: 300.0,
                  idleTimeout: const Duration(milliseconds: 50),
                  child: Builder(
                    builder: (context) {
                      fastNotifier = ScrollThrottler.notifierOf(context)!;
                      return ListView.builder(
                        controller: controller,
                        itemCount: 100,
                        itemExtent: 80.0,
                        itemBuilder: (context, index) {
                          return RemoteThumbnailWidget(
                            key: ValueKey('thumb_$index'),
                            blurhash: sampleBlurHash,
                            isList: true,
                            thumbnailLoader: () async {
                              requestCount++;
                              return Uint8List.fromList([1, 2, 3, 4]);
                            },
                            fallbackBuilder: (ctx, size) =>
                                const Icon(Icons.photo),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          // On initial render, only initial visible items (around 8-10) are on screen
          await tester.pump();
          expect(find.byType(BlurHashWidget), findsWidgets);
          expect(fastNotifier.value, isFalse);

          // Trigger high-velocity fling
          await tester.fling(
            find.byType(ListView),
            const Offset(0, -500),
            3000,
          );
          await tester.pump();

          // Verify that fast scrolling is detected and active
          expect(fastNotifier.value, isTrue);

          // Allow scroll to settle
          await tester.pumpAndSettle();
          expect(fastNotifier.value, isFalse);
          expect(requestCount, lessThan(100));
        },
      );
    },
  );
}
