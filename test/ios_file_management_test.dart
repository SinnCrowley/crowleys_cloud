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

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iOS File Management & Localization', () {
    test(
      'localizations provide categoryBrowseFiles and categoryDownloadedFiles in all supported locales',
      () {
        for (final locale in AppLocalizations.supportedLocales) {
          final l10n = lookupAppLocalizations(locale);
          expect(
            l10n.categoryBrowseFiles,
            isNotEmpty,
            reason: 'Missing categoryBrowseFiles in ${locale.languageCode}',
          );
          expect(
            l10n.categoryDownloadedFiles,
            isNotEmpty,
            reason: 'Missing categoryDownloadedFiles in ${locale.languageCode}',
          );
        }

        final en = lookupAppLocalizations(const Locale('en'));
        final ru = lookupAppLocalizations(const Locale('ru'));
        final de = lookupAppLocalizations(const Locale('de'));
        final es = lookupAppLocalizations(const Locale('es'));
        final fr = lookupAppLocalizations(const Locale('fr'));
        final zh = lookupAppLocalizations(const Locale('zh'));

        expect(en.categoryBrowseFiles, 'Browse Files');
        expect(en.categoryDownloadedFiles, 'Downloaded Files');
        expect(ru.categoryBrowseFiles, 'Обзор файлов');
        expect(ru.categoryDownloadedFiles, 'Загруженные файлы');
        expect(de.categoryBrowseFiles, 'Dateien durchsuchen');
        expect(de.categoryDownloadedFiles, 'Heruntergeladene Dateien');
        expect(es.categoryBrowseFiles, 'Explorar archivos');
        expect(es.categoryDownloadedFiles, 'Archivos descargados');
        expect(fr.categoryBrowseFiles, 'Parcourir les fichiers');
        expect(fr.categoryDownloadedFiles, 'Fichiers téléchargés');
        expect(zh.categoryBrowseFiles, '瀏覽檔案');
        expect(zh.categoryDownloadedFiles, '已下載的檔案');
      },
    );

    test('FileCategory supports Browse Files and Downloaded Files', () {
      const browse = FileCategory('Browse Files', Icons.folder_open);
      const downloaded = FileCategory('Downloaded Files', Icons.download_done);

      expect(browse.name, 'Browse Files');
      expect(browse.icon, Icons.folder_open);
      expect(downloaded.name, 'Downloaded Files');
      expect(downloaded.icon, Icons.download_done);
    });

    test(
      'leading slashes stripping regex works accurately for POSIX and Windows separators',
      () {
        const paths = [
          '/photo.jpg',
          '///nested/video.mp4',
          r'\nested\audio.mp3',
          'plain.txt',
        ];

        final sanitized = paths
            .map((p) => p.replaceAll(RegExp(r'^[/\\]+'), ''))
            .toList();

        expect(sanitized[0], 'photo.jpg');
        expect(sanitized[1], 'nested/video.mp4');
        expect(sanitized[2], r'nested\audio.mp3');
        expect(sanitized[3], 'plain.txt');
      },
    );
  });
}
