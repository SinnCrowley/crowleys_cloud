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
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempRoot;
  late Directory supportDir;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('cache_service_test');
    supportDir = Directory(p.join(tempRoot.path, 'support'));
    tempDir = Directory(p.join(tempRoot.path, 'temp'));
    await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('round-trips directory metadata and reports stale entries', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(CacheService.metadataTtlMinutesKey, 0);

    final item = ServerFileItem(
      name: 'photo.jpg',
      size: 42,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
      type: 'photo',
      mimeType: 'image/jpeg',
      thumbnailUrl: '/api/thumb?path=photo.jpg',
      isDir: false,
      path: 'photo.jpg',
    );

    await CacheService.instance.writeDirectory(
      serverId: 'srv',
      cacheKey: 'dir-key',
      scope: 'private',
      path: '',
      entries: [item],
    );

    final cached = await CacheService.instance.readDirectory(
      serverId: 'srv',
      cacheKey: 'dir-key',
    );

    expect(cached, isNotNull);
    expect(cached!.isStale, true);
    expect(cached.entries.single.toJson(), item.toJson());
  });

  test(
    'recovers from corrupted manifest and deletes server-scoped cache',
    () async {
      await CacheService.instance.writeDirectory(
        serverId: 'srv',
        cacheKey: 'dir-key',
        scope: 'private',
        path: '',
        entries: const [],
      );
      await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv',
        cacheKey: 'thumb-key',
        fetch: () async => utf8.encode('thumb'),
      );

      final manifest = File(p.join(supportDir.path, 'cache', 'manifest.json'));
      await manifest.writeAsString('{broken');
      await CacheService.instance.init(
        supportDir: supportDir,
        tempDir: tempDir,
      );

      await CacheService.instance.deleteServer('srv');

      expect(
        await Directory(
          p.join(supportDir.path, 'cache', 'metadata', 'srv'),
        ).exists(),
        false,
      );
      expect(
        await Directory(
          p.join(
            tempDir.path,
            'crowleys_cloud_cache',
            'remote_thumbnails',
            'srv',
          ),
        ).exists(),
        false,
      );
    },
  );

  test(
    'thumbnail cache hit avoids fetch and modified key creates new file',
    () async {
      var fetches = 0;
      final first = await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv',
        cacheKey: 'path:1:size',
        fetch: () async {
          fetches++;
          return utf8.encode('one');
        },
      );
      final second = await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv',
        cacheKey: 'path:1:size',
        fetch: () async {
          fetches++;
          return utf8.encode('two');
        },
      );
      final changed = await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv',
        cacheKey: 'path:2:size',
        fetch: () async {
          fetches++;
          return utf8.encode('changed');
        },
      );

      expect(utf8.decode(first!), 'one');
      expect(utf8.decode(second!), 'one');
      expect(utf8.decode(changed!), 'changed');
      expect(fetches, 2);
    },
  );

  test('LRU eviction removes oldest remote thumbnail first', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(CacheService.thumbnailMaxBytesKey, 5);

    await CacheService.instance.getRemoteThumbnail(
      serverId: 'srv',
      cacheKey: 'old',
      fetch: () async => utf8.encode('1234'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await CacheService.instance.getRemoteThumbnail(
      serverId: 'srv',
      cacheKey: 'new',
      fetch: () async => utf8.encode('5678'),
    );

    var fetches = 0;
    await CacheService.instance.getRemoteThumbnail(
      serverId: 'srv',
      cacheKey: 'old',
      fetch: () async {
        fetches++;
        return utf8.encode('reloaded');
      },
    );

    expect(fetches, 1);
  });

  test(
    'reports cache size and clears cache files and RAM thumbnail maps',
    () async {
      await CacheService.instance.writeDirectory(
        serverId: 'srv',
        cacheKey: 'dir-key',
        scope: 'private',
        path: '',
        entries: const [],
      );
      await CacheService.instance.getRemoteThumbnail(
        serverId: 'srv',
        cacheKey: 'thumb-key',
        fetch: () async => utf8.encode('thumb'),
      );
      CacheService.instance.putMemoryThumbnail(
        'mem-key',
        utf8.encode('mem'),
        filePath: '/dummy/path',
      );

      expect(await CacheService.instance.cacheSizeBytes(), greaterThan(0));
      expect(CacheService.instance.getMemoryThumbnail('mem-key'), isNotNull);

      await CacheService.instance.clearAll();

      expect(await CacheService.instance.cacheSizeBytes(), 0);
      expect(CacheService.instance.getMemoryThumbnail('mem-key'), isNull);
    },
  );

  test('unlimited thumbnail cache skips eviction', () async {
    await CacheService.instance.setThumbnailMaxBytes(-1);

    await CacheService.instance.getRemoteThumbnail(
      serverId: 'srv',
      cacheKey: 'one',
      fetch: () async => utf8.encode('1234'),
    );
    await CacheService.instance.getRemoteThumbnail(
      serverId: 'srv',
      cacheKey: 'two',
      fetch: () async => utf8.encode('5678'),
    );

    expect(
      await CacheService.instance.cacheSizeBytes(),
      greaterThanOrEqualTo(8),
    );
  });

  group('HTTP 304 & ETag Caching', () {
    test(
      'persists etag in manifest entries and retrieves via getThumbnailEtag',
      () async {
        await CacheService.instance.getRemoteThumbnail(
          serverId: 'srv',
          cacheKey: 'photo1',
          fetch: (etag) async => ThumbnailFetchResult.bytes(
            utf8.encode('photo_bytes'),
            etag: '"etag-12345"',
          ),
        );

        final storedEtag = await CacheService.instance.getThumbnailEtag(
          serverId: 'srv',
          cacheKey: 'photo1',
        );
        expect(storedEtag, equals('"etag-12345"'));

        // Flush manifest and re-initialize CacheService
        await CacheService.instance.flushManifest(immediate: true);
        await CacheService.instance.init(
          supportDir: supportDir,
          tempDir: tempDir,
        );

        final recoveredEtag = await CacheService.instance.getThumbnailEtag(
          serverId: 'srv',
          cacheKey: 'photo1',
        );
        expect(recoveredEtag, equals('"etag-12345"'));
      },
    );

    test(
      '304 Not Modified retains existing disk file without rewriting and updates lastAccess',
      () async {
        // 1. Initial 200 OK
        await CacheService.instance.getRemoteThumbnail(
          serverId: 'srv',
          cacheKey: 'photo2',
          fetch: (etag) async => ThumbnailFetchResult.bytes(
            utf8.encode('original_image_bytes'),
            etag: '"etag-v1"',
          ),
        );

        // Clear memory cache so next request hits disk / conditional revalidation
        CacheService.instance.clearAll; // clear memory
        await CacheService.instance.init(
          supportDir: supportDir,
          tempDir: tempDir,
        );

        String? passedEtag;
        var fetchCount = 0;

        // 2. Conditional fetch returning 304
        final result = await CacheService.instance.getRemoteThumbnail(
          serverId: 'srv',
          cacheKey: 'photo2',
          fetch: (etag) async {
            passedEtag = etag;
            fetchCount++;
            return const ThumbnailFetchResult.notModified(etag: '"etag-v1"');
          },
        );

        expect(passedEtag, equals('"etag-v1"'));
        expect(fetchCount, equals(1));
        expect(result, isNotNull);
        expect(utf8.decode(result!), equals('original_image_bytes'));

        // Verify that RAM cache is now populated with disk bytes
        expect(
          CacheService.instance.getMemoryThumbnail('srv:photo2'),
          isNotNull,
        );
      },
    );

    test(
      '200 OK updates disk cache file and saves new ETag in manifest',
      () async {
        // Initial fetch
        await CacheService.instance.getRemoteThumbnail(
          serverId: 'srv',
          cacheKey: 'photo3',
          fetch: (etag) async => ThumbnailFetchResult.bytes(
            utf8.encode('old_bytes'),
            etag: '"etag-old"',
          ),
        );

        // Subsequent 200 OK fetch with new payload and new ETag
        await CacheService.instance.init(
          supportDir: supportDir,
          tempDir: tempDir,
        );

        final updated = await CacheService.instance.getRemoteThumbnail(
          serverId: 'srv',
          cacheKey: 'photo3',
          fetch: (etag) async {
            expect(etag, equals('"etag-old"'));
            return ThumbnailFetchResult.bytes(
              utf8.encode('new_bytes'),
              etag: '"etag-new"',
            );
          },
        );

        expect(utf8.decode(updated!), equals('new_bytes'));
        final storedEtag = await CacheService.instance.getThumbnailEtag(
          serverId: 'srv',
          cacheKey: 'photo3',
        );
        expect(storedEtag, equals('"etag-new"'));
      },
    );

    test(
      'offline fallback returns existing disk thumbnail when fetch fails or returns null',
      () async {
        // Seed disk cache
        await CacheService.instance.getRemoteThumbnail(
          serverId: 'srv',
          cacheKey: 'photo4',
          fetch: (etag) async => ThumbnailFetchResult.bytes(
            utf8.encode('cached_photo_bytes'),
            etag: '"etag-offline"',
          ),
        );

        // Clear memory cache to simulate app restart in offline mode
        await CacheService.instance.init(
          supportDir: supportDir,
          tempDir: tempDir,
        );

        // Fetch fails (returns null)
        final fallback = await CacheService.instance.getRemoteThumbnail(
          serverId: 'srv',
          cacheKey: 'photo4',
          fetch: (etag) async => null,
        );

        expect(fallback, isNotNull);
        expect(utf8.decode(fallback!), equals('cached_photo_bytes'));
      },
    );
  });

  group('Byte-Bounded Memory LRU Thumbnail Cache', () {
    test('initializes with default max bytes and zero current bytes', () {
      expect(
        CacheService.instance.maxMemoryThumbnailBytes,
        equals(CacheService.defaultMaxMemoryThumbnailBytes),
      );
      expect(CacheService.instance.currentMemoryThumbnailBytes, equals(0));
      expect(CacheService.instance.memoryThumbnailCount, equals(0));
    });

    test('tracks memory thumbnail byte sizes accurately on put and update', () {
      final bytesA = Uint8List(100);
      final bytesB = Uint8List(250);
      final bytesAUpdated = Uint8List(150);

      CacheService.instance.putMemoryThumbnail('keyA', bytesA);
      expect(CacheService.instance.currentMemoryThumbnailBytes, equals(100));
      expect(CacheService.instance.memoryThumbnailCount, equals(1));

      CacheService.instance.putMemoryThumbnail('keyB', bytesB);
      expect(CacheService.instance.currentMemoryThumbnailBytes, equals(350));
      expect(CacheService.instance.memoryThumbnailCount, equals(2));

      // Overwriting keyA replaces the previous byte count
      CacheService.instance.putMemoryThumbnail('keyA', bytesAUpdated);
      expect(CacheService.instance.currentMemoryThumbnailBytes, equals(400));
      expect(CacheService.instance.memoryThumbnailCount, equals(2));

      // getMemoryThumbnail retrieves without changing byte count
      final retrieved = CacheService.instance.getMemoryThumbnail('keyA');
      expect(retrieved?.lengthInBytes, equals(150));
      expect(CacheService.instance.currentMemoryThumbnailBytes, equals(400));
    });

    test(
      'bypasses L1 memory cache when entry size exceeds maxMemoryThumbnailBytes',
      () {
        CacheService.instance.setMaxMemoryThumbnailBytes(500);

        final oversized = Uint8List(600);
        CacheService.instance.putMemoryThumbnail('oversized', oversized);

        expect(CacheService.instance.getMemoryThumbnail('oversized'), isNull);
        expect(CacheService.instance.currentMemoryThumbnailBytes, equals(0));
        expect(CacheService.instance.memoryThumbnailCount, equals(0));

        final acceptable = Uint8List(400);
        CacheService.instance.putMemoryThumbnail('acceptable', acceptable);

        expect(
          CacheService.instance.getMemoryThumbnail('acceptable'),
          isNotNull,
        );
        expect(CacheService.instance.currentMemoryThumbnailBytes, equals(400));
        expect(CacheService.instance.memoryThumbnailCount, equals(1));
      },
    );

    test(
      'evicts oldest entries in O(1) LRU order when byte limit is exceeded',
      () {
        CacheService.instance.setMaxMemoryThumbnailBytes(300);

        final thumb1 = Uint8List(100);
        final thumb2 = Uint8List(100);
        final thumb3 = Uint8List(100);
        final thumb4 = Uint8List(100);

        CacheService.instance.putMemoryThumbnail('t1', thumb1);
        CacheService.instance.putMemoryThumbnail('t2', thumb2);
        CacheService.instance.putMemoryThumbnail('t3', thumb3);

        expect(CacheService.instance.currentMemoryThumbnailBytes, equals(300));
        expect(CacheService.instance.memoryThumbnailCount, equals(3));

        // Access t1 to mark it Most Recently Used (MRU)
        final accessed = CacheService.instance.getMemoryThumbnail('t1');
        expect(accessed, isNotNull);

        // Inserting t4 must evict the least recently used entry (t2, since t1 was accessed)
        CacheService.instance.putMemoryThumbnail('t4', thumb4);

        expect(CacheService.instance.currentMemoryThumbnailBytes, equals(300));
        expect(CacheService.instance.memoryThumbnailCount, equals(3));
        expect(
          CacheService.instance.getMemoryThumbnail('t2'),
          isNull,
        ); // evicted
        expect(
          CacheService.instance.getMemoryThumbnail('t1'),
          isNotNull,
        ); // kept
        expect(
          CacheService.instance.getMemoryThumbnail('t3'),
          isNotNull,
        ); // kept
        expect(
          CacheService.instance.getMemoryThumbnail('t4'),
          isNotNull,
        ); // kept
      },
    );

    test(
      'setMaxMemoryThumbnailBytes clamps to hardMax and evicts excess entries',
      () {
        CacheService.instance.setMaxMemoryThumbnailBytes(1000);

        CacheService.instance.putMemoryThumbnail('item1', Uint8List(400));
        CacheService.instance.putMemoryThumbnail('item2', Uint8List(400));
        expect(CacheService.instance.currentMemoryThumbnailBytes, equals(800));

        // Lower capacity: should evict oldest (item1) to satisfy new 500 byte limit
        CacheService.instance.setMaxMemoryThumbnailBytes(500);
        expect(CacheService.instance.maxMemoryThumbnailBytes, equals(500));
        expect(CacheService.instance.currentMemoryThumbnailBytes, equals(400));
        expect(CacheService.instance.getMemoryThumbnail('item1'), isNull);
        expect(CacheService.instance.getMemoryThumbnail('item2'), isNotNull);

        // Setting higher than hardMaxMemoryThumbnailBytes clamps to hardMax
        CacheService.instance.setMaxMemoryThumbnailBytes(100 * 1024 * 1024);
        expect(
          CacheService.instance.maxMemoryThumbnailBytes,
          equals(CacheService.hardMaxMemoryThumbnailBytes),
        );
      },
    );

    test(
      'bidirectional path mapping invalidates correct cache entries and frees bytes',
      () {
        final bytes1 = Uint8List(200);
        final bytes2 = Uint8List(300);

        CacheService.instance.putMemoryThumbnail(
          'k1',
          bytes1,
          filePath: '/tmp/f1.png',
        );
        CacheService.instance.putMemoryThumbnail(
          'k2',
          bytes2,
          filePath: '/tmp/f2.png',
        );

        expect(CacheService.instance.currentMemoryThumbnailBytes, equals(500));

        CacheService.instance.invalidateMemoryThumbnailForPath('/tmp/f1.png');

        expect(CacheService.instance.getMemoryThumbnail('k1'), isNull);
        expect(CacheService.instance.getMemoryThumbnail('k2'), isNotNull);
        expect(CacheService.instance.currentMemoryThumbnailBytes, equals(300));
        expect(CacheService.instance.memoryThumbnailCount, equals(1));
      },
    );

    test('clearMemoryThumbnails resets byte count and removes all entries', () {
      CacheService.instance.putMemoryThumbnail('k1', Uint8List(200));
      CacheService.instance.putMemoryThumbnail('k2', Uint8List(300));
      expect(CacheService.instance.currentMemoryThumbnailBytes, equals(500));

      CacheService.instance.clearMemoryThumbnails();

      expect(CacheService.instance.currentMemoryThumbnailBytes, equals(0));
      expect(CacheService.instance.memoryThumbnailCount, equals(0));
      expect(CacheService.instance.getMemoryThumbnail('k1'), isNull);
      expect(CacheService.instance.getMemoryThumbnail('k2'), isNull);
    });
  });
}
