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
import 'package:crowleys_cloud/file_browser.dart';
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

  group('Group 1: TransferManager, TransferBottomBar & TransferPage Adversarial Stress', () {
    test('formatSummary pluralization and percentage across EN and RU with edge cases', () {
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nRu = lookupAppLocalizations(const Locale('ru'));

      final manager = TransferManager();

      // Zero items
      expect(manager.formatSummary(l10nEn), '0%  0/0 files');
      expect(manager.formatSummary(l10nRu), '0%  0/0 файлов');

      // 1 item (0% complete)
      final it1 = manager.addItem(name: 'doc1.pdf', direction: TransferDirection.upload, totalBytes: 1000);
      expect(manager.formatSummary(l10nEn), '0%  0/1 files');
      expect(manager.formatSummary(l10nRu), '0%  0/1 файлов');

      // 1 item (100% complete)
      manager.completeItem(it1);
      expect(manager.formatSummary(l10nEn), '100%  1/1 files');
      expect(manager.formatSummary(l10nRu), '100%  1/1 файлов');

      // Add 4 more items (total 5)
      final drafts = [
        const TransferItemDraft(name: 'f2.bin', direction: TransferDirection.download, totalBytes: 1000),
        const TransferItemDraft(name: 'f3.bin', direction: TransferDirection.download, totalBytes: 1000),
        const TransferItemDraft(name: 'f4.bin', direction: TransferDirection.upload, totalBytes: 1000),
        const TransferItemDraft(name: 'f5.bin', direction: TransferDirection.upload, totalBytes: 1000),
      ];
      final added = manager.addItems(drafts);
      // Currently 1 of 5 completed, total 5000 bytes, transferred 1000 bytes => 20%
      expect(manager.formatSummary(l10nEn), '20%  1/5 files');
      expect(manager.formatSummary(l10nRu), '20%  1/5 файлов');

      // Complete 2 more => 3 of 5 completed => 60%
      manager.completeItem(added[0]);
      manager.completeItem(added[1]);
      expect(manager.formatSummary(l10nEn), '60%  3/5 files');
      expect(manager.formatSummary(l10nRu), '60%  3/5 файлов');

      // Complete all
      manager.completeItem(added[2]);
      manager.completeItem(added[3]);
      expect(manager.formatSummary(l10nEn), '100%  5/5 files');
      expect(manager.formatSummary(l10nRu), '100%  5/5 файлов');

      manager.dispose();
    });

    testWidgets('TransferBottomBar dynamic states and tooltips in Russian', (tester) async {
      final manager = TransferManager();
      final it = manager.addItem(name: 'archive.zip', direction: TransferDirection.download, totalBytes: 500);

      var opened = false;
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            bottomNavigationBar: TransferBottomBar(
              manager: manager,
              onOpen: () => opened = true,
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      // Russian summary
      expect(find.text('0%  0/1 файлов'), findsOneWidget);

      // Verify pause button tooltip: "Пауза"
      expect(find.byTooltip('Пауза'), findsOneWidget);
      expect(find.byTooltip('Отмена'), findsOneWidget);

      // Tap pause
      await tester.tap(find.byTooltip('Пауза'));
      await tester.pumpAndSettle();

      // Now it should show resume tooltip: "Возобновить"
      expect(find.byTooltip('Возобновить'), findsOneWidget);
      expect(manager.isPaused, isTrue);

      // Tap summary text to test onOpen callback
      await tester.tap(find.text('0%  0/1 файлов'));
      await tester.pumpAndSettle();
      expect(opened, isTrue);

      manager.completeItem(it);
      await tester.pumpAndSettle();
      expect(find.text('100%  1/1 файлов'), findsOneWidget);

      manager.dispose();
    });

    testWidgets('TransferPage renders all localized status badges and actions in Russian', (tester) async {
      final manager = TransferManager();
      manager.addItem(name: 'q.txt', direction: TransferDirection.download, totalBytes: 100);
      final rItem = manager.addItem(name: 'r.txt', direction: TransferDirection.upload, totalBytes: 200);
      manager.startItem(rItem);
      final cItem = manager.addItem(name: 'c.txt', direction: TransferDirection.download, totalBytes: 300);
      manager.completeItem(cItem);
      final fItem = manager.addItem(name: 'f.txt', direction: TransferDirection.upload, totalBytes: 400);
      manager.failItem(fItem, 'Network error');
      final xItem = manager.addItem(name: 'x.txt', direction: TransferDirection.download, totalBytes: 500);
      manager.cancelItem(xItem);

      await tester.pumpWidget(
        wrapWithLocalization(
          TransferPage(manager: manager),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Передачи'), findsOneWidget);

      // Status labels in Russian
      expect(find.textContaining('В очереди'), findsOneWidget);
      expect(find.textContaining('Выполняется'), findsOneWidget);
      expect(find.textContaining('Завершено'), findsOneWidget);
      expect(find.textContaining('Ошибка'), findsOneWidget);
      expect(find.textContaining('Отменено'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);

      // App bar tooltips in Russian
      expect(find.byTooltip('Пауза всех'), findsOneWidget);
      expect(find.byTooltip('Отменить все'), findsOneWidget);

      manager.dispose();
    });

    testWidgets('TransferPage renders empty state in English and Russian', (tester) async {
      final manager = TransferManager();

      await tester.pumpWidget(
        wrapWithLocalization(
          TransferPage(manager: manager),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No transfers.'), findsOneWidget);

      await tester.pumpWidget(
        wrapWithLocalization(
          TransferPage(manager: manager),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Нет передач.'), findsOneWidget);

      manager.dispose();
    });
  });

  group('Group 2: CreateFolderDialog Stress & Null Fallbacks', () {
    testWidgets('CreateFolderDialog with null parameters defaults to localized strings in EN', (tester) async {
      String? createdName;
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  createdName = await CreateFolderDialog.show(ctx);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Create Folder'), findsOneWidget);
      expect(find.text('Folder name'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Photos_2026');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(createdName, 'Photos_2026');
    });

    testWidgets('CreateFolderDialog with null parameters defaults to localized strings in RU', (tester) async {
      String? createdName;
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  createdName = await CreateFolderDialog.show(ctx);
                },
                child: const Text('Открыть'),
              ),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();

      expect(find.text('Создать папку'), findsOneWidget);
      expect(find.text('Имя папки'), findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('Создать'), findsOneWidget);

      // Test cancel button
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(createdName, isNull);
    });

    testWidgets('CreateFolderDialog respects custom title and hint overrides without regression', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          const Scaffold(
            body: CreateFolderDialog(
              title: 'Специальная папка',
              hintText: 'Введите название',
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Специальная папка'), findsOneWidget);
      expect(find.text('Введите название'), findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('Создать'), findsOneWidget);
    });
  });

  group('Group 3: RestoreConflictDialog Adversarial Multi-Conflict & Date Formatting', () {
    testWidgets('RestoreConflictDialog multi-item pagination, dates and Apply to Remaining in RU', (tester) async {
      final items = [
        RestoreConflictItem(
          id: 101,
          name: 'doc_alpha.pdf',
          originalPath: 'documents/doc_alpha.pdf',
          existingSize: 2048,
          existingModified: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          trashSize: 4096,
          trashDeletedAt: DateTime(2026, 8, 18, 12, 30),
        ),
        RestoreConflictItem(
          id: 102,
          name: 'doc_beta.pdf',
          originalPath: 'documents/doc_beta.pdf',
          existingSize: 1048576,
          existingModified: DateTime(2026, 8, 17, 9, 15),
          trashSize: 1048576 * 2,
          trashDeletedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
        RestoreConflictItem(
          id: 103,
          name: 'doc_gamma.pdf',
          originalPath: 'documents/doc_gamma.pdf',
          existingSize: 512,
          existingModified: DateTime(2026, 8, 10, 8, 0),
          trashSize: 512,
          trashDeletedAt: DateTime(2026, 8, 11, 8, 0),
        ),
      ];

      RestoreConflictResolution? result;
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await showRestoreConflictDialog(
                    ctx,
                    conflicts: items,
                    allIds: [101, 102, 103, 104],
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Pagination indicator
      expect(find.text('Конфликт 1 из 3'), findsOneWidget);
      expect(find.text('Файл уже существует'), findsOneWidget);
      expect(find.text('В папке'), findsOneWidget);
      expect(find.text('Из корзины'), findsOneWidget);

      // Epoch 0 date in RU -> Неизвестно
      expect(find.text('Дата: Неизвестно'), findsOneWidget);

      // Check multi-conflict buttons
      expect(find.text('Оставить все копии'), findsOneWidget);
      expect(find.text('Перезаписать все'), findsOneWidget);
      expect(find.text('Восстановить как копию'), findsOneWidget);
      expect(find.text('Перезаписать'), findsOneWidget);

      // Checkbox "Применить к 3 оставшимся конфликтам"
      expect(find.text('Применить к 3 оставшимся конфликтам'), findsOneWidget);

      // Toggle Apply to all remaining
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(find.text('Восстановить все как копии'), findsOneWidget);
      expect(find.text('Перезаписать все оставшиеся'), findsOneWidget);

      // Click "Перезаписать все оставшиеся"
      await tester.tap(find.text('Перезаписать все оставшиеся'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.overwriteDecisions[101], isTrue);
      expect(result!.overwriteDecisions[102], isTrue);
      expect(result!.overwriteDecisions[103], isTrue);
      // Non-conflicting ID 104 defaults to false
      expect(result!.overwriteDecisions[104], isFalse);
    });

    testWidgets('RestoreConflictDialog "Оставить все копии" shortcut action', (tester) async {
      final items = [
        RestoreConflictItem(
          id: 1,
          name: 'file1.txt',
          originalPath: 'file1.txt',
          existingSize: 100,
          existingModified: DateTime.fromMillisecondsSinceEpoch(0),
          trashSize: 100,
          trashDeletedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        RestoreConflictItem(
          id: 2,
          name: 'file2.txt',
          originalPath: 'file2.txt',
          existingSize: 200,
          existingModified: DateTime.fromMillisecondsSinceEpoch(0),
          trashSize: 200,
          trashDeletedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ];

      RestoreConflictResolution? result;
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await showRestoreConflictDialog(
                    ctx,
                    conflicts: items,
                    allIds: [1, 2],
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Оставить все копии'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.overwriteDecisions[1], isFalse);
      expect(result!.overwriteDecisions[2], isFalse);
    });
  });

  group('Group 4: UploadConflictDialog Adversarial Multi-Conflict & Action Flow', () {
    testWidgets('UploadConflictDialog step-by-step resolution and date fallbacks in EN and RU', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('upload_conflict_test');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final f1 = File('${tempDir.path}/a.png')..writeAsStringSync('123');
      final f2 = File('${tempDir.path}/b.png')..writeAsStringSync('45678');
      final f3 = File('${tempDir.path}/c.png')..writeAsStringSync('9');

      final item1 = FileItem.fromEntity(f1);
      final item2 = FileItem.fromEntity(f2);
      final item3 = FileItem.fromEntity(f3);

      final srv1 = ServerFileItem(
        name: 'a.png',
        size: 123,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        type: 'photo',
        mimeType: 'image/png',
        thumbnailUrl: null,
        isDir: false,
        path: 'a.png',
      );
      final srv2 = ServerFileItem(
        name: 'b.png',
        size: 45678,
        modifiedAt: DateTime(2026, 8, 18, 15, 0),
        type: 'photo',
        mimeType: 'image/png',
        thumbnailUrl: null,
        isDir: false,
        path: 'b.png',
      );

      final conflicts = [
        UploadConflictItem(item: item1, existingItem: srv1),
        UploadConflictItem(item: item2, existingItem: srv2),
      ];

      UploadConflictResolution? res;
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  res = await showUploadConflictDialog(
                    ctx,
                    conflicts: conflicts,
                    nonConflictingItems: [item3],
                  );
                },
                child: const Text('Start Upload'),
              ),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Upload'));
      await tester.pumpAndSettle();

      expect(find.text('Конфликт 1 из 2'), findsOneWidget);
      expect(find.text('Файл уже существует'), findsOneWidget);
      expect(find.text('Существующий'), findsOneWidget);
      expect(find.text('Новая загрузка'), findsOneWidget);
      expect(find.text('Дата: Неизвестно'), findsOneWidget);
      expect(find.text('Пропустить все'), findsOneWidget);
      expect(find.text('Перезаписать все'), findsOneWidget);
      expect(find.text('Пропустить'), findsOneWidget);
      expect(find.text('Перезаписать'), findsOneWidget);

      // Overwrite item 1
      await tester.tap(find.text('Перезаписать'));
      await tester.pumpAndSettle();

      // Now at item 2
      expect(find.text('Конфликт 2 из 2'), findsOneWidget);

      // Skip item 2
      await tester.tap(find.text('Пропустить'));
      await tester.pumpAndSettle();

      expect(res, isNotNull);
      expect(res!.confirmedItems.map((e) => e.name), containsAll(['c.png', 'a.png']));
      expect(res!.skippedItems.map((e) => e.name), containsAll(['b.png']));
    });
  });

  group('Group 5: ServerFileBrowser & LocalFolderPicker Controls, Menus & Stats Sheet', () {
    testWidgets('LocalFolderPickerScreen renders localized strings and sort dropdown in RU', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final tempDir = Directory.systemTemp.createTempSync('local_picker_test');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      Directory('${tempDir.path}/FolderA').createSync();
      Directory('${tempDir.path}/FolderB').createSync();

      final controller = FileBrowserController(
        category: const FileCategory('All files', Icons.folder),
        loadOnInit: false,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          LocalFolderPickerScreen(
            controller: controller,
            initialPath: tempDir.path,
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify header and button labels in RU
      expect(find.text('Выбрать папку'), findsOneWidget);
      expect(find.text('Новая папка'), findsOneWidget);
      expect(find.text('Использовать эту папку'), findsOneWidget);

      // Sort dropdown in RU
      expect(find.text('Имя'), findsOneWidget);
      await tester.tap(find.text('Имя'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Дата'), findsWidgets);
      expect(find.text('Размер'), findsWidgets);
      expect(find.text('Тип'), findsWidgets);

      // Tap to select 'Дата'
      await tester.tap(find.text('Дата').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      controller.disposeController();
      controller.dispose();
    });

    testWidgets('ServerFileBrowser selection action bar and context menu labels in EN and RU', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 's1',
        accessToken: 'tok',
        refreshToken: 'ref',
      );

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/account/stats')) {
          return http.Response(
            jsonEncode({
              'total_size': 10485760,
              'total_count': 42,
              'photo_count': 10,
              'photo_size': 5242880,
              'video_count': 2,
              'video_size': 3145728,
              'audio_count': 5,
              'audio_size': 1048576,
              'document_count': 15,
              'document_size': 524288,
              'shared_count': 3,
              'shared_size': 262144,
              'other_count': 7,
              'other_size': 262144,
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'entries': [
              {
                'name': 'vacation.jpg',
                'size': 50000,
                'modified_at': 1700000000000,
                'type': 'photo',
                'mime_type': 'image/jpeg',
                'is_dir': false,
                'path': 'vacation.jpg',
              }
            ]
          }),
          200,
        );
      });

      final controller = ServerBrowserController(
        profile: ServerProfile(
          id: 's1',
          displayName: 'Test Server',
          baseUrl: 'http://localhost:8080',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        ),
        serverId: 's1',
        authService: AuthService(secretStore: store),
        client: client,
      );

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: ServerFileBrowser(
              controller: controller,
              isGridView: false,
            ),
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      // Root breadcrumb in RU is 'корень' (serverRoot)
      expect(find.text('корень'), findsOneWidget);

      // Open Stats Sheet
      expect(find.byTooltip('Статистика хранилища'), findsOneWidget);
      await tester.tap(find.byTooltip('Статистика хранилища'));
      await tester.pumpAndSettle();

      expect(find.text('Статистика хранилища'), findsWidgets);
      expect(find.text('Использовано'), findsOneWidget);
      expect(find.text('Всего файлов'), findsOneWidget);
      expect(find.text('42 элементов'), findsOneWidget);
      expect(find.text('Фото'), findsOneWidget);
      expect(find.text('Видео'), findsOneWidget);
      expect(find.text('Аудио'), findsOneWidget);
      expect(find.text('Документы'), findsOneWidget);
      expect(find.text('Общие'), findsOneWidget);
      expect(find.text('Другое'), findsOneWidget);

      // Close bottom sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Open Context Menu for vacation.jpg
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Переименовать'), findsOneWidget);
      expect(find.text('Скачать'), findsOneWidget);
      expect(find.text('Удалить'), findsOneWidget);
      expect(find.text('Поделиться ссылкой'), findsOneWidget);
      expect(find.text('Поделиться на сервере'), findsOneWidget);
      expect(find.text('Добавить в папку'), findsOneWidget);

      // Dismiss menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      controller.disposeController();
      controller.dispose();
    });
  });

  group('Group 6: FileBrowserController Operation Messages Exhaustive Locale Check', () {
    test('FileBrowserController produces accurate localized messages across EN and RU', () async {
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nRu = lookupAppLocalizations(const Locale('ru'));

      final tempDir = Directory.systemTemp.createTempSync('fbc_msg_test');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final controller = FileBrowserController(
        category: const FileCategory('Photos', Icons.photo),
        loadOnInit: false,
      );

      // 1. Folder creation restricted to All Files
      final nonAllFilesErrEn = await controller.createFolder('MyFolder', l10nEn);
      final nonAllFilesErrRu = await controller.createFolder('MyFolder', l10nRu);
      expect(nonAllFilesErrEn, 'Folder creation is only available in All files.');
      expect(nonAllFilesErrRu, 'Создание папок доступно только в разделе «Все файлы».');

      // 2. Switch to All files category without directory
      final allFilesController = FileBrowserController(
        category: const FileCategory('All files', Icons.folder),
        loadOnInit: false,
      );
      final noDirErrEn = await allFilesController.createFolder('Folder', l10nEn);
      final noDirErrRu = await allFilesController.createFolder('Folder', l10nRu);
      expect(noDirErrEn, 'Current directory is unavailable.');
      expect(noDirErrRu, 'Текущая папка недоступна.');

      // 3. Empty folder name
      allFilesController.directoryHistory.add(tempDir);
      final emptyNameErrEn = await allFilesController.createFolder('   ', l10nEn);
      final emptyNameErrRu = await allFilesController.createFolder('   ', l10nRu);
      expect(emptyNameErrEn, 'Folder name cannot be empty.');
      expect(emptyNameErrRu, 'Имя папки не может быть пустым.');

      // 4. Folder already exists
      final existingSub = Directory('${tempDir.path}/Existing')..createSync();
      final existsErrEn = await allFilesController.createFolder('Existing', l10nEn);
      final existsErrRu = await allFilesController.createFolder('Existing', l10nRu);
      expect(existsErrEn, 'Folder already exists.');
      expect(existsErrRu, 'Папка с таким именем уже существует.');

      // 5. Move selected with empty selection
      final moveNothingEn = await allFilesController.moveSelectedToFolder(tempDir.path, l10nEn);
      final moveNothingRu = await allFilesController.moveSelectedToFolder(tempDir.path, l10nRu);
      expect(moveNothingEn, 'Nothing selected.');
      expect(moveNothingRu, 'Ничего не выбрано.');

      // 6. Move to nonexistent folder
      final dummyFile = File('${tempDir.path}/test.txt')..writeAsStringSync('data');
      allFilesController.selectedFiles.add(FileItem.fromEntity(dummyFile));
      final noDestErrEn = await allFilesController.moveSelectedToFolder('/nonexistent_path_xyz', l10nEn);
      final noDestErrRu = await allFilesController.moveSelectedToFolder('/nonexistent_path_xyz', l10nRu);
      expect(noDestErrEn, 'Destination folder does not exist.');
      expect(noDestErrRu, 'Папка назначения не существует.');

      // 7. Move folder into itself
      final subInside = Directory('${existingSub.path}/sub')..createSync();
      allFilesController.selectedFiles.clear();
      allFilesController.selectedFiles.add(FileItem.fromEntity(existingSub));
      final insideErrEn = await allFilesController.moveSelectedToFolder(subInside.path, l10nEn);
      expect(insideErrEn, 'Cannot move folder "Existing" into itself.');

      allFilesController.selectedFiles.add(FileItem.fromEntity(existingSub));
      final insideErrRu = await allFilesController.moveSelectedToFolder(subInside.path, l10nRu);
      expect(insideErrRu, 'Нельзя переместить папку «Existing» саму в себя.');

      // 8. Rename conflict already exists
      final fA = File('${tempDir.path}/fileA.txt')..writeAsStringSync('A');
      File('${tempDir.path}/fileB.txt').writeAsStringSync('B');
      final itemA = FileItem.fromEntity(fA);

      await allFilesController.renameItem(itemA, 'fileB.txt', l10nEn);
      expect(allFilesController.operationMessage, 'Failed to rename: A file or folder with that name already exists.');

      await allFilesController.renameItem(itemA, 'fileB.txt', l10nRu);
      expect(allFilesController.operationMessage, 'Не удалось переименовать: файл или папка с таким именем уже существует.');

      // 9. Successful rename
      await allFilesController.renameItem(itemA, 'fileC.txt', l10nEn);
      expect(allFilesController.operationMessage, 'Renamed "fileA.txt" to "fileC.txt".');

      final fC = File('${tempDir.path}/fileC.txt');
      final itemC = FileItem.fromEntity(fC);
      await allFilesController.renameItem(itemC, 'fileD.txt', l10nRu);
      expect(allFilesController.operationMessage, '«fileC.txt» переименован в «fileD.txt».');

      controller.disposeController();
      controller.dispose();
      allFilesController.disposeController();
      allFilesController.dispose();
    });
  });

  group('Group 7: ServerBrowserController Operation Messages Exhaustive Locale Check', () {
    test('ServerBrowserController produces accurate localized messages across EN and RU', () async {
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nRu = lookupAppLocalizations(const Locale('ru'));

      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 's_test',
        accessToken: 'tok',
        refreshToken: 'ref',
      );

      final controller = ServerBrowserController(
        profile: ServerProfile(
          id: 's_test',
          displayName: 'Test Server',
          baseUrl: 'http://localhost:8080',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        ),
        serverId: 's_test',
        authService: AuthService(secretStore: store),
        client: MockClient((request) async {
          if (request.url.path.endsWith('/folders')) {
            if (request.url.queryParameters['path'] == 'existing_folder') {
              return http.Response('Folder exists', 409);
            }
            return http.Response('OK', 200);
          }
          if (request.url.path.endsWith('/files/move')) {
            if (request.url.queryParameters['dest'] == 'fail_rename') {
              return http.Response('Failed', 500);
            }
            return http.Response('Created', 201);
          }
          if (request.url.path.endsWith('/files')) {
            return http.Response('OK', 200);
          }
          return http.Response('{"entries": []}', 200);
        }),
      );

      // 1. Create folder empty name
      await controller.createFolder('   ', l10nEn);
      expect(controller.operationMessage, 'Folder name cannot be empty.');
      await controller.createFolder('   ', l10nRu);
      expect(controller.operationMessage, 'Имя папки не может быть пустым.');

      // 2. Create folder failure with status code
      await controller.createFolder('existing_folder', l10nEn);
      expect(controller.operationMessage, 'Failed to create folder (409).');
      await controller.createFolder('existing_folder', l10nRu);
      expect(controller.operationMessage, 'Не удалось создать папку (код 409).');

      // 3. Rename failure with status code
      final testItem = ServerFileItem(
        name: 'old_doc.pdf',
        size: 100,
        modifiedAt: DateTime.now(),
        type: 'document',
        mimeType: 'application/pdf',
        thumbnailUrl: null,
        isDir: false,
        path: 'old_doc.pdf',
      );
      final renameFailedEn = await controller.renameItem(testItem, 'fail_rename', l10nEn);
      expect(renameFailedEn, isFalse);
      expect(controller.operationMessage, 'Failed to rename "old_doc.pdf" (500).');

      final renameFailedRu = await controller.renameItem(testItem, 'fail_rename', l10nRu);
      expect(renameFailedRu, isFalse);
      expect(controller.operationMessage, 'Не удалось переименовать «old_doc.pdf» (500).');

      // 4. Delete selected files
      controller.selectedFiles.add(testItem);
      await controller.deleteSelectedFiles(l10nEn);
      expect(controller.operationMessage, 'Deleted 1 items.');

      controller.selectedFiles.add(testItem);
      await controller.deleteSelectedFiles(l10nRu);
      expect(controller.operationMessage, 'Удалено 1 элемент(ов).');

      controller.disposeController();
      controller.dispose();
    });
  });

  group('Group 8: Fallback and Stability Invariants', () {
    test('Format display path transforms android storage root in RU', () {
      final store = InMemorySecretStore();
      final controller = ServerBrowserController(
        profile: ServerProfile(
          id: 's_fb',
          displayName: 'Test',
          baseUrl: 'http://localhost:8080',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        ),
        serverId: 's_fb',
        authService: AuthService(secretStore: store),
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      final l10nRu = lookupAppLocalizations(const Locale('ru'));
      final l10nEn = lookupAppLocalizations(const Locale('en'));

      expect(controller.currentPath, '');
      expect(l10nRu.storageRoot, 'Хранилище');
      expect(l10nEn.storageRoot, 'Storage');

      controller.disposeController();
      controller.dispose();
    });
  });
}
