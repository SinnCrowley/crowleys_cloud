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
import 'dart:io';

import 'package:crowleys_cloud/active_server_manager.dart';
import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/app_update_service.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/biometric_auth_service.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_en.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_ru.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:crowleys_cloud/settings_screen.dart';
import 'package:crowleys_cloud/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

// --- Mocks & Fakes for Challenger Suite ---

class _CapturingLocalAuth implements LocalAuthentication {
  String? capturedReason;
  bool returnAuthSuccess = true;
  bool hardwareSupported = true;

  @override
  Future<bool> get canCheckBiometrics async => hardwareSupported;

  @override
  Future<bool> isDeviceSupported() async => hardwareSupported;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    bool biometricOnly = false,
    bool persistAcrossBackgrounding = false,
    bool sensitiveTransaction = true,
  }) async {
    capturedReason = localizedReason;
    return returnAuthSuccess;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ChallengerSyncScanner implements SyncFileScanner {
  _ChallengerSyncScanner(this.candidates);
  final List<SyncCandidate> candidates;

  @override
  Future<List<SyncCandidate>> scan(ServerProfile server) async => candidates;
}

class _ChallengerSyncApiClient implements SyncApiClient {
  bool isServerUnreachable = false;
  bool authRequired = false;
  final createdFolders = <String>[];
  final uploadedPaths = <String>[];
  final existingPaths = <String>{};
  final Map<String, String> hashToExistingPath = {};
  String? failUploadPath;

  @override
  Future<bool> ping({required ServerProfile server}) async {
    return !isServerUnreachable;
  }

  @override
  Future<void> createFolder({
    required ServerProfile server,
    required String remotePath,
  }) async {
    if (authRequired) throw const SyncException('Authentication required');
    createdFolders.add(remotePath);
  }

  @override
  Future<void> uploadFile({
    required ServerProfile server,
    required String remotePath,
    required File file,
  }) async {
    if (authRequired) throw const SyncException('Authentication required');
    if (remotePath == failUploadPath) {
      throw const SyncException('Upload failed');
    }
    uploadedPaths.add(remotePath);
  }

  @override
  Future<bool> fileExists({
    required ServerProfile server,
    required String remotePath,
  }) async {
    if (authRequired) throw const SyncException('Authentication required');
    return existingPaths.contains(remotePath) ||
        uploadedPaths.contains(remotePath);
  }

  @override
  Future<Map<String, String>> checkHashes({
    required ServerProfile server,
    required List<String> hashes,
  }) async {
    if (authRequired) throw const SyncException('Authentication required');
    final result = <String, String>{};
    for (final hash in hashes) {
      if (hashToExistingPath.containsKey(hash)) {
        result[hash] = hashToExistingPath[hash]!;
      }
    }
    return result;
  }

  @override
  Future<int> getUploadStatus({
    required ServerProfile server,
    required String remotePath,
  }) async {
    if (authRequired) throw const SyncException('Authentication required');
    return 0;
  }
}

Future<void> _setTallScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('M2 Challenger - BiometricAuthService Localized Reason Stress Tests', () {
    test(
      'passes custom English localizedReason to native authenticator',
      () async {
        final mockAuth = _CapturingLocalAuth();
        final bioService = BiometricAuthService(auth: mockAuth);

        final result = await bioService.unlockSavedCredentials(
          localizedReason: 'Unlock your vault to continue.',
        );

        expect(result, isTrue);
        expect(
          mockAuth.capturedReason,
          equals('Unlock your vault to continue.'),
        );
      },
    );

    test(
      'passes custom Russian localizedReason to native authenticator',
      () async {
        final mockAuth = _CapturingLocalAuth();
        final bioService = BiometricAuthService(auth: mockAuth);

        final result = await bioService.unlockSavedCredentials(
          localizedReason:
              'Подтвердите личность для доступа к Crowley\'s Cloud.',
        );

        expect(result, isTrue);
        expect(
          mockAuth.capturedReason,
          equals('Подтвердите личность для доступа к Crowley\'s Cloud.'),
        );
      },
    );

    test(
      'falls back to default English string when localizedReason is omitted/null',
      () async {
        final mockAuth = _CapturingLocalAuth();
        final bioService = BiometricAuthService(auth: mockAuth);

        final result = await bioService.unlockSavedCredentials();

        expect(result, isTrue);
        expect(
          mockAuth.capturedReason,
          equals('Unlock saved credentials for Crowley\'s Cloud.'),
        );
      },
    );

    test('handles unsupported hardware gracefully', () async {
      final mockAuth = _CapturingLocalAuth()..hardwareSupported = false;
      final bioService = BiometricAuthService(auth: mockAuth);

      final canAuth = await bioService.canAuthenticate();
      expect(canAuth, isFalse);

      final unlocked = await bioService.unlockSavedCredentials(
        localizedReason: 'Test reason',
      );
      expect(unlocked, isFalse);
      expect(mockAuth.capturedReason, isNull);
    });
  });

  group('M2 Challenger - SettingsScreen Dropdown & Locale Parity Tests', () {
    testWidgets('renders all TokenLifetimeOption labels in English', (
      tester,
    ) async {
      await _setTallScreen(tester);
      final manager = ActiveServerManager(
        store: ServerStore(),
        authService: AuthService(secretStore: InMemorySecretStore()),
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: manager,
            biometricAuthService: BiometricAuthService(
              auth: _CapturingLocalAuth(),
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      final dropdown = find.byType(
        DropdownButtonFormField<TokenLifetimeOption>,
      );
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      expect(find.text('Every app open').last, findsOneWidget);
      expect(find.text('After 1 hour').last, findsOneWidget);
      expect(find.text('After 1 day').last, findsOneWidget);
      expect(find.text('After 1 week').last, findsOneWidget);
      expect(find.text('After 1 month').last, findsOneWidget);
      expect(find.text('After 3 months').last, findsOneWidget);
      expect(find.text('Never on this device').last, findsOneWidget);
    });

    testWidgets('renders all TokenLifetimeOption labels in Russian', (
      tester,
    ) async {
      await _setTallScreen(tester);
      final manager = ActiveServerManager(
        store: ServerStore(),
        authService: AuthService(secretStore: InMemorySecretStore()),
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: manager,
            biometricAuthService: BiometricAuthService(
              auth: _CapturingLocalAuth(),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      final dropdown = find.byType(
        DropdownButtonFormField<TokenLifetimeOption>,
      );
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      expect(find.text('При каждом открытии приложения').last, findsOneWidget);
      expect(find.text('Через 1 час').last, findsOneWidget);
      expect(find.text('Через 1 день').last, findsOneWidget);
      expect(find.text('Через 1 неделю').last, findsOneWidget);
      expect(find.text('Через 1 месяц').last, findsOneWidget);
      expect(find.text('Через 3 месяца').last, findsOneWidget);
      expect(find.text('Никогда на этом устройстве').last, findsOneWidget);
    });

    testWidgets(
      'renders CacheLimitOption Unlimited localized label in English and Russian',
      (tester) async {
        await _setTallScreen(tester);
        final manager = ActiveServerManager(
          store: ServerStore(),
          authService: AuthService(secretStore: InMemorySecretStore()),
        );

        // 1. English
        await tester.pumpWidget(
          wrapWithLocalization(
            SettingsScreen(
              serverManager: manager,
              biometricAuthService: BiometricAuthService(
                auth: _CapturingLocalAuth(),
              ),
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        final cacheDropdown = find.byType(DropdownButtonFormField<int>);
        expect(cacheDropdown, findsOneWidget);
        await tester.tap(cacheDropdown);
        await tester.pumpAndSettle();

        expect(find.text('Unlimited').last, findsOneWidget);
        expect(find.text('500 MB').last, findsOneWidget);
        expect(find.text('1 GB').last, findsOneWidget);
        expect(find.text('5 GB').last, findsOneWidget);

        await tester.tap(find.text('500 MB').last);
        await tester.pumpAndSettle();

        // 2. Russian
        await tester.pumpWidget(
          wrapWithLocalization(
            SettingsScreen(
              serverManager: manager,
              biometricAuthService: BiometricAuthService(
                auth: _CapturingLocalAuth(),
              ),
            ),
            locale: const Locale('ru'),
          ),
        );
        await tester.pumpAndSettle();

        final cacheDropdownRu = find.byType(DropdownButtonFormField<int>);
        await tester.tap(cacheDropdownRu);
        await tester.pumpAndSettle();

        expect(find.text('Без ограничений').last, findsOneWidget);
      },
    );

    testWidgets(
      'renders sync frequency picker options correctly in English and Russian',
      (tester) async {
        await _setTallScreen(tester);
        final server = ServerProfile(
          id: 'srv1',
          displayName: 'Cloud Backup',
          baseUrl: 'https://cloud.example.com',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {'syncEnabled': true, 'syncFrequency': 15},
        );
        final manager =
            ActiveServerManager(
                store: ServerStore(),
                authService: AuthService(secretStore: InMemorySecretStore()),
              )
              ..activeServer = server
              ..servers = [server];

        // English
        await tester.pumpWidget(
          wrapWithLocalization(
            SettingsScreen(
              serverManager: manager,
              biometricAuthService: BiometricAuthService(
                auth: _CapturingLocalAuth(),
              ),
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Synchronization frequency'));
        await tester.pumpAndSettle();

        expect(find.text('Choose Sync Frequency'), findsOneWidget);
        expect(
          find.widgetWithText(SimpleDialogOption, 'Every 15 minutes'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Every 30 minutes'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Every hour'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Every 2 hours'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Every 4 hours'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Every 8 hours'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Every 12 hours'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Daily'),
          findsOneWidget,
        );

        await tester.tap(
          find.widgetWithText(SimpleDialogOption, 'Every 30 minutes'),
        );
        await tester.pumpAndSettle();

        // Russian
        await tester.pumpWidget(
          wrapWithLocalization(
            SettingsScreen(
              serverManager: manager,
              biometricAuthService: BiometricAuthService(
                auth: _CapturingLocalAuth(),
              ),
            ),
            locale: const Locale('ru'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Частота синхронизации'));
        await tester.pumpAndSettle();

        expect(find.text('Выберите частоту синхронизации'), findsOneWidget);
        expect(
          find.widgetWithText(SimpleDialogOption, 'Каждые 15 минут'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Каждые 30 минут'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Каждый час'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Каждые 2 ч'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Каждые 4 ч'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Каждые 8 ч'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Каждые 12 ч'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Ежедневно'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders SyncCategoriesDialog in English and Russian', (
      tester,
    ) async {
      await _setTallScreen(tester);
      final server = ServerProfile(
        id: 'srv1',
        displayName: 'Cloud Backup',
        baseUrl: 'https://cloud.example.com',
        authMode: 'login',
        lastUsedAt: DateTime.now().toUtc(),
        syncPrefs: const {
          'syncEnabled': true,
          'syncCategories': ['photos', 'videos', 'documents'],
        },
      );
      final manager =
          ActiveServerManager(
              store: ServerStore(),
              authService: AuthService(secretStore: InMemorySecretStore()),
            )
            ..activeServer = server
            ..servers = [server];

      // English
      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: manager,
            biometricAuthService: BiometricAuthService(
              auth: _CapturingLocalAuth(),
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Categories to synchronize'));
      await tester.pumpAndSettle();

      expect(find.text('Categories to synchronize'), findsWidgets);
      expect(
        find.text(
          'Choose one or more categories. Leaving everything unchecked is valid.',
        ),
        findsOneWidget,
      );
      expect(find.text('Media'), findsOneWidget);
      expect(find.text('Audio and documents'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Other files'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Russian
      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: manager,
            biometricAuthService: BiometricAuthService(
              auth: _CapturingLocalAuth(),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Категории для синхронизации'));
      await tester.pumpAndSettle();

      expect(find.text('Категории для синхронизации'), findsWidgets);
      expect(
        find.text(
          'Выберите одну или несколько категорий. Можно не выбирать ни одной.',
        ),
        findsOneWidget,
      );
      expect(find.text('Медиа'), findsOneWidget);
      expect(find.text('Аудио и документы'), findsOneWidget);
      expect(find.text('Другое'), findsOneWidget);
      expect(find.text('Фото'), findsOneWidget);
      expect(find.text('Видео'), findsOneWidget);
      expect(find.text('Аудио'), findsOneWidget);
      expect(find.text('Документы'), findsOneWidget);
      expect(find.text('Другие файлы'), findsOneWidget);
      expect(find.text('Сбросить всё'), findsOneWidget);
    });

    testWidgets(
      'renders PasswordChangeDialog validation and labels in Russian',
      (tester) async {
        await _setTallScreen(tester);
        final server = ServerProfile(
          id: 'srv1',
          displayName: 'My Production Server',
          baseUrl: 'https://cloud.example.com',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        );
        final manager =
            ActiveServerManager(
                store: ServerStore(),
                authService: AuthService(secretStore: InMemorySecretStore()),
              )
              ..activeServer = server
              ..servers = [server];

        await tester.pumpWidget(
          wrapWithLocalization(
            SettingsScreen(
              serverManager: manager,
              biometricAuthService: BiometricAuthService(
                auth: _CapturingLocalAuth(),
              ),
            ),
            locale: const Locale('ru'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Изменить пароль'));
        await tester.pumpAndSettle();

        expect(find.text('Изменить пароль'), findsWidgets);
        expect(find.text('Новый пароль'), findsOneWidget);
        expect(find.text('Подтвердите пароль'), findsOneWidget);

        await tester.tap(find.text('Сохранить'));
        await tester.pumpAndSettle();
        expect(find.text('Введите новый пароль.'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'Новый пароль'),
          'secret123',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Подтвердите пароль'),
          'secret456',
        );
        await tester.tap(find.text('Сохранить'));
        await tester.pumpAndSettle();
        expect(find.text('Пароли не совпадают.'), findsOneWidget);
      },
    );

    testWidgets('renders Account Deletion dialog in Russian', (tester) async {
      await _setTallScreen(tester);
      final server = ServerProfile(
        id: 'srv1',
        displayName: 'Test Server',
        baseUrl: 'https://cloud.example.com',
        authMode: 'login',
        lastUsedAt: DateTime.now().toUtc(),
        syncPrefs: const {},
      );
      final manager =
          ActiveServerManager(
              store: ServerStore(),
              authService: AuthService(secretStore: InMemorySecretStore()),
            )
            ..activeServer = server
            ..servers = [server];

      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: manager,
            biometricAuthService: BiometricAuthService(
              auth: _CapturingLocalAuth(),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Удалить аккаунт'));
      await tester.pumpAndSettle();

      expect(find.text('Удалить аккаунт?'), findsOneWidget);
      expect(
        find.text(
          'Это навсегда удалит ваш аккаунт на Test Server и все файлы в личном облаке. Это действие нельзя отменить.',
        ),
        findsOneWidget,
      );
      expect(find.text('Удалить аккаунт'), findsWidgets);
      expect(find.text('Отмена'), findsOneWidget);
    });

    testWidgets('renders storage root fallback in English and Russian', (
      tester,
    ) async {
      await _setTallScreen(tester);
      final server = ServerProfile(
        id: 'srv1',
        displayName: 'Backup Target',
        baseUrl: 'https://cloud.example.com',
        authMode: 'login',
        lastUsedAt: DateTime.now().toUtc(),
        syncPrefs: const {
          'syncEnabled': true,
          'syncFolders': ['/storage/emulated/0'],
        },
      );
      final manager =
          ActiveServerManager(
              store: ServerStore(),
              authService: AuthService(secretStore: InMemorySecretStore()),
            )
            ..activeServer = server
            ..servers = [server];

      // English
      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: manager,
            biometricAuthService: BiometricAuthService(
              auth: _CapturingLocalAuth(),
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Storage'), findsWidgets);

      // Russian
      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: manager,
            biometricAuthService: BiometricAuthService(
              auth: _CapturingLocalAuth(),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Хранилище'), findsWidgets);
    });
  });

  group('M2 Challenger - SyncService Localization & Fallback Stress Tests', () {
    late Directory tempDir;
    late ServerProfile server;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sync_challenger_test');
      server = ServerProfile(
        id: 'srv_sync',
        displayName: 'Primary Cloud',
        baseUrl: 'https://sync.example.com',
        authMode: 'login',
        lastUsedAt: DateTime.utc(2026, 8, 18),
        syncPrefs: const {'syncEnabled': true},
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'SyncService with English AppLocalizations produces exact English progress messages',
      () async {
        final file = File('${tempDir.path}/report.pdf');
        await file.writeAsString('pdf content data');

        final api = _ChallengerSyncApiClient();
        final stateStore = FileSyncStateStore(
          fileProvider: () async => File('${tempDir.path}/state.json'),
        );
        final service = SyncService(
          scanner: _ChallengerSyncScanner([
            SyncCandidate(
              file: file,
              remotePath: 'backup/documents/report.pdf',
            ),
          ]),
          apiClient: api,
          stateStore: stateStore,
        );

        final progressLog = <String>[];
        final l10n = AppLocalizationsEn();

        final result = await service.syncServer(
          server,
          l10n: l10n,
          onProgress: (msg, _) => progressLog.add(msg),
        );

        expect(result.status, SyncRunStatus.success);
        expect(result.uploadedFiles, 1);

        expect(progressLog, contains('Connecting to server...'));
        expect(progressLog, contains('Scanning files on device...'));
        expect(progressLog, contains('Calculating checksum (1/1): report.pdf'));
        expect(progressLog, contains('Checking for duplicates on server...'));
        expect(progressLog, contains('Syncing (1/1): report.pdf'));
      },
    );

    test(
      'SyncService with Russian AppLocalizations produces exact Russian progress messages',
      () async {
        final file = File('${tempDir.path}/video.mp4');
        await file.writeAsString('video binary data stream');

        final api = _ChallengerSyncApiClient();
        final stateStore = FileSyncStateStore(
          fileProvider: () async => File('${tempDir.path}/state.json'),
        );
        final service = SyncService(
          scanner: _ChallengerSyncScanner([
            SyncCandidate(file: file, remotePath: 'backup/videos/video.mp4'),
          ]),
          apiClient: api,
          stateStore: stateStore,
        );

        final progressLog = <String>[];
        final l10n = AppLocalizationsRu();

        final result = await service.syncServer(
          server,
          l10n: l10n,
          onProgress: (msg, _) => progressLog.add(msg),
        );

        expect(result.status, SyncRunStatus.success);
        expect(result.uploadedFiles, 1);

        expect(progressLog, contains('Подключение к серверу...'));
        expect(progressLog, contains('Сканирование файлов на устройстве...'));
        expect(
          progressLog,
          contains('Вычисление контрольной суммы (1/1): video.mp4'),
        );
        expect(progressLog, contains('Проверка дубликатов на сервере...'));
        expect(progressLog, contains('Синхронизация (1/1): video.mp4'));
      },
    );

    test(
      'SyncService with null l10n falls back cleanly without null crashes',
      () async {
        final file = File('${tempDir.path}/photo.jpg');
        await file.writeAsString('photo bytes');

        final api = _ChallengerSyncApiClient();
        final stateStore = FileSyncStateStore(
          fileProvider: () async => File('${tempDir.path}/state.json'),
        );
        final service = SyncService(
          scanner: _ChallengerSyncScanner([
            SyncCandidate(file: file, remotePath: 'backup/photos/photo.jpg'),
          ]),
          apiClient: api,
          stateStore: stateStore,
        );

        final progressLog = <String>[];

        final result = await service.syncServer(
          server,
          l10n: null,
          onProgress: (msg, _) => progressLog.add(msg),
        );

        expect(result.status, SyncRunStatus.success);
        expect(result.uploadedFiles, 1);

        expect(progressLog, contains('Connecting to server...'));
        expect(progressLog, contains('Scanning files on device...'));
        expect(progressLog, contains('Calculating checksum (1/1): photo.jpg'));
        expect(progressLog, contains('Checking for duplicates on server...'));
        expect(progressLog, contains('Syncing (1/1): photo.jpg'));
      },
    );

    test(
      'SyncService handles unreachable server in English and Russian',
      () async {
        final api = _ChallengerSyncApiClient()..isServerUnreachable = true;
        final stateStore = FileSyncStateStore(
          fileProvider: () async => File('${tempDir.path}/state.json'),
        );
        final service = SyncService(
          scanner: _ChallengerSyncScanner([]),
          apiClient: api,
          stateStore: stateStore,
        );

        // 1. English
        final resultEn = await service.syncServer(
          server,
          l10n: AppLocalizationsEn(),
        );
        expect(resultEn.status, SyncRunStatus.serverUnreachable);
        expect(
          resultEn.message,
          equals('Could not connect to Primary Cloud. Connection lost.'),
        );

        // 2. Russian
        final resultRu = await service.syncServer(
          server,
          l10n: AppLocalizationsRu(),
        );
        expect(resultRu.status, SyncRunStatus.serverUnreachable);
        expect(
          resultRu.message,
          equals(
            'Не удалось подключиться к Primary Cloud. Соединение потеряно.',
          ),
        );

        // 3. Null fallback
        final resultNull = await service.syncServer(server, l10n: null);
        expect(resultNull.status, SyncRunStatus.serverUnreachable);
        expect(
          resultNull.message,
          equals('Could not connect to Primary Cloud. Connection lost.'),
        );
      },
    );

    test(
      'SyncService handles no files candidate scenario in EN, RU and null fallback',
      () async {
        final api = _ChallengerSyncApiClient();
        final stateStore = FileSyncStateStore(
          fileProvider: () async => File('${tempDir.path}/state.json'),
        );
        final service = SyncService(
          scanner: _ChallengerSyncScanner([]),
          apiClient: api,
          stateStore: stateStore,
        );

        // 1. English
        final resultEn = await service.syncServer(
          server,
          l10n: AppLocalizationsEn(),
        );
        expect(resultEn.status, SyncRunStatus.noFiles);
        expect(
          resultEn.message,
          equals('No files selected for synchronization.'),
        );

        // 2. Russian
        final resultRu = await service.syncServer(
          server,
          l10n: AppLocalizationsRu(),
        );
        expect(resultRu.status, SyncRunStatus.noFiles);
        expect(resultRu.message, equals('Не выбраны файлы для синхронизации.'));

        // 3. Null fallback
        final resultNull = await service.syncServer(server, l10n: null);
        expect(resultNull.status, SyncRunStatus.noFiles);
        expect(
          resultNull.message,
          equals('No files selected for synchronization.'),
        );
      },
    );
  });

  group(
    'M2 Challenger - Headless Localization Resolution & Unsupported Locales',
    () {
      test(
        'lookupAppLocalizations returns appropriate localization delegate for supported locales',
        () {
          final en = lookupAppLocalizations(const Locale('en'));
          expect(en, isA<AppLocalizationsEn>());
          expect(en.settingsTitle, equals('Settings'));

          final ru = lookupAppLocalizations(const Locale('ru'));
          expect(ru, isA<AppLocalizationsRu>());
          expect(ru.settingsTitle, equals('Настройки'));
        },
      );

      test(
        'unsupported locale fallback behavior in background sync helper',
        () {
          AppLocalizations safeResolve(Locale locale) {
            try {
              return lookupAppLocalizations(locale);
            } catch (_) {
              return AppLocalizationsEn();
            }
          }

          final frResolved = safeResolve(const Locale('xx'));
          expect(frResolved, isA<AppLocalizationsEn>());
          expect(frResolved.appTitle, equals('Crowley\'s Cloud'));

          final deResolved = safeResolve(const Locale('yy'));
          expect(deResolved, isA<AppLocalizationsEn>());
        },
      );
    },
  );

  group('M2 Challenger - AppUpdateService Multi-Locale & Changelog Tests', () {
    test(
      'AppReleaseItem.fromJson localizes missing release notes in EN, RU and default',
      () {
        final jsonNoBody = {
          'tag_name': 'v1.5.0',
          'name': 'Release 1.5.0',
          'html_url': 'https://example.com',
        };

        // EN
        final itemEn = AppReleaseItem.fromJson(
          jsonNoBody,
          l10n: AppLocalizationsEn(),
        );
        expect(itemEn.body, equals('No release notes provided.'));

        // RU
        final itemRu = AppReleaseItem.fromJson(
          jsonNoBody,
          l10n: AppLocalizationsRu(),
        );
        expect(itemRu.body, equals('Примечания к выпуску не предоставлены.'));

        // Null fallback
        final itemNull = AppReleaseItem.fromJson(jsonNoBody, l10n: null);
        expect(itemNull.body, equals('No release notes provided.'));
      },
    );

    test(
      'checkForUpdates handles 404 No Releases Published in EN, RU and default',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({'message': 'Not Found'}), 404);
        });

        final service = AppUpdateService(currentVersion: '1.0.0');

        // EN
        final resEn = await service.checkForUpdates(
          client: mockClient,
          l10n: AppLocalizationsEn(),
        );
        expect(resEn, isNotNull);
        expect(resEn!.hasUpdate, isFalse);
        expect(resEn.releaseNotes, equals('No releases published yet.'));

        // RU
        final resRu = await service.checkForUpdates(
          client: mockClient,
          l10n: AppLocalizationsRu(),
        );
        expect(resRu, isNotNull);
        expect(resRu!.hasUpdate, isFalse);
        expect(resRu.releaseNotes, equals('Выпуски пока не опубликованы.'));

        // Null fallback
        final resNull = await service.checkForUpdates(
          client: mockClient,
          l10n: null,
        );
        expect(resNull, isNotNull);
        expect(resNull!.hasUpdate, isFalse);
        expect(resNull.releaseNotes, equals('No releases published yet.'));
      },
    );

    testWidgets(
      'AppUpdateDialog renders multi-release notes and Russian actions correctly',
      (tester) async {
        const updateInfo = AppUpdateInfo(
          hasUpdate: true,
          currentVersion: '1.0.0',
          latestVersion: '1.3.0',
          latestReleaseName: 'v1.3.0',
          releaseNotes:
              '### v1.3.0\n*2026-08-18*\n\nНовые функции\n\n---\n\n### v1.2.0\n*2026-08-10*\n\nИсправления ошибок',
          htmlUrl:
              'https://github.com/SinnCrowley/crowleys_cloud/releases/tag/v1.3.0',
          apkUrl: 'https://example.com/app-v1.3.0.apk',
          newReleases: [
            AppReleaseItem(
              tagName: 'v1.3.0',
              version: '1.3.0',
              name: 'v1.3.0',
              body: 'Новые функции',
              htmlUrl: 'https://example.com/1.3.0',
            ),
            AppReleaseItem(
              tagName: 'v1.2.0',
              version: '1.2.0',
              name: 'v1.2.0',
              body: 'Исправления ошибок',
              htmlUrl: 'https://example.com/1.2.0',
            ),
          ],
        );

        await tester.pumpWidget(
          wrapWithLocalization(
            const Scaffold(body: AppUpdateDialog(updateInfo: updateInfo)),
            locale: const Locale('ru'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Доступно обновление'), findsOneWidget);
        expect(find.text('Версия 1.3.0'), findsOneWidget);
        expect(find.text('Текущая: v1.0.0'), findsOneWidget);
        expect(find.text('Новая: v1.3.0'), findsOneWidget);
        expect(find.text('+2'), findsOneWidget);
        expect(find.text('Что нового:'), findsOneWidget);
        expect(find.text('GitHub'), findsOneWidget);
        expect(find.text('Позже'), findsOneWidget);
        expect(find.text('Скачать APK'), findsOneWidget);
        expect(find.textContaining('Новые функции'), findsOneWidget);
        expect(find.textContaining('Исправления ошибок'), findsOneWidget);
      },
    );
  });
}
