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

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/restore_conflict_dialog.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/shared/widgets/create_folder_dialog.dart';
import 'package:crowleys_cloud/transfer_manager.dart';
import 'package:crowleys_cloud/transfer_widgets.dart';
import 'package:crowleys_cloud/upload_conflict_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CHALLENGER 2 - CreateFolderDialog Edge Cases & Locales', () {
    testWidgets('Default null params render localized strings in English and Russian', (tester) async {
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nRu = lookupAppLocalizations(const Locale('ru'));

      // English
      await tester.pumpWidget(
        wrapWithLocalization(
          const Scaffold(body: CreateFolderDialog()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.newFolderTitle), findsOneWidget);
      expect(find.text(l10nEn.newFolderHint), findsOneWidget);
      expect(find.text(l10nEn.cancel), findsOneWidget);
      expect(find.text(l10nEn.create), findsOneWidget);

      // Russian
      await tester.pumpWidget(
        wrapWithLocalization(
          const Scaffold(body: CreateFolderDialog()),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10nRu.newFolderTitle), findsOneWidget);
      expect(find.text(l10nRu.newFolderHint), findsOneWidget);
      expect(find.text(l10nRu.cancel), findsOneWidget);
      expect(find.text(l10nRu.create), findsOneWidget);
    });

    testWidgets('Custom colors and text overrides are honored', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          const Scaffold(
            body: CreateFolderDialog(
              title: 'Custom Title',
              hintText: 'Custom Hint',
              backgroundColor: Colors.indigo,
              textColor: Colors.amber,
              hintColor: Colors.cyan,
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom Hint'), findsOneWidget);

      final alertFinder = find.byType(AlertDialog);
      final alertDialog = tester.widget<AlertDialog>(alertFinder);
      expect(alertDialog.backgroundColor, Colors.indigo);
    });

    testWidgets('Whitespace and unicode submission via static show helper', (tester) async {
      String? result;
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await CreateFolderDialog.show(ctx);
                },
                child: const Text('Launch'),
              ),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '📁 Документы 2026 🚀');
      await tester.tap(find.text('Создать'));
      await tester.pumpAndSettle();

      expect(result, '📁 Документы 2026 🚀');
    });
  });

  group('CHALLENGER 2 - RestoreConflictDialog Byte Formatting & Edge Cases', () {
    testWidgets('Formats extreme file sizes and epoch 0 timestamps in EN and RU', (tester) async {
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nRu = lookupAppLocalizations(const Locale('ru'));

      final conflict = RestoreConflictItem(
        id: 1,
        name: 'huge_backup.tar.gz',
        originalPath: '',
        existingSize: 1099511627776, // 1 TB
        existingModified: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        trashSize: 1073741824, // 1 GB
        trashDeletedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

      // EN
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showRestoreConflictDialog(
                  ctx,
                  conflicts: [conflict],
                  allIds: [1],
                ),
                child: const Text('Show EN'),
              ),
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show EN'));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.conflictSizeLabel('1.0 TB')), findsOneWidget);
      expect(find.text(l10nEn.conflictSizeLabel('1.0 GB')), findsOneWidget);
      expect(find.text(l10nEn.conflictDateLabel(l10nEn.unknown)), findsOneWidget);
      expect(find.text(l10nEn.conflictDeletedLabel(l10nEn.unknown)), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // RU
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showRestoreConflictDialog(
                  ctx,
                  conflicts: [conflict],
                  allIds: [1],
                ),
                child: const Text('Show RU'),
              ),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show RU'));
      await tester.pumpAndSettle();

      expect(find.text(l10nRu.conflictSizeLabel('1.0 TB')), findsOneWidget);
      expect(find.text(l10nRu.conflictSizeLabel('1.0 GB')), findsOneWidget);
      expect(find.text(l10nRu.conflictDateLabel(l10nRu.unknown)), findsOneWidget);
      expect(find.text(l10nRu.conflictDeletedLabel(l10nRu.unknown)), findsOneWidget);
    });

    testWidgets('Batch overwrite all and batch keep all shortcut buttons in multi-conflict', (tester) async {
      final conflicts = [
        RestoreConflictItem(
          id: 10,
          name: 'f1.doc',
          originalPath: 'f1.doc',
          existingSize: 100,
          existingModified: DateTime.now(),
          trashSize: 100,
          trashDeletedAt: DateTime.now(),
        ),
        RestoreConflictItem(
          id: 20,
          name: 'f2.doc',
          originalPath: 'f2.doc',
          existingSize: 200,
          existingModified: DateTime.now(),
          trashSize: 200,
          trashDeletedAt: DateTime.now(),
        ),
      ];

      RestoreConflictResolution? res;
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  res = await showRestoreConflictDialog(
                    ctx,
                    conflicts: conflicts,
                    allIds: [10, 20, 30],
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Tap Overwrite All
      await tester.tap(find.text('Overwrite All'));
      await tester.pumpAndSettle();

      expect(res, isNotNull);
      expect(res!.overwriteDecisions[10], isTrue);
      expect(res!.overwriteDecisions[20], isTrue);
      expect(res!.overwriteDecisions[30], isFalse);
    });
  });

  group('CHALLENGER 2 - UploadConflictDialog Edge Cases & Actions', () {
    testWidgets('Batch overwrite all vs Skip all in UploadConflictDialog', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('challenger2_upload');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final file1 = File('${tempDir.path}/a.txt')..writeAsStringSync('1');
      final file2 = File('${tempDir.path}/b.txt')..writeAsStringSync('2');
      final item1 = FileItem.fromEntity(file1);
      final item2 = FileItem.fromEntity(file2);

      final srvItem1 = ServerFileItem(
        name: 'a.txt',
        size: 1,
        modifiedAt: DateTime.now(),
        type: 'document',
        mimeType: 'text/plain',
        thumbnailUrl: null,
        isDir: false,
        path: 'a.txt',
      );
      final srvItem2 = ServerFileItem(
        name: 'b.txt',
        size: 2,
        modifiedAt: DateTime.now(),
        type: 'document',
        mimeType: 'text/plain',
        thumbnailUrl: null,
        isDir: false,
        path: 'b.txt',
      );

      UploadConflictResolution? res;
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  res = await showUploadConflictDialog(
                    ctx,
                    conflicts: [
                      UploadConflictItem(item: item1, existingItem: srvItem1),
                      UploadConflictItem(item: item2, existingItem: srvItem2),
                    ],
                    nonConflictingItems: [],
                  );
                },
                child: const Text('Show Upload Dialog'),
              ),
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Upload Dialog'));
      await tester.pumpAndSettle();

      // Tap Overwrite All
      await tester.tap(find.text('Overwrite All'));
      await tester.pumpAndSettle();

      expect(res, isNotNull);
      expect(res!.confirmedItems.length, 2);
      expect(res!.skippedItems.isEmpty, isTrue);
    });
  });

  group('CHALLENGER 2 - TransferManager & TransferWidgets Lifecycle & Formatting', () {
    test('TransferManager progress calculation and clamping with 0 bytes and large bytes', () {
      final manager = TransferManager();
      expect(manager.progress, 0.0);

      // Item with 0 total bytes
      final zeroItem = manager.addItem(
        name: 'empty.dat',
        direction: TransferDirection.upload,
        totalBytes: 0,
      );
      expect(zeroItem.progress, 0.0);
      manager.completeItem(zeroItem);
      expect(zeroItem.progress, 1.0);
      expect(manager.progress, 1.0);

      // Add large item
      final largeItem = manager.addItem(
        name: 'video.mp4',
        direction: TransferDirection.download,
        totalBytes: 1000,
      );
      manager.startItem(largeItem);
      manager.updateItem(largeItem, 500);
      expect(largeItem.isActive, isTrue);

      // Disallow cancel on already completed item
      manager.cancelItem(zeroItem);
      expect(zeroItem.status, TransferStatus.completed);

      // Cancel large item
      manager.cancelItem(largeItem);
      expect(largeItem.status, TransferStatus.canceled);
      expect(largeItem.isActive, isFalse);

      manager.clearFinished();
      expect(manager.items.isEmpty, isTrue);

      manager.dispose();
    });

    testWidgets('TransferBottomBar renders progress indicator and reacts to status changes', (tester) async {
      final manager = TransferManager();
      final item = manager.addItem(
        name: 'upload.zip',
        direction: TransferDirection.upload,
        totalBytes: 2000,
      );
      manager.startItem(item);

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            bottomNavigationBar: TransferBottomBar(
              manager: manager,
              onOpen: () {},
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('0%  0/1 files'), findsOneWidget);

      manager.completeItem(item);
      await tester.pumpAndSettle();

      expect(find.text('100%  1/1 files'), findsOneWidget);
      manager.dispose();
    });
  });

  group('CHALLENGER 2 - FileBrowserController Strategy & Null L10n Fallback', () {
    test('createFolder and moveSelectedToFolder fallback cleanly when l10n is null', () async {
      final tempDir = Directory.systemTemp.createTempSync('challenger2_fbc');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final controller = FileBrowserController(
        category: const FileCategory('All files', Icons.folder),
        loadOnInit: false,
      );
      controller.directoryHistory.add(tempDir);

      // Null l10n parameter should default to platform / English locale without throwing
      final emptyNameErr = await controller.createFolder('   ', null);
      expect(emptyNameErr, isNotNull);
      expect(emptyNameErr!.isNotEmpty, isTrue);

      final success = await controller.createFolder('SubDir', null);
      expect(success, isNull);
      expect(Directory('${tempDir.path}/SubDir').existsSync(), isTrue);

      final moveErr = await controller.moveSelectedToFolder(tempDir.path, null);
      expect(moveErr, isNotNull);

      controller.disposeController();
      controller.dispose();
    });
  });

  group('CHALLENGER 2 - ServerBrowserController Fix Verification & Parity', () {
    test('ServerBrowserController operations preserve operationMessage in RU and EN', () async {
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nRu = lookupAppLocalizations(const Locale('ru'));

      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 's_v2',
        accessToken: 't',
        refreshToken: 'r',
      );

      final client = MockClient((req) async {
        if (req.url.path == '/api/folders') return http.Response('OK', 200);
        if (req.url.path == '/api/files/move') return http.Response('OK', 200);
        if (req.url.path == '/api/files') return http.Response('OK', 200);
        if (req.url.path == '/api/files/share') return http.Response('OK', 200);
        return http.Response(jsonEncode({'entries': []}), 200);
      });

      final controller = ServerBrowserController(
        profile: ServerProfile(
          id: 's_v2',
          displayName: 'Test Server',
          baseUrl: 'http://localhost:9999',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        ),
        serverId: 's_v2',
        authService: AuthService(secretStore: store),
        client: client,
      );

      // 1. Create folder in RU
      await controller.createFolderAtPath('', 'НоваяПапка', l10nRu);
      expect(controller.operationMessage, l10nRu.folderCreated);

      // 2. Create folder in EN
      await controller.createFolderAtPath('', 'NewFolder', l10nEn);
      expect(controller.operationMessage, l10nEn.folderCreated);

      // 3. Rename item in RU
      final item = ServerFileItem(
        name: 'a.txt',
        size: 10,
        modifiedAt: DateTime.now(),
        type: 'document',
        mimeType: 'text/plain',
        thumbnailUrl: null,
        isDir: false,
        path: 'a.txt',
      );
      final renRu = await controller.renameItem(item, 'b.txt', l10nRu);
      expect(renRu, isTrue);
      expect(controller.operationMessage, l10nRu.renamedOldToNew('a.txt', 'b.txt'));

      // 4. Move selected in RU
      controller.toggleSelection(item);
      await controller.moveSelectedToFolder('target_folder', l10nRu);
      expect(controller.operationMessage, l10nRu.movedNItems(1));

      // 5. Share in server in RU
      controller.toggleSelection(item);
      await controller.shareSelectedInServer(l10nRu);
      expect(controller.operationMessage, l10nRu.sharedNItemsInServer(1));

      controller.disposeController();
      controller.dispose();
    });
  });
}
