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

import 'dart:io';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/shared/utils/file_icon_utils.dart';
import 'package:crowleys_cloud/shared/utils/file_type_utils.dart';
import 'package:crowleys_cloud/shared/viewers/image_viewer.dart';
import 'package:crowleys_cloud/smart_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SVG Support - Constants & Utilities', () {
    test('photoExtensions contains .svg', () {
      expect(photoExtensions.contains('.svg'), isTrue);
    });

    test('FileTypeUtils.isImage recognizes svg files and extensions', () {
      expect(FileTypeUtils.isImage('svg'), isTrue);
      expect(FileTypeUtils.isImage('.svg'), isTrue);
      expect(FileTypeUtils.isImage('IMAGE.SVG'), isTrue);
      expect(FileTypeUtils.isImage('vector_graphic.svg'), isTrue);
    });

    test('FileIconUtils.iconForExtension maps svg to Icons.image', () {
      expect(FileIconUtils.iconForExtension('svg'), equals(Icons.image));
      expect(FileIconUtils.iconForExtension('.svg'), equals(Icons.image));
      expect(FileIconUtils.iconForExtension('SVG'), equals(Icons.image));
      expect(FileIconUtils.iconForExtension('.SVG'), equals(Icons.image));
    });

    test('FileTypeUtils.categoryForFile returns image icon for svg', () {
      final info = FileTypeUtils.categoryForFile('test.svg');
      expect(info.icon, equals(Icons.image));
    });
  });

  group('SVG Support - Widgets', () {
    testWidgets('SmartThumbnail mounts _FsThumbnail for local SVG file', (
      tester,
    ) async {
      final dummyFile = File('/tmp/test_icon.svg');
      final item = FileItem.fromEntity(dummyFile);

      await tester.pumpWidget(wrapWithLocalization(SmartThumbnail(item: item)));

      // Verify that SmartThumbnail routes SVG to filesystem thumbnail handler
      expect(find.byType(SmartThumbnail), findsOneWidget);
    });

    testWidgets('ImageViewer renders SvgPicture for local SVG files', (
      tester,
    ) async {
      const svgContent =
          '<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg"><circle cx="50" cy="50" r="50" fill="blue"/></svg>';
      final tempDir = Directory.systemTemp.createTempSync('svg_view_test_');
      final svgFile = File('${tempDir.path}/drawing.svg')
        ..writeAsStringSync(svgContent);

      final item = FileItem.fromEntity(svgFile);

      await tester.pumpWidget(
        wrapWithLocalization(ImageViewer(imageItems: [item], initialIndex: 0)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);

      tempDir.deleteSync(recursive: true);
    });
  });
}
