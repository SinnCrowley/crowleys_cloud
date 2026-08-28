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
import 'package:crowleys_cloud/app_constants.dart';
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

class _MockLocalAuthentication extends LocalAuthentication {
  String? lastLocalizedReason;
  bool shouldSucceed = true;
  bool isHardwareAvailable = true;

  @override
  Future<bool> get canCheckBiometrics async => isHardwareAvailable;

  @override
  Future<bool> isDeviceSupported() async => isHardwareAvailable;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    dynamic authMessages = const [],
    bool biometricOnly = false,
    bool persistAcrossBackgrounding = false,
    bool sensitiveTransaction = true,
  }) async {
    lastLocalizedReason = localizedReason;
    return shouldSucceed;
  }
}

class _StressFakeBiometricAuthService extends BiometricAuthService {
  _StressFakeBiometricAuthService(this.available, {this.authMock})
    : super(auth: authMock);

  final bool available;
  final _MockLocalAuthentication? authMock;

  @override
  Future<bool> canAuthenticate() async => available;
}

class _StressFakeScanner implements SyncFileScanner {
  _StressFakeScanner(this.candidates);

  final List<SyncCandidate> candidates;

  @override
  Future<List<SyncCandidate>> scan(ServerProfile server) async => candidates;
}

class _StressFakeApiClient implements SyncApiClient {
  final createdFolders = <String>[];
  final uploadedPaths = <String>[];
  final existingPaths = <String>{};
  final Map<String, String> hashToExistingPath = {};
  String? failUploadPath;
  bool isServerUnreachable = false;
  bool authRequired = false;

