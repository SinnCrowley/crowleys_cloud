import 'dart:convert';
import 'dart:io';

import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('uses server type field from API entries', () async {
    final store = InMemorySecretStore();
    await store.saveTokens(
      serverId: 'srv',
      accessToken: 'token',
      refreshToken: 'refresh',
    );

    final client = MockClient((request) async {
      expect(request.url.path, '/api/dir');
      return http.Response(
        jsonEncode({
          'entries': [
            {
              'name': 'sample.unknown',
              'size': 12,
              'modified_at': 0,
              'type': 'document',
              'mime_type': 'application/pdf',
              'is_dir': false,
              'path': 'sample.unknown',
            },
          ],
        }),
        200,
      );
    });

    final controller = ServerBrowserController(
      profile: ServerProfile(
        id: 'srv',
        displayName: 'Test',
        baseUrl: 'http://localhost:7777',
        authMode: 'login',
        lastUsedAt: DateTime.now().toUtc(),
        syncPrefs: const {},
      ),
      serverId: 'srv',
      authService: AuthService(secretStore: store),
      client: client,
    );

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(controller.files, hasLength(1));
    expect(controller.files.first.type, 'document');
    controller.disposeController();
    controller.dispose();
  });

  test(
    'loads persisted server sort preferences and uses them in query',
    () async {
      SharedPreferences.setMockInitialValues({
        'serverSortBy': ServerSortBy.size.index,
        'serverSortAscending': false,
      });

      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv',
        accessToken: 'token',
        refreshToken: 'refresh',
      );

      final client = MockClient((request) async {
        expect(request.url.queryParameters['sort'], 'size');
        expect(request.url.queryParameters['order'], 'desc');
        return http.Response(jsonEncode({'entries': []}), 200);
      });

      final controller = ServerBrowserController(
        profile: ServerProfile(
          id: 'srv',
          displayName: 'Test',
          baseUrl: 'http://localhost:7777',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        ),
        serverId: 'srv',
        authService: AuthService(secretStore: store),
        client: client,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.sortBy, ServerSortBy.size);
      expect(controller.sortAscending, false);
      controller.disposeController();
      controller.dispose();
    },
  );

  test('server file items compare by path', () {
    final first = ServerFileItem(
      name: 'a.txt',
      size: 1,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      type: 'document',
      mimeType: 'text/plain',
      thumbnailUrl: null,
      isDir: false,
      path: 'folder/a.txt',
    );
    final second = ServerFileItem(
      name: 'a.txt',
      size: 2,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
      type: 'document',
      mimeType: 'text/plain',
      thumbnailUrl: null,
      isDir: false,
      path: 'folder/a.txt',
    );

    final selected = <ServerFileItem>{first};
    expect(selected, contains(second));
  });

  test(
    'renders cached entries before fresh network response replaces them',
    () async {
      final tempRoot = await Directory.systemTemp.createTemp(
        'server_browser_cache_test',
      );
      addTearDown(() async {
        if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
      });
      final supportDir = Directory(p.join(tempRoot.path, 'support'));
      final tempDir = Directory(p.join(tempRoot.path, 'temp'));
      await CacheService.instance.init(
        supportDir: supportDir,
        tempDir: tempDir,
      );

      final cachedItem = _serverItem(name: 'cached.txt', path: 'cached.txt');
      await CacheService.instance.writeDirectory(
        serverId: 'srv',
        cacheKey: _cacheKey(),
        scope: 'private',
        path: '',
        entries: [cachedItem],
      );

      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv',
        accessToken: 'token',
        refreshToken: 'refresh',
      );

      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response(
          jsonEncode({
            'entries': [
              _serverItem(name: 'fresh.txt', path: 'fresh.txt').toJson(),
            ],
          }),
          200,
        );
      });

      final controller = _controller(store: store, client: client);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.files.single.name, 'cached.txt');

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(controller.files.single.name, 'fresh.txt');
      controller.disposeController();
      controller.dispose();
    },
  );

  test(
    'network failure keeps cached entries and exposes non-fatal message',
    () async {
      final tempRoot = await Directory.systemTemp.createTemp(
        'server_browser_cache_error_test',
      );
      addTearDown(() async {
        if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
      });
      final supportDir = Directory(p.join(tempRoot.path, 'support'));
      final tempDir = Directory(p.join(tempRoot.path, 'temp'));
      await CacheService.instance.init(
        supportDir: supportDir,
        tempDir: tempDir,
      );

      await CacheService.instance.writeDirectory(
        serverId: 'srv',
        cacheKey: _cacheKey(),
        scope: 'private',
        path: '',
        entries: [_serverItem(name: 'cached.txt', path: 'cached.txt')],
      );

      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv',
        accessToken: 'token',
        refreshToken: 'refresh',
      );

      final controller = _controller(
        store: store,
        client: MockClient((request) async => http.Response('', 503)),
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(controller.files.single.name, 'cached.txt');
      expect(controller.error, contains('Server error 503'));
      expect(
        controller.operationMessage,
        'Showing cached files. Refresh failed.',
      );
      controller.disposeController();
      controller.dispose();
    },
  );

  test('thumbnail cache hit avoids HTTP request', () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'server_browser_thumb_cache_test',
    );
    addTearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });
    final supportDir = Directory(p.join(tempRoot.path, 'support'));
    final tempDir = Directory(p.join(tempRoot.path, 'temp'));
    await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);

    final store = InMemorySecretStore();
    await store.saveTokens(
      serverId: 'srv',
      accessToken: 'token',
      refreshToken: 'refresh',
    );

    var thumbRequests = 0;
    final controller = _controller(
      store: store,
      client: MockClient((request) async {
        if (request.url.path == '/api/dir') {
          return http.Response(jsonEncode({'entries': []}), 200);
        }
        thumbRequests++;
        return http.Response.bytes(utf8.encode('thumb'), 200);
      }),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final item = _serverItem(name: 'photo.jpg', path: 'photo.jpg');
    final first = await controller.loadThumbnailWithRetry(item);
    final second = await controller.loadThumbnailWithRetry(item);

    expect(utf8.decode(first!), 'thumb');
    expect(utf8.decode(second!), 'thumb');
    expect(thumbRequests, 1);
    controller.disposeController();
    controller.dispose();
  });
}

ServerBrowserController _controller({
  required InMemorySecretStore store,
  required http.Client client,
}) {
  return ServerBrowserController(
    profile: ServerProfile(
      id: 'srv',
      displayName: 'Test',
      baseUrl: 'http://localhost:7777',
      authMode: 'login',
      lastUsedAt: DateTime.now().toUtc(),
      syncPrefs: const {},
    ),
    serverId: 'srv',
    authService: AuthService(secretStore: store),
    client: client,
  );
}

ServerFileItem _serverItem({required String name, required String path}) {
  return ServerFileItem(
    name: name,
    size: 12,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    type: 'document',
    mimeType: 'text/plain',
    thumbnailUrl: null,
    isDir: false,
    path: path,
  );
}

String _cacheKey() {
  return jsonEncode({
    'serverId': 'srv',
    'scope': 'private',
    'path': '',
    'selectedType': 'all',
    'searchQuery': '',
    'sort': ServerSortBy.name.name,
    'order': 'asc',
  });
}
