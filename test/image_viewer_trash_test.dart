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

import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/shared/viewers/image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyServerFile = ServerFileItem(
    id: 101,
    name: 'test_photo.jpg',
    path: 'test_photo.jpg',
    isDir: false,
    size: 2048,
    modifiedAt: DateTime.now(),
    type: 'photo',
    mimeType: 'image/jpeg',
    thumbnailUrl: null,
  );

  final dummyFileItem = FileItem.fromServer(dummyServerFile);

  testWidgets('ImageViewer normal mode shows standard buttons', (tester) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        ImageViewer(
          imageItems: [dummyFileItem],
          initialIndex: 0,
          isTrash: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Add to folder'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    expect(find.text('Restore'), findsNothing);
    expect(find.text('Delete Permanently'), findsNothing);
  });

  testWidgets(
    'ImageViewer trash mode shows ONLY Restore and Delete Permanently',
    (tester) async {
      bool restored = false;

      await tester.pumpWidget(
        wrapWithLocalization(
          ImageViewer(
            imageItems: [dummyFileItem],
            initialIndex: 0,
            isTrash: true,
            onRestoreItem: (item) async {
              restored = true;
            },
          ),
        ),
      );
      await tester.pump();

      // Standard buttons are hidden
      expect(find.text('Upload'), findsNothing);
      expect(find.text('Rename'), findsNothing);
      expect(find.text('Add to folder'), findsNothing);
      expect(find.text('Share'), findsNothing);

      // Trash action buttons are present
      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);

      // Tap restore
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(restored, isTrue);
    },
  );

  testWidgets(
    'ImageViewer trash mode Delete Permanently shows confirmation dialog and executes',
    (tester) async {
      bool deletedPermanently = false;

      await tester.pumpWidget(
        wrapWithLocalization(
          ImageViewer(
            imageItems: [dummyFileItem],
            initialIndex: 0,
            isTrash: true,
            onDeletePermanentlyItem: (item) async {
              deletedPermanently = true;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears (action bar button, dialog title, dialog action button)
      expect(find.text('Delete Permanently'), findsNWidgets(3));
      expect(find.textContaining('permanently'), findsOneWidget);

      // Tap confirm delete in dialog
      await tester.tap(find.widgetWithText(TextButton, 'Delete Permanently'));
      await tester.pumpAndSettle();

      expect(deletedPermanently, isTrue);
    },
  );
}
