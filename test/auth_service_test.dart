import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<AuthResult> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    return const AuthResult(
      accessToken: 'access-login',
      refreshToken: 'refresh-login',
    );
  }

  @override
  Future<AuthResult> refresh({
    required String baseUrl,
    required String refreshToken,
  }) async {
    return const AuthResult(
      accessToken: 'access-refresh',
      refreshToken: 'refresh-rotated',
    );
  }

  @override
  Future<AuthResult> register({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    return const AuthResult(
      accessToken: 'access-register',
      refreshToken: 'refresh-register',
    );
  }
}

void main() {
  test('authenticate stores token and hasSession reflects state', () async {
    final secrets = InMemorySecretStore();
    final service = AuthService(
      secretStore: secrets,
      gateway: _FakeAuthGateway(),
    );

    await service.authenticate(
      serverId: 'server1',
      baseUrl: 'https://test.local',
      username: 'alice',
      password: 'secret',
      mode: AuthMode.register,
    );

    expect(await service.hasSession('server1'), true);
    expect(await secrets.readRefreshToken('server1'), 'refresh-register');

    await service.logout('server1');
    expect(await service.hasSession('server1'), false);
  });

  test('checkSession returns authorized on 2xx response', () async {
    final secrets = InMemorySecretStore();
    final service = AuthService(
      secretStore: secrets,
      gateway: _FakeAuthGateway(),
      client: MockClient((request) async {
        expect(request.url.path, '/api/dir');
        expect(request.url.queryParameters['scope'], 'private');
        return http.Response('{"entries":[]}', 200);
      }),
    );
    await secrets.saveTokens(
      serverId: 'server1',
      accessToken: 'token',
      refreshToken: 'refresh',
    );

    final result = await service.checkSession(
      serverId: 'server1',
      baseUrl: 'http://localhost:8080',
    );
    expect(result.status, SessionCheckStatus.authorized);
  });

  test('checkSession returns noSession when token is missing', () async {
    final service = AuthService(
      secretStore: InMemorySecretStore(),
      gateway: _FakeAuthGateway(),
      client: MockClient((request) async => http.Response('', 500)),
    );

    final result = await service.checkSession(
      serverId: 'server1',
      baseUrl: 'http://localhost:8080',
    );
    expect(result.status, SessionCheckStatus.noSession);
  });
}
