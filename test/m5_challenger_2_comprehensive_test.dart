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

import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_ar.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_bn.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_cs.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_de.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_en.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_es.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_fa.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_fr.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_hi.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_id.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_it.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_ja.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_ko.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_pl.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_pt.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_ru.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_tr.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_uk.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_vi.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_zh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final allLocalesWithExpectedTypes = <Locale, Type>{
    const Locale('ar'): AppLocalizationsAr,
    const Locale('bn'): AppLocalizationsBn,
    const Locale('cs'): AppLocalizationsCs,
    const Locale('de'): AppLocalizationsDe,
    const Locale('en'): AppLocalizationsEn,
    const Locale('es'): AppLocalizationsEs,
    const Locale('fa'): AppLocalizationsFa,
    const Locale('fr'): AppLocalizationsFr,
    const Locale('hi'): AppLocalizationsHi,
    const Locale('id'): AppLocalizationsId,
    const Locale('it'): AppLocalizationsIt,
    const Locale('ja'): AppLocalizationsJa,
    const Locale('ko'): AppLocalizationsKo,
    const Locale('pl'): AppLocalizationsPl,
    const Locale('pt'): AppLocalizationsPt,
    const Locale('pt', 'BR'): AppLocalizationsPtBr,
    const Locale('ru'): AppLocalizationsRu,
    const Locale('tr'): AppLocalizationsTr,
    const Locale('uk'): AppLocalizationsUk,
    const Locale('vi'): AppLocalizationsVi,
    const Locale('zh'): AppLocalizationsZh,
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'): AppLocalizationsZhHans,
  };

  const expectedArbFiles = [
    'app_ar.arb',
    'app_bn.arb',
    'app_cs.arb',
    'app_de.arb',
    'app_en.arb',
    'app_es.arb',
    'app_fa.arb',
    'app_fr.arb',
    'app_hi.arb',
    'app_id.arb',
    'app_it.arb',
    'app_ja.arb',
    'app_ko.arb',
    'app_pl.arb',
    'app_pt.arb',
    'app_pt_BR.arb',
    'app_ru.arb',
    'app_tr.arb',
    'app_uk.arb',
    'app_vi.arb',
    'app_zh.arb',
    'app_zh_Hans.arb',
  ];

  const expectedWebJsonFiles = [
    'ar.json',
    'bn.json',
    'cs.json',
    'de.json',
    'en.json',
    'es.json',
    'fa.json',
    'fr.json',
    'hi.json',
    'id.json',
    'it.json',
    'ja.json',
    'ko.json',
    'pl.json',
    'pt-BR.json',
    'pt.json',
    'ru.json',
    'tr.json',
    'uk.json',
    'vi.json',
    'zh-CN.json',
    'zh.json',
  ];

  List<String> flattenJson(dynamic value, [String prefix = '']) {
    if (value is! Map<String, dynamic>) {
      return prefix.isNotEmpty ? [prefix] : [];
    }
    final results = <String>[];
    for (final entry in value.entries) {
      if (entry.key == '@@locale' || entry.key.startsWith('@')) continue;
      final full = prefix.isNotEmpty ? '$prefix.${entry.key}' : entry.key;
      if (entry.value is Map<String, dynamic>) {
        results.addAll(flattenJson(entry.value, full));
      } else {
        results.add(full);
      }
    }
    return results;
  }

  group('M5 Challenger 2: Static Catalog Integrity & Key Parity', () {
    test('All 22 ARB files exist with @@locale header and exact 507 key parity', () {
      final enFile = File('lib/l10n/app_en.arb');
      expect(enFile.existsSync(), isTrue);
      final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final baseKeys = enMap.keys.where((k) => !k.startsWith('@')).toSet();

      expect(baseKeys.length, equals(507));

      for (final arbName in expectedArbFiles) {
        final arbFile = File('lib/l10n/$arbName');
        expect(arbFile.existsSync(), isTrue, reason: '$arbName does not exist');
        final content = arbFile.readAsStringSync();
        final arbMap = jsonDecode(content) as Map<String, dynamic>;

        expect(arbMap.containsKey('@@locale'), isTrue, reason: '$arbName missing @@locale');
        final currentKeys = arbMap.keys.where((k) => !k.startsWith('@')).toSet();

        final missing = baseKeys.difference(currentKeys);
        final extra = currentKeys.difference(baseKeys);

        expect(missing, isEmpty, reason: '$arbName missing keys: $missing');
        expect(extra, isEmpty, reason: '$arbName extra keys: $extra');
        expect(currentKeys.length, equals(507));

        for (final key in currentKeys) {
          final val = arbMap[key].toString().trim();
          expect(val, isNotEmpty, reason: '$arbName key "$key" is empty');
        }
      }
    });

    test('All 22 Web JSON files exist with exact 319 flattened key parity', () {
      final enFile = File('server/web/src/i18n/en.json');
      expect(enFile.existsSync(), isTrue);
      final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final baseKeys = flattenJson(enMap).toSet();

      expect(baseKeys.length, equals(319));

      for (final jsonName in expectedWebJsonFiles) {
        final jsonFile = File('server/web/src/i18n/$jsonName');
        expect(jsonFile.existsSync(), isTrue, reason: '$jsonName does not exist');
        final content = jsonFile.readAsStringSync();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;
        final currentKeys = flattenJson(jsonMap).toSet();

        final missing = baseKeys.difference(currentKeys);
        final extra = currentKeys.difference(baseKeys);

        expect(missing, isEmpty, reason: '$jsonName missing keys: $missing');
        expect(extra, isEmpty, reason: '$jsonName extra keys: $extra');
        expect(currentKeys.length, equals(319));
      }
    });
  });

  group('M5 Challenger 2: Runtime Resolution Across All 22 Locales', () {
    test('AppLocalizations.supportedLocales matches exactly all 22 supported locales', () {
      expect(AppLocalizations.supportedLocales.length, equals(22));
      for (final loc in allLocalesWithExpectedTypes.keys) {
        expect(AppLocalizations.supportedLocales.contains(loc), isTrue, reason: 'Missing locale $loc');
      }
    });

    for (final entry in allLocalesWithExpectedTypes.entries) {
      final locale = entry.key;
      final expectedType = entry.value;

      test('lookupAppLocalizations($locale) returns valid $expectedType instance', () {
        final l10n = lookupAppLocalizations(locale);
        expect(l10n, isNotNull);
        expect(l10n.runtimeType, equals(expectedType));
      });
    }

    test('Unsupported locale throws FlutterError', () {
      expect(() => lookupAppLocalizations(const Locale('zz')), throwsA(isA<FlutterError>()));
      expect(() => lookupAppLocalizations(const Locale('unknown')), throwsA(isA<FlutterError>()));
    });
  });

  group('M5 Challenger 2: Comprehensive Method & Parameterized Stress Testing (All 22 Locales)', () {
    final testStrings = [
      'NormalString',
      '',
      '   ',
      'Special !@#\$%^&*()_+-=[]{}|;\':",.<>/?',
      'Unicode_🌟_Тест_Zażółć_Příliš_中文_日本語_한국어_العربية_فارسی_বাংলা_हिन्दी_TiếngViệt',
      'A' * 200,
    ];

    final testInts = [0, 1, 2, 3, 4, 5, 6, 10, 11, 14, 20, 21, 22, 25, 100, 101, 102, 105, 111, 999999, -1];

    for (final entry in allLocalesWithExpectedTypes.entries) {
      final locale = entry.key;

      test('Locale $locale stress tests all parameterized methods and non-empty getters', () {
        final l10n = lookupAppLocalizations(locale);

        // Core getters
        expect(l10n.appTitle, isNotEmpty);
        expect(l10n.ok, isNotEmpty);
        expect(l10n.cancel, isNotEmpty);
        expect(l10n.save, isNotEmpty);
        expect(l10n.delete, isNotEmpty);
        expect(l10n.rename, isNotEmpty);
        expect(l10n.close, isNotEmpty);
        expect(l10n.retry, isNotEmpty);
        expect(l10n.loading, isNotEmpty);
        expect(l10n.confirm, isNotEmpty);
        expect(l10n.error, isNotEmpty);
        expect(l10n.settingsTitle, isNotEmpty);
        expect(l10n.welcomeBack, isNotEmpty);

        // String parameter methods
        for (final s in testStrings) {
          expect(l10n.errorWithMessage(s), isNotEmpty);
          expect(l10n.authFailed(s), isNotEmpty);
          expect(l10n.signInToAccess(s), isNotEmpty);
          expect(l10n.unableToConnectTo(s), isNotEmpty);
          expect(l10n.switchServerBody(s), isNotEmpty);
          expect(l10n.syncNotificationSyncingWith(s), isNotEmpty);
          expect(l10n.uploadErrorLocalPathEmpty(s), isNotEmpty);
          expect(l10n.selectColor(s), isNotEmpty);
        }

        // Multi-string parameter methods
        expect(l10n.renamedOldToNew('old_name.txt', 'new_name.txt'), isNotEmpty);
        expect(l10n.copiedOldToNew('old_name.txt', 'new_name.txt'), isNotEmpty);
        expect(l10n.movedOldToNew('old_name.txt', 'new_name.txt'), isNotEmpty);

        // Int / plural parameter methods
        for (final n in testInts) {
          expect(l10n.uploadSummaryFailedCount(n), isNotEmpty);
          expect(l10n.uploadedNItems(n), isNotEmpty);
          expect(l10n.uploadErrorFolderCreateHttp(n), isNotEmpty);
          expect(l10n.movedNItems(n), isNotEmpty);
          expect(l10n.sharedNItemsInServer(n), isNotEmpty);
          expect(l10n.deleteFilesBody(n), isNotEmpty);
          expect(l10n.unshareItemsBody(n), isNotEmpty);
          expect(l10n.nCategoriesSelected(n), isNotEmpty);
          expect(l10n.nFolders(n), isNotEmpty);
          expect(l10n.storageStatsNItems(n), isNotEmpty);
          expect(l10n.syncFreqEveryNHours(n), isNotEmpty);
          expect(l10n.syncFreqEveryNMin(n), isNotEmpty);
          expect(l10n.nSelected(n), isNotEmpty);
          expect(l10n.deleteTrashConfirmationMessage(n), isNotEmpty);
        }

        // Mixed int + string parameter methods
        for (final n in [1, 2, 5, 21]) {
          for (final s in ['/path/to/folder', 'file.txt']) {
            expect(l10n.downloadedNFilesToPath(n, s), isNotEmpty);
            expect(l10n.failedToRenameWithStatus(s, n), isNotEmpty);
            expect(l10n.failedToMoveWithStatus(s, n), isNotEmpty);
          }
        }
      });
    }
  });
}
