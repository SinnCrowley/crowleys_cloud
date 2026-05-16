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
