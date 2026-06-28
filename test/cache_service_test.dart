import 'dart:convert';
import 'dart:io';

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

  test('reports cache size and clears cache files', () async {
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

    expect(await CacheService.instance.cacheSizeBytes(), greaterThan(0));

    await CacheService.instance.clearAll();

    expect(await CacheService.instance.cacheSizeBytes(), 0);
  });

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
}