  @override
  Future<bool> ping({required ServerProfile server}) async {
    if (isServerUnreachable) return false;
    return true;
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

Future<File> _createTestFile(
  Directory tempDir,
  String name,
  String contents,
) async {
  final file = File('${tempDir.path}/$name');
  await file.writeAsString(contents);
  return file;
}

Future<void> _setTallViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  final enL10n = lookupAppLocalizations(const Locale('en'));
  final ruL10n = lookupAppLocalizations(const Locale('ru'));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('M2 Headless & Channel Localization Resolution Stress', () {
    test(
      'lookupAppLocalizations resolves correct subclasses for supported locales',
      () {
        final en = lookupAppLocalizations(const Locale('en'));
        final ru = lookupAppLocalizations(const Locale('ru'));
        expect(en, isA<AppLocalizationsEn>());
        expect(ru, isA<AppLocalizationsRu>());
      },
    );

    test(
      'lookupAppLocalizations throws on unsupported locales and headless fallback catches it',
      () {
        final unsupportedLocales = [
          const Locale('xx'),
          const Locale('yy'),
          const Locale('aa'),
          const Locale('qq'),
          const Locale('bb'),
        ];

        for (final locale in unsupportedLocales) {
          expect(
            () => lookupAppLocalizations(locale),
            throwsA(isA<FlutterError>()),
            reason:
                'lookupAppLocalizations should throw for unsupported ${locale.languageCode}',
          );

          // Verify headless resolution fallback behavior
          AppLocalizations resolved;
          try {
            resolved = lookupAppLocalizations(locale);
          } catch (_) {
            resolved = AppLocalizationsEn();
          }
          expect(resolved, isA<AppLocalizationsEn>());
          expect(resolved.syncChannelName, 'Background Synchronization');
        }
      },
    );

    test('Notification channel localized strings exact parity', () {
      expect(enL10n.syncChannelName, 'Background Synchronization');
      expect(
        enL10n.syncChannelDescription,
        'Shows status of files syncing in the background.',
      );

      expect(ruL10n.syncChannelName, 'Фоновая синхронизация');
      expect(
        ruL10n.syncChannelDescription,
        'Показывает статус синхронизации файлов в фоне.',
      );
    });

    test(
      'Notification state titles and bodies exact parity across EN and RU',
      () {
        const serverName = 'VaultServer';

        // Syncing
        expect(
          enL10n.syncNotificationSyncingWith(serverName),
          'Syncing with VaultServer',
        );
        expect(
          ruL10n.syncNotificationSyncingWith(serverName),
          'Синхронизация с VaultServer',
        );

        // Paused
        expect(
          enL10n.syncNotificationPausedTitle(serverName),
          'Sync with VaultServer paused',
        );
        expect(
          ruL10n.syncNotificationPausedTitle(serverName),
          'Синхронизация с VaultServer приостановлена',
        );

        // Unreachable
        expect(
          enL10n.syncNotificationUnreachableBody,
          'Server is unreachable. Background sync paused until app is opened.',
        );
        expect(
          ruL10n.syncNotificationUnreachableBody,
          'Сервер недоступен. Фоновая синхронизация приостановлена до открытия приложения.',
        );

        // Auth Required
        expect(
          enL10n.syncNotificationAuthRequiredBody,
          'Authentication required. Open app to log in.',
        );
        expect(
          ruL10n.syncNotificationAuthRequiredBody,
          'Требуется авторизация. Откройте приложение для входа.',
        );

        // Failed
        expect(
          enL10n.syncNotificationFailedTitle(serverName),
          'Sync with VaultServer failed',
        );
        expect(
          ruL10n.syncNotificationFailedTitle(serverName),
          'Синхронизация с VaultServer не удалась',
        );

        expect(
          enL10n.syncNotificationGenericErrorBody,
          'An error occurred during synchronization.',
        );
        expect(
          ruL10n.syncNotificationGenericErrorBody,
          'Произошла ошибка во время синхронизации.',
        );

        // Complete
        expect(
          enL10n.syncNotificationCompleteTitle(serverName),
          'Sync with VaultServer complete',
        );
        expect(
          ruL10n.syncNotificationCompleteTitle(serverName),
          'Синхронизация с VaultServer завершена',
        );

        expect(enL10n.syncNotificationCompleteBody, 'Sync complete.');
        expect(ruL10n.syncNotificationCompleteBody, 'Синхронизация завершена.');
      },
    );

    test(
      'High-frequency concurrent headless localizations resolution loop',
      () {
        final stopwatch = Stopwatch()..start();
        const iterations = 1000;
        for (var i = 0; i < iterations; i++) {
          final targetLocale = i.isEven
              ? const Locale('en')
              : const Locale('ru');
          final l10n = lookupAppLocalizations(targetLocale);
          if (i.isEven) {
            expect(l10n.syncChannelName, 'Background Synchronization');
            expect(l10n.syncNotificationCompleteBody, 'Sync complete.');
          } else {
            expect(l10n.syncChannelName, 'Фоновая синхронизация');
            expect(
              l10n.syncNotificationCompleteBody,
              'Синхронизация завершена.',
            );
          }
        }
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      },
    );
  });

  group('M2 TokenLifetimeOption and CacheLimitOption Locale Mappings Stress', () {
    test(
      'TokenLifetimeOption ID switch mapping covers all enum values completely',
      () {
        final expectedEn = {
          'everyOpen': 'Every app open',
          'oneHour': 'After 1 hour',
          'oneDay': 'After 1 day',
          'oneWeek': 'After 1 week',
          'oneMonth': 'After 1 month',
          'threeMonths': 'After 3 months',
          'never': 'Never on this device',
        };

        final expectedRu = {
          'everyOpen': 'При каждом открытии приложения',
          'oneHour': 'Через 1 час',
          'oneDay': 'Через 1 день',
          'oneWeek': 'Через 1 неделю',
          'oneMonth': 'Через 1 месяц',
          'threeMonths': 'Через 3 месяца',
          'never': 'Никогда на этом устройстве',
        };

        for (final option in TokenLifetimeOption.values) {
          final enLabel = switch (option.id) {
            'everyOpen' => enL10n.tokenLifetimeEveryOpen,
            'oneHour' => enL10n.tokenLifetimeOneHour,
            'oneDay' => enL10n.tokenLifetimeOneDay,
            'oneWeek' => enL10n.tokenLifetimeOneWeek,
            'oneMonth' => enL10n.tokenLifetimeOneMonth,
            'threeMonths' => enL10n.tokenLifetimeThreeMonths,
            'never' => enL10n.tokenLifetimeNever,
            _ => option.label,
          };

          final ruLabel = switch (option.id) {
            'everyOpen' => ruL10n.tokenLifetimeEveryOpen,
            'oneHour' => ruL10n.tokenLifetimeOneHour,
            'oneDay' => ruL10n.tokenLifetimeOneDay,
            'oneWeek' => ruL10n.tokenLifetimeOneWeek,
            'oneMonth' => ruL10n.tokenLifetimeOneMonth,
            'threeMonths' => ruL10n.tokenLifetimeThreeMonths,
            'never' => ruL10n.tokenLifetimeNever,
            _ => option.label,
          };

          expect(enLabel, equals(expectedEn[option.id]));
          expect(ruLabel, equals(expectedRu[option.id]));
        }
      },
    );

    test(
      'CacheLimitOption mapping accurately localizes Unlimited and retains byte labels',
      () {
        for (final option in CacheLimitOption.values) {
          final enLabel = option.bytes == CacheLimitOption.unlimitedBytes
              ? enL10n.cacheLimitUnlimited
              : option.label;
          final ruLabel = option.bytes == CacheLimitOption.unlimitedBytes
              ? ruL10n.cacheLimitUnlimited
              : option.label;

          if (option.bytes == CacheLimitOption.unlimitedBytes) {
            expect(enLabel, 'Unlimited');
            expect(ruLabel, 'Без ограничений');
          } else {
            expect(enLabel, option.label);
            expect(ruLabel, option.label);
          }
        }
      },
    );

    testWidgets(
      'SettingsScreen renders localized TokenLifetimeOption and CacheLimitOption in Russian',
      (tester) async {
        await _setTallViewport(tester);
        final manager = ActiveServerManager(
          store: ServerStore(),
          authService: AuthService(secretStore: InMemorySecretStore()),
        );

        await tester.pumpWidget(
          wrapWithLocalization(
            SettingsScreen(
              serverManager: manager,
              biometricAuthService: _StressFakeBiometricAuthService(false),
            ),
            locale: const Locale('ru'),
          ),
        );
        await tester.pumpAndSettle();

        // Check Dropdown for TokenLifetimeOption in Russian (default is oneMonth -> "Через 1 месяц")
        expect(find.text('Через 1 месяц'), findsOneWidget);

        final tokenDropdown = find.byType(
          DropdownButtonFormField<TokenLifetimeOption>,
        );
        await tester.tap(tokenDropdown);
        await tester.pumpAndSettle();

        expect(
          find.text('При каждом открытии приложения').last,
          findsOneWidget,
        );
        expect(find.text('Через 1 час').last, findsOneWidget);
        expect(find.text('Через 1 день').last, findsOneWidget);
        expect(find.text('Через 1 неделю').last, findsOneWidget);
        expect(find.text('Через 1 месяц').last, findsOneWidget);
        expect(find.text('Через 3 месяца').last, findsOneWidget);
        expect(find.text('Никогда на этом устройстве').last, findsOneWidget);

        // Close dropdown by tapping current selection
        await tester.tap(find.text('Через 1 месяц').last);
        await tester.pumpAndSettle();

        // Check Dropdown for CacheLimitOption in Russian
        final cacheDropdown = find.byType(DropdownButtonFormField<int>);
        await tester.ensureVisible(cacheDropdown);
        await tester.pumpAndSettle();

        expect(find.text('Лимит кеша'), findsOneWidget);

        await tester.tap(cacheDropdown);
        await tester.pumpAndSettle();

        expect(find.text('500 MB').last, findsOneWidget);
        expect(find.text('1 GB').last, findsOneWidget);
        expect(find.text('5 GB').last, findsOneWidget);
        expect(find.text('Без ограничений').last, findsOneWidget);
      },
    );
  });

  group('M2 BiometricAuthService Prompt Reason Stress', () {
    test(
      'unlockSavedCredentials passes provided localizedReason to LocalAuthentication',
      () async {
        final mockAuth = _MockLocalAuthentication();
        final service = BiometricAuthService(auth: mockAuth);

        const customReason = 'Пользовательский запрос биометрии';
        final result = await service.unlockSavedCredentials(
          localizedReason: customReason,
        );

        expect(result, isTrue);
        expect(mockAuth.lastLocalizedReason, equals(customReason));
      },
    );

    test(
      'unlockSavedCredentials falls back to default reason when localizedReason is null',
      () async {
        final mockAuth = _MockLocalAuthentication();
        final service = BiometricAuthService(auth: mockAuth);

        final result = await service.unlockSavedCredentials();

        expect(result, isTrue);
        expect(
          mockAuth.lastLocalizedReason,
          equals("Unlock saved credentials for Crowley's Cloud."),
        );
      },
    );

    test(
      'unlockSavedCredentials receives Russian biometric unlock string from catalog',
      () async {
        final mockAuth = _MockLocalAuthentication();
        final service = BiometricAuthService(auth: mockAuth);

        final result = await service.unlockSavedCredentials(
          localizedReason: ruL10n.biometricUnlockReason,
        );

        expect(result, isTrue);
        expect(
          mockAuth.lastLocalizedReason,
          equals(
            "Разблокируйте сохранённые учётные данные для Crowley's Cloud.",
          ),
        );
      },
    );
  });

  group('M2 SyncService Localized Progress & Error Reporting Stress', () {
    late Directory tempDir;
    late ServerProfile testServer;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('m2_sync_stress_test');
      testServer = ServerProfile(
        id: 'stress_srv',
        displayName: 'Резервный Сервер',
        baseUrl: 'http://test.local',
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
      'syncServer emits complete sequence of Russian localized progress messages',
      () async {
        final file1 = await _createTestFile(tempDir, 'photo1.jpg', 'data1');
        final file2 = await _createTestFile(tempDir, 'photo2.jpg', 'data2');
        final api = _StressFakeApiClient();
        final stateStore = FileSyncStateStore(
          fileProvider: () async => File('${tempDir.path}/state.json'),
        );
        final service = SyncService(
          scanner: _StressFakeScanner([
            SyncCandidate(file: file1, remotePath: 'backup/photos/photo1.jpg'),
            SyncCandidate(file: file2, remotePath: 'backup/photos/photo2.jpg'),
          ]),
          apiClient: api,
          stateStore: stateStore,
        );

        final progressMessages = <String>[];
        final result = await service.syncServer(
          testServer,
          l10n: ruL10n,
          onProgress: (msg, prog) => progressMessages.add(msg),
        );

        expect(result.status, SyncRunStatus.success);
        expect(progressMessages, contains('Подключение к серверу...'));
        expect(
          progressMessages,
          contains('Сканирование файлов на устройстве...'),
        );
        expect(
          progressMessages,
          contains('Вычисление контрольной суммы (1/2): photo1.jpg'),
        );
        expect(
          progressMessages,
          contains('Вычисление контрольной суммы (2/2): photo2.jpg'),
        );
        expect(progressMessages, contains('Проверка дубликатов на сервере...'));
        expect(progressMessages, contains('Синхронизация (1/2): photo1.jpg'));
        expect(progressMessages, contains('Синхронизация (2/2): photo2.jpg'));
        expect(progressMessages, contains('Завершение синхронизации...'));
      },
    );

    test(
      'syncServer returns Russian connection lost message on ping failure',
      () async {
        final api = _StressFakeApiClient()..isServerUnreachable = true;
        final stateStore = FileSyncStateStore(
          fileProvider: () async => File('${tempDir.path}/state.json'),
        );
        final service = SyncService(
          scanner: _StressFakeScanner([]),
          apiClient: api,
          stateStore: stateStore,
        );

        final result = await service.syncServer(testServer, l10n: ruL10n);

        expect(result.status, SyncRunStatus.serverUnreachable);
        expect(
          result.message,
          'Не удалось подключиться к Резервный Сервер. Соединение потеряно.',
        );
      },
    );

    test(
      'syncServer returns Russian no files selected message when candidate list empty',
      () async {
        final api = _StressFakeApiClient();
        final stateStore = FileSyncStateStore(
          fileProvider: () async => File('${tempDir.path}/state.json'),
        );
        final service = SyncService(
          scanner: _StressFakeScanner([]),
          apiClient: api,
          stateStore: stateStore,
        );

        final result = await service.syncServer(testServer, l10n: ruL10n);

        expect(result.status, SyncRunStatus.noFiles);
        expect(result.message, 'Не выбраны файлы для синхронизации.');
      },
    );
  });

  group('M2 AppUpdateService & Dialog Russian Localization Stress', () {
    test(
      'AppReleaseItem.fromJson falls back to localized release notes message',
      () {
        final itemEn = AppReleaseItem.fromJson({
          'tag_name': 'v1.5.0',
          'body': null,
        }, l10n: enL10n);
        final itemRu = AppReleaseItem.fromJson({
          'tag_name': 'v1.5.0',
          'body': null,
        }, l10n: ruL10n);

        expect(itemEn.body, 'No release notes provided.');
        expect(itemRu.body, 'Примечания к выпуску не предоставлены.');
      },
    );

    test(
      'checkForUpdates handles 404 with Russian localized fallback string',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({'message': 'Not Found'}), 404);
        });

        final service = AppUpdateService(currentVersion: '1.0.0');
        final result = await service.checkForUpdates(
          client: mockClient,
          l10n: ruL10n,
        );

        expect(result, isNotNull);
        expect(result!.hasUpdate, isFalse);
        expect(result.releaseNotes, 'Выпуски пока не опубликованы.');
      },
    );

    testWidgets('AppUpdateDialog renders full Russian interface correctly', (
      tester,
    ) async {
      const updateInfo = AppUpdateInfo(
        hasUpdate: true,
        currentVersion: '1.0.0',
        latestVersion: '1.5.0',
        latestReleaseName: 'v1.5.0 - Большое обновление',
        releaseNotes:
            '### Изменения\n- Локализация всех модулей\n- Исправление ошибок',
        htmlUrl:
            'https://github.com/SinnCrowley/crowleys_cloud/releases/tag/v1.5.0',
        apkUrl: 'https://example.com/crowleys-cloud.apk',
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          const Scaffold(body: AppUpdateDialog(updateInfo: updateInfo)),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Доступно обновление'), findsOneWidget);
      expect(find.text('v1.5.0 - Большое обновление'), findsOneWidget);
      expect(find.text('Текущая: v1.0.0'), findsOneWidget);
      expect(find.text('Новая: v1.5.0'), findsOneWidget);
      expect(find.text('Что нового:'), findsOneWidget);
      expect(find.text('Позже'), findsOneWidget);
      expect(find.text('Скачать APK'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
    });
  });

  group('M2 SettingsScreen Complete Russian Dialog & Interactive Stress', () {
    late ActiveServerManager serverManager;
    late ServerProfile activeProfile;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      activeProfile = ServerProfile(
        id: 'active_srv',
        displayName: 'Домашний Сервер',
        baseUrl: 'http://home.local',
        authMode: 'login',
        lastUsedAt: DateTime.utc(2026, 8, 18),
        syncPrefs: const {
          'syncEnabled': true,
          'backupWifiOnly': true,
          'backupChargingOnly': false,
          'backupTargetDirectory': '/backup/phone',
          'syncFrequency': 15,
          'syncCategories': ['photos', 'videos'],
          'syncFolders': ['/storage/emulated/0/DCIM', '/storage/emulated/0'],
        },
      );
      serverManager =
          ActiveServerManager(
              store: ServerStore(),
              authService: AuthService(secretStore: InMemorySecretStore()),
            )
            ..activeServer = activeProfile
            ..servers = [activeProfile];
    });

    testWidgets('Renders all Russian section titles and tiles correctly', (
      tester,
    ) async {
      await _setTallViewport(tester);
      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: serverManager,
            biometricAuthService: _StressFakeBiometricAuthService(true),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      // Section titles
      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Внешний вид и оформление'), findsOneWidget);
      expect(
        find.text('Резервное копирование и синхронизация'),
        findsOneWidget,
      );
      expect(find.text('Хранилище и кеш'), findsOneWidget);
      expect(find.text('Безопасность и поведение'), findsOneWidget);
      expect(find.text('О приложении и обновления'), findsOneWidget);

      // Appearance
      expect(find.text('Тема оформления'), findsOneWidget);
      expect(find.text('Тёмная'), findsOneWidget);
      expect(find.text('Светлая'), findsOneWidget);
      expect(find.text('Своя'), findsOneWidget);
      expect(find.text('Акцентный цвет'), findsOneWidget);
      expect(find.text('Масштаб шрифта'), findsOneWidget);

      // Backup & Sync
      expect(find.text('Синхронизация папок и категорий'), findsOneWidget);
      expect(find.text('Только по Wi-Fi'), findsOneWidget);
      expect(find.text('Только при зарядке'), findsOneWidget);
      expect(find.text('Целевая директория на сервере'), findsOneWidget);
      expect(find.text('Частота синхронизации'), findsOneWidget);
      expect(find.text('Каждые 15 минут'), findsOneWidget);
      expect(find.text('Синхронизировать сейчас'), findsOneWidget);
      expect(find.text('Категории для синхронизации'), findsOneWidget);
      expect(find.text('2 выбрано'), findsOneWidget);
      expect(find.text('Папки для синхронизации'), findsOneWidget);
      expect(find.text('2 папка(-ок)'), findsOneWidget);
      expect(find.text('/DCIM'), findsOneWidget);
      expect(find.text('Хранилище'), findsWidgets);

      // Storage & Cache
      expect(find.text('Размер кеша'), findsOneWidget);
      expect(find.text('Лимит кеша'), findsOneWidget);
      expect(find.text('Путь загрузки'), findsOneWidget);
      expect(find.text('Папка CrowleysCloud по умолчанию'), findsOneWidget);
      expect(find.text('Очистить кеш'), findsOneWidget);

      // Security & Behavior
      expect(find.text('Требовать вход'), findsOneWidget);
      expect(find.text('Биометрический вход'), findsOneWidget);
      expect(find.text('Показывать скрытые файлы'), findsOneWidget);
      expect(find.text('Изменить пароль'), findsOneWidget);
      expect(find.text('Удалить аккаунт'), findsOneWidget);

      // About
      expect(find.text('Проверить обновления'), findsOneWidget);
      expect(find.text('Версия $appVersion'), findsOneWidget);
    });

    testWidgets('Password Change Dialog validation strings in Russian', (
      tester,
    ) async {
      await _setTallViewport(tester);
      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: serverManager,
            biometricAuthService: _StressFakeBiometricAuthService(true),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Изменить пароль'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Изменить пароль'));
      await tester.pumpAndSettle();

      expect(find.text('Изменить пароль'), findsWidgets);
      expect(find.text('Новый пароль'), findsOneWidget);
      expect(find.text('Подтвердите пароль'), findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('Сохранить'), findsOneWidget);

      // Submit empty -> validation error
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('Введите новый пароль.'), findsOneWidget);

      // Enter mismatched passwords -> validation error
      await tester.enterText(
        find.widgetWithText(TextField, 'Новый пароль'),
        'secret1',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Подтвердите пароль'),
        'secret2',
      );
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('Пароли не совпадают.'), findsOneWidget);
    });

    testWidgets('Delete Account Confirmation Dialog strings in Russian', (
      tester,
    ) async {
      await _setTallViewport(tester);
      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: serverManager,
            biometricAuthService: _StressFakeBiometricAuthService(true),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Удалить аккаунт'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить аккаунт'));
      await tester.pumpAndSettle();

      expect(find.text('Удалить аккаунт?'), findsOneWidget);
      expect(
        find.text(
          'Это навсегда удалит ваш аккаунт на Домашний Сервер и все файлы в личном облаке. Это действие нельзя отменить.',
        ),
        findsOneWidget,
      );
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('Удалить аккаунт'), findsWidgets);
    });

    testWidgets('Clear Cache Dialog strings in Russian', (tester) async {
      await _setTallViewport(tester);
      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: serverManager,
            biometricAuthService: _StressFakeBiometricAuthService(true),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Очистить кеш'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Очистить кеш'));
      await tester.pumpAndSettle();

      expect(find.text('Очистить кеш?'), findsOneWidget);
      expect(
        find.text(
          'Это удалит локальные миниатюры и кешированные данные сервера.',
        ),
        findsOneWidget,
      );
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('Очистить'), findsOneWidget);
    });

    testWidgets(
      'Download Path and Target Directory Dialog strings in Russian',
      (tester) async {
        await _setTallViewport(tester);
        await tester.pumpWidget(
          wrapWithLocalization(
            SettingsScreen(
              serverManager: serverManager,
              biometricAuthService: _StressFakeBiometricAuthService(true),
            ),
            locale: const Locale('ru'),
          ),
        );
        await tester.pumpAndSettle();

        // Download path dialog
        await tester.ensureVisible(find.text('Путь загрузки'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Путь загрузки'));
        await tester.pumpAndSettle();
        expect(find.text('Путь загрузки'), findsWidgets);
        expect(find.text('/storage/emulated/0/CrowleysCloud'), findsOneWidget);
        expect(find.text('По умолчанию'), findsOneWidget);
        expect(find.text('Отмена'), findsOneWidget);
        expect(find.text('Сохранить'), findsOneWidget);

        await tester.tap(find.text('Отмена'));
        await tester.pumpAndSettle();

        // Target directory dialog
        await tester.ensureVisible(find.text('Целевая директория на сервере'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Целевая директория на сервере'));
        await tester.pumpAndSettle();
        expect(find.text('Целевая директория на сервере'), findsWidgets);
        expect(find.text('/backup/mobile_phone'), findsOneWidget);
        expect(find.text('Отмена'), findsOneWidget);
        expect(find.text('Сохранить'), findsOneWidget);
      },
    );

    testWidgets(
      'Sync Frequency Picker Dialog strings in Russian for all intervals',
      (tester) async {
        await _setTallViewport(tester);
        await tester.pumpWidget(
          wrapWithLocalization(
            SettingsScreen(
              serverManager: serverManager,
              biometricAuthService: _StressFakeBiometricAuthService(true),
            ),
            locale: const Locale('ru'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Частота синхронизации'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Частота синхронизации'));
        await tester.pumpAndSettle();

        expect(find.text('Выберите частоту синхронизации'), findsOneWidget);
        expect(find.text('Каждые 15 минут'), findsWidgets);
        expect(find.text('Каждые 30 минут'), findsOneWidget);
        expect(find.text('Каждый час'), findsOneWidget);
        expect(find.text('Каждые 2 ч'), findsOneWidget);
        expect(find.text('Каждые 4 ч'), findsOneWidget);
        expect(find.text('Каждые 8 ч'), findsOneWidget);
        expect(find.text('Каждые 12 ч'), findsOneWidget);
        expect(find.text('Ежедневно'), findsOneWidget);
      },
    );

    testWidgets('Sync Categories Dialog strings and sections in Russian', (
      tester,
    ) async {
      await _setTallViewport(tester);
      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: serverManager,
            biometricAuthService: _StressFakeBiometricAuthService(true),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Категории для синхронизации'));
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
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('Сохранить'), findsOneWidget);
    });
  });
}
