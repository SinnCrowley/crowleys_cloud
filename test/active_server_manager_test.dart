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

import 'dart:ui';

import 'package:crowleys_cloud/active_server_manager.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
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

  group('ActiveServerManager Localization & Error Handling', () {
    test(
      'reportConnectionError sets localized default message in English and Russian',
      () async {
        final s1 = ServerProfile(
          id: 's1',
          displayName: 'Server 1',
          baseUrl: 'https://s1',
          authMode: 'login',
          lastUsedAt: DateTime.utc(2026, 5, 1),
          syncPrefs: const {},
        );
        final store = _FakeServerStore(
          ServerStoreSnapshot(servers: [s1], activeServerId: 's1'),
        );
        final auth = AuthService(
          secretStore: InMemorySecretStore(),
          gateway: _FakeAuthGateway(),
        );
        final manager = ActiveServerManager(store: store, authService: auth);
        await manager.initialize();

        // Test default without l10n (English fallback)
        manager.reportConnectionError(serverId: 's1');
        expect(
          manager.connectionErrorMessage,
          'Unable to connect to the active server.',
        );

        // Test with Russian l10n
        final ruL10n = lookupAppLocalizations(const Locale('ru'));
        manager.reportConnectionError(serverId: 's1', l10n: ruL10n);
        expect(
          manager.connectionErrorMessage,
          'Не удаётся подключиться к активному серверу.',
        );

        // Test with English l10n
        final enL10n = lookupAppLocalizations(const Locale('en'));
        manager.reportConnectionError(serverId: 's1', l10n: enL10n);
        expect(
          manager.connectionErrorMessage,
          'Unable to connect to the active server.',
        );

        // Test with custom message
        manager.reportConnectionError(
          serverId: 's1',
          message: 'Custom network timeout',
        );
        expect(manager.connectionErrorMessage, 'Custom network timeout');

        // Test reporting error for inactive server is ignored
        manager.reportConnectionError(
          serverId: 'other-server',
          message: 'Ignored error',
        );
        expect(manager.connectionErrorMessage, 'Custom network timeout');
      },
    );

    test(
      'lifecycle methods accept optional l10n parameter and execute cleanly',
      () async {
        final s1 = ServerProfile(
          id: 's1',
          displayName: 'Server 1',
          baseUrl: 'https://s1',
          authMode: 'login',
          lastUsedAt: DateTime.utc(2026, 5, 1),
          syncPrefs: const {},
        );
        final s2 = ServerProfile(
          id: 's2',
          displayName: 'Server 2',
          baseUrl: 'https://s2',
          authMode: 'login',
          lastUsedAt: DateTime.utc(2026, 5, 2),
          syncPrefs: const {},
        );
        final store = _FakeServerStore(
          ServerStoreSnapshot(servers: [s1, s2], activeServerId: 's1'),
        );
        final auth = AuthService(
          secretStore: InMemorySecretStore(),
          gateway: _FakeAuthGateway(),
        );
        final manager = ActiveServerManager(store: store, authService: auth);

        final ruL10n = lookupAppLocalizations(const Locale('ru'));
        await manager.initialize(ruL10n);
        expect(manager.isReady, true);
        expect(manager.activeServer?.id, 's1');

        await manager.switchActive('s2', ruL10n);
        expect(manager.activeServer?.id, 's2');

        await manager.markAuthed('s2', ruL10n);
        expect(manager.activeServer?.id, 's2');

        await manager.removeServer('s2', ruL10n);
        expect(manager.activeServer?.id, 's1');
      },
    );
  });
}
