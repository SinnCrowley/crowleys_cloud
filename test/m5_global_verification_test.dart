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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expectedMobileLocales = [
    Locale('ar'),
    Locale('bn'),
    Locale('cs'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  const expectedArbFileNames = [
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

  const expectedWebJsonFileNames = [
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

  group('Milestone 5 Global Verification: Mobile ARB Catalog Integrity', () {
    test('All 22 ARB files exist in lib/l10n/', () {
      final l10nDir = Directory('lib/l10n');
      expect(l10nDir.existsSync(), isTrue, reason: 'lib/l10n must exist');

      final foundFiles = l10nDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .map((f) => f.path.split(Platform.pathSeparator).last)
          .toSet();

      expect(foundFiles, equals(expectedArbFileNames.toSet()));
      expect(foundFiles.length, equals(22));
    });

    test('Exact key parity across all 22 Mobile ARB files (507 keys matching app_en.arb)', () {
      final enFile = File('lib/l10n/app_en.arb');
      final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final baseKeys = enMap.keys.where((k) => !k.startsWith('@')).toSet();

      expect(baseKeys.length, equals(507), reason: 'app_en.arb must contain exactly 507 keys');

      for (final arbFileName in expectedArbFileNames) {
        final arbFile = File('lib/l10n/$arbFileName');
        expect(arbFile.existsSync(), isTrue, reason: '$arbFileName must exist');

        final arbMap = jsonDecode(arbFile.readAsStringSync()) as Map<String, dynamic>;
        final currentKeys = arbMap.keys.where((k) => !k.startsWith('@')).toSet();

        final missing = baseKeys.difference(currentKeys);
        final extra = currentKeys.difference(baseKeys);

        expect(missing, isEmpty, reason: '$arbFileName has missing keys: $missing');
        expect(extra, isEmpty, reason: '$arbFileName has extra keys: $extra');
        expect(currentKeys.length, equals(507), reason: '$arbFileName must contain exactly 507 keys');

        // Check non-empty values
        for (final key in currentKeys) {
          final val = arbMap[key].toString().trim();
          expect(val, isNotEmpty, reason: '$arbFileName: key "$key" is empty');
        }
      }
    });

    test('ICU Placeholders consistency across all 22 Mobile ARB files', () {
      final enFile = File('lib/l10n/app_en.arb');
      final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final placeholderRegex = RegExp(r'\{([a-zA-Z0-9_]+)\}');

      for (final arbFileName in expectedArbFileNames) {
        if (arbFileName == 'app_en.arb') continue;
        final arbFile = File('lib/l10n/$arbFileName');
        final arbMap = jsonDecode(arbFile.readAsStringSync()) as Map<String, dynamic>;

        for (final key in enMap.keys.where((k) => !k.startsWith('@'))) {
          final enStr = enMap[key].toString();
          final targetStr = arbMap[key].toString();

          // If the template contains simple {var} placeholders (and is not an ICU plural selector)
          if (!enStr.contains('plural,') && !targetStr.contains('plural,')) {
            final enPlaceholders = placeholderRegex.allMatches(enStr).map((m) => m.group(1)!).toSet();
            final targetPlaceholders = placeholderRegex.allMatches(targetStr).map((m) => m.group(1)!).toSet();

            expect(
              targetPlaceholders,
              equals(enPlaceholders),
              reason: 'Placeholder mismatch in $arbFileName for key "$key": EN=$enPlaceholders, Target=$targetPlaceholders',
            );
          }
        }
      }
    });
  });

  group('Milestone 5 Global Verification: Web JSON Dictionary Integrity', () {
    test('All 22 Web JSON files exist in server/web/src/i18n/', () {
      final webDir = Directory('server/web/src/i18n');
      expect(webDir.existsSync(), isTrue, reason: 'server/web/src/i18n must exist');

      final foundFiles = webDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .map((f) => f.path.split(Platform.pathSeparator).last)
          .toSet();

      expect(foundFiles, equals(expectedWebJsonFileNames.toSet()));
      expect(foundFiles.length, equals(22));
    });

    test('Exact key parity across all 22 Web JSON files (319 keys matching en.json)', () {
      final enFile = File('server/web/src/i18n/en.json');
      final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final baseKeys = flattenJson(enMap).toSet();

      expect(baseKeys.length, equals(319), reason: 'en.json must contain exactly 319 flattened keys');

      for (final jsonFileName in expectedWebJsonFileNames) {
        final jsonFile = File('server/web/src/i18n/$jsonFileName');
        expect(jsonFile.existsSync(), isTrue, reason: '$jsonFileName must exist');

        final jsonMap = jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
        final currentKeys = flattenJson(jsonMap).toSet();

        final missing = baseKeys.difference(currentKeys);
        final extra = currentKeys.difference(baseKeys);

        expect(missing, isEmpty, reason: '$jsonFileName has missing keys: $missing');
        expect(extra, isEmpty, reason: '$jsonFileName has extra keys: $extra');
        expect(currentKeys.length, equals(319), reason: '$jsonFileName must contain exactly 319 flattened keys');
      }
    });
  });

  group('Milestone 5 Global Verification: Runtime AppLocalizations Resolution', () {
    test('AppLocalizations.supportedLocales has all 22 locales', () {
      expect(AppLocalizations.supportedLocales.length, equals(22));
      for (final loc in expectedMobileLocales) {
        expect(
          AppLocalizations.supportedLocales.contains(loc),
          isTrue,
          reason: 'AppLocalizations.supportedLocales must contain $loc',
        );
      }
    });

    test('lookupAppLocalizations successfully returns non-null instance for all 22 locales', () {
      for (final loc in expectedMobileLocales) {
        final l10n = lookupAppLocalizations(loc);
        expect(l10n, isNotNull, reason: 'Failed to look up AppLocalizations for $loc');
        expect(l10n.appTitle, isNotEmpty, reason: 'appTitle empty for $loc');
        expect(l10n.ok, isNotEmpty, reason: 'ok empty for $loc');
        expect(l10n.cancel, isNotEmpty, reason: 'cancel empty for $loc');
        expect(l10n.save, isNotEmpty, reason: 'save empty for $loc');
        expect(l10n.delete, isNotEmpty, reason: 'delete empty for $loc');
        expect(l10n.settingsTitle, isNotEmpty, reason: 'settingsTitle empty for $loc');
      }
    });

    test('All parameterized formatters produce valid strings for all 22 locales', () {
      for (final loc in expectedMobileLocales) {
        final l10n = lookupAppLocalizations(loc);

        // String parameter tests
        expect(l10n.errorWithMessage('Test Error'), contains('Test Error'));
        expect(l10n.signInToAccess('My Server'), contains('My Server'));
        expect(l10n.syncNotificationSyncingWith('NAS'), contains('NAS'));

        // Int parameter tests
        expect(l10n.uploadSummaryFailedCount(5), isNotEmpty);
        expect(l10n.uploadedNItems(1), isNotEmpty);
        expect(l10n.uploadedNItems(5), isNotEmpty);
        expect(l10n.nSelected(10), isNotEmpty);
      }
    });
  });
}
