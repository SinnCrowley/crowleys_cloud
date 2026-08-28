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
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/biometric_auth_service.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:crowleys_cloud/settings_screen.dart';
import 'package:crowleys_cloud/theme_customizer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

class _MockAuthGateway implements AuthGateway {
  @override
  Future<AuthResult> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    return const AuthResult(accessToken: 'mock_access', refreshToken: 'mock_refresh');
  }

  @override
  Future<AuthResult> refresh({
    required String baseUrl,
    required String refreshToken,
  }) async {
    return const AuthResult(accessToken: 'mock_refreshed', refreshToken: 'mock_refresh');
  }

  @override
  Future<AuthResult> register({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    return const AuthResult(accessToken: 'mock_reg_access', refreshToken: 'mock_refresh');
  }
}

class _FakeBiometrics extends BiometricAuthService {
  @override
  Future<bool> canAuthenticate() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('M4/M5 CHALLENGER 2: ARB Key Parity & Integrity Oracles', () {
    test('100% ARB key parity and non-empty translations between EN and RU', () {
      final enFile = File('lib/l10n/app_en.arb');
      final ruFile = File('lib/l10n/app_ru.arb');

      expect(enFile.existsSync(), isTrue, reason: 'app_en.arb must exist');
      expect(ruFile.existsSync(), isTrue, reason: 'app_ru.arb must exist');

      final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final ruMap = jsonDecode(ruFile.readAsStringSync()) as Map<String, dynamic>;

      final enKeys = enMap.keys.where((k) => !k.startsWith('@')).toSet();
      final ruKeys = ruMap.keys.where((k) => !k.startsWith('@')).toSet();

      final missingInRu = enKeys.difference(ruKeys);
      final missingInEn = ruKeys.difference(enKeys);

      expect(missingInRu, isEmpty, reason: 'Keys in EN missing in RU: $missingInRu');
      expect(missingInEn, isEmpty, reason: 'Keys in RU missing in EN: $missingInEn');

      expect(enKeys.length, greaterThan(450), reason: 'Total translation keys count');
      expect(enKeys.length, equals(ruKeys.length), reason: 'Exact count parity');

      for (final key in enKeys) {
        final enVal = enMap[key].toString().trim();
        final ruVal = ruMap[key].toString().trim();

        expect(enVal, isNotEmpty, reason: 'EN key "$key" is empty');
        expect(ruVal, isNotEmpty, reason: 'RU key "$key" is empty');
      }
    });

    test('Placeholder consistency between EN and RU catalogs', () {
      final enFile = File('lib/l10n/app_en.arb');
      final ruFile = File('lib/l10n/app_ru.arb');

      final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final ruMap = jsonDecode(ruFile.readAsStringSync()) as Map<String, dynamic>;

      final placeholderRegex = RegExp(r'\{([a-zA-Z0-9_]+)\}');

      for (final key in enMap.keys.where((k) => !k.startsWith('@'))) {
        final enStr = enMap[key].toString();
        final ruStr = ruMap[key].toString();

        final enPlaceholders = placeholderRegex.allMatches(enStr).map((m) => m.group(1)!).toSet();
        final ruPlaceholders = placeholderRegex.allMatches(ruStr).map((m) => m.group(1)!).toSet();

        expect(
          ruPlaceholders,
          equals(enPlaceholders),
          reason: 'Placeholder mismatch for key "$key": EN=$enPlaceholders, RU=$ruPlaceholders',
        );
      }
    });
  });

