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
import 'package:crowleys_cloud/file_browser.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpBrowser(
    WidgetTester tester,
    FileBrowserController controller, {
    bool isGridView = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileBrowser(
            category: const FileCategory('Documents', Icons.description),
            isGridView: isGridView,
            controller: controller,
          ),
        ),
      ),
    );
  }

  testWidgets('renders loading and empty states', (tester) async {
    final controller = FileBrowserController(
      category: const FileCategory('Documents', Icons.description),
      loadOnInit: false,
    );

    controller.setViewStateForTest(loading: true, visibleFiles: const []);
    await pumpBrowser(tester, controller);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.setViewStateForTest(loading: false, visibleFiles: const []);
    await tester.pump();
    expect(find.text('No files found.'), findsOneWidget);
  });

  testWidgets('renders list and selection header/action bar transitions', (
    tester,
  ) async {
    final item = FileItem.fromEntity(File('/tmp/a.txt'));
    final controller = FileBrowserController(
      category: const FileCategory('Documents', Icons.description),
      loadOnInit: false,
    );

    controller.setViewStateForTest(loading: false, visibleFiles: [item]);
    await pumpBrowser(tester, controller, isGridView: false);

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('0 selected'), findsNothing);

    controller.toggleSelection(item);
    await tester.pump();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}
