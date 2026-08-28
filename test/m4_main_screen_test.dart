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

import 'package:crowleys_cloud/auth_card.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Milestone M4: Upload and Operation Error Localization Parity', () {
    test('Localization keys for upload errors format correctly in English and Russian', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final ru = lookupAppLocalizations(const Locale('ru'));

      // uploadErrorLocalPathEmpty
      expect(en.uploadErrorLocalPathEmpty('file.txt'), 'file.txt: local path is empty');
      expect(ru.uploadErrorLocalPathEmpty('file.txt'), 'file.txt: локальный путь пуст');

      // directoryUploadFailed
      expect(en.directoryUploadFailed, 'Directory upload failed');
      expect(ru.directoryUploadFailed, 'Не удалось загрузить папку');

      // serverIsUnreachable
      expect(en.serverIsUnreachable, 'Server is unreachable.');
      expect(ru.serverIsUnreachable, 'Сервер недоступен.');

      // uploadSummaryFailedCount
      expect(en.uploadSummaryFailedCount(3), ', failed 3');
      expect(ru.uploadSummaryFailedCount(3), ', с ошибкой 3');

      // uploadErrorLocalFileNotFound
      expect(en.uploadErrorLocalFileNotFound, 'Local file not found');
      expect(ru.uploadErrorLocalFileNotFound, 'Локальный файл не найден');

      // uploadErrorNoSessionToken
      expect(en.uploadErrorNoSessionToken, 'No active session token');
      expect(ru.uploadErrorNoSessionToken, 'Нет активного токена сессии');

      // serverDisconnected
      expect(en.serverDisconnected, 'Server disconnected');
      expect(ru.serverDisconnected, 'Сервер отключён');

      // serverDisconnectedStatus
      expect(en.serverDisconnectedStatus, 'Server disconnected');
      expect(ru.serverDisconnectedStatus, 'Сервер отключён');

      // uploadErrorLocalDirectoryNotFound
      expect(en.uploadErrorLocalDirectoryNotFound, 'Local directory not found');
      expect(ru.uploadErrorLocalDirectoryNotFound, 'Локальная папка не найдена');

      // uploadErrorFailedToScanDirectory
      expect(en.uploadErrorFailedToScanDirectory, 'Failed to scan directory');
      expect(ru.uploadErrorFailedToScanDirectory, 'Не удалось просканировать папку');

      // uploadErrorFolderCreateHttp
      expect(en.uploadErrorFolderCreateHttp(500), 'Folder creation failed (HTTP 500)');
      expect(ru.uploadErrorFolderCreateHttp(500), 'Не удалось создать папку (HTTP 500)');
    });

    test('Disconnected error detector recognizes English and Russian disconnection messages', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final ru = lookupAppLocalizations(const Locale('ru'));

      bool isDisconnected(String error, [AppLocalizations? l10n]) {
        final lower = error.toLowerCase();
        return lower.contains('server disconnected') ||
            (l10n != null &&
                (error == l10n.serverDisconnected ||
                    error == l10n.serverDisconnectedStatus));
      }

      // English string tests
      expect(isDisconnected('server disconnected', en), isTrue);
      expect(isDisconnected('Server Disconnected', en), isTrue);
      expect(isDisconnected('error: server disconnected during upload', en), isTrue);

      // Russian localized string tests
      expect(isDisconnected('Сервер отключён', ru), isTrue);
      expect(isDisconnected(ru.serverDisconnected, ru), isTrue);
      expect(isDisconnected(ru.serverDisconnectedStatus, ru), isTrue);

      // Non-disconnection errors
      expect(isDisconnected('File not found', en), isFalse);
      expect(isDisconnected('Локальный файл не найден', ru), isFalse);
    });
  });

  group('Milestone M4: Category Localization Parity', () {
    test('Categories translate accurately in English and Russian', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final ru = lookupAppLocalizations(const Locale('ru'));

      String getLocalizedCategory(String name, AppLocalizations l10n) {
        switch (name) {
          case 'All files':
            return l10n.allFiles;
          case 'Photos':
            return l10n.categoryPhotos;
          case 'Videos':
            return l10n.categoryVideos;
          case 'Audio':
            return l10n.categoryAudio;
          case 'Documents':
            return l10n.categoryDocuments;
          case 'Other':
            return l10n.categoryOther;
          case 'Shared':
            return l10n.categoryShared;
          default:
            return name;
        }
      }

      expect(getLocalizedCategory('All files', en), en.allFiles);
      expect(getLocalizedCategory('All files', ru), ru.allFiles);

      expect(getLocalizedCategory('Photos', en), en.categoryPhotos);
      expect(getLocalizedCategory('Photos', ru), ru.categoryPhotos);

      expect(getLocalizedCategory('Videos', en), en.categoryVideos);
      expect(getLocalizedCategory('Videos', ru), ru.categoryVideos);

      expect(getLocalizedCategory('Audio', en), en.categoryAudio);
      expect(getLocalizedCategory('Audio', ru), ru.categoryAudio);

      expect(getLocalizedCategory('Documents', en), en.categoryDocuments);
      expect(getLocalizedCategory('Documents', ru), ru.categoryDocuments);

      expect(getLocalizedCategory('Other', en), en.categoryOther);
      expect(getLocalizedCategory('Other', ru), ru.categoryOther);

      expect(getLocalizedCategory('Shared', en), en.categoryShared);
      expect(getLocalizedCategory('Shared', ru), ru.categoryShared);
    });
  });

  group('Milestone M4: ServerSetupScreen Localization', () {
    testWidgets('renders all fields and labels in English', (tester) async {
      final auth = AuthService(
        secretStore: InMemorySecretStore(),
        gateway: _FakeAuthGateway(),
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          ServerSetupScreen(authService: auth),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add server'), findsOneWidget);
      expect(find.text('Connect Server'), findsOneWidget);
      expect(find.text('Add your home file server and sign in.'), findsOneWidget);
      expect(find.text('Save Server'), findsOneWidget);
      expect(find.text('Server name'), findsOneWidget);
      expect(find.text('Base URL'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders all fields and labels in Russian', (tester) async {
      final auth = AuthService(
        secretStore: InMemorySecretStore(),
        gateway: _FakeAuthGateway(),
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          ServerSetupScreen(authService: auth),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Добавить сервер'), findsOneWidget);
      expect(find.text('Подключить сервер'), findsOneWidget);
      expect(find.text('Добавьте домашний файловый сервер и войдите.'), findsOneWidget);
      expect(find.text('Сохранить сервер'), findsOneWidget);
      expect(find.text('Имя сервера'), findsOneWidget);
      expect(find.text('Базовый URL'), findsOneWidget);
      expect(find.text('Имя пользователя'), findsOneWidget);
      expect(find.text('Пароль'), findsOneWidget);
    });

    testWidgets('shows validation snackbar in Russian when fields are empty', (tester) async {
      final auth = AuthService(
        secretStore: InMemorySecretStore(),
        gateway: _FakeAuthGateway(),
      );

      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithLocalization(
          ServerSetupScreen(authService: auth),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.text('Сохранить сервер');
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Все поля обязательны.'), findsOneWidget);
    });
  });

  group('Milestone M4: AuthCard Localization', () {
    testWidgets('renders login card elements in English and Russian', (tester) async {
      final usernameController = TextEditingController();
      final passwordController = TextEditingController();

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: AuthCard(
              title: 'Welcome Back',
              subtitle: 'Sign in to continue',
              usernameController: usernameController,
              passwordController: passwordController,
              onSubmit: (mode, {email}) async => true,
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Log In'), findsWidgets);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Do not have an account? Switch to Register.'), findsOneWidget);

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: AuthCard(
              title: 'С возвращением',
              subtitle: 'Войдите, чтобы продолжить',
              usernameController: usernameController,
              passwordController: passwordController,
              onSubmit: (mode, {email}) async => true,
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('С возвращением'), findsOneWidget);
      expect(find.text('Войдите, чтобы продолжить'), findsOneWidget);
      expect(find.text('Вход'), findsWidgets);
      expect(find.text('Регистрация'), findsOneWidget);
      expect(find.text('Забыли пароль?'), findsOneWidget);
      expect(find.text('Нет аккаунта? Перейти к регистрации.'), findsOneWidget);
    });
  });
}
