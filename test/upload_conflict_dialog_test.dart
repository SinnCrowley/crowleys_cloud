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
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/upload_conflict_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  final tempDir = Directory.systemTemp.createTempSync('cc_conflict_test_');
  final localFile1 = File('${tempDir.path}/test1.txt')
    ..writeAsStringSync('hello 1');
  final localFile2 = File('${tempDir.path}/test2.txt')
    ..writeAsStringSync('hello 2');
  final localFile3 = File('${tempDir.path}/test3.txt')
    ..writeAsStringSync('hello 3');

  final item1 = FileItem.fromEntity(localFile1);
  final item2 = FileItem.fromEntity(localFile2);
  final item3 = FileItem.fromEntity(localFile3);

  final serverItem1 = ServerFileItem(
    name: 'test1.txt',
    size: 100,
    modifiedAt: DateTime.utc(2026, 1, 1),
    type: 'document',
    mimeType: 'text/plain',
    thumbnailUrl: null,
    isDir: false,
    path: 'test1.txt',
  );

  final serverItem2 = ServerFileItem(
    name: 'test2.txt',
    size: 200,
    modifiedAt: DateTime.utc(2026, 1, 2),
    type: 'document',
    mimeType: 'text/plain',
    thumbnailUrl: null,
    isDir: false,
    path: 'test2.txt',
  );

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('Single conflict: Overwrite resolves confirmed item', (
    tester,
  ) async {
    UploadConflictResolution? result;

    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showUploadConflictDialog(
                  context,
                  conflicts: [
                    UploadConflictItem(item: item1, existingItem: serverItem1),
                  ],
                  nonConflictingItems: [item3],
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('File already exists'), findsOneWidget);
    expect(find.text('Overwrite'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Overwrite'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.confirmedItems.length, 2);
    expect(result!.confirmedItems.contains(item1), isTrue);
    expect(result!.confirmedItems.contains(item3), isTrue);
    expect(result!.skippedItems.isEmpty, isTrue);
  });

  testWidgets('Single conflict: Skip excludes conflicting item', (
    tester,
  ) async {
    UploadConflictResolution? result;

    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showUploadConflictDialog(
                  context,
                  conflicts: [
                    UploadConflictItem(item: item1, existingItem: serverItem1),
                  ],
                  nonConflictingItems: [item3],
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.confirmedItems.length, 1);
    expect(result!.confirmedItems.contains(item3), isTrue);
    expect(result!.skippedItems.length, 1);
    expect(result!.skippedItems.contains(item1), isTrue);
  });

  testWidgets('Multiple conflicts: Overwrite All confirms all items', (
    tester,
  ) async {
    UploadConflictResolution? result;

    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showUploadConflictDialog(
                  context,
                  conflicts: [
                    UploadConflictItem(item: item1, existingItem: serverItem1),
                    UploadConflictItem(item: item2, existingItem: serverItem2),
                  ],
                  nonConflictingItems: [item3],
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Conflict 1 of 2'), findsOneWidget);
    expect(find.text('Overwrite All'), findsOneWidget);
    expect(find.text('Skip All'), findsOneWidget);

    await tester.tap(find.text('Overwrite All'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.confirmedItems.length, 3);
    expect(result!.confirmedItems.contains(item1), isTrue);
    expect(result!.confirmedItems.contains(item2), isTrue);
    expect(result!.confirmedItems.contains(item3), isTrue);
  });

  testWidgets('Multiple conflicts: Skip All skips all conflicting items', (
    tester,
  ) async {
    UploadConflictResolution? result;

    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showUploadConflictDialog(
                  context,
                  conflicts: [
                    UploadConflictItem(item: item1, existingItem: serverItem1),
                    UploadConflictItem(item: item2, existingItem: serverItem2),
                  ],
                  nonConflictingItems: [item3],
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip All'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.confirmedItems.length, 1);
    expect(result!.confirmedItems.contains(item3), isTrue);
    expect(result!.skippedItems.length, 2);
  });
}
