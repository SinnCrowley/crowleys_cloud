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
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/restore_conflict_dialog.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_browser.dart';
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

  group('CreateFolderDialog Localization', () {
    testWidgets('renders default title and hint in English', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          const Scaffold(body: CreateFolderDialog()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Folder'), findsOneWidget);
      expect(find.text('Folder name'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('renders default title and hint in Russian', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          const Scaffold(body: CreateFolderDialog()),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Создать папку'), findsOneWidget);
      expect(find.text('Имя папки'), findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('Создать'), findsOneWidget);
    });

    testWidgets('allows custom title and hint overrides', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          const Scaffold(
            body: CreateFolderDialog(
              title: 'Custom Title',
              hintText: 'Custom Hint',
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom Hint'), findsOneWidget);
    });
  });

  group('Conflict Dialog Date Fallback Localization', () {
    testWidgets('RestoreConflictDialog formats epoch 0 as Unknown in EN', (
      tester,
    ) async {
      final conflict = RestoreConflictItem(
        id: 1,
        name: 'test.pdf',
        originalPath: 'test.pdf',
        existingSize: 1024,
        existingModified: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        trashSize: 1024,
        trashDeletedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showRestoreConflictDialog(
                    context,
                    conflicts: [conflict],
                    allIds: [1],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
          locale: const Locale('en'),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Date: Unknown'), findsOneWidget);
      expect(find.text('Deleted: Unknown'), findsOneWidget);
    });

    testWidgets('RestoreConflictDialog formats epoch 0 as Неизвестно in RU', (
      tester,
    ) async {
      final conflict = RestoreConflictItem(
        id: 1,
        name: 'test.pdf',
        originalPath: 'test.pdf',
        existingSize: 1024,
        existingModified: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        trashSize: 1024,
        trashDeletedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showRestoreConflictDialog(
                    context,
                    conflicts: [conflict],
                    allIds: [1],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Дата: Неизвестно'), findsOneWidget);
      expect(find.text('Удалён: Неизвестно'), findsOneWidget);
    });

    testWidgets('UploadConflictDialog formats epoch 0 as Unknown in EN', (
      tester,
    ) async {
      final tempDir = Directory.systemTemp.createTempSync('m3_upload_conflict');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final localFile = File('${tempDir.path}/test.txt')..writeAsStringSync('a');
      final localItem = FileItem.fromEntity(localFile);
      final serverItem = ServerFileItem(
        name: 'test.txt',
        size: 1,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        type: 'document',
        mimeType: 'text/plain',
        thumbnailUrl: null,
        isDir: false,
        path: 'test.txt',
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showUploadConflictDialog(
                    context,
                    conflicts: [
                      UploadConflictItem(
                        item: localItem,
                        existingItem: serverItem,
                      ),
                    ],
                    nonConflictingItems: [],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
          locale: const Locale('en'),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Date: Unknown'), findsOneWidget);
    });

    testWidgets('UploadConflictDialog formats epoch 0 as Неизвестно in RU', (
      tester,
    ) async {
      final tempDir = Directory.systemTemp.createTempSync('m3_upload_conflict_ru');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final localFile = File('${tempDir.path}/test.txt')..writeAsStringSync('a');
      final localItem = FileItem.fromEntity(localFile);
      final serverItem = ServerFileItem(
        name: 'test.txt',
        size: 1,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        type: 'document',
        mimeType: 'text/plain',
        thumbnailUrl: null,
        isDir: false,
        path: 'test.txt',
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showUploadConflictDialog(
                    context,
                    conflicts: [
                      UploadConflictItem(
                        item: localItem,
                        existingItem: serverItem,
                      ),
                    ],
                    nonConflictingItems: [],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Дата: Неизвестно'), findsOneWidget);
    });
  });

  group('TransferManager & TransferBottomBar Localization', () {
    test('formatSummary returns correct string across locales', () {
      final manager = TransferManager();
      final item1 = manager.addItem(
        name: 'f1.txt',
        direction: TransferDirection.download,
        totalBytes: 100,
      );
      manager.addItem(
        name: 'f2.txt',
        direction: TransferDirection.download,
        totalBytes: 100,
      );
      manager.completeItem(item1);

      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nRu = lookupAppLocalizations(const Locale('ru'));

      expect(manager.formatSummary(l10nEn), '50%  1/2 files');
      expect(manager.formatSummary(l10nRu), '50%  1/2 файлов');
    });

    testWidgets('TransferBottomBar renders localized summary in Russian', (
      tester,
    ) async {
      final manager = TransferManager();
      final item = manager.addItem(
        name: 'test.png',
        direction: TransferDirection.upload,
        totalBytes: 200,
      );
      manager.completeItem(item);

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            bottomNavigationBar: TransferBottomBar(
              manager: manager,
              onOpen: () {},
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100%  1/1 файлов'), findsOneWidget);
    });
  });

  group('ServerFileBrowser Sort Dropdown Localization', () {
    testWidgets('renders sort dropdown items in Russian', (tester) async {
      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv',
        accessToken: 'token',
        refreshToken: 'refresh',
      );

      final client = MockClient((request) async {
        return http.Response(
          '{"entries": []}',
          200,
        );
      });

      final controller = ServerBrowserController(
        profile: ServerProfile(
          id: 'srv',
          displayName: 'Test',
          baseUrl: 'http://localhost:7777',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        ),
        serverId: 'srv',
        authService: AuthService(secretStore: store),
        client: client,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: ServerFileBrowser(
              controller: controller,
              isGridView: true,
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      // Current selected sort by is Name -> Имя
      expect(find.text('Имя'), findsOneWidget);

      // Open dropdown
      await tester.tap(find.text('Имя'));
      await tester.pumpAndSettle();

      // Check all 4 localized options
      expect(find.text('Дата'), findsWidgets);
      expect(find.text('Размер'), findsWidgets);
      expect(find.text('Тип'), findsWidgets);

      controller.disposeController();
      controller.dispose();
    });
  });

  group('Controller Localized Messages', () {
    test('FileBrowserController localized operation messages', () async {
      final l10nRu = lookupAppLocalizations(const Locale('ru'));
      final controller = FileBrowserController(
        category: const FileCategory('All files', Icons.folder),
        loadOnInit: false,
      );

      // Empty folder name
      final err = await controller.createFolder('   ', l10nRu);
      expect(err, 'Текущая папка недоступна.');

      // Move empty
      final moveErr = await controller.moveSelectedToFolder('/tmp', l10nRu);
      expect(moveErr, 'Ничего не выбрано.');
    });

    test('ServerBrowserController localized operation messages', () async {
      final l10nRu = lookupAppLocalizations(const Locale('ru'));
      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv',
        accessToken: 'token',
        refreshToken: 'refresh',
      );

      final controller = ServerBrowserController(
        profile: ServerProfile(
          id: 'srv',
          displayName: 'Test',
          baseUrl: 'http://localhost:7777',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        ),
        serverId: 'srv',
        authService: AuthService(secretStore: store),
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      // Empty folder name in Russian
      await controller.createFolder('   ', l10nRu);
      expect(controller.operationMessage, 'Имя папки не может быть пустым.');

      controller.disposeController();
      controller.dispose();
    });
  });
}
