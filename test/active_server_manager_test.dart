import 'package:crowleys_cloud/active_server_manager.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeServerStore extends ServerStore {
  _FakeServerStore(this.snapshot) : super(fileProvider: null);

  ServerStoreSnapshot snapshot;
  List<ServerProfile> savedServers = [];
  String? savedActiveId;

  @override
  Future<ServerStoreSnapshot> load() async => snapshot;

  @override
  Future<void> save({
    required List<ServerProfile> servers,
    required String? activeServerId,
  }) async {
    savedServers = servers;
    savedActiveId = activeServerId;
  }
}

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<AuthResult> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    return const AuthResult(accessToken: 'access', refreshToken: 'refresh');
  }

  @override
  Future<AuthResult> refresh({
    required String baseUrl,
    required String refreshToken,
  }) async {
    return const AuthResult(accessToken: 'access2', refreshToken: 'refresh2');
  }

  @override
  Future<AuthResult> register({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    return const AuthResult(accessToken: 'access', refreshToken: 'refresh');
  }
}

void main() {
  test(
    'initialize falls back to most recent server when active id missing',
    () async {
      final older = ServerProfile(
        id: 'a',
        displayName: 'A',
        baseUrl: 'https://a',
        authMode: 'register',
        lastUsedAt: DateTime.utc(2026, 1, 1),
        syncPrefs: const {},
      );
      final newer = ServerProfile(
        id: 'b',
        displayName: 'B',
        baseUrl: 'https://b',
        authMode: 'login',
        lastUsedAt: DateTime.utc(2026, 5, 1),
        syncPrefs: const {},
      );

      final store =
          _FakeServerStore(
              const ServerStoreSnapshot(servers: [], activeServerId: 'missing'),
            )
            ..snapshot = ServerStoreSnapshot(
              servers: [older, newer],
              activeServerId: 'missing',
            );

      final auth = AuthService(
        secretStore: InMemorySecretStore(),
        gateway: _FakeAuthGateway(),
      );
      await auth.authenticate(
        serverId: 'b',
        baseUrl: newer.baseUrl,
        username: 'user',
        password: 'pass',
        mode: AuthMode.login,
      );

      final manager = ActiveServerManager(store: store, authService: auth);
      await manager.initialize();

      expect(manager.activeServer?.id, 'b');
      expect(manager.requiresAuth, false);
    },
  );

  test('remove active server picks fallback server and persists', () async {
    final s1 = ServerProfile(
      id: 's1',
      displayName: 'One',
      baseUrl: 'https://one',
      authMode: 'login',
      lastUsedAt: DateTime.utc(2026, 5, 1),
      syncPrefs: const {},
    );
    final s2 = ServerProfile(
      id: 's2',
      displayName: 'Two',
      baseUrl: 'https://two',
      authMode: 'register',
      lastUsedAt: DateTime.utc(2026, 5, 2),
      syncPrefs: const {},
    );

    final store = _FakeServerStore(
      ServerStoreSnapshot(servers: [s1, s2], activeServerId: 's2'),
    );
    final auth = AuthService(
      secretStore: InMemorySecretStore(),
      gateway: _FakeAuthGateway(),
    );
    final manager = ActiveServerManager(store: store, authService: auth);
    await manager.initialize();

    await manager.removeServer('s2');

    expect(manager.activeServer?.id, 's1');
    expect(store.savedActiveId, 's1');
    expect(store.savedServers.length, 1);
  });
}
