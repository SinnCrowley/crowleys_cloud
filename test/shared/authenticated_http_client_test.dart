import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/shared/utils/authenticated_http_client.dart';

class MockAuthGateway implements AuthGateway {
  @override
  Future<AuthResult> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    return const AuthResult(
      accessToken: 'initial_token',
      refreshToken: 'refresh_tok',
    );
  }

  @override
  Future<AuthResult> register({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    return const AuthResult(
      accessToken: 'initial_token',
      refreshToken: 'refresh_tok',
    );
  }

  @override
  Future<AuthResult> refresh({
    required String baseUrl,
    required String refreshToken,
  }) async {
    return const AuthResult(
      accessToken: 'refreshed_token',
      refreshToken: 'new_refresh_tok',
    );
  }
}

void main() {
  group('AuthenticatedHttpClient', () {
    late InMemorySecretStore secretStore;
    late AuthService authService;

    setUp(() async {
      secretStore = InMemorySecretStore();
      authService = AuthService(
        secretStore: secretStore,
        gateway: MockAuthGateway(),
      );
      await secretStore.saveTokens(
        serverId: 'srv1',
        accessToken: 'initial_token',
        refreshToken: 'refresh_tok',
      );
    });

    test('attaches bearer token to get request', () async {
      String? authHeader;
      final mockClient = MockClient((request) async {
        authHeader = request.headers['authorization'];
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final client = AuthenticatedHttpClient(
        authService: authService,
        serverId: 'srv1',
        baseUrl: 'http://localhost:8080',
        client: mockClient,
      );

      final response = await client.get(
        Uri.parse('http://localhost:8080/api/dir'),
      );
      expect(response.statusCode, 200);
      expect(authHeader, 'Bearer initial_token');
    });

    test(
      'automatically refreshes token on 401 response and retries request',
      () async {
        var requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            expect(request.headers['authorization'], 'Bearer initial_token');
            return http.Response('Unauthorized', 401);
          } else {
            expect(request.headers['authorization'], 'Bearer refreshed_token');
            return http.Response(jsonEncode({'status': 'ok'}), 200);
          }
        });

        final client = AuthenticatedHttpClient(
          authService: authService,
          serverId: 'srv1',
          baseUrl: 'http://localhost:8080',
          client: mockClient,
        );

        final response = await client.get(
          Uri.parse('http://localhost:8080/api/dir'),
        );
        expect(response.statusCode, 200);
        expect(requestCount, 2);
      },
    );
  });
}
