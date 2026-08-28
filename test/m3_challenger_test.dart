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

  group('CHALLENGER: CreateFolderDialog null vs explicit parameters', () {
    testWidgets(
      'null title & hintText defaults to localized strings in English',
      (tester) async {
        await tester.pumpWidget(
          wrapWithLocalization(
            const Scaffold(
              body: CreateFolderDialog(title: null, hintText: null),
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create Folder'), findsOneWidget);
        expect(find.text('Folder name'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Create'), findsOneWidget);
      },
    );

    testWidgets(
      'null title & hintText defaults to localized strings in Russian',
      (tester) async {
        await tester.pumpWidget(
          wrapWithLocalization(
            const Scaffold(
              body: CreateFolderDialog(title: null, hintText: null),
            ),
            locale: const Locale('ru'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Создать папку'), findsOneWidget);
        expect(find.text('Имя папки'), findsOneWidget);
        expect(find.text('Отмена'), findsOneWidget);
        expect(find.text('Создать'), findsOneWidget);
      },
    );

    testWidgets(
      'explicit custom title & hintText override defaults in English',
      (tester) async {
        await tester.pumpWidget(
          wrapWithLocalization(
            const Scaffold(
              body: CreateFolderDialog(
                title: 'Adversarial Folder Title',
                hintText: 'Adversarial Folder Hint',
              ),
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Adversarial Folder Title'), findsOneWidget);
        expect(find.text('Adversarial Folder Hint'), findsOneWidget);
        expect(find.text('Create Folder'), findsNothing);
        expect(find.text('Folder name'), findsNothing);
      },
    );

    testWidgets(
      'explicit custom title & hintText override defaults in Russian',
      (tester) async {
        await tester.pumpWidget(
          wrapWithLocalization(
            const Scaffold(
              body: CreateFolderDialog(
                title: 'Специальная папка',
                hintText: 'Специальное имя',
              ),
            ),
            locale: const Locale('ru'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Специальная папка'), findsOneWidget);
        expect(find.text('Специальное имя'), findsOneWidget);
        expect(find.text('Создать папку'), findsNothing);
        expect(find.text('Имя папки'), findsNothing);
      },
    );

    testWidgets(
      'CreateFolderDialog input interaction & return value on submit',
      (tester) async {
        String? createdName;
        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    createdName = await CreateFolderDialog.show(context);
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
            locale: const Locale('en'),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'My New Folder');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(createdName, 'My New Folder');
      },
    );

    testWidgets('CreateFolderDialog cancel returns null', (tester) async {
      String? createdName = 'initial';
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  createdName = await CreateFolderDialog.show(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Несохраненная папка');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(createdName, isNull);
    });
  });

  group('CHALLENGER: RestoreConflictDialog Stress & Epoch 0 Fallback', () {
    testWidgets(
      'Single conflict with epoch 0 timestamps renders Unknown in English',
      (tester) async {
        final conflict = RestoreConflictItem(
          id: 42,
          name: 'ghost_file.bin',
          originalPath: '',
          existingSize: 0,
          existingModified: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          trashSize: 0,
          trashDeletedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );

        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showRestoreConflictDialog(
                    context,
                    conflicts: [conflict],
                    allIds: [42],
                  ),
                  child: const Text('Show Restore Conflict'),
                ),
              ),
            ),
            locale: const Locale('en'),
          ),
        );

        await tester.tap(find.text('Show Restore Conflict'));
        await tester.pumpAndSettle();

        expect(find.text('File already exists'), findsOneWidget);
        expect(find.text('Date: Unknown'), findsOneWidget);
        expect(find.text('Deleted: Unknown'), findsOneWidget);
        expect(find.text('Size: 0 B'), findsNWidgets(2));
        expect(find.text('Overwrite'), findsOneWidget);
        expect(find.text('Restore as Copy'), findsOneWidget);
      },
    );

    testWidgets(
      'Single conflict with valid timestamps renders formatted date',
      (tester) async {
        final validDate = DateTime(2026, 8, 18, 14, 30);
        final conflict = RestoreConflictItem(
          id: 99,
          name: 'valid.pdf',
          originalPath: 'docs/valid.pdf',
          existingSize: 2048,
          existingModified: validDate,
          trashSize: 2048,
          trashDeletedAt: validDate,
        );

        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showRestoreConflictDialog(
                    context,
                    conflicts: [conflict],
                    allIds: [99],
                  ),
                  child: const Text('Show Valid Restore'),
                ),
              ),
            ),
            locale: const Locale('ru'),
          ),
        );

        await tester.tap(find.text('Show Valid Restore'));
        await tester.pumpAndSettle();

        expect(find.text('Файл уже существует'), findsOneWidget);
        expect(find.textContaining('2026-08-18 14:30'), findsNWidgets(2));
        expect(find.textContaining('Неизвестно'), findsNothing);
      },
    );

    testWidgets(
      'Single conflict with epoch 0 timestamps renders Неизвестно in Russian',
      (tester) async {
        final conflict = RestoreConflictItem(
          id: 42,
          name: 'ghost_file.bin',
          originalPath: '',
          existingSize: 0,
          existingModified: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          trashSize: 0,
          trashDeletedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );

        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showRestoreConflictDialog(
                    context,
                    conflicts: [conflict],
                    allIds: [42],
                  ),
                  child: const Text('Show Restore Conflict'),
                ),
              ),
            ),
            locale: const Locale('ru'),
          ),
        );

        await tester.tap(find.text('Show Restore Conflict'));
        await tester.pumpAndSettle();

        expect(find.text('Файл уже существует'), findsOneWidget);
        expect(find.text('Дата: Неизвестно'), findsOneWidget);
        expect(find.text('Удалён: Неизвестно'), findsOneWidget);
        expect(find.text('Размер: 0 B'), findsNWidgets(2));
        expect(find.text('Перезаписать'), findsOneWidget);
        expect(find.text('Восстановить как копию'), findsOneWidget);
      },
    );

    testWidgets(
      'Multi-conflict with batch buttons & apply to all remaining toggle in RU',
      (tester) async {
        final conflict1 = RestoreConflictItem(
          id: 1,
          name: 'doc1.pdf',
          originalPath: 'docs/doc1.pdf',
          existingSize: 1024,
          existingModified: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          trashSize: 2048,
          trashDeletedAt: DateTime.utc(2026, 8, 10, 10, 0),
        );
        final conflict2 = RestoreConflictItem(
          id: 2,
          name: 'doc2.pdf',
          originalPath: 'docs/doc2.pdf',
          existingSize: 4096,
          existingModified: DateTime.utc(2026, 8, 12, 12, 0),
          trashSize: 4096,
          trashDeletedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        final conflict3 = RestoreConflictItem(
          id: 3,
          name: 'doc3.pdf',
          originalPath: 'docs/doc3.pdf',
          existingSize: 8192,
          existingModified: DateTime.utc(2026, 8, 14, 14, 0),
          trashSize: 8192,
          trashDeletedAt: DateTime.utc(2026, 8, 15, 15, 0),
        );

        RestoreConflictResolution? resolution;

        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    resolution = await showRestoreConflictDialog(
                      context,
                      conflicts: [conflict1, conflict2, conflict3],
                      allIds: [1, 2, 3, 4],
                    );
                  },
                  child: const Text('Show Multi Restore'),
                ),
              ),
            ),
            locale: const Locale('ru'),
          ),
        );

        await tester.tap(find.text('Show Multi Restore'));
        await tester.pumpAndSettle();

        final l10nRu = lookupAppLocalizations(const Locale('ru'));

        // Check conflict counter
        expect(find.text(l10nRu.conflictNofM(1, 3)), findsOneWidget);
        expect(find.text(l10nRu.conflictKeepAllCopies), findsOneWidget);
        expect(find.text(l10nRu.conflictOverwriteAll), findsOneWidget);
        expect(find.text(l10nRu.conflictRestoreAsCopy), findsOneWidget);
        expect(find.text(l10nRu.conflictOverwrite), findsOneWidget);

        // Check checkbox text
        expect(find.text(l10nRu.conflictApplyToRemaining(3)), findsOneWidget);

        // Toggle checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        expect(find.text(l10nRu.conflictRestoreAllAsCopies), findsOneWidget);
        expect(find.text(l10nRu.conflictOverwriteAllRemaining), findsOneWidget);

        // Tap overwrite all remaining
        await tester.tap(find.text(l10nRu.conflictOverwriteAllRemaining));
        await tester.pumpAndSettle();

        expect(resolution, isNotNull);
        expect(resolution!.overwriteDecisions[1], isTrue);
        expect(resolution!.overwriteDecisions[2], isTrue);
        expect(resolution!.overwriteDecisions[3], isTrue);
        expect(
          resolution!.overwriteDecisions[4],
          isFalse,
        ); // non-conflicting default
      },
    );

    testWidgets(
      'Empty conflict list resolves immediately without showing dialog',
      (tester) async {
        RestoreConflictResolution? resolution;

        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    resolution = await showRestoreConflictDialog(
                      context,
                      conflicts: [],
                      allIds: [10, 20],
                    );
                  },
                  child: const Text('Show Empty Conflicts'),
                ),
              ),
            ),
            locale: const Locale('en'),
          ),
        );

        await tester.tap(find.text('Show Empty Conflicts'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(resolution, isNotNull);
        expect(resolution!.overwriteDecisions[10], isFalse);
        expect(resolution!.overwriteDecisions[20], isFalse);
      },
    );
  });

  group('CHALLENGER: UploadConflictDialog Stress & Epoch 0 Fallback', () {
    testWidgets(
      'Single upload conflict with epoch 0 dates renders Unknown in EN and Неизвестно in RU',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync(
          'm3_challenger_upload',
        );
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final localFile = File('${tempDir.path}/photo.raw')
          ..writeAsStringSync('dummy');
        final localItem = FileItem.fromEntity(localFile);
        final serverItem = ServerFileItem(
          name: 'photo.raw',
          size: 5,
          modifiedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          type: 'image',
          mimeType: 'image/raw',
          thumbnailUrl: null,
          isDir: false,
          path: 'photo.raw',
        );

        final l10nEn = lookupAppLocalizations(const Locale('en'));
        final l10nRu = lookupAppLocalizations(const Locale('ru'));

        // EN test
        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showUploadConflictDialog(
                    context,
                    conflicts: [
                      UploadConflictItem(
                        item: localItem,
                        existingItem: serverItem,
                      ),
                    ],
                    nonConflictingItems: [],
                  ),
                  child: const Text('Show Upload Conflict EN'),
                ),
              ),
            ),
            locale: const Locale('en'),
          ),
        );

        await tester.tap(find.text('Show Upload Conflict EN'));
        await tester.pumpAndSettle();

        expect(find.text(l10nEn.conflictFileAlreadyExists), findsOneWidget);
        expect(find.text(l10nEn.conflictExisting), findsOneWidget);
        expect(find.text(l10nEn.conflictNewUpload), findsOneWidget);
        expect(
          find.text(l10nEn.conflictDateLabel(l10nEn.unknown)),
          findsWidgets,
        );
        expect(find.text(l10nEn.conflictSkip), findsOneWidget);
        expect(find.text(l10nEn.conflictOverwrite), findsOneWidget);

        await tester.tap(find.text(l10nEn.conflictSkip));
        await tester.pumpAndSettle();

        // RU test
        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showUploadConflictDialog(
                    context,
                    conflicts: [
                      UploadConflictItem(
                        item: localItem,
                        existingItem: serverItem,
                      ),
                    ],
                    nonConflictingItems: [],
                  ),
                  child: const Text('Show Upload Conflict RU'),
                ),
              ),
            ),
            locale: const Locale('ru'),
          ),
        );

        await tester.tap(find.text('Show Upload Conflict RU'));
        await tester.pumpAndSettle();

        expect(find.text(l10nRu.conflictFileAlreadyExists), findsOneWidget);
        expect(find.text(l10nRu.conflictExisting), findsOneWidget);
        expect(find.text(l10nRu.conflictNewUpload), findsOneWidget);
        expect(
          find.text(l10nRu.conflictDateLabel(l10nRu.unknown)),
          findsWidgets,
        );
        expect(find.text(l10nRu.conflictSkip), findsOneWidget);
        expect(find.text(l10nRu.conflictOverwrite), findsOneWidget);
      },
    );

    testWidgets(
      'Multiple upload conflicts batch skip and overwrite decisions in RU',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync(
          'm3_challenger_upload_multi',
        );
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final file1 = File('${tempDir.path}/f1.txt')..writeAsStringSync('1');
        final file2 = File('${tempDir.path}/f2.txt')..writeAsStringSync('2');
        final file3 = File('${tempDir.path}/f3.txt')..writeAsStringSync('3');
        final item1 = FileItem.fromEntity(file1);
        final item2 = FileItem.fromEntity(file2);
        final item3 = FileItem.fromEntity(file3);

        final sItem1 = ServerFileItem(
          name: 'f1.txt',
          size: 1,
          modifiedAt: DateTime.utc(2026, 1, 1),
          type: 'document',
          mimeType: 'text/plain',
          thumbnailUrl: null,
          isDir: false,
          path: 'f1.txt',
        );
        final sItem2 = ServerFileItem(
          name: 'f2.txt',
          size: 2,
          modifiedAt: DateTime.utc(2026, 1, 2),
          type: 'document',
          mimeType: 'text/plain',
          thumbnailUrl: null,
          isDir: false,
          path: 'f2.txt',
        );

        UploadConflictResolution? resolution;

        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    resolution = await showUploadConflictDialog(
                      context,
                      conflicts: [
                        UploadConflictItem(item: item1, existingItem: sItem1),
                        UploadConflictItem(item: item2, existingItem: sItem2),
                      ],
                      nonConflictingItems: [item3],
                    );
                  },
                  child: const Text('Show Multi Upload RU'),
                ),
              ),
            ),
            locale: const Locale('ru'),
          ),
        );

        await tester.tap(find.text('Show Multi Upload RU'));
        await tester.pumpAndSettle();

        final l10nRu = lookupAppLocalizations(const Locale('ru'));

        expect(find.text(l10nRu.conflictNofM(1, 2)), findsOneWidget);
        expect(find.text(l10nRu.conflictSkipAll), findsOneWidget);
        expect(find.text(l10nRu.conflictOverwriteAll), findsOneWidget);
        expect(find.text(l10nRu.conflictSkip), findsOneWidget);
        expect(find.text(l10nRu.conflictOverwrite), findsOneWidget);

        // Tap Skip All
        await tester.tap(find.text(l10nRu.conflictSkipAll));
        await tester.pumpAndSettle();

        expect(resolution, isNotNull);
        expect(resolution!.confirmedItems, [item3]);
        expect(resolution!.skippedItems.length, 2);
        expect(resolution!.skippedItems.contains(item1), isTrue);
        expect(resolution!.skippedItems.contains(item2), isTrue);
      },
    );

    testWidgets(
      'Empty upload conflict list returns non-conflicting items immediately',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync(
          'm3_challenger_upload_empty',
        );
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final file1 = File('${tempDir.path}/safe.txt')
          ..writeAsStringSync('safe');
        final safeItem = FileItem.fromEntity(file1);

        UploadConflictResolution? resolution;

        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    resolution = await showUploadConflictDialog(
                      context,
                      conflicts: [],
                      nonConflictingItems: [safeItem],
                    );
                  },
                  child: const Text('Show Empty Upload'),
                ),
              ),
            ),
            locale: const Locale('ru'),
          ),
        );

        await tester.tap(find.text('Show Empty Upload'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(resolution, isNotNull);
        expect(resolution!.confirmedItems, [safeItem]);
        expect(resolution!.skippedItems.isEmpty, isTrue);
      },
    );
  });

  group(
    'CHALLENGER: TransferManager & TransferBottomBar Pluralization & Tooltips',
    () {
      test('formatSummary exhaustive edge cases across locales', () {
        final l10nEn = lookupAppLocalizations(const Locale('en'));
        final l10nRu = lookupAppLocalizations(const Locale('ru'));

        final manager = TransferManager();

        // Case 1: Empty manager
        expect(manager.formatSummary(l10nEn), '0%  0/0 files');
        expect(manager.formatSummary(l10nRu), '0%  0/0 файлов');

        // Case 2: 1 item added
        final item1 = manager.addItem(
          name: 'one.txt',
          direction: TransferDirection.upload,
          totalBytes: 1000,
        );
        expect(manager.formatSummary(l10nEn), '0%  0/1 files');
        expect(manager.formatSummary(l10nRu), '0%  0/1 файлов');

        // Case 3: 1 item completed
        manager.completeItem(item1);
        expect(manager.formatSummary(l10nEn), '100%  1/1 files');
        expect(manager.formatSummary(l10nRu), '100%  1/1 файлов');

        // Case 4: 5 items with 2 completed
        final drafts = [
          const TransferItemDraft(
            name: 'two.txt',
            direction: TransferDirection.download,
            totalBytes: 1000,
          ),
          const TransferItemDraft(
            name: 'three.txt',
            direction: TransferDirection.download,
            totalBytes: 1000,
          ),
          const TransferItemDraft(
            name: 'four.txt',
            direction: TransferDirection.download,
            totalBytes: 1000,
          ),
          const TransferItemDraft(
            name: 'five.txt',
            direction: TransferDirection.download,
            totalBytes: 1000,
          ),
        ];
        final added = manager.addItems(drafts);
        manager.completeItem(
          added[0],
        ); // 2 of 5 completed, total 2000 of 5000 bytes = 40%

        expect(manager.formatSummary(l10nEn), '40%  2/5 files');
        expect(manager.formatSummary(l10nRu), '40%  2/5 файлов');
      });

      testWidgets('TransferBottomBar interactions and tooltips in EN and RU', (
        tester,
      ) async {
        final manager = TransferManager();
        final item = manager.addItem(
          name: 'test.zip',
          direction: TransferDirection.upload,
          totalBytes: 5000,
        );
        manager.startItem(item);

        var openTapped = false;

        // English
        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              bottomNavigationBar: TransferBottomBar(
                manager: manager,
                onOpen: () => openTapped = true,
              ),
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('0%  0/1 files'), findsOneWidget);
        expect(find.byTooltip('Pause'), findsOneWidget);
        expect(find.byTooltip('Cancel'), findsOneWidget);

        await tester.tap(find.text('0%  0/1 files'));
        expect(openTapped, isTrue);

        // Russian
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

        expect(find.text('0%  0/1 файлов'), findsOneWidget);
        expect(find.byTooltip('Пауза'), findsOneWidget);
        expect(find.byTooltip('Отмена'), findsOneWidget);

        // Pause toggle
        await tester.tap(find.byTooltip('Пауза'));
        await tester.pumpAndSettle();

        expect(manager.isPaused, isTrue);
        expect(find.byTooltip('Возобновить'), findsOneWidget);
      });

      testWidgets(
        'TransferPage empty state & all transfer status labels in EN and RU',
        (tester) async {
          final manager = TransferManager();
          final l10nRu = lookupAppLocalizations(const Locale('ru'));
          final l10nEn = lookupAppLocalizations(const Locale('en'));

          // Empty state RU
          await tester.pumpWidget(
            wrapWithLocalization(
              TransferPage(manager: manager),
              locale: const Locale('ru'),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(l10nRu.transfersTitle), findsOneWidget);
          expect(find.text(l10nRu.noTransfers), findsOneWidget);

          // Add items with different statuses
          manager.addItem(
            name: 'q.txt',
            direction: TransferDirection.upload,
            totalBytes: 100,
          );
          final rItem = manager.addItem(
            name: 'r.txt',
            direction: TransferDirection.upload,
            totalBytes: 100,
          );
          manager.startItem(rItem);
          final cItem = manager.addItem(
            name: 'c.txt',
            direction: TransferDirection.download,
            totalBytes: 100,
          );
          manager.completeItem(cItem);
          final fItem = manager.addItem(
            name: 'f.txt',
            direction: TransferDirection.download,
            totalBytes: 100,
          );
          manager.failItem(fItem, 'Disk full');

          await tester.pumpWidget(
            wrapWithLocalization(
              TransferPage(manager: manager),
              locale: const Locale('ru'),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.textContaining(l10nRu.transferStatusQueued),
            findsOneWidget,
          );
          expect(
            find.textContaining(l10nRu.transferStatusRunning),
            findsOneWidget,
          );
          expect(
            find.textContaining(l10nRu.transferStatusCompleted),
            findsOneWidget,
          );
          expect(
            find.textContaining(l10nRu.transferStatusFailed),
            findsOneWidget,
          );
          expect(find.text('Disk full'), findsOneWidget);

          // EN verification
          await tester.pumpWidget(
            wrapWithLocalization(
              TransferPage(manager: manager),
              locale: const Locale('en'),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(l10nEn.transfersTitle), findsOneWidget);
          expect(
            find.textContaining(l10nEn.transferStatusQueued),
            findsOneWidget,
          );
          expect(
            find.textContaining(l10nEn.transferStatusRunning),
            findsOneWidget,
          );
          expect(
            find.textContaining(l10nEn.transferStatusCompleted),
            findsOneWidget,
          );
          expect(
            find.textContaining(l10nEn.transferStatusFailed),
            findsOneWidget,
          );
        },
      );
    },
  );

  group('CHALLENGER: ServerSortBy Dropdown in EN and RU', () {
    testWidgets(
      'ServerFileBrowser header sort dropdown options in English and Russian',
      (tester) async {
        final store = InMemorySecretStore();
        await store.saveTokens(
          serverId: 'srv_sort',
          accessToken: 'token',
          refreshToken: 'refresh',
        );

        final controller = ServerBrowserController(
          profile: ServerProfile(
            id: 'srv_sort',
            displayName: 'Test Sort',
            baseUrl: 'http://localhost:7777',
            authMode: 'login',
            lastUsedAt: DateTime.now().toUtc(),
            syncPrefs: const {},
          ),
          serverId: 'srv_sort',
          authService: AuthService(secretStore: store),
          client: MockClient(
            (_) async => http.Response('{"entries": []}', 200),
          ),
        );

        // English check
        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: ServerFileBrowser(controller: controller, isGridView: true),
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Name'), findsOneWidget);
        await tester.tap(find.text('Name'));
        await tester.pumpAndSettle();

        expect(find.text('Date'), findsWidgets);
        expect(find.text('Size'), findsWidgets);
        expect(find.text('Type'), findsWidgets);

        // Close dropdown by tapping outside or selecting
        await tester.tap(find.text('Date').last);
        await tester.pumpAndSettle();

        expect(controller.sortBy, ServerSortBy.date);

        // Russian check
        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: ServerFileBrowser(controller: controller, isGridView: true),
            ),
            locale: const Locale('ru'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Дата'), findsOneWidget);
        await tester.tap(find.text('Дата'));
        await tester.pumpAndSettle();

        expect(find.text('Имя'), findsWidgets);
        expect(find.text('Размер'), findsWidgets);
        expect(find.text('Тип'), findsWidgets);

        await tester.tap(find.text('Размер').last);
        await tester.pumpAndSettle();

        expect(controller.sortBy, ServerSortBy.size);

        controller.disposeController();
        controller.dispose();
      },
    );
  });

  group('CHALLENGER: Controller Localized Errors & Edge Operations', () {
    test('FileBrowserController edge cases in RU and EN', () async {
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nRu = lookupAppLocalizations(const Locale('ru'));

      final controller = FileBrowserController(
        category: const FileCategory('Custom Category', Icons.image),
        loadOnInit: false,
      );

      // 1. Folder creation outside All Files
      final catErrEn = await controller.createFolder('folder1', l10nEn);
      final catErrRu = await controller.createFolder('folder1', l10nRu);
      expect(catErrEn, l10nEn.folderCreationOnlyInAllFiles);
      expect(catErrRu, l10nRu.folderCreationOnlyInAllFiles);

      // 2. Move with empty selection
      final moveErrEn = await controller.moveSelectedToFolder('/var', l10nEn);
      final moveErrRu = await controller.moveSelectedToFolder('/var', l10nRu);
      expect(moveErrEn, l10nEn.nothingSelected);
      expect(moveErrRu, l10nRu.nothingSelected);

      // 3. Rename with existing conflict
      final tempDir = Directory.systemTemp.createTempSync('m3_fbc_rename');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final fileA = File('${tempDir.path}/a.txt')..writeAsStringSync('a');
      File('${tempDir.path}/b.txt').writeAsStringSync('b');
      final itemA = FileItem.fromEntity(fileA);

      final okRenEn = await controller.renameItem(itemA, 'b.txt', l10nEn);
      expect(okRenEn, isFalse);
      expect(controller.operationMessage, l10nEn.renameConflictAlreadyExists);

      final okRenRu = await controller.renameItem(itemA, 'b.txt', l10nRu);
      expect(okRenRu, isFalse);
      expect(controller.operationMessage, l10nRu.renameConflictAlreadyExists);
    });

    test('ServerBrowserController edge operations in RU and EN', () async {
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nRu = lookupAppLocalizations(const Locale('ru'));

      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv_ops',
        accessToken: 'token',
        refreshToken: 'refresh',
      );

      final controller = ServerBrowserController(
        profile: ServerProfile(
          id: 'srv_ops',
          displayName: 'Ops Test',
          baseUrl: 'http://localhost:7777',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        ),
        serverId: 'srv_ops',
        authService: AuthService(secretStore: store),
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      // 1. Empty folder name
      await controller.createFolder('   ', l10nEn);
      expect(controller.operationMessage, l10nEn.folderNameCannotBeEmpty);
      await controller.createFolder('   ', l10nRu);
      expect(controller.operationMessage, l10nRu.folderNameCannotBeEmpty);

      // 2. Rename item with empty / same name
      final testItem = ServerFileItem(
        name: 'original.txt',
        size: 10,
        modifiedAt: DateTime.now(),
        type: 'document',
        mimeType: 'text/plain',
        thumbnailUrl: null,
        isDir: false,
        path: 'original.txt',
      );

      final renEmpty = await controller.renameItem(testItem, '   ', l10nEn);
      expect(renEmpty, isFalse);

      final renSame = await controller.renameItem(
        testItem,
        'original.txt',
        l10nEn,
      );
      expect(renSame, isFalse);

      controller.disposeController();
      controller.dispose();
    });

    test(
      'ServerBrowserController operations preserve operationMessage in EN and RU across reload',
      () async {
        final l10nEn = lookupAppLocalizations(const Locale('en'));
        final l10nRu = lookupAppLocalizations(const Locale('ru'));

        final store = InMemorySecretStore();
        await store.saveTokens(
          serverId: 'srv_ops_full',
          accessToken: 'token',
          refreshToken: 'refresh',
        );

        final client = MockClient((request) async {
          if (request.url.path == '/api/folders') {
            return http.Response('{"ok": true}', 200);
          }
          if (request.url.path == '/api/files/move') {
            return http.Response('{"ok": true}', 200);
          }
          if (request.url.path == '/api/files') {
            if (request.method == 'GET') {
              return http.Response('data', 200);
            }
            if (request.method == 'POST') {
              return http.Response('ok', 200);
            }
            if (request.method == 'DELETE') {
              return http.Response('deleted', 200);
            }
          }
          return http.Response(jsonEncode({'entries': []}), 200);
        });

        final controller = ServerBrowserController(
          profile: ServerProfile(
            id: 'srv_ops_full',
            displayName: 'Ops Test Full',
            baseUrl: 'http://localhost:7777',
            authMode: 'login',
            lastUsedAt: DateTime.now().toUtc(),
            syncPrefs: const {},
          ),
          serverId: 'srv_ops_full',
          authService: AuthService(secretStore: store),
          client: client,
        );

        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Test 1: createFolderAtPath
        await controller.createFolderAtPath('', 'Projects', l10nEn);
        expect(controller.operationMessage, l10nEn.folderCreated);
        await controller.createFolderAtPath('', 'Проекты', l10nRu);
        expect(controller.operationMessage, l10nRu.folderCreated);

        // Test 2: renameItem
        final fileItem = ServerFileItem(
          name: 'report.pdf',
          size: 1024,
          modifiedAt: DateTime.now(),
          type: 'document',
          mimeType: 'application/pdf',
          thumbnailUrl: null,
          isDir: false,
          path: 'report.pdf',
        );

        final okRenEn = await controller.renameItem(
          fileItem,
          'final_report.pdf',
          l10nEn,
        );
        expect(okRenEn, isTrue);
        expect(
          controller.operationMessage,
          l10nEn.renamedOldToNew('report.pdf', 'final_report.pdf'),
        );

        final okRenRu = await controller.renameItem(
          fileItem,
          'отчет.pdf',
          l10nRu,
        );
        expect(okRenRu, isTrue);
        expect(
          controller.operationMessage,
          l10nRu.renamedOldToNew('report.pdf', 'отчет.pdf'),
        );

        // Test 3: moveSelectedToFolder
        controller.toggleSelection(fileItem);
        expect(controller.selectedFiles.length, 1);
        await controller.moveSelectedToFolder('archive', l10nEn);
        expect(controller.operationMessage, l10nEn.movedNItems(1));

        controller.toggleSelection(fileItem);
        await controller.moveSelectedToFolder('архив', l10nRu);
        expect(controller.operationMessage, l10nRu.movedNItems(1));

        controller.disposeController();
        controller.dispose();
      },
    );
  });
}