  group('M4/M5 CHALLENGER 2: Stress-Testing Localizations with Adversarial Inputs', () {
    final enL10n = lookupAppLocalizations(const Locale('en'));
    final ruL10n = lookupAppLocalizations(const Locale('ru'));

    test('Exhaustive stress calls with extreme values, special chars, emojis, and unicode', () {
      final adversarialStrings = [
        '',
        '   ',
        'file.txt',
        '📁 /special/path/with spaces and (brackets) & % symbols!',
        '<script>alert("xss")</script>',
        'Привет, мир! 🚀 123 \n\t\r \u0000 \uFFFF',
        'A' * 1000,
      ];

      final adversarialNumbers = [0, 1, 2, 3, 4, 5, 11, 21, 22, 100, 101, 111, 999999, -1, -5];

      for (final text in adversarialStrings) {
        // String parameter methods
        expect(enL10n.errorWithMessage(text), isNotNull);
        expect(ruL10n.errorWithMessage(text), isNotNull);
        expect(enL10n.authFailed(text), isNotNull);
        expect(ruL10n.authFailed(text), isNotNull);
        expect(enL10n.uploadErrorLocalPathEmpty(text), isNotNull);
        expect(ruL10n.uploadErrorLocalPathEmpty(text), isNotNull);
        expect(enL10n.signInToAccess(text), isNotNull);
        expect(ruL10n.signInToAccess(text), isNotNull);
        expect(enL10n.unableToConnectTo(text), isNotNull);
        expect(ruL10n.unableToConnectTo(text), isNotNull);
        expect(enL10n.switchServerBody(text), isNotNull);
        expect(ruL10n.switchServerBody(text), isNotNull);
        expect(enL10n.syncNotificationSyncingWith(text), isNotNull);
        expect(ruL10n.syncNotificationSyncingWith(text), isNotNull);
        expect(enL10n.syncNotificationCompleteTitle(text), isNotNull);
        expect(ruL10n.syncNotificationCompleteTitle(text), isNotNull);
        expect(enL10n.syncNotificationFailedTitle(text), isNotNull);
        expect(ruL10n.syncNotificationFailedTitle(text), isNotNull);
        expect(enL10n.syncNotificationPausedTitle(text), isNotNull);
        expect(ruL10n.syncNotificationPausedTitle(text), isNotNull);
        expect(enL10n.selectColor(text), isNotNull);
        expect(ruL10n.selectColor(text), isNotNull);
      }

      for (final num in adversarialNumbers) {
        // Integer parameter methods
        expect(enL10n.uploadSummaryFailedCount(num), isNotNull);
        expect(ruL10n.uploadSummaryFailedCount(num), isNotNull);
        expect(enL10n.uploadedNItems(num), isNotNull);
        expect(ruL10n.uploadedNItems(num), isNotNull);
        expect(enL10n.uploadErrorFolderCreateHttp(num), isNotNull);
        expect(ruL10n.uploadErrorFolderCreateHttp(num), isNotNull);
        expect(enL10n.movedNItems(num), isNotNull);
        expect(ruL10n.movedNItems(num), isNotNull);
        expect(enL10n.sharedNItemsInServer(num), isNotNull);
        expect(ruL10n.sharedNItemsInServer(num), isNotNull);
        expect(enL10n.deleteFilesBody(num), isNotNull);
        expect(ruL10n.deleteFilesBody(num), isNotNull);
        expect(enL10n.unshareItemsBody(num), isNotNull);
        expect(ruL10n.unshareItemsBody(num), isNotNull);
        expect(enL10n.nCategoriesSelected(num), isNotNull);
        expect(ruL10n.nCategoriesSelected(num), isNotNull);
        expect(enL10n.nFolders(num), isNotNull);
        expect(ruL10n.nFolders(num), isNotNull);
        expect(enL10n.storageStatsNItems(num), isNotNull);
        expect(ruL10n.storageStatsNItems(num), isNotNull);
        expect(enL10n.syncFreqEveryNHours(num), isNotNull);
        expect(ruL10n.syncFreqEveryNHours(num), isNotNull);
        expect(enL10n.syncFreqEveryNMin(num), isNotNull);
        expect(ruL10n.syncFreqEveryNMin(num), isNotNull);
        expect(enL10n.userFallback(num), isNotNull);
        expect(ruL10n.userFallback(num), isNotNull);
      }
    });

    test('Cyrillic character verification for core Russian localizations', () {
      final cyrillicRegex = RegExp(r'[\u0400-\u04FF]');

      expect(cyrillicRegex.hasMatch(ruL10n.welcomeBack), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.settingsTitle), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.allFiles), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.categoryPhotos), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.categoryVideos), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.categoryAudio), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.categoryDocuments), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.categoryOther), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.categoryShared), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.deleteAccountTitle), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.newFolder), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.serverTargetDirectory), isTrue);
      expect(cyrillicRegex.hasMatch(ruL10n.syncFreqEvery15Min), isTrue);
    });
  });

  group('M4/M5 CHALLENGER 2: Screen & Dialog Rendering Parity', () {
    testWidgets('SettingsScreen appearance and behavior sections render localized in EN and RU', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final secretStore = InMemorySecretStore();
      final auth = AuthService(secretStore: secretStore, gateway: _MockAuthGateway());
      final serverStore = ServerStore();
      final serverManager = ActiveServerManager(store: serverStore, authService: auth);

      // EN
      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: serverManager,
            settingsService: AppSettingsService(),
            biometricAuthService: _FakeBiometrics(),
            cacheService: CacheService.instance,
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance & Customization'), findsOneWidget);
      expect(find.text('Storage & Cache'), findsOneWidget);
      expect(find.text('Security & Behavior'), findsOneWidget);
      expect(find.text('About & Updates'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // RU
      await tester.pumpWidget(
        wrapWithLocalization(
          SettingsScreen(
            serverManager: serverManager,
            settingsService: AppSettingsService(),
            biometricAuthService: _FakeBiometrics(),
            cacheService: CacheService.instance,
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Внешний вид и оформление'), findsOneWidget);
      expect(find.text('Хранилище и кеш'), findsOneWidget);
      expect(find.text('Безопасность и поведение'), findsOneWidget);
      expect(find.text('О приложении и обновления'), findsOneWidget);
      expect(find.text('Тёмная'), findsOneWidget);
      expect(find.text('Светлая'), findsOneWidget);
      expect(find.text('Своя'), findsOneWidget);
    });

    testWidgets('ColorPickerDialog renders localized in EN and RU', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ColorPickerDialog.show(
                  ctx,
                  initialColor: Colors.deepPurple,
                  title: 'Select Accent Color',
                ),
                child: const Text('Show Color Picker EN'),
              ),
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Color Picker EN'));
      await tester.pumpAndSettle();

      expect(find.text('Select Accent Color'), findsOneWidget);
      expect(find.text('Presets'), findsOneWidget);
      expect(find.text('Custom Palette'), findsOneWidget);
      expect(find.text('HEX RGB Code'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ColorPickerDialog.show(
                  ctx,
                  initialColor: Colors.deepPurple,
                  title: 'Выбор цвета',
                ),
                child: const Text('Show Color Picker RU'),
              ),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Color Picker RU'));
      await tester.pumpAndSettle();

      expect(find.text('Выбор цвета'), findsOneWidget);
      expect(find.text('Пресеты'), findsOneWidget);
      expect(find.text('Пользовательская палитра'), findsOneWidget);
      expect(find.text('HEX RGB код'), findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('Применить'), findsOneWidget);
    });
  });

  group('M4/M5 CHALLENGER 2: Static Hardcoded UI String Static Scan', () {
    test('Zero untranslated UI literal strings across all screen and dialog files', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('/l10n/generated/'))
          .where((f) => !f.path.contains('/proto/'))
          .toList();

      final suspiciousPatterns = [
        RegExp(r'''Text\(\s*['"](Sign in|Welcome|Delete|Cancel|Save|Settings|Upload|Download|Search|Folder|Server|Error)['"]\s*\)''', caseSensitive: false),
        RegExp(r'''Tooltip\(\s*message:\s*['"]([a-zA-Z\s]{4,})['"]'''),
        RegExp(r'''SnackBar\(\s*content:\s*Text\(\s*['"]([a-zA-Z\s]{4,})['"]\s*\)\)'''),
      ];

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Skip comments
          if (line.trim().startsWith('//') || line.trim().startsWith('/*') || line.trim().startsWith('*')) {
            continue;
          }
          for (final pattern in suspiciousPatterns) {
            if (pattern.hasMatch(line)) {
              violations.add('${file.path}:${i + 1}: $line');
            }
          }
        }
      }

      expect(violations, isEmpty, reason: 'Found suspicious hardcoded UI strings:\n${violations.join('\n')}');
    });
  });
}
