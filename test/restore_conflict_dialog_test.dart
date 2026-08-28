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

import 'package:crowleys_cloud/restore_conflict_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  final conflict1 = RestoreConflictItem(
    id: 101,
    name: 'document.pdf',
    originalPath: 'docs/document.pdf',
    existingSize: 1024,
    existingModified: DateTime.utc(2026, 1, 1),
    trashSize: 2048,
    trashDeletedAt: DateTime.utc(2026, 1, 5),
  );

  final conflict2 = RestoreConflictItem(
    id: 102,
    name: 'notes.txt',
    originalPath: 'notes.txt',
    existingSize: 512,
    existingModified: DateTime.utc(2026, 1, 2),
    trashSize: 512,
    trashDeletedAt: DateTime.utc(2026, 1, 6),
  );

  testWidgets('Single restore conflict: Overwrite resolves true for id', (
    tester,
  ) async {
    RestoreConflictResolution? result;

    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showRestoreConflictDialog(
                  context,
                  conflicts: [conflict1],
                  allIds: [101, 103],
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
    expect(find.text('Restore as Copy'), findsOneWidget);

    await tester.tap(find.text('Overwrite'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.overwriteDecisions[101], isTrue);
    expect(result!.overwriteDecisions[103], isFalse);
  });

  testWidgets(
    'Single restore conflict: Restore as Copy resolves false for id',
    (tester) async {
      RestoreConflictResolution? result;

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showRestoreConflictDialog(
                    context,
                    conflicts: [conflict1],
                    allIds: [101],
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

      await tester.tap(find.text('Restore as Copy'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.overwriteDecisions[101], isFalse);
    },
  );

  testWidgets(
    'Multiple restore conflicts: Overwrite All sets true for all conflicts',
    (tester) async {
      RestoreConflictResolution? result;

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showRestoreConflictDialog(
                    context,
                    conflicts: [conflict1, conflict2],
                    allIds: [101, 102],
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
      expect(find.text('Keep All Copies'), findsOneWidget);

      await tester.tap(find.text('Overwrite All'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.overwriteDecisions[101], isTrue);
      expect(result!.overwriteDecisions[102], isTrue);
    },
  );

  testWidgets(
    'Multiple restore conflicts: Keep All Copies sets false for all conflicts',
    (tester) async {
      RestoreConflictResolution? result;

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showRestoreConflictDialog(
                    context,
                    conflicts: [conflict1, conflict2],
                    allIds: [101, 102],
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

      await tester.tap(find.text('Keep All Copies'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.overwriteDecisions[101], isFalse);
      expect(result!.overwriteDecisions[102], isFalse);
    },
  );
}
