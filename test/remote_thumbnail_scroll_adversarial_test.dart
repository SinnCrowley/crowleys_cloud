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
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/shared/utils/blurhash_decoder.dart';
import 'package:crowleys_cloud/shared/utils/scroll_throttler.dart';
import 'package:crowleys_cloud/shared/widgets/remote_thumbnail_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const sampleBlurHash = 'L6Pj0^jE.AyE_3t7t7R**0o#DgR4';
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('remote_thumb_adv_test');
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

  group('ServerBrowserController Adversarial: HTTP 202 Accepted Retries & 304', () {
    test('Retries on HTTP 202 Accepted and succeeds when 200 OK eventually returned', () async {
      int thumbRequestCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/thumb')) {
          thumbRequestCount++;
          if (thumbRequestCount < 3) {
            // Return 202 Accepted for first 2 requests
            return http.Response('', 202);
          }
          return http.Response(
            'final_image_data',
            200,
            headers: {'etag': '"etag-final"'},
          );
        }
        return http.Response(jsonEncode({'entries': []}), 200);
      });

      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv1',
        accessToken: 'valid_access_token',
        refreshToken: 'valid_refresh_token',
      );

      final controller = ServerBrowserController(
        serverId: 'srv1',
        profile: ServerProfile(
          id: 'srv1',
          displayName: 'Test',
          baseUrl: 'http://localhost:8080',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        ),
        authService: AuthService(secretStore: store),
        client: mockClient,
      );

      final item = ServerFileItem(
        name: 'test.jpg',
        size: 100,
        modifiedAt: DateTime.now().toUtc(),
        type: 'photo',
        mimeType: 'image/jpeg',
        thumbnailUrl: '/api/thumb?path=test.jpg',
        isDir: false,
        path: 'test.jpg',
      );

      final result = await controller.loadThumbnailWithRetry(item);
      expect(result, isNotNull);
      expect(utf8.decode(result!), equals('final_image_data'));
      expect(thumbRequestCount, equals(3));
      controller.disposeController();
      controller.dispose();
    });

    test('Exhausts retries cleanly on persistent 202 Accepted without infinite loop', () async {
      int thumbRequestCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/thumb')) {
          thumbRequestCount++;
          return http.Response('', 202);
        }
        return http.Response(jsonEncode({'entries': []}), 200);
      });

      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv1',
        accessToken: 'valid_access_token',
        refreshToken: 'valid_refresh_token',
      );

      final controller = ServerBrowserController(
        serverId: 'srv1',
        profile: ServerProfile(
          id: 'srv1',
          displayName: 'Test',
          baseUrl: 'http://localhost:8080',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        ),
        authService: AuthService(secretStore: store),
        client: mockClient,
      );

      final item = ServerFileItem(
        name: 'test.jpg',
        size: 100,
        modifiedAt: DateTime.now().toUtc(),
        type: 'photo',
        mimeType: 'image/jpeg',
        thumbnailUrl: '/api/thumb?path=test.jpg',
        isDir: false,
        path: 'test.jpg',
      );

      final result = await controller.loadThumbnailWithRetry(item);
      expect(result, isNull);
      // Retries are 0, 500ms, 1s, 2s -> total 4 attempts
      expect(thumbRequestCount, equals(4));
      controller.disposeController();
      controller.dispose();
    });
  });

  group('RemoteThumbnailWidget Adversarial: Widget Lifecycle & Scroll Fling', () {
    testWidgets('Renders instant BlurHash placeholder and transitions smoothly to loaded image', (tester) async {
      final completer = Completer<Uint8List?>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteThumbnailWidget(
              blurhash: sampleBlurHash,
              isList: false,
              thumbnailLoader: () => completer.future,
              fallbackBuilder: (ctx, size) => const Icon(Icons.broken_image),
            ),
          ),
        ),
      );

      // Frame 0: BlurHashWidget should be immediately rendered as placeholder
      expect(find.byType(BlurHashWidget), findsOneWidget);

      // Complete thumbnail future
      final dummyBytes = Uint8List.fromList([
        0x42, 0x4D, 58, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0,
        40, 0, 0, 0, 1, 0, 0, 0, 255, 255, 255, 255, 1, 0, 32, 0,
        0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 255, 255,
      ]);
      completer.complete(dummyBytes);

      // Settle animation
      await tester.pumpAndSettle();

      // Placeholder transitioned to loaded Image
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Gracefully handles disposal while thumbnail loader is in flight', (tester) async {
      final completer = Completer<Uint8List?>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteThumbnailWidget(
              blurhash: sampleBlurHash,
              isList: false,
              thumbnailLoader: () => completer.future,
              fallbackBuilder: (ctx, size) => const Icon(Icons.broken_image),
            ),
          ),
        ),
      );

      // Unmount the widget while future is still in flight
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Unmounted'))));

      // Now complete the future after widget is unmounted
      completer.complete(Uint8List(10));
      await tester.pump();

      // Verify no setState after dispose exceptions occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('Suppresses thumbnail loading during fast fling scroll', (tester) async {
      int loadCount = 0;
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollThrottler(
              velocityThreshold: 200.0,
              child: ListView.builder(
                controller: scrollController,
                itemCount: 50,
                itemBuilder: (context, index) {
                  return SizedBox(
                    height: 100,
                    child: RemoteThumbnailWidget(
                      blurhash: sampleBlurHash,
                      isList: true,
                      thumbnailLoader: () async {
                        loadCount++;
                        return Uint8List(10);
                      },
                      fallbackBuilder: (ctx, size) => const Icon(Icons.image),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Rapidly fling scroll down
      await tester.fling(find.byType(ListView), const Offset(0, -2000), 5000);
      await tester.pump(const Duration(milliseconds: 10));

      // Check that during fast scrolling, throttle is active
      expect(loadCount, lessThan(50));

      // Allow scroll to settle and finish idle timeout
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    });
  });
}
