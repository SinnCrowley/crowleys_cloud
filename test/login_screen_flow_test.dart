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

import 'package:crowleys_cloud/active_server_manager.dart';
import 'package:crowleys_cloud/auth_card.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/biometric_auth_service.dart';
import 'package:crowleys_cloud/main.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helpers.dart';

class _FakeBiometricAuthService extends BiometricAuthService {
  @override
  Future<bool> canAuthenticate() async => false;
}

class _FakeServerStore extends ServerStore {
  _FakeServerStore(this.snapshot) : super(fileProvider: null);
  final ServerStoreSnapshot snapshot;

  @override
  Future<ServerStoreSnapshot> load() async => snapshot;

  @override
  Future<void> save({
    required List<ServerProfile> servers,
    required String? activeServerId,
  }) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpUntilReady(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('Login & Choose Server UI Cleanup Tests', () {
    testWidgets(
      'Login required screen has clean AppBar with no duplicate actions',
      (tester) async {
        final server = ServerProfile(
          id: 's1',
          displayName: 'Main Server',
          baseUrl: 'https://cloud.example.com:8443',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        );

        final manager = ActiveServerManager(
          store: _FakeServerStore(
            ServerStoreSnapshot(servers: [server], activeServerId: server.id),
          ),
          authService: AuthService(secretStore: InMemorySecretStore()),
        );

        await tester.pumpWidget(
          wrapWithLocalization(
            MainScreen(
              serverManager: manager,
              biometricAuthService: _FakeBiometricAuthService(),
            ),
            locale: const Locale('ru'),
          ),
        );
        await pumpUntilReady(tester);

        // Verify AppBar on the login required screen has no actions
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(
          appBar.actions,
          isNull,
          reason: 'Top app bar should have no actions on Login Required screen',
        );

        // Verify body contains the expected actions
        expect(find.text('Войти с паролем'), findsOneWidget);
        expect(find.text('Добавить сервер'), findsOneWidget);
        expect(find.text('Выбрать сервер'), findsOneWidget);
      },
    );

    testWidgets(
      'Password auth dialog does not show redundant edit, choose, add buttons at bottom',
      (tester) async {
        final server = ServerProfile(
          id: 's1',
          displayName: 'Main Server',
          baseUrl: 'https://cloud.example.com:8443',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        );

        final manager = ActiveServerManager(
          store: _FakeServerStore(
            ServerStoreSnapshot(servers: [server], activeServerId: server.id),
          ),
          authService: AuthService(secretStore: InMemorySecretStore()),
        );

        await tester.pumpWidget(
          wrapWithLocalization(
            MainScreen(
              serverManager: manager,
              biometricAuthService: _FakeBiometricAuthService(),
            ),
            locale: const Locale('ru'),
          ),
        );
        await pumpUntilReady(tester);

        // Tap "Войти с паролем"
        final passwordBtn = find.text('Войти с паролем');
        expect(passwordBtn, findsOneWidget);
        await tester.tap(passwordBtn);
        await pumpUntilReady(tester);

        // AuthCard is visible
        expect(find.byType(AuthCard), findsOneWidget);

        // Verify the redundant bottom buttons inside Dialog are gone
        final dialogFinder = find.byType(Dialog);
        expect(dialogFinder, findsOneWidget);

        // Verify "Изменить", "Выбрать сервер", "Добавить сервер" are not present in this dialog
        expect(
          find.descendant(
            of: dialogFinder,
            matching: find.widgetWithText(TextButton, 'Изменить'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: dialogFinder,
            matching: find.widgetWithText(TextButton, 'Выбрать сервер'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: dialogFinder,
            matching: find.widgetWithText(TextButton, 'Добавить сервер'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Choose server dialog has no top-right add button, and uses PopupMenu for actions',
      (tester) async {
        final s1 = ServerProfile(
          id: 's1',
          displayName: 'Home Cloud',
          baseUrl: 'https://cloud.home.net:8443',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        );
        final s2 = ServerProfile(
          id: 's2',
          displayName: 'Office Server',
          baseUrl: 'http://192.168.1.50:8080',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        );

        final manager = ActiveServerManager(
          store: _FakeServerStore(
            ServerStoreSnapshot(servers: [s1, s2], activeServerId: s1.id),
          ),
          authService: AuthService(secretStore: InMemorySecretStore()),
        );

        await tester.pumpWidget(
          wrapWithLocalization(
            MainScreen(
              serverManager: manager,
              biometricAuthService: _FakeBiometricAuthService(),
            ),
            locale: const Locale('ru'),
          ),
        );
        await pumpUntilReady(tester);

        // Tap "Сменить сервер" (because manager has > 1 servers)
        final chooseServerBtn = find.text('Сменить сервер');
        expect(chooseServerBtn, findsOneWidget);
        await tester.tap(chooseServerBtn);
        await pumpUntilReady(tester);

        final alertDialog = find.byType(AlertDialog);
        expect(alertDialog, findsOneWidget);

        // Verify Dialog Title does NOT contain an IconButton
        final titleFinder = find.descendant(
          of: alertDialog,
          matching: find.text('Выбрать сервер'),
        );
        expect(titleFinder, findsOneWidget);

        // Ensure title row does not have an Add IconButton
        // The Add button should only be in the actions at the bottom
        final addServerButtons = find.widgetWithText(
          TextButton,
          'Добавить сервер',
        );
        expect(addServerButtons, findsOneWidget);

        // Verify servers are displayed with clean URL and PopupMenuButton
        expect(
          find.descendant(of: alertDialog, matching: find.text('Home Cloud')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: alertDialog,
            matching: find.text('https://cloud.home.net:8443'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: alertDialog,
            matching: find.text('Office Server'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: alertDialog,
            matching: find.text('http://192.168.1.50:8080'),
          ),
          findsOneWidget,
        );

        // PopupMenuButton should be present for options
        expect(find.byType(PopupMenuButton<String>), findsNWidgets(2));

        // Tap the popup menu of the first server
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await pumpUntilReady(tester);

        // Verify Edit and Remove options are visible in the popup menu
        expect(
          find.descendant(
            of: find.byType(PopupMenuItem<String>),
            matching: find.text('Редактировать'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(PopupMenuItem<String>),
            matching: find.text('Удалить сервер'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Choose server dialog renders without layout overflow on 320px screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final s1 = ServerProfile(
          id: 's1',
          displayName: 'Very Long Server Display Name For Cloud Storage',
          baseUrl: 'https://very-long-server-address.myorganization.cloud:8443',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        );

        final manager = ActiveServerManager(
          store: _FakeServerStore(
            ServerStoreSnapshot(servers: [s1], activeServerId: s1.id),
          ),
          authService: AuthService(secretStore: InMemorySecretStore()),
        );

        await tester.pumpWidget(
          wrapWithLocalization(
            MainScreen(
              serverManager: manager,
              biometricAuthService: _FakeBiometricAuthService(),
            ),
            locale: const Locale('ru'),
          ),
        );
        await pumpUntilReady(tester);

        // Tap "Выбрать сервер"
        await tester.tap(find.text('Выбрать сервер'));
        await pumpUntilReady(tester);

        expect(tester.takeException(), isNull);
        final alertDialog = find.byType(AlertDialog);
        expect(alertDialog, findsOneWidget);
        expect(
          find.descendant(
            of: alertDialog,
            matching: find.text(
              'https://very-long-server-address.myorganization.cloud:8443',
            ),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
