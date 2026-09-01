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

import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/shared/proto/dir_entry.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';
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
        if (request.url.path == '/api/account/stats') {
          return http.Response(jsonEncode({}), 200);
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

  test('filters hidden server entries unless setting is enabled', () async {
    SharedPreferences.setMockInitialValues({
      AppSettingsService.showHiddenFilesKey: false,
    });
    final store = InMemorySecretStore();
    await store.saveTokens(
      serverId: 'srv',
      accessToken: 'token',
      refreshToken: 'refresh',
    );

    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'entries': [
            _serverItem(name: '.env', path: '.env').toJson(),
            _serverItem(name: 'notes.txt', path: 'notes.txt').toJson(),
          ],
        }),
        200,
      );
    });

    final controller = _controller(store: store, client: client);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.files.map((item) => item.name), ['notes.txt']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppSettingsService.showHiddenFilesKey, true);
    await controller.reload();
    expect(controller.files.map((item) => item.name), contains('.env'));
    controller.disposeController();
    controller.dispose();
  });

  test('uses configured download root', () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'server_browser_download_root_test',
    );
    addTearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });
    SharedPreferences.setMockInitialValues({
      AppSettingsService.downloadDirectoryPathKey: tempRoot.path,
    });

    final store = InMemorySecretStore();
    await store.saveTokens(
      serverId: 'srv',
      accessToken: 'token',
      refreshToken: 'refresh',
    );

    final controller = _controller(
      store: store,
      client: MockClient((request) async {
        return http.Response(jsonEncode({'entries': []}), 200);
      }),
    );

    expect((await controller.downloadRootForTest()).path, tempRoot.path);
    controller.disposeController();
    controller.dispose();
  });

  test('parses ownerName and uploaderUserId in ServerFileItem', () {
    final item = ServerFileItem.fromJson({
      'name': 'shared_doc.pdf',
      'size': 100,
      'modified_at': 0,
      'type': 'document',
      'mime_type': 'application/pdf',
      'thumbnail_url': null,
      'is_dir': false,
      'path': 'shared_doc.pdf',
      'owner_name': 'crowley',
      'uploader_user_id': 42,
    });

    expect(item.ownerName, 'crowley');
    expect(item.uploaderUserId, 42);
    expect(item.toJson()['owner_name'], 'crowley');
    expect(item.toJson()['uploader_user_id'], 42);
  });

  test('fetches account stats from /api/account/stats endpoint', () async {
    final store = InMemorySecretStore();
    await store.saveTokens(
      serverId: 'srv',
      accessToken: 'token',
      refreshToken: 'refresh',
    );

    final client = MockClient((request) async {
      if (request.url.path == '/api/account/stats') {
        return http.Response(
          jsonEncode({
            'total_size': 1024,
            'total_count': 5,
            'photo_count': 2,
            'photo_size': 500,
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'entries': []}), 200);
    });

    final controller = _controller(store: store, client: client);
    await controller.fetchAccountStats();

    expect(controller.accountStats, isNotNull);
    expect(controller.accountStats!['total_size'], 1024);
    expect(controller.accountStats!['total_count'], 5);
    controller.disposeController();
    controller.dispose();
  });

  test('createFolderAtPath preserves operationMessage across reload', () async {
    final l10nEn = lookupAppLocalizations(const Locale('en'));
    final l10nRu = lookupAppLocalizations(const Locale('ru'));

    final store = InMemorySecretStore();
    await store.saveTokens(
      serverId: 'srv',
      accessToken: 'token',
      refreshToken: 'refresh',
    );

    final client = MockClient((request) async {
      if (request.url.path == '/api/folders') {
        if (request.url.queryParameters['path'] == 'fail') {
          return http.Response('error', 500);
        }
        return http.Response('{"ok": true}', 200);
      }
      return http.Response(jsonEncode({'entries': []}), 200);
    });

    final controller = _controller(store: store, client: client);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Success EN
    await controller.createFolderAtPath('', 'MyFolder', l10nEn);
    expect(controller.operationMessage, l10nEn.folderCreated);

    // Success RU
    await controller.createFolderAtPath('', 'МояПапка', l10nRu);
    expect(controller.operationMessage, l10nRu.folderCreated);

    // Failure EN
    await controller.createFolderAtPath('', 'fail', l10nEn);
    expect(
      controller.operationMessage,
      l10nEn.failedToCreateFolderWithCode(500),
    );

    controller.disposeController();
    controller.dispose();
  });

  test(
    'moveSelectedToFolder preserves operationMessage across reload',
    () async {
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nRu = lookupAppLocalizations(const Locale('ru'));

      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv',
        accessToken: 'token',
        refreshToken: 'refresh',
      );

      final item = _serverItem(name: 'file1.txt', path: 'file1.txt');

      final client = MockClient((request) async {
        if (request.url.path == '/api/files') {
          if (request.method == 'GET') {
            return http.Response('content', 200);
          }
          if (request.method == 'POST') {
            return http.Response('ok', 200);
          }
          if (request.method == 'DELETE') {
            return http.Response('deleted', 200);
          }
        }
        return http.Response(jsonEncode({'entries': []}), 200);
      });

      final controller = _controller(store: store, client: client);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      controller.toggleSelection(item);
      expect(controller.selectedFiles, contains(item));

      await controller.moveSelectedToFolder('destination', l10nEn);
      expect(controller.operationMessage, l10nEn.movedNItems(1));
      expect(controller.selectedFiles, isEmpty);

      controller.toggleSelection(item);
      await controller.moveSelectedToFolder('destination', l10nRu);
      expect(controller.operationMessage, l10nRu.movedNItems(1));

      controller.disposeController();
      controller.dispose();
    },
  );

  test('renameItem preserves operationMessage across reload', () async {
    final l10nEn = lookupAppLocalizations(const Locale('en'));
    final l10nRu = lookupAppLocalizations(const Locale('ru'));

    final store = InMemorySecretStore();
    await store.saveTokens(
      serverId: 'srv',
      accessToken: 'token',
      refreshToken: 'refresh',
    );

    final item = _serverItem(name: 'old_name.txt', path: 'old_name.txt');

    final client = MockClient((request) async {
      if (request.url.path == '/api/files/move') {
        if (request.url.queryParameters['dest'] == 'conflict.txt') {
          return http.Response('conflict', 409);
        }
        return http.Response('ok', 200);
      }
      return http.Response(jsonEncode({'entries': []}), 200);
    });

    final controller = _controller(store: store, client: client);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Success EN
    final okEn = await controller.renameItem(item, 'new_name.txt', l10nEn);
    expect(okEn, isTrue);
    expect(
      controller.operationMessage,
      l10nEn.renamedOldToNew('old_name.txt', 'new_name.txt'),
    );

    // Success RU
    final okRu = await controller.renameItem(item, 'новое_имя.txt', l10nRu);
    expect(okRu, isTrue);
    expect(
      controller.operationMessage,
      l10nRu.renamedOldToNew('old_name.txt', 'новое_имя.txt'),
    );

    // Failure EN
    final failEn = await controller.renameItem(item, 'conflict.txt', l10nEn);
    expect(failEn, isFalse);
    expect(
      controller.operationMessage,
      l10nEn.failedToRenameWithStatus('old_name.txt', 409),
    );

    controller.disposeController();
    controller.dispose();
  });

  group('BlurHash Integration', () {
    test('ServerFileItem serializes and deserializes blurhash cleanly', () {
      const blurHashStr = 'L6Pj0^jE.AyE_3t7t7R**0o#DgR4';
      final item = ServerFileItem(
        name: 'photo.jpg',
        size: 1024,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(
          1725134000,
          isUtc: true,
        ),
        type: 'photo',
        mimeType: 'image/jpeg',
        thumbnailUrl: '/api/thumb?path=photo.jpg',
        isDir: false,
        path: 'photo.jpg',
        blurhash: blurHashStr,
      );

      final json = item.toJson();
      expect(json['blurhash'], blurHashStr);

      final fromJson = ServerFileItem.fromJson(json);
      expect(fromJson.blurhash, blurHashStr);

      // Empty/null blurhash handling
      final noBlurJson = Map<String, Object?>.from(json)..remove('blurhash');
      final fromNoBlur = ServerFileItem.fromJson(noBlurJson);
      expect(fromNoBlur.blurhash, isNull);

      final emptyBlurJson = Map<String, Object?>.from(json)..['blurhash'] = '';
      final fromEmptyBlur = ServerFileItem.fromJson(emptyBlurJson);
      expect(fromEmptyBlur.blurhash, isNull);
    });

    test('DirResponse protobuf parses blurhash field tag 10', () {
      const blurHashStr = 'L~TSUA~qfQ~q~q%MfQ%MfQfQfQfQ';
      final protoResponse = DirResponse(
        entries: [
          DirEntry(
            name: 'sample.png',
            path: 'sample.png',
            isDir: false,
            size: Int64(2048),
            modifiedAt: Int64(1725134000),
            type: 'photo',
            mimeType: 'image/png',
            thumbnailUrl: '/api/thumb?path=sample.png',
            id: Int64(1),
            blurhash: blurHashStr,
          ),
        ],
      );

      final buffer = protoResponse.writeToBuffer();
      final parsed = DirResponse.fromBuffer(buffer);
      expect(parsed.entries.length, 1);
      expect(parsed.entries[0].name, 'sample.png');
      expect(parsed.entries[0].blurhash, blurHashStr);

      final item = ServerFileItem(
        name: parsed.entries[0].name,
        size: parsed.entries[0].size.toInt(),
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(
          parsed.entries[0].modifiedAt.toInt(),
          isUtc: true,
        ),
        type: parsed.entries[0].type,
        mimeType: parsed.entries[0].mimeType,
        thumbnailUrl: parsed.entries[0].thumbnailUrl.isEmpty
            ? null
            : parsed.entries[0].thumbnailUrl,
        isDir: parsed.entries[0].isDir,
        path: parsed.entries[0].path,
        blurhash: parsed.entries[0].blurhash.isNotEmpty
            ? parsed.entries[0].blurhash
            : null,
      );

      expect(item.blurhash, blurHashStr);
    });
  });

  group('ServerBrowserController HTTP 304 & ETag Thumbnail Loading', () {
    late Directory tempRoot;
    late Directory supportDir;
    late Directory tempDir;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('controller_thumb_test');
      supportDir = Directory(p.join(tempRoot.path, 'support'));
      tempDir = Directory(p.join(tempRoot.path, 'temp'));
      await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('loadThumbnailWithRetry handles 200 OK and conditional 304 Not Modified', () async {
      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv',
        accessToken: 'token',
        refreshToken: 'refresh',
      );

      final item = ServerFileItem(
        name: 'photo.jpg',
        size: 100,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
        type: 'photo',
        mimeType: 'image/jpeg',
        thumbnailUrl: '/api/thumb?path=photo.jpg',
        isDir: false,
        path: 'photo.jpg',
      );

      var requestCount = 0;
      String? sentIfNoneMatch;

      final client = MockClient((request) async {
        if (request.url.path == '/api/dir') {
          return http.Response(jsonEncode({'entries': []}), 200);
        }
        if (request.url.path.contains('/thumb')) {
          requestCount++;
          sentIfNoneMatch = request.headers['if-none-match'];
          if (sentIfNoneMatch == '"etag-100"') {
            return http.Response('', 304, headers: {'etag': '"etag-100"'});
          }
          return http.Response.bytes(
            utf8.encode('thumb_bytes_v1'),
            200,
            headers: {'etag': '"etag-100"'},
          );
        }
        return http.Response('not found', 404);
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

      // 1. First fetch -> 200 OK
      final bytes1 = await controller.loadThumbnailWithRetry(item);
      expect(bytes1, isNotNull);
      expect(utf8.decode(bytes1!), equals('thumb_bytes_v1'));
      expect(sentIfNoneMatch, isNull);
      expect(requestCount, equals(1));

      // Clear memory cache so next request checks conditional ETag
      CacheService.instance.clearAll;
      await CacheService.instance.init(supportDir: supportDir, tempDir: tempDir);

      // 2. Second fetch -> sends If-None-Match: "etag-100" -> receives 304 Not Modified -> returns cached disk bytes
      final bytes2 = await controller.loadThumbnailWithRetry(item);
      expect(bytes2, isNotNull);
      expect(utf8.decode(bytes2!), equals('thumb_bytes_v1'));
      expect(sentIfNoneMatch, equals('"etag-100"'));
      expect(requestCount, equals(2));

      controller.disposeController();
      controller.dispose();
    });
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
    'showHiddenFiles': false,
  });
}
