import 'dart:convert';

import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
}
