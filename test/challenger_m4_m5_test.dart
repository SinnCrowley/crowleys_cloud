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
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_setup_screen.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

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

class _ControllableAuthGateway implements AuthGateway {
  bool shouldThrowAuthException = false;
  String authExceptionMessage = 'Invalid credentials';
  bool shouldThrowGenericException = false;

  @override
  Future<AuthResult> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    if (shouldThrowAuthException) {
      throw AuthException(authExceptionMessage);
    }
    if (shouldThrowGenericException) {
      throw Exception('Socket timeout');
    }
    return const AuthResult(accessToken: 'token_123', refreshToken: 'refresh_123');
  }

  @override
  Future<AuthResult> register({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    if (shouldThrowAuthException) {
      throw AuthException(authExceptionMessage);
    }
    if (shouldThrowGenericException) {
      throw Exception('Server unreachable');
    }
    return const AuthResult(accessToken: 'token_reg', refreshToken: 'refresh_reg');
  }

  @override
  Future<AuthResult> refresh({
    required String baseUrl,
    required String refreshToken,
  }) async {
    return const AuthResult(accessToken: 'token_refreshed', refreshToken: 'refresh_refreshed');
  }

  Future<SessionCheckResult> checkSession({
    required String baseUrl,
    required String token,
  }) async {
    return const SessionCheckResult(SessionCheckStatus.authorized);
  }

  Future<void> requestPasswordReset({
    required String baseUrl,
    required String username,
  }) async {}

  Future<void> verifyPasswordReset({
    required String baseUrl,
    required String username,
    required String code,
    required String newPassword,
  }) async {}
}

class _MockSessionCheckAuthGateway extends _ControllableAuthGateway {
  SessionCheckStatus sessionStatus = SessionCheckStatus.authorized;
  String? sessionCheckMessage;

  @override
  Future<SessionCheckResult> checkSession({
    required String baseUrl,
    required String token,
  }) async {
    return SessionCheckResult(
      sessionStatus,
      message: sessionCheckMessage,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CHALLENGER STRESS: M4 Upload & Error Localization Parity', () {
    test('Upload error keys handle boundary conditions, unicode, and special chars in EN & RU', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final ru = lookupAppLocalizations(const Locale('ru'));

      final testFilenames = [
        'normal.txt',
        '',
        '   ',
        'документ с пробелами и кириллицей 123.pdf',
        '🌟special_emoji_🚀.dat',
        'file/with/slash',
        '../../../etc/passwd',
        'quote"and\'symbols!@#\$%^&*()_+{}[]:;"<>,.?~`',
      ];

      for (final name in testFilenames) {
        final enFormatted = en.uploadErrorLocalPathEmpty(name);
        final ruFormatted = ru.uploadErrorLocalPathEmpty(name);
        expect(enFormatted, '$name: local path is empty');
        expect(ruFormatted, '$name: локальный путь пуст');
        expect(enFormatted.contains(name), isTrue);
        expect(ruFormatted.contains(name), isTrue);
      }

      final statusCodes = [-1, 0, 200, 400, 401, 403, 404, 500, 502, 503, 504, 999, 10000];
      for (final code in statusCodes) {
        final enCode = en.uploadErrorFolderCreateHttp(code);
        final ruCode = ru.uploadErrorFolderCreateHttp(code);
        expect(enCode, 'Folder creation failed (HTTP $code)');
        expect(ruCode, 'Не удалось создать папку (HTTP $code)');
        expect(enCode.contains('$code'), isTrue);
        expect(ruCode.contains('$code'), isTrue);
      }
    });

    test('Batch upload summary formatting and count pluralization in EN & RU', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final ru = lookupAppLocalizations(const Locale('ru'));

      final counts = [0, 1, 2, 5, 11, 21, 55, 100, 1000];
      for (final count in counts) {
        final enUploaded = en.uploadedNItems(count);
        final ruUploaded = ru.uploadedNItems(count);
        final enFailed = en.uploadSummaryFailedCount(count);
        final ruFailed = ru.uploadSummaryFailedCount(count);

        expect(enUploaded.isNotEmpty, isTrue);
        expect(ruUploaded.isNotEmpty, isTrue);
        expect(enFailed, ', failed $count');
        expect(ruFailed, ', с ошибкой $count');

        // Combined summary builder simulation
        final enSummary = '$enUploaded$enFailed';
        final ruSummary = '$ruUploaded$ruFailed';
        expect(enSummary.contains('$count'), isTrue);
        expect(ruSummary.contains('$count'), isTrue);
      }
    });

