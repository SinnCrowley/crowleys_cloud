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
import 'dart:typed_data';

import 'package:crowleys_cloud/cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempRoot;
  late Directory supportDir;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('cache_service_adv_test');
    supportDir = Directory(p.join(tempRoot.path, 'support'));
    tempDir = Directory(p.join(tempRoot.path, 'temp'));
    await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);
  });

  tearDown(() async {
    CacheService.instance.dispose();
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('CacheService Adversarial: HTTP 304 & ETag Nuances', () {
    test('304 Not Modified when cached file missing on disk returns null without crash', () async {
      // 1. Initial 200 OK
      await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv1',
        cacheKey: 'item_missing_disk',
        fetch: (etag) async => ThumbnailFetchResult.bytes(
          utf8.encode('initial_content'),
          etag: '"etag_initial"',
        ),
      );

      // 2. Delete the physical thumbnail file from disk behind CacheService's back
      final remoteDir = Directory(
        p.join(tempDir.path, 'crowleys_cloud_cache', 'remote_thumbnails', 'srv1'),
      );
      if (await remoteDir.exists()) {
        await remoteDir.delete(recursive: true);
      }

      // Clear memory cache so next read attempts disk / conditional fetch
      await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);

      // 3. Server returns 304 Not Modified
      final result = await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv1',
        cacheKey: 'item_missing_disk',
        fetch: (etag) async {
          // etag is null because file is not on disk (smart guard against conditional requests without disk backing)
          expect(etag, isNull);
          return const ThumbnailFetchResult.notModified(etag: '"etag_initial"');
        },
      );

      // Since file was physically deleted from disk, 304 cannot read old file -> must return null gracefully
      expect(result, isNull);
    });

    test('304 Not Modified with refreshed ETag header updates manifest etag', () async {
      // 1. Initial 200 OK with etag-v1
      await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv1',
        cacheKey: 'item_etag_refresh',
        fetch: (etag) async => ThumbnailFetchResult.bytes(
          utf8.encode('photo_content_v1'),
          etag: '"etag-v1"',
        ),
      );

      // Clear RAM cache
      await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);

      // 2. Server returns 304 Not Modified with a newer ETag (e.g. server re-tagged)
      final result = await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv1',
        cacheKey: 'item_etag_refresh',
        fetch: (etag) async {
          expect(etag, equals('"etag-v1"'));
          return const ThumbnailFetchResult.notModified(etag: '"etag-v2-refreshed"');
        },
      );

      expect(result, isNotNull);
      expect(utf8.decode(result!), equals('photo_content_v1'));

      // Flush manifest and verify ETag was updated to "etag-v2-refreshed"
      await CacheService.instance.flushManifest(immediate: true);
      final updatedEtag = await CacheService.instance.getThumbnailEtag(
        serverId: 'srv1',
        cacheKey: 'item_etag_refresh',
      );
      expect(updatedEtag, equals('"etag-v2-refreshed"'));
    });

    test('Handles weak ETags (W/"...") and unquoted ETags seamlessly', () async {
      await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv1',
        cacheKey: 'weak_etag_item',
        fetch: (etag) async => ThumbnailFetchResult.bytes(
          utf8.encode('weak_etag_bytes'),
          etag: 'W/"weak-12345"',
        ),
      );

      final storedEtag = await CacheService.instance.getThumbnailEtag(
        serverId: 'srv1',
        cacheKey: 'weak_etag_item',
      );
      expect(storedEtag, equals('W/"weak-12345"'));

      await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);

      String? passedEtag;
      await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv1',
        cacheKey: 'weak_etag_item',
        fetch: (etag) async {
          passedEtag = etag;
          return const ThumbnailFetchResult.notModified();
        },
      );
      expect(passedEtag, equals('W/"weak-12345"'));
    });
  });

  group('CacheService Adversarial: Offline Fallback & Network Error Handling', () {
    test('Offline fallback returns cached disk thumbnail when network fetch fails (returns null)', () async {
      // 1. Initial successful cache
      await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv1',
        cacheKey: 'offline_item',
        fetch: (etag) async => ThumbnailFetchResult.bytes(
          utf8.encode('offline_bytes_test'),
          etag: '"etag-offline-test"',
        ),
      );

      // App restarts / RAM cache cleared
      await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);

      // 2. Fetch fails (returns null, as controller does when network is down)
      final fallback = await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv1',
        cacheKey: 'offline_item',
        fetch: (etag) async => null,
      );

      // Must gracefully return cached disk bytes
      expect(fallback, isNotNull);
      expect(utf8.decode(fallback!), equals('offline_bytes_test'));
    });

    test('Non-cached item returning null from fetch returns null without throwing', () async {
      final result = await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv1',
        cacheKey: 'non_existent_item',
        fetch: (etag) async => null,
      );

      expect(result, isNull);
    });
  });

  group('CacheService Adversarial: Manifest Corruption & Recovery Harness', () {
    test('Recovers gracefully from corrupted JSON text in manifest.json', () async {
      final manifest = File(p.join(supportDir.path, 'cache', 'manifest.json'));
      await manifest.parent.create(recursive: true);
      await manifest.writeAsString('{{{{ NOT A VALID JSON }}}}');

      await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);

      // Cache operations should continue working normally after recovery
      await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv1',
        cacheKey: 'recovered_key',
        fetch: (etag) async => ThumbnailFetchResult.bytes(
          utf8.encode('recovered_bytes'),
          etag: '"etag-rec"',
        ),
      );

      expect(await CacheService.instance.cacheSizeBytes(), greaterThan(0));
    });

    test('Recovers gracefully from empty 0-byte manifest.json', () async {
      final manifest = File(p.join(supportDir.path, 'cache', 'manifest.json'));
      await manifest.parent.create(recursive: true);
      await manifest.writeAsString('');

      await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);

      final etag = await CacheService.instance.getThumbnailEtag(
        serverId: 'srv1',
        cacheKey: 'any',
      );
      expect(etag, isNull);
    });

    test('Recovers gracefully from malformed manifest structure (array root, null fields)', () async {
      final manifest = File(p.join(supportDir.path, 'cache', 'manifest.json'));
      await manifest.parent.create(recursive: true);

      // JSON Array root
      await manifest.writeAsString(jsonEncode([{"random": "value"}]));
      await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);
      expect(await CacheService.instance.cacheSizeBytes(), equals(0));

      // JSON Map with non-list entries
      await manifest.writeAsString(jsonEncode({"entries": "invalid_type"}));
      await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);
      expect(await CacheService.instance.cacheSizeBytes(), equals(0));

      // JSON Map with malformed entry maps (null / missing fields)
      await manifest.writeAsString(
        jsonEncode({
          "entries": [
            {"path": null, "size": "not_an_int"},
            null,
            42,
            {"path": "/tmp/dummy", "created_at": null}
          ]
        }),
      );
      await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);
      // No unhandled exception should be thrown
      expect(await CacheService.instance.cacheSizeBytes(), isNotNull);
    });
  });

  group('CacheService Adversarial: Concurrency & Eviction Stress', () {
    test('Concurrent requests for same thumbnail coalesce into a single in-flight fetch', () async {
      var fetchCount = 0;
      final futures = List.generate(20, (i) {
        return CacheService.instance.getRemoteThumbnail(
          serverId: 'srv1',
          cacheKey: 'coalesce_key',
          fetch: (etag) async {
            fetchCount++;
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return ThumbnailFetchResult.bytes(
              utf8.encode('coalesced_data'),
              etag: '"etag-c"',
            );
          },
        );
      });

      final results = await Future.wait(futures);
      expect(fetchCount, equals(1));
      for (final res in results) {
        expect(res, isNotNull);
        expect(utf8.decode(res!), equals('coalesced_data'));
      }
    });

    test('LRU eviction handles rapid successive writes exceeding max bytes limit', () async {
      // Limit cache to 100 bytes
      await CacheService.instance.setThumbnailMaxBytes(100);

      // Write 20 entries of 10 bytes each (total 200 bytes)
      for (int i = 0; i < 20; i++) {
        await CacheService.instance.getRemoteThumbnail(
          serverId: 'srv1',
          cacheKey: 'item_$i',
          fetch: (etag) async => ThumbnailFetchResult.bytes(
            Uint8List(10),
            etag: '"etag-$i"',
          ),
        );
        // Small delay to ensure distinct access timestamps
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      await CacheService.instance.evictThumbnails();
      final totalSize = await CacheService.instance.cacheSizeBytes();
      expect(totalSize, lessThanOrEqualTo(100));
    });
  });
}
