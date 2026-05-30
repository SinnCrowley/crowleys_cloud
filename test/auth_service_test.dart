import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeAuthGateway implements AuthGateway {
  String? lastLoginUsername;
  String? lastLoginPassword;

  @override
  Future<AuthResult> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    lastLoginUsername = username;
    lastLoginPassword = password;
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
  test(
    'secure store keeps tokens process-only across store instances',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final firstStore = FlutterSecureSecretStore(
        storage: const FlutterSecureStorage(),
      );

      await firstStore.saveTokens(
        serverId: 'server1',
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      await firstStore.saveCredentials(
        serverId: 'server1',
        username: 'alice',
        password: 'secret',
      );

      expect(await firstStore.readToken('server1'), 'access');
      expect(await firstStore.readRefreshToken('server1'), 'refresh');

      final restartedStore = FlutterSecureSecretStore(
        storage: const FlutterSecureStorage(),
      );

      expect(await restartedStore.readToken('server1'), null);
      expect(await restartedStore.readRefreshToken('server1'), null);
      expect(await restartedStore.readLastUsername('server1'), 'alice');
      expect(await restartedStore.readSavedPassword('server1'), 'secret');
    },
  );

  test('authenticate stores session and credentials', () async {
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
    expect(await service.readLastUsername('server1'), 'alice');
    expect(await service.hasSavedCredentials('server1'), true);
    expect(await secrets.readSavedPassword('server1'), 'secret');
  });

  test('logout clears session and saved credentials', () async {
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
      mode: AuthMode.login,
    );

    await service.logout('server1');
    expect(await service.hasSession('server1'), false);
    expect(await service.readLastUsername('server1'), null);
    expect(await service.hasSavedCredentials('server1'), false);
    expect(await secrets.readSavedPassword('server1'), null);
  });

  test(
    'authenticateWithSavedCredentials replays saved login credentials',
    () async {
      final secrets = InMemorySecretStore();
      final gateway = _FakeAuthGateway();
      final service = AuthService(secretStore: secrets, gateway: gateway);
      await secrets.saveCredentials(
        serverId: 'server1',
        username: 'alice',
        password: 'secret',
      );

      await service.authenticateWithSavedCredentials(
        serverId: 'server1',
        baseUrl: 'https://test.local',
      );

      expect(gateway.lastLoginUsername, 'alice');
      expect(gateway.lastLoginPassword, 'secret');
      expect(await secrets.readToken('server1'), 'access-login');
    },
  );

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
