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
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/shared/utils/authenticated_http_client.dart';
import 'package:crowleys_cloud/shared/utils/byte_formatter.dart';
import 'package:crowleys_cloud/shared/utils/file_icon_utils.dart';
import 'package:crowleys_cloud/shared/utils/file_type_utils.dart';
import 'package:crowleys_cloud/shared/utils/url_utils.dart';

class FailingRefreshGateway implements AuthGateway {
  final bool throwOnRefresh;
  final String? newAccessToken;

  const FailingRefreshGateway({
    this.throwOnRefresh = false,
    this.newAccessToken,
  });

  @override
  Future<AuthResult> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async =>
      const AuthResult(accessToken: 'init_token', refreshToken: 'init_refresh');

  @override
  Future<AuthResult> register({
    required String baseUrl,
    required String username,
    required String password,
  }) async =>
      const AuthResult(accessToken: 'init_token', refreshToken: 'init_refresh');

  @override
  Future<AuthResult> refresh({
    required String baseUrl,
    required String refreshToken,
  }) async {
    if (throwOnRefresh) {
      throw const SocketException('Refresh network failed');
    }
    return AuthResult(
      accessToken: newAccessToken ?? '',
      refreshToken: 'new_refresh',
    );
  }
}

void main() {
  group('UrlUtils Adversarial Edge Cases', () {
    test('buildEndpoint with query params in baseUrl', () {
      final uri = UrlUtils.buildEndpoint(
        'http://example.com/api?v=1',
        'download',
      );
      expect(uri.toString(), 'http://example.com/api/download?v=1');
    });

    test('buildEndpoint with multiple consecutive slashes', () {
      final uri = UrlUtils.buildEndpoint(
        'http://example.com///sub///',
        '///dir///file.txt',
      );
      expect(uri.toString(), 'http://example.com/sub/dir/file.txt');
    });

    test('buildEndpoint with spaces and unicode', () {
      final uri = UrlUtils.buildEndpoint('http://example.com', 'foo bar/baz');
      expect(uri.toString(), 'http://example.com/foo%20bar/baz');
    });

    test('buildApiEndpoint with baseUrl containing /api/v1', () {
      final uri = UrlUtils.buildApiEndpoint(
        'http://localhost:8080/api/v1',
        '/users',
      );
      expect(uri.toString(), 'http://localhost:8080/api/v1/users');
    });

    test('buildApiEndpoint with existing query parameters in baseUrl', () {
      final uri = UrlUtils.buildApiEndpoint(
        'http://localhost:8080/v1?token=abc',
        '/users',
        {'limit': '10'},
      );
      expect(
        uri.toString(),
        'http://localhost:8080/v1/api/users?token=abc&limit=10',
      );
    });

    test('parseUrlInput with user authentication in URL', () {
      final res = UrlUtils.parseUrlInput(
        'http://admin:secret@192.168.1.1:8080/path',
      );
      expect(res['baseUrl'], 'http://admin:secret@192.168.1.1');
      expect(res['port'], '8080');
    });

    test('parseUrlInput with IPv6 address', () {
      final res = UrlUtils.parseUrlInput('http://[::1]:8080');
      expect(res['baseUrl'], 'http://[::1]');
      expect(res['port'], '8080');
    });

    test('parseUrlInput with spaces surrounding host/port', () {
      final res = UrlUtils.parseUrlInput('  http://example.com : 8080 / ');
      expect(res['baseUrl'], 'http://example.com');
      expect(res['port'], '8080');
    });

    test('normalizeBaseUrl with invalid URL string', () {
      final res = UrlUtils.normalizeBaseUrl('http://example.com:8080 /api/');
      expect(res, 'http://example.com:8080/api');
    });
  });

  group('AuthenticatedHttpClient Adversarial Edge Cases', () {
    late InMemorySecretStore secretStore;

    setUp(() async {
      secretStore = InMemorySecretStore();
      await secretStore.saveTokens(
        serverId: 'srv1',
        accessToken: 'init_token',
        refreshToken: 'init_refresh',
      );
    });

    test('token refresh throws exception during 401 retry', () async {
      final authService = AuthService(
        secretStore: secretStore,
        gateway: const FailingRefreshGateway(throwOnRefresh: true),
      );

      final mockClient = MockClient((req) async {
        return http.Response('Unauthorized', 401);
      });

      final client = AuthenticatedHttpClient(
        authService: authService,
        serverId: 'srv1',
        baseUrl: 'http://localhost:8080',
        client: mockClient,
      );

      final resp = await client.get(
        Uri.parse('http://localhost:8080/api/test'),
      );
      expect(resp.statusCode, 401);
    });

    test('token refresh returns empty token', () async {
      final authService = AuthService(
        secretStore: secretStore,
        gateway: const FailingRefreshGateway(newAccessToken: ''),
      );

      final mockClient = MockClient((req) async {
        return http.Response('Unauthorized', 401);
      });

      final client = AuthenticatedHttpClient(
        authService: authService,
        serverId: 'srv1',
        baseUrl: 'http://localhost:8080',
        client: mockClient,
      );

      final resp = await client.get(
        Uri.parse('http://localhost:8080/api/test'),
      );
      expect(resp.statusCode, 401);
    });

    test(
      'sendAuthorized with explicitToken falls back to stored session token on 401',
      () async {
        final authService = AuthService(
          secretStore: secretStore,
          gateway: const FailingRefreshGateway(newAccessToken: 'new_token'),
        );

        final sentTokens = <String?>[];
        final mockClient = MockClient((req) async {
          final authHeader = req.headers['authorization'];
          sentTokens.add(authHeader);
          if (authHeader == 'Bearer custom_explicit_token') {
            return http.Response('Unauthorized', 401);
          }
          return http.Response('OK', 200);
        });

        final client = AuthenticatedHttpClient(
          authService: authService,
          serverId: 'srv1',
          baseUrl: 'http://localhost:8080',
          client: mockClient,
        );

        final resp = await client.sendAuthorized(
          explicitToken: 'custom_explicit_token',
          send: (token) => client.get(
            Uri.parse('http://localhost:8080/api/test'),
            headers: {'authorization': 'Bearer $token'},
          ),
        );

        expect(resp.statusCode, 200);
        expect(sentTokens, [
          'Bearer custom_explicit_token',
          'Bearer new_token',
        ]);
      },
    );

    test('onConnectionLost callback throws exception when invoked', () async {
      final authService = AuthService(
        secretStore: secretStore,
        gateway: const FailingRefreshGateway(),
      );

      final mockClient = MockClient((req) async {
        throw const SocketException('Network down');
      });

      final client = AuthenticatedHttpClient(
        authService: authService,
        serverId: 'srv1',
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        onConnectionLost: (msg) {
          throw StateError('Callback crashed!');
        },
      );

      final resp = await client.get(
        Uri.parse('http://localhost:8080/api/test'),
      );
      expect(resp.statusCode, 503);
    });

    test('streamedGet network exception during stream body read', () async {
      final authService = AuthService(
        secretStore: secretStore,
        gateway: const FailingRefreshGateway(),
      );

      final mockClient = MockClient.streaming((req, bodyStream) async {
        final controller = StreamController<List<int>>();
        controller.add([1, 2, 3]);
        controller.addError(
          const SocketException('Connection broken mid-stream'),
        );
        controller.close();
        return http.StreamedResponse(controller.stream, 200);
      });

      final client = AuthenticatedHttpClient(
        authService: authService,
        serverId: 'srv1',
        baseUrl: 'http://localhost:8080',
        client: mockClient,
      );

      final streamedResp = await client.streamedGet(
        Uri.parse('http://localhost:8080/api/stream'),
      );
      expect(streamedResp.statusCode, 200);
      expect(
        () async => await streamedResp.stream.toBytes(),
        throwsA(isA<SocketException>()),
      );
    });
  });

  group('ByteFormatter & FileIconUtils Adversarial Edge Cases', () {
    test('ByteFormatter boundary values and exabyte values', () {
      expect(ByteFormatter.format(0), '0 B');
      expect(ByteFormatter.format(-1), '0 B');
      expect(ByteFormatter.format(-9223372036854775808), '0 B');
      expect(ByteFormatter.format(1048524), '1023.9 KB');
      expect(ByteFormatter.format(1048575), '1024.0 KB');
      expect(ByteFormatter.format(9223372036854775807), '8.0 EB');
    });

    test('FileTypeUtils.isImage / isVideo / isAudio with full filenames', () {
      expect(FileTypeUtils.isImage('photo.png'), isTrue);
      expect(FileTypeUtils.isImage('.png'), isTrue);
      expect(FileTypeUtils.isImage('png'), isTrue);
      expect(FileTypeUtils.isVideo('movie.mp4'), isTrue);
      expect(FileTypeUtils.isAudio('song.mp3'), isTrue);
    });

    test(
      'FileIconUtils and FileTypeUtils on dotfiles and compound extensions',
      () {
        expect(FileIconUtils.iconForExtension('.tar.gz'), isNotNull);
        expect(FileTypeUtils.categoryForFile('.gitignore').icon, isNotNull);
        expect(FileTypeUtils.categoryForFile('.env').icon, isNotNull);
        expect(FileTypeUtils.categoryForFile('.pdf').icon, isNotNull);
        expect(FileTypeUtils.categoryForFile('.').icon, isNotNull);
        expect(FileTypeUtils.categoryForFile('').icon, isNotNull);
      },
    );
  });
}