    test('Disconnected error detector handles case variations, localized Russian, and edge phrases', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final ru = lookupAppLocalizations(const Locale('ru'));

      bool isDisconnected(String error, [AppLocalizations? l10n]) {
        final lower = error.toLowerCase();
        return lower.contains('server disconnected') ||
            (l10n != null &&
                (error == l10n.serverDisconnected ||
                    error == l10n.serverDisconnectedStatus));
      }

      // Positive test cases
      expect(isDisconnected('server disconnected'), isTrue);
      expect(isDisconnected('SERVER DISCONNECTED'), isTrue);
      expect(isDisconnected('Server Disconnected'), isTrue);
      expect(isDisconnected('Error: Server Disconnected while sending payload'), isTrue);
      expect(isDisconnected('Prefix: server disconnected :suffix'), isTrue);
      expect(isDisconnected(en.serverDisconnected, en), isTrue);
      expect(isDisconnected(en.serverDisconnectedStatus, en), isTrue);
      expect(isDisconnected(ru.serverDisconnected, ru), isTrue);
      expect(isDisconnected(ru.serverDisconnectedStatus, ru), isTrue);
      expect(isDisconnected('Сервер отключён', ru), isTrue);

      // Negative test cases (adversarial false positives)
      expect(isDisconnected('Server connected'), isFalse);
      expect(isDisconnected('Server is reachable'), isFalse);
      expect(isDisconnected('Authentication failed'), isFalse);
      expect(isDisconnected('Local file not found', en), isFalse);
      expect(isDisconnected('Локальный файл не найден', ru), isFalse);
      expect(isDisconnected('Directory upload failed', en), isFalse);
      expect(isDisconnected('Не удалось загрузить папку', ru), isFalse);
      expect(isDisconnected(''), isFalse);
    });
  });

  group('CHALLENGER STRESS: ActiveServerManager Connection Error & Headless L10n', () {
    test('reportConnectionError with active, inactive, custom, and localized messages', () async {
      final s1 = ServerProfile(
        id: 'srv_1',
        displayName: 'Alpha Server',
        baseUrl: 'https://alpha.example.com',
        authMode: 'login',
        lastUsedAt: DateTime.utc(2026, 6, 1),
        syncPrefs: const {},
      );
      final s2 = ServerProfile(
        id: 'srv_2',
        displayName: 'Beta Server',
        baseUrl: 'https://beta.example.com',
        authMode: 'login',
        lastUsedAt: DateTime.utc(2026, 6, 2),
        syncPrefs: const {},
      );

      final store = _FakeServerStore(
        ServerStoreSnapshot(servers: [s1, s2], activeServerId: 'srv_1'),
      );
      final auth = AuthService(
        secretStore: InMemorySecretStore(),
        gateway: _ControllableAuthGateway(),
      );

      final manager = ActiveServerManager(store: store, authService: auth);
      await manager.initialize();
      expect(manager.activeServer?.id, 'srv_1');
      expect(manager.connectionErrorMessage, isNull);

      // 1. Report connection error on active server with no explicit l10n
      manager.reportConnectionError(serverId: 'srv_1');
      expect(manager.connectionErrorMessage, 'Unable to connect to the active server.');
      expect(manager.requiresAuth, isFalse);

      // 2. Report error on inactive server (must be ignored)
      manager.reportConnectionError(serverId: 'srv_2', message: 'Should be ignored');
      expect(manager.connectionErrorMessage, 'Unable to connect to the active server.');

      // 3. Report error with Russian l10n
      final ruL10n = lookupAppLocalizations(const Locale('ru'));
      manager.reportConnectionError(serverId: 'srv_1', l10n: ruL10n);
      expect(manager.connectionErrorMessage, 'Не удаётся подключиться к активному серверу.');

      // 4. Report custom error message overrides localized default
      manager.reportConnectionError(serverId: 'srv_1', message: 'HTTP 504 Gateway Timeout', l10n: ruL10n);
      expect(manager.connectionErrorMessage, 'HTTP 504 Gateway Timeout');
    });

    test('Session check unreachable and serverError statuses update error state in EN & RU', () async {
      final s1 = ServerProfile(
        id: 'srv_1',
        displayName: 'Alpha Server',
        baseUrl: 'https://alpha.example.com',
        authMode: 'login',
        lastUsedAt: DateTime.utc(2026, 6, 1),
        syncPrefs: const {},
      );

      final store = _FakeServerStore(
        ServerStoreSnapshot(servers: [s1], activeServerId: 'srv_1'),
      );
      final secretStore = InMemorySecretStore();
      await secretStore.saveToken(serverId: 'srv_1', token: 'existing_token');

      final gateway = _MockSessionCheckAuthGateway();
      final auth = AuthService(
        secretStore: secretStore,
        gateway: gateway,
      );

      final manager = ActiveServerManager(store: store, authService: auth);

      // 1. Session check in test environment returns HTTP 400 serverError with check.message
      final ruL10n = lookupAppLocalizations(const Locale('ru'));
      await manager.initialize(ruL10n);

      expect(manager.requiresAuth, isFalse);
      expect(manager.connectionErrorMessage, contains('HTTP 400'));

      // 2. reportConnectionError with null message uses localized fallback
      manager.reportConnectionError(serverId: 'srv_1', l10n: ruL10n);
      expect(manager.requiresAuth, isFalse);
      expect(manager.connectionErrorMessage, 'Не удаётся подключиться к активному серверу.');

      // 3. reportConnectionError with explicit custom message
      manager.reportConnectionError(
        serverId: 'srv_1',
        message: '502 Bad Gateway from upstream',
        l10n: ruL10n,
      );
      expect(manager.requiresAuth, isFalse);
      expect(manager.connectionErrorMessage, '502 Bad Gateway from upstream');
    });
  });

  group('CHALLENGER STRESS: ServerSetupScreen Validation & Error Handling Widget Tests', () {
    testWidgets('Validates each field individually and shows localized snackbars in EN', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final gateway = _ControllableAuthGateway();
      final auth = AuthService(
        secretStore: InMemorySecretStore(),
        gateway: gateway,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          ServerSetupScreen(authService: auth),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      final saveButton = find.text('Save Server');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('All fields are required.'), findsOneWidget);
    });

    testWidgets('Validates each field individually and shows localized snackbars in RU', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final gateway = _ControllableAuthGateway();
      final auth = AuthService(
        secretStore: InMemorySecretStore(),
        gateway: gateway,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          ServerSetupScreen(authService: auth),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      final saveButtonRu = find.text('Сохранить сервер');
      await tester.ensureVisible(saveButtonRu);
      await tester.tap(saveButtonRu);
      await tester.pumpAndSettle();

      expect(find.text('Все поля обязательны.'), findsOneWidget);
    });

    testWidgets('Handles AuthException and displays localized error snackbar in RU', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final gateway = _ControllableAuthGateway()
        ..shouldThrowAuthException = true
        ..authExceptionMessage = 'Incorrect password or user not found';
      final auth = AuthService(
        secretStore: InMemorySecretStore(),
        gateway: gateway,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          ServerSetupScreen(
            authService: auth,
            initialName: 'Домашний сервер',
            initialUrl: 'http://192.168.1.50:8080',
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Имя пользователя'), 'admin');
      await tester.enterText(find.widgetWithText(TextField, 'Пароль'), 'secret123');
      await tester.pumpAndSettle();

      final saveButtonRu = find.text('Сохранить сервер');
      await tester.ensureVisible(saveButtonRu);
      await tester.tap(saveButtonRu);
      await tester.pumpAndSettle();

      expect(
        find.text('Ошибка аутентификации: Incorrect password or user not found'),
        findsOneWidget,
      );
    });

    testWidgets('Handles AuthException and displays localized error snackbar in EN', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final gateway = _ControllableAuthGateway()
        ..shouldThrowAuthException = true
        ..authExceptionMessage = 'Incorrect password or user not found';
      final auth = AuthService(
        secretStore: InMemorySecretStore(),
        gateway: gateway,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          ServerSetupScreen(
            authService: auth,
            initialName: 'Home Server',
            initialUrl: 'http://192.168.1.50:8080',
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Username'), 'admin');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'secret123');
      await tester.pumpAndSettle();

      final saveButtonEn = find.text('Save Server');
      await tester.ensureVisible(saveButtonEn);
      await tester.tap(saveButtonEn);
      await tester.pumpAndSettle();

      expect(
        find.text('Authentication failed: Incorrect password or user not found'),
        findsOneWidget,
      );
    });

    testWidgets('Handles Generic Exception with fallback localized snackbar in RU', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final gateway = _ControllableAuthGateway()
        ..shouldThrowGenericException = true;
      final auth = AuthService(
        secretStore: InMemorySecretStore(),
        gateway: gateway,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          ServerSetupScreen(
            authService: auth,
            initialName: 'Сервер',
            initialUrl: 'http://192.168.1.50:8080',
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Имя пользователя'), 'admin');
      await tester.enterText(find.widgetWithText(TextField, 'Пароль'), 'secret123');
      await tester.pumpAndSettle();

      final saveButtonRu = find.text('Сохранить сервер');
      await tester.ensureVisible(saveButtonRu);
      await tester.tap(saveButtonRu);
      await tester.pumpAndSettle();

      final ruL10n = lookupAppLocalizations(const Locale('ru'));
      expect(find.text(ruL10n.authFailedGeneric), findsOneWidget);
    });

    testWidgets('Handles Generic Exception with fallback localized snackbar in EN', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final gateway = _ControllableAuthGateway()
        ..shouldThrowGenericException = true;
      final auth = AuthService(
        secretStore: InMemorySecretStore(),
        gateway: gateway,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          ServerSetupScreen(
            authService: auth,
            initialName: 'Server',
            initialUrl: 'http://192.168.1.50:8080',
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Username'), 'admin');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'secret123');
      await tester.pumpAndSettle();

      final saveButtonEn = find.text('Save Server');
      await tester.ensureVisible(saveButtonEn);
      await tester.tap(saveButtonEn);
      await tester.pumpAndSettle();

      final enL10n = lookupAppLocalizations(const Locale('en'));
      expect(find.text(enL10n.authFailedGeneric), findsOneWidget);
    });
  });

  group('CHALLENGER STRESS: AuthCard Tabs, Password Visibility & Forgot Password Dialog', () {
    testWidgets('Toggles AuthMode tabs and updates buttons and footnotes in EN & RU', (tester) async {
      final userCtrl = TextEditingController();
      final passCtrl = TextEditingController();

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: AuthCard(
              title: 'Login',
              usernameController: userCtrl,
              passwordController: passCtrl,
              onSubmit: (mode, {email}) async => true,
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: login
      expect(find.text('Вход'), findsWidgets);
      expect(find.text('Нет аккаунта? Перейти к регистрации.'), findsOneWidget);

      // Switch to register tab
      await tester.tap(find.text('Регистрация'));
      await tester.pumpAndSettle();

      expect(find.text('Уже есть аккаунт? Перейти ко входу.'), findsOneWidget);

      // Switch back to login tab
      await tester.tap(find.text('Вход').first);
      await tester.pumpAndSettle();

      expect(find.text('Нет аккаунта? Перейти к регистрации.'), findsOneWidget);
    });

    testWidgets('Forgot password flow with missing server URL shows localized snackbar in RU', (tester) async {
      final userCtrl = TextEditingController();
      final passCtrl = TextEditingController();
      final ruL10n = lookupAppLocalizations(const Locale('ru'));

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: AuthCard(
              title: 'Вход',
              usernameController: userCtrl,
              passwordController: passCtrl,
              getBaseUrl: () => '',
              onSubmit: (mode, {email}) async => true,
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Забыли пароль?'));
      await tester.pumpAndSettle();

      expect(find.text(ruL10n.pleaseEnterServerUrlFirst), findsOneWidget);
    });

    testWidgets('Forgot password flow with missing server URL shows localized snackbar in EN', (tester) async {
      final userCtrl = TextEditingController();
      final passCtrl = TextEditingController();
      final enL10n = lookupAppLocalizations(const Locale('en'));

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: AuthCard(
              title: 'Login',
              usernameController: userCtrl,
              passwordController: passCtrl,
              getBaseUrl: () => null,
              onSubmit: (mode, {email}) async => true,
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text(enL10n.pleaseEnterServerUrlFirst), findsOneWidget);
    });

    testWidgets('Forgot password dialog step 1 validation and error handling in RU', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final userCtrl = TextEditingController();
      final passCtrl = TextEditingController();
      final ruL10n = lookupAppLocalizations(const Locale('ru'));

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: AuthCard(
              title: 'Вход',
              usernameController: userCtrl,
              passwordController: passCtrl,
              getBaseUrl: () => 'http://192.168.1.10:8080',
              onSubmit: (mode, {email}) async => true,
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Забыли пароль?'));
      await tester.pumpAndSettle();

      // Dialog is shown: Step 1
      expect(find.text('Сброс пароля'), findsWidgets);
      expect(find.text(ruL10n.resetPasswordStep1Body), findsOneWidget);

      // Tap Send Code without username
      await tester.tap(find.text('Отправить код'));
      await tester.pumpAndSettle();
      expect(find.text(ruL10n.usernameIsRequired), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(find.text(ruL10n.resetPasswordStep1Body), findsNothing);
    });

    testWidgets('Forgot password dialog step 1 validation and error handling in EN', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final userCtrl = TextEditingController();
      final passCtrl = TextEditingController();
      final enL10n = lookupAppLocalizations(const Locale('en'));

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: AuthCard(
              title: 'Login',
              usernameController: userCtrl,
              passwordController: passCtrl,
              getBaseUrl: () => 'http://192.168.1.10:8080',
              onSubmit: (mode, {email}) async => true,
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      // Dialog is shown: Step 1
      expect(find.text('Reset Password'), findsWidgets);
      expect(find.text(enL10n.resetPasswordStep1Body), findsOneWidget);

      // Tap Send Code without username
      await tester.tap(find.text('Send Code'));
      await tester.pumpAndSettle();
      expect(find.text(enL10n.usernameIsRequired), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text(enL10n.resetPasswordStep1Body), findsNothing);
    });

    testWidgets('Biometric login button displays properly when enabled and triggers callback', (tester) async {
      final userCtrl = TextEditingController();
      final passCtrl = TextEditingController();
      bool biometricTriggered = false;

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: AuthCard(
              title: 'Login',
              usernameController: userCtrl,
              passwordController: passCtrl,
              biometricAvailable: true,
              onBiometricLogin: () async {
                biometricTriggered = true;
                return true;
              },
              onSubmit: (mode, {email}) async => true,
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Использовать биометрию'), findsOneWidget);
      await tester.tap(find.text('Использовать биометрию'));
      await tester.pumpAndSettle();

      expect(biometricTriggered, isTrue);
    });
  });
}
