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

import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('AppLocalizations loads Russian strings properly', (
    tester,
  ) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      wrapWithLocalization(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(body: Text(l10n.welcomeBack));
          },
        ),
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('С возвращением'), findsOneWidget);
    expect(l10n.allFiles, 'Все');
    expect(l10n.navSettings, 'Настройки');
    expect(l10n.deletePermanently, 'Удалить навсегда');
    expect(l10n.nSelected(5), '5 выбрано');
    expect(l10n.uploadedNItems(3), 'Загружено 3 файл(ов)');
    expect(
      l10n.biometricUnlockReason,
      "Разблокируйте сохранённые учётные данные для Crowley's Cloud.",
    );
    expect(l10n.tokenLifetimeEveryOpen, 'При каждом открытии приложения');
    expect(l10n.tokenLifetimeOneHour, 'Через 1 час');
    expect(l10n.cacheLimitUnlimited, 'Без ограничений');
    expect(l10n.internalStorage, 'Внутренняя память');
    expect(l10n.syncNotificationSyncingWith('NAS'), 'Синхронизация с NAS');
    expect(l10n.transferSummaryFiles(75, 3, 4), '75%  3/4 файлов');
    expect(
      l10n.downloadedNFilesToPath(2, '/path'),
      'Скачано файлов: 2 в /path',
    );
    expect(
      l10n.renamedOldToNew('old.txt', 'new.txt'),
      '«old.txt» переименован в «new.txt».',
    );
    expect(
      l10n.failedToRenameWithStatus('file.png', 404),
      'Не удалось переименовать «file.png» (404).',
    );
  });

  testWidgets('AppLocalizations loads English strings properly', (
    tester,
  ) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      wrapWithLocalization(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(body: Text(l10n.welcomeBack));
          },
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(
      l10n.biometricUnlockReason,
      "Unlock saved credentials for Crowley's Cloud.",
    );
    expect(l10n.tokenLifetimeEveryOpen, 'Every app open');
    expect(l10n.tokenLifetimeOneHour, 'After 1 hour');
    expect(l10n.cacheLimitUnlimited, 'Unlimited');
    expect(l10n.internalStorage, 'Internal Storage');
    expect(l10n.syncNotificationSyncingWith('NAS'), 'Syncing with NAS');
    expect(l10n.transferSummaryFiles(75, 3, 4), '75%  3/4 files');
    expect(
      l10n.downloadedNFilesToPath(2, '/path'),
      'Downloaded 2 file(s) to /path',
    );
    expect(
      l10n.renamedOldToNew('old.txt', 'new.txt'),
      'Renamed "old.txt" to "new.txt".',
    );
    expect(
      l10n.failedToRenameWithStatus('file.png', 404),
      'Failed to rename "file.png" (404).',
    );
  });

  test(
    'lookupAppLocalizations works without BuildContext for background tasks',
    () {
      final enL10n = lookupAppLocalizations(const Locale('en'));
      final ruL10n = lookupAppLocalizations(const Locale('ru'));

      expect(
        enL10n.syncNotificationSyncingWith('ServerA'),
        'Syncing with ServerA',
      );
      expect(
        ruL10n.syncNotificationSyncingWith('ServerA'),
        'Синхронизация с ServerA',
      );
      expect(
        enL10n.syncNotificationUnreachableBody,
        'Server is unreachable. Background sync paused until app is opened.',
      );
      expect(
        ruL10n.syncNotificationUnreachableBody,
        'Сервер недоступен. Фоновая синхронизация приостановлена до открытия приложения.',
      );
    },
  );
}
