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

import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/shared/utils/scram_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthGateway implements AuthGateway {
  String? lastLoginUsername;
  String? lastLoginPassword;

  @override
  Future<bool> ping(
    String baseUrl, {
    Duration timeout = const Duration(seconds: 4),
  }) async => true;

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'pending registration creates no session or saved credentials',
    () async {
      final secrets = InMemorySecretStore();
      final service = AuthService(
        secretStore: secrets,
        gateway: HttpAuthGateway(
          client: MockClient((request) async {
            if (request.url.path == '/api/ping') {
              return http.Response('{"ok":true}', 200);
            }
            expect(request.url.path, '/api/register');
            return http.Response(
              '{"status":"pending","code":"registration_pending"}',
              202,
            );
          }),
        ),
      );
      expect(
        await service.authenticate(
          serverId: 'pending',
          baseUrl: 'http://localhost:8080',
          username: 'new-user',
          password: 'secret',
          mode: AuthMode.register,
        ),
        isFalse,
      );
      expect(await secrets.readToken('pending'), isNull);
      expect(await secrets.readRefreshToken('pending'), isNull);
      expect(await secrets.readLastUsername('pending'), isNull);
      expect(await secrets.readSavedPassword('pending'), isNull);
    },
  );

  test('account error codes have localized messages', () {
    for (final code in [
      'registration_pending',
      'registration_closed',
      'account_blocked',
      'password_reset_required',
      'maintenance',
      'quota_exceeded',
    ]) {
      final message = accountErrorMessage(jsonEncode({'code': code}));
      expect(message, isNotNull);
      expect(message, isNot(code));
    }
  });

  test(
    'secure store keeps tokens process-only across store instances',
    () async {
      SharedPreferences.setMockInitialValues({
        'settings.tokenLifetime': 'everyOpen',
      });
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

  test('secure store restores tokens within configured lifetime', () async {
    SharedPreferences.setMockInitialValues({
      'settings.tokenLifetime': 'oneHour',
    });
    FlutterSecureStorage.setMockInitialValues({});
    final firstStore = FlutterSecureSecretStore(
      storage: const FlutterSecureStorage(),
    );

    await firstStore.saveTokens(
      serverId: 'server1',
      accessToken: 'access',
      refreshToken: 'refresh',
    );

    final restartedStore = FlutterSecureSecretStore(
      storage: const FlutterSecureStorage(),
    );

    expect(await restartedStore.readToken('server1'), 'access');
    expect(await restartedStore.readRefreshToken('server1'), 'refresh');
  });

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

  test('changePassword posts new password and refreshes saved login', () async {
    final secrets = InMemorySecretStore();
    final gateway = _FakeAuthGateway();
    final service = AuthService(
      secretStore: secrets,
      gateway: gateway,
      client: MockClient((request) async {
        if (request.url.path == '/api/account/reauth/challenge') {
          return http.Response(
            jsonEncode({
              'ok': true,
              'auth_mode': 'scram-argon2id',
              'salt': '0102030405060708090a0b0c0d0e0f10',
              'm': 19456,
              't': 2,
              'p': 1,
              'nonce': 'client_server',
              'challenge_token': 'token.9999999999',
            }),
            200,
          );
        }
        expect(request.method, 'POST');
        expect(request.url.path, '/api/account/password');
        expect(request.headers['authorization'], 'Bearer access');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('salt'), isTrue);
        expect(body.containsKey('stored_key'), isTrue);
        expect(body.containsKey('server_key'), isTrue);
        expect(body.containsKey('current_client_proof'), isTrue);
        expect(body.containsKey('current_nonce'), isTrue);
        expect(body.containsKey('current_challenge_token'), isTrue);
        expect(body['kdf'], 'argon2id');
        expect(body['m'], 19456);
        return http.Response('{"ok":true}', 200);
      }),
    );
    await secrets.saveTokens(
      serverId: 'server1',
      accessToken: 'access',
      refreshToken: 'refresh',
    );
    await secrets.saveCredentials(
      serverId: 'server1',
      username: 'alice',
      password: 'old-secret',
    );

    await service.changePassword(
      serverId: 'server1',
      baseUrl: 'http://localhost:8080',
      newPassword: 'new-secret',
    );

    expect(gateway.lastLoginUsername, 'alice');
    expect(gateway.lastLoginPassword, 'new-secret');
    expect(await secrets.readSavedPassword('server1'), 'new-secret');
  });

  test(
    'deleteAccount deletes account endpoint and clears local auth',
    () async {
      final secrets = InMemorySecretStore();
      final service = AuthService(
        secretStore: secrets,
        gateway: _FakeAuthGateway(),
        client: MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/api/account');
          expect(request.headers['authorization'], 'Bearer access');
          return http.Response('{"ok":true}', 200);
        }),
      );
      await secrets.saveTokens(
        serverId: 'server1',
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      await secrets.saveCredentials(
        serverId: 'server1',
        username: 'alice',
        password: 'secret',
      );

      await service.deleteAccount(
        serverId: 'server1',
        baseUrl: 'http://localhost:8080',
      );

      expect(await secrets.readToken('server1'), null);
      expect(await secrets.readLastUsername('server1'), null);
    },
  );

  test('requestPasswordReset posts correct username and succeeds', () async {
    final service = AuthService(
      secretStore: InMemorySecretStore(),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/reset-password/request');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['username'], 'bob');
        return http.Response('{"ok":true}', 200);
      }),
    );

    await service.requestPasswordReset(
      baseUrl: 'http://localhost:8080',
      username: 'bob',
    );
  });

  test(
    'verifyPasswordReset posts code and new password and succeeds',
    () async {
      final service = AuthService(
        secretStore: InMemorySecretStore(),
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/auth/reset-password/verify');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['username'], 'bob');
          expect(body['code'], '123456');
          expect(body.containsKey('salt'), isTrue);
          expect(body.containsKey('stored_key'), isTrue);
          expect(body.containsKey('server_key'), isTrue);
          expect(body['kdf'], 'argon2id');
          expect(body['m'], 19456);
          return http.Response('{"ok":true}', 200);
        }),
      );

      await service.verifyPasswordReset(
        baseUrl: 'http://localhost:8080',
        username: 'bob',
        code: '123456',
        newPassword: 'brand-new-secret',
      );
    },
  );

  test('HttpAuthGateway.register sends SCRAM keys without password', () async {
    final gateway = HttpAuthGateway(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/register');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['username'], 'alice');
        expect(body['password'], isNull);
        expect(body.containsKey('salt'), isTrue);
        expect(body.containsKey('stored_key'), isTrue);
        expect(body.containsKey('server_key'), isTrue);
        expect(body['kdf'], 'argon2id');
        expect(body['m'], 19456);
        return http.Response(
          '{"access_token":"acc1","refresh_token":"ref1"}',
          200,
        );
      }),
    );

    final res = await gateway.register(
      baseUrl: 'http://localhost:8080',
      username: 'alice',
      password: 'password123',
    );
    expect(res.accessToken, 'acc1');
    expect(res.refreshToken, 'ref1');
  });

  test(
    'HttpAuthGateway.login performs SCRAM challenge-response with mutual auth',
    () async {
      String? expectedSig;
      final gateway = HttpAuthGateway(
        client: MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path == '/api/auth/challenge') {
            expect(request.url.queryParameters['username'], 'alice');
            final clientNonce = request.url.queryParameters['nonce']!;
            final nonce = '${clientNonce}servernonce123';
            const saltHex = '0102030405060708090a0b0c0d0e0f10';
            const memCostKb = 19456;
            const timeCost = 2;
            const lanes = 1;

            final authMsg = ScramUtils.scramArgon2idAuthMessage(
              'alice',
              nonce,
              saltHex,
              memCostKb,
              timeCost,
              lanes,
            );
            final proof = await ScramUtils.computeArgon2idProof(
              password: 'password123',
              saltHex: saltHex,
              memCostKb: memCostKb,
              timeCost: timeCost,
              lanes: lanes,
              authMessage: authMsg,
            );
            expectedSig = proof.expectedServerSignatureHex;

            return http.Response(
              jsonEncode({
                'auth_mode': 'scram-argon2id',
                'salt': saltHex,
                'm': memCostKb,
                't': timeCost,
                'p': lanes,
                'nonce': nonce,
                'challenge_token': 'sig123.9999999999',
              }),
              200,
            );
          } else if (request.method == 'POST' &&
              request.url.path == '/api/login') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['username'], 'alice');
            expect(body['password'], isNull);
            expect(body.containsKey('client_proof'), isTrue);
            expect(body['challenge_token'], 'sig123.9999999999');

            return http.Response(
              jsonEncode({
                'access_token': 'acc-scram',
                'refresh_token': 'ref-scram',
                'server_signature': expectedSig,
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        }),
      );

      final res = await gateway.login(
        baseUrl: 'http://localhost:8080',
        username: 'alice',
        password: 'password123',
      );
      expect(res.accessToken, 'acc-scram');
      expect(res.refreshToken, 'ref-scram');
    },
  );

  test(
    'HttpAuthGateway.login throws if server signature does not match',
    () async {
      final gateway = HttpAuthGateway(
        client: MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path == '/api/auth/challenge') {
            return http.Response(
              jsonEncode({
                'auth_mode': 'scram',
                'salt': '0102030405060708090a0b0c0d0e0f10',
                'iterations': 4096,
                'nonce': 'random_nonce_123',
                'challenge_token': 'sig.9999999999',
              }),
              200,
            );
          } else if (request.method == 'POST' &&
              request.url.path == '/api/login') {
            return http.Response(
              jsonEncode({
                'access_token': 'acc-scram',
                'refresh_token': 'ref-scram',
                'server_signature': 'invalid_signature_hex',
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        }),
      );

      expect(
        () => gateway.login(
          baseUrl: 'http://localhost:8080',
          username: 'alice',
          password: 'password123',
        ),
        throwsA(isA<AuthException>()),
      );
    },
  );

  test(
    'OverrideSyncTokenSecretStore overrides readSyncToken and delegates others',
    () async {
      final delegateStore = InMemorySecretStore();
      await delegateStore.saveTokens(
        serverId: 'srv1',
        accessToken: 'acc1',
        refreshToken: 'ref1',
      );
      await delegateStore.saveSyncToken(
        serverId: 'srv1',
        syncToken: 'sync-delegate',
      );

      final overrideStore = OverrideSyncTokenSecretStore(
        delegate: delegateStore,
        overrideSyncToken: 'sync-override',
      );

      expect(await overrideStore.readToken('srv1'), 'acc1');
      expect(await overrideStore.readSyncToken('srv1'), 'sync-override');

      final overrideStoreEmpty = OverrideSyncTokenSecretStore(
        delegate: delegateStore,
        overrideSyncToken: null,
      );
      expect(await overrideStoreEmpty.readSyncToken('srv1'), 'sync-delegate');
    },
  );

  test(
    'FlutterSecureSecretStore falls back to session memory if secure storage write throws',
    () async {
      final store = FlutterSecureSecretStore(
        storage: const _FailingSecureStorage(),
      );

      // Should not throw even when platform KeyStore fails
      await store.saveTokens(
        serverId: 'srv_fail',
        accessToken: 'mem_access',
        refreshToken: 'mem_refresh',
      );
      await store.saveCredentials(
        serverId: 'srv_fail',
        username: 'alice',
        password: 'password123',
      );

      expect(await store.readToken('srv_fail'), 'mem_access');
      expect(await store.readRefreshToken('srv_fail'), 'mem_refresh');
      expect(await store.readLastUsername('srv_fail'), 'alice');
      expect(await store.readSavedPassword('srv_fail'), 'password123');
    },
  );
}

class _FailingSecureStorage extends FlutterSecureStorage {
  const _FailingSecureStorage();

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw PlatformException(
      code: 'KEYSTORE_ERROR',
      message: 'Android KeyStore corrupted or unavailable',
    );
  }
}
