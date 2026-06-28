import 'package:crowleys_cloud/active_server_manager.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/biometric_auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:crowleys_cloud/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBiometricAuthService extends BiometricAuthService {
  _FakeBiometricAuthService(this.available);

  final bool available;

  @override
  Future<bool> canAuthenticate() async => available;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'renders settings sections and disables biometrics if unavailable',
    (tester) async {
      await _useTallScreen(tester);
      final manager =
          ActiveServerManager(
              store: ServerStore(),
              authService: AuthService(secretStore: InMemorySecretStore()),
            )
            ..activeServer = ServerProfile(
              id: 'srv',
              displayName: 'Home',
              baseUrl: 'http://localhost',
              authMode: 'login',
              lastUsedAt: DateTime.now().toUtc(),
              syncPrefs: const {},
            )
            ..servers = [
              ServerProfile(
                id: 'srv',
                displayName: 'Home',
                baseUrl: 'http://localhost',
                authMode: 'login',
                lastUsedAt: DateTime.now().toUtc(),
                syncPrefs: const {},
              ),
            ];

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            serverManager: manager,
            biometricAuthService: _FakeBiometricAuthService(false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Backup & Sync'), findsOneWidget);
      expect(find.text('Storage & Cache'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Security & Behavior'), findsOneWidget);
      expect(
        find.text('Biometrics are not available on this device.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('clear cache asks for confirmation', (tester) async {
    await _useTallScreen(tester);
    final manager = ActiveServerManager(
      store: ServerStore(),
      authService: AuthService(secretStore: InMemorySecretStore()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          serverManager: manager,
          biometricAuthService: _FakeBiometricAuthService(true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Clear cache'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear cache'));
    await tester.pumpAndSettle();

    expect(find.text('Clear cache?'), findsOneWidget);
  });

  testWidgets('sync settings stay hidden until enabled', (tester) async {
    await _useTallScreen(tester);
    final profile = ServerProfile(
      id: 'srv',
      displayName: 'Home',
      baseUrl: 'http://localhost',
      authMode: 'login',
      lastUsedAt: DateTime.now().toUtc(),
      syncPrefs: const {'syncEnabled': false},
    );
    final manager =
        ActiveServerManager(
            store: ServerStore(),
            authService: AuthService(secretStore: InMemorySecretStore()),
          )
          ..activeServer = profile
          ..servers = [profile];

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          serverManager: manager,
          biometricAuthService: _FakeBiometricAuthService(false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Folder and category sync'), findsOneWidget);
    expect(find.text('Server target directory'), findsNothing);
    expect(find.text('Categories to synchronize'), findsNothing);
    expect(find.text('Folders to synchronize'), findsNothing);
  });

  testWidgets('path dialogs close without framework assertion', (tester) async {
    await _useTallScreen(tester);
    final profile = ServerProfile(
      id: 'srv',
      displayName: 'Home',
      baseUrl: 'http://localhost',
      authMode: 'login',
      lastUsedAt: DateTime.now().toUtc(),
      syncPrefs: const {},
    );
    final manager =
        ActiveServerManager(
            store: ServerStore(),
            authService: AuthService(secretStore: InMemorySecretStore()),
          )
          ..activeServer = profile
          ..servers = [profile];

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          serverManager: manager,
          biometricAuthService: _FakeBiometricAuthService(false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Download path'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download path'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use default'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
  });

  testWidgets('sync category modal allows clearing all categories', (
    tester,
  ) async {
    await _useTallScreen(tester);
    final profile = ServerProfile(
      id: 'srv',
      displayName: 'Home',
      baseUrl: 'http://localhost',
      authMode: 'login',
      lastUsedAt: DateTime.now().toUtc(),
      syncPrefs: const {
        'syncEnabled': true,
        'syncCategories': ['photos', 'videos'],
      },
    );
    final manager =
        ActiveServerManager(
            store: ServerStore(),
            authService: AuthService(secretStore: InMemorySecretStore()),
          )
          ..activeServer = profile
          ..servers = [profile];

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          serverManager: manager,
          biometricAuthService: _FakeBiometricAuthService(false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Categories to synchronize'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(manager.activeServer?.syncPrefs['syncCategories'], isEmpty);
  });

  testWidgets('sync folder picker adds selected folder to server prefs', (
    tester,
  ) async {
    await _useTallScreen(tester);
    final profile = ServerProfile(
      id: 'srv',
      displayName: 'Home',
      baseUrl: 'http://localhost',
      authMode: 'login',
      lastUsedAt: DateTime.now().toUtc(),
      syncPrefs: const {'syncEnabled': true},
    );
    final manager =
        ActiveServerManager(
            store: ServerStore(),
            authService: AuthService(secretStore: InMemorySecretStore()),
          )
          ..activeServer = profile
          ..servers = [profile];

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          serverManager: manager,
          biometricAuthService: _FakeBiometricAuthService(false),
          localFolderPicker: (_) async => '/storage/emulated/0/Documents',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('/backup/'), findsOneWidget);

    await tester.tap(find.text('Folders to synchronize'));
    await tester.pumpAndSettle();

    expect(manager.activeServer?.syncPrefs['syncFolders'], [
      '/storage/emulated/0/Documents',
    ]);
  });

  testWidgets('sync folder list hides Android primary storage prefix', (
    tester,
  ) async {
    await _useTallScreen(tester);
    final profile = ServerProfile(
      id: 'srv',
      displayName: 'Home',
      baseUrl: 'http://localhost',
      authMode: 'login',
      lastUsedAt: DateTime.now().toUtc(),
      syncPrefs: const {
        'syncEnabled': true,
        'syncFolders': ['/storage/emulated/0/Documents'],
      },
    );
    final manager =
        ActiveServerManager(
            store: ServerStore(),
            authService: AuthService(secretStore: InMemorySecretStore()),
          )
          ..activeServer = profile
          ..servers = [profile];

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          serverManager: manager,
          biometricAuthService: _FakeBiometricAuthService(false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('/Documents'), findsWidgets);
    expect(find.text('/storage/emulated/0/Documents'), findsNothing);
  });

  testWidgets('settings server list can select and remove servers', (
    tester,
  ) async {
    await _useTallScreen(tester);
    final home = ServerProfile(
      id: 'home',
      displayName: 'Home',
      baseUrl: 'http://home.local',
      authMode: 'login',
      lastUsedAt: DateTime.now().toUtc(),
      syncPrefs: const {'syncEnabled': false},
    );
    final backup = ServerProfile(
      id: 'backup',
      displayName: 'Backup',
      baseUrl: 'http://backup.local',
      authMode: 'login',
      lastUsedAt: DateTime.now().toUtc(),
      syncPrefs: const {'syncEnabled': true},
    );
    final manager =
        ActiveServerManager(
            store: ServerStore(),
            authService: AuthService(secretStore: InMemorySecretStore()),
          )
          ..activeServer = home
          ..servers = [home, backup];

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          serverManager: manager,
          biometricAuthService: _FakeBiometricAuthService(false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Backup'));
    await tester.pumpAndSettle();
    expect(find.text('Server target directory'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove server').first);
    await tester.pumpAndSettle();

    expect(manager.servers.map((server) => server.id), ['backup']);
    expect(manager.activeServer?.id, 'backup');
  });
}

Future<void> _useTallScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
