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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crowleys_cloud/shared/utils/file_icon_utils.dart';
import 'package:crowleys_cloud/shared/utils/file_type_utils.dart';

void main() {
  group('FileIconUtils & FileTypeUtils', () {
    test('iconForExtension maps known extensions to icons', () {
      expect(FileIconUtils.iconForExtension('pdf'), Icons.picture_as_pdf);
      expect(FileIconUtils.iconForExtension('.docx'), Icons.description);
      expect(FileIconUtils.iconForExtension('png'), Icons.image);
      expect(FileIconUtils.iconForExtension('mp4'), Icons.movie);
      expect(FileIconUtils.iconForExtension('zip'), Icons.folder_zip);
      expect(
        FileIconUtils.iconForExtension('unknown_ext'),
        Icons.insert_drive_file,
      );
    });

    test('categoryForFile resolves category info', () {
      final info = FileTypeUtils.categoryForFile('document.pdf');
      expect(info.icon, Icons.picture_as_pdf);
      expect(FileTypeUtils.isImage('.png'), isTrue);
      expect(FileTypeUtils.isVideo('.mp4'), isTrue);
      expect(FileTypeUtils.isAudio('.mp3'), isTrue);
    });
  });
}
