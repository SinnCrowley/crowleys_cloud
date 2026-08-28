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

import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10nEn = lookupAppLocalizations(const Locale('en'));
  final l10nRu = lookupAppLocalizations(const Locale('ru'));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ServerFileItem makeItem({
    required String name,
    required String path,
    bool isDir = false,
    int size = 100,
  }) {
    return ServerFileItem(
      name: name,
      size: size,
      modifiedAt: DateTime.utc(2026, 8, 19, 12, 0),
      type: isDir ? 'folder' : 'document',
      mimeType: isDir ? 'inode/directory' : 'text/plain',
      thumbnailUrl: null,
      isDir: isDir,
      path: path,
    );
  }

  Future<ServerBrowserController> createMockController({
    required Future<http.Response> Function(http.Request request) handler,
    String initialScope = 'private',
    String serverId = 'test_srv',
  }) async {
    final store = InMemorySecretStore();
    await store.saveTokens(
      serverId: serverId,
      accessToken: 'test_token',
      refreshToken: 'test_refresh',
    );

    final client = MockClient(handler);

    final controller = ServerBrowserController(
      profile: ServerProfile(
        id: serverId,
        displayName: 'Test Server',
        baseUrl: 'http://localhost:8080',
        authMode: 'login',
        lastUsedAt: DateTime.now().toUtc(),
        syncPrefs: const {},
      ),
      serverId: serverId,
      authService: AuthService(secretStore: store),
      client: client,
    );

    if (initialScope != 'private') {
      controller.setScope(initialScope);
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
    return controller;
  }

  group('ADVERSARIAL: createFolderAtPath operationMessage Lifecycle & Localization', () {
    test('Empty and whitespace-only folder names produce validation error without network call', () async {
      var networkCalls = 0;
      final controller = await createMockController(
        handler: (req) async {
          networkCalls++;
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      // EN Empty & Whitespace
      await controller.createFolderAtPath('', '', l10nEn);
      expect(controller.operationMessage, l10nEn.folderNameCannotBeEmpty);

      await controller.createFolderAtPath('', '   ', l10nEn);
      expect(controller.operationMessage, l10nEn.folderNameCannotBeEmpty);

      // RU Empty & Whitespace
      await controller.createFolderAtPath('sub', '', l10nRu);
      expect(controller.operationMessage, l10nRu.folderNameCannotBeEmpty);

      await controller.createFolderAtPath('sub', ' \t\n ', l10nRu);
      expect(controller.operationMessage, l10nRu.folderNameCannotBeEmpty);

      // Initial directory fetch and account stats was 2, no create folder network calls
      expect(networkCalls, 2);

      controller.disposeController();
      controller.dispose();
    });

    test('Success retains localized message across reload in both EN and RU for root and nested paths', () async {
      final createdPaths = <String>[];
      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/folders' && req.method == 'POST') {
            createdPaths.add(req.url.queryParameters['path'] ?? '');
            return http.Response('{"status":"created"}', 201);
          }
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      // 1. Root folder in English
      await controller.createFolderAtPath('', 'Documents', l10nEn);
      expect(controller.operationMessage, l10nEn.folderCreated);
      expect(createdPaths, contains('Documents'));

      // 2. Nested folder in Russian
      await controller.createFolderAtPath('Documents', 'Финансы', l10nRu);
      expect(controller.operationMessage, l10nRu.folderCreated);
      expect(createdPaths, contains('Documents/Финансы'));

      controller.disposeController();
      controller.dispose();
    });

    test('HTTP error responses retain localized failure code in EN and RU', () async {
      final statusCodesToTest = [400, 403, 404, 409, 500, 503];

      for (final code in statusCodesToTest) {
        final controller = await createMockController(
          handler: (req) async {
            if (req.url.path == '/api/folders' && req.method == 'POST') {
              return http.Response('Error $code', code);
            }
            return http.Response(jsonEncode({'entries': []}), 200);
          },
        );

        // EN test
        await controller.createFolderAtPath('', 'FolderFailEn', l10nEn);
        expect(
          controller.operationMessage,
          l10nEn.failedToCreateFolderWithCode(code),
          reason: 'Failed for status code $code in EN',
        );

        // RU test
        await controller.createFolderAtPath('nested', 'FolderFailRu', l10nRu);
        expect(
          controller.operationMessage,
          l10nRu.failedToCreateFolderWithCode(code),
          reason: 'Failed for status code $code in RU',
        );

        controller.disposeController();
        controller.dispose();
      }
    });

    test('Listeners receive notification with non-null operationMessage upon folder creation', () async {
      final observedMessages = <String?>[];
      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/folders' && req.method == 'POST') {
            return http.Response('{}', 200);
          }
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      controller.addListener(() {
        if (controller.operationMessage != null) {
          observedMessages.add(controller.operationMessage);
        }
      });

      await controller.createFolderAtPath('', 'NotifyTest', l10nEn);
      expect(observedMessages, contains(l10nEn.folderCreated));
      expect(controller.operationMessage, l10nEn.folderCreated);

      controller.disposeController();
      controller.dispose();
    });
  });

  group('ADVERSARIAL: moveSelectedToFolder operationMessage Lifecycle & Localization', () {
    test('Empty selection does nothing and leaves operationMessage null', () async {
      var deleteCalled = false;
      var copyCalled = false;

      final controller = await createMockController(
        handler: (req) async {
          if (req.method == 'DELETE') deleteCalled = true;
          if (req.url.path == '/api/files' && req.method == 'POST') copyCalled = true;
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      expect(controller.selectedFiles, isEmpty);
      await controller.moveSelectedToFolder('destination', l10nEn);
      expect(controller.operationMessage, isNull);
      expect(deleteCalled, isFalse);
      expect(copyCalled, isFalse);

      await controller.moveSelectedToFolder('destination', l10nRu);
      expect(controller.operationMessage, isNull);

      controller.disposeController();
      controller.dispose();
    });

    test('Single item move success in English and Russian', () async {
      final item1 = makeItem(name: 'file1.txt', path: 'file1.txt');

      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/files' && req.method == 'GET') {
            return http.Response('file content', 200);
          }
          if (req.url.path == '/api/files' && req.method == 'POST') {
            return http.Response('{"ok":true}', 200);
          }
          if (req.url.path == '/api/files' && req.method == 'DELETE') {
            return http.Response('{"deleted":true}', 200);
          }
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      // EN
      controller.toggleSelection(item1);
      expect(controller.selectedFiles.length, 1);
      await controller.moveSelectedToFolder('target_dir', l10nEn);
      expect(controller.operationMessage, l10nEn.movedNItems(1));
      expect(controller.selectedFiles, isEmpty);

      // RU
      controller.toggleSelection(item1);
      await controller.moveSelectedToFolder('целевая_папка', l10nRu);
      expect(controller.operationMessage, l10nRu.movedNItems(1));
      expect(controller.selectedFiles, isEmpty);

      controller.disposeController();
      controller.dispose();
    });

    test('Multiple items (5 items) move success in English and Russian', () async {
      final items = List.generate(
        5,
        (i) => makeItem(name: 'doc_$i.txt', path: 'doc_$i.txt'),
      );

      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/files' && req.method == 'GET') {
            return http.Response('content', 200);
          }
          if (req.url.path == '/api/files' && req.method == 'POST') {
            return http.Response('ok', 200);
          }
          if (req.url.path == '/api/files' && req.method == 'DELETE') {
            return http.Response('deleted', 200);
          }
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      // EN: Move 5 items
      for (final item in items) {
        controller.toggleSelection(item);
      }
      expect(controller.selectedFiles.length, 5);

      await controller.moveSelectedToFolder('bulk_target', l10nEn);
      expect(controller.operationMessage, l10nEn.movedNItems(5));
      expect(controller.selectedFiles, isEmpty);

      // RU: Move 5 items
      for (final item in items) {
        controller.toggleSelection(item);
      }
      await controller.moveSelectedToFolder('целевая_папка', l10nRu);
      expect(controller.operationMessage, l10nRu.movedNItems(5));
      expect(controller.selectedFiles, isEmpty);

      controller.disposeController();
      controller.dispose();
    });

    test('All items fail move produces movedNItemsFailedM(0, N) in EN and RU', () async {
      final item1 = makeItem(name: 'fail1.txt', path: 'fail1.txt');
      final item2 = makeItem(name: 'fail2.txt', path: 'fail2.txt');

      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/files' && req.method == 'GET') {
            return http.Response('error', 500);
          }
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      // EN
      controller.toggleSelection(item1);
      controller.toggleSelection(item2);
      await controller.moveSelectedToFolder('dest', l10nEn);
      expect(controller.operationMessage, l10nEn.movedNItemsFailedM(0, 2));
      expect(controller.selectedFiles, isEmpty);

      // RU
      controller.toggleSelection(item1);
      controller.toggleSelection(item2);
      await controller.moveSelectedToFolder('dest', l10nRu);
      expect(controller.operationMessage, l10nRu.movedNItemsFailedM(0, 2));
      expect(controller.selectedFiles, isEmpty);

      controller.disposeController();
      controller.dispose();
    });

    test('Partial failure (3 moved, 2 failed) retains correct count in EN and RU', () async {
      final items = List.generate(
        5,
        (i) => makeItem(name: 'partial_$i.txt', path: 'partial_$i.txt'),
      );

      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/files' && req.method == 'GET') {
            // Fail items 3 and 4
            final path = req.url.queryParameters['path'] ?? '';
            if (path.contains('partial_3') || path.contains('partial_4')) {
              return http.Response('forbidden', 403);
            }
            return http.Response('data', 200);
          }
          if (req.url.path == '/api/files' && req.method == 'POST') {
            return http.Response('ok', 200);
          }
          if (req.url.path == '/api/files' && req.method == 'DELETE') {
            return http.Response('deleted', 200);
          }
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      // EN: 3 moved, 2 failed
      for (final item in items) {
        controller.toggleSelection(item);
      }
      await controller.moveSelectedToFolder('dest', l10nEn);
      expect(controller.operationMessage, l10nEn.movedNItemsFailedM(3, 2));
      expect(controller.selectedFiles, isEmpty);

      // RU: 3 moved, 2 failed
      for (final item in items) {
        controller.toggleSelection(item);
      }
      await controller.moveSelectedToFolder('dest', l10nRu);
      expect(controller.operationMessage, l10nRu.movedNItemsFailedM(3, 2));
      expect(controller.selectedFiles, isEmpty);

      controller.disposeController();
      controller.dispose();
    });

    test('Moving folder into its own subdirectory fails without network call and updates failure count', () async {
      final dirItem = makeItem(name: 'parent_folder', path: 'parent_folder', isDir: true);
      final normalFile = makeItem(name: 'file.txt', path: 'file.txt');

      var networkCalls = 0;
      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/files' && req.method == 'GET') {
            networkCalls++;
            return http.Response('ok', 200);
          }
          if (req.url.path == '/api/files' && req.method == 'POST') {
            networkCalls++;
            return http.Response('ok', 200);
          }
          if (req.url.path == '/api/files' && req.method == 'DELETE') {
            networkCalls++;
            return http.Response('deleted', 200);
          }
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      // 1. Move folder into its own subdirectory: parent_folder -> parent_folder/child
      controller.toggleSelection(dirItem);
      await controller.moveSelectedToFolder('parent_folder/child', l10nEn);
      expect(controller.operationMessage, l10nEn.movedNItemsFailedM(0, 1));
      expect(networkCalls, 0); // Guard prevented network calls for dirItem

      // 2. Mix: 1 normal file succeeds, 1 illegal dir move fails -> 1 moved, 1 failed
      controller.toggleSelection(dirItem);
      controller.toggleSelection(normalFile);
      await controller.moveSelectedToFolder('parent_folder/sub', l10nRu);
      expect(controller.operationMessage, l10nRu.movedNItemsFailedM(1, 1));

      controller.disposeController();
      controller.dispose();
    });
  });

  group('ADVERSARIAL: renameItem operationMessage Lifecycle & Localization', () {
    test('Rename with whitespace-only or identical name returns false and leaves previous operationMessage unchanged', () async {
      final item = makeItem(name: 'original.txt', path: 'original.txt');
      final controller = await createMockController(
        handler: (req) async => http.Response(jsonEncode({'entries': []}), 200),
      );

      // Seed an operationMessage
      controller.operationMessage = 'PREVIOUS_MESSAGE';

      // Empty name
      final resEmpty = await controller.renameItem(item, '   ', l10nEn);
      expect(resEmpty, isFalse);
      expect(controller.operationMessage, 'PREVIOUS_MESSAGE');

      // Identical name
      final resSame = await controller.renameItem(item, 'original.txt', l10nEn);
      expect(resSame, isFalse);
      expect(controller.operationMessage, 'PREVIOUS_MESSAGE');

      // Identical name with padding whitespace
      final resSamePadded = await controller.renameItem(item, '  original.txt  ', l10nRu);
      expect(resSamePadded, isFalse);
      expect(controller.operationMessage, 'PREVIOUS_MESSAGE');

      controller.disposeController();
      controller.dispose();
    });

    test('Success retains localized renamedOldToNew message in EN and RU across reload', () async {
      final movedRequests = <Map<String, String>>[];
      final item = makeItem(name: 'alpha.txt', path: 'alpha.txt');

      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/files/move' && req.method == 'POST') {
            movedRequests.add(Map<String, String>.from(req.url.queryParameters));
            return http.Response('{"ok":true}', 200);
          }
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      // English rename
      final okEn = await controller.renameItem(item, 'beta.txt', l10nEn);
      expect(okEn, isTrue);
      expect(
        controller.operationMessage,
        l10nEn.renamedOldToNew('alpha.txt', 'beta.txt'),
      );
      expect(movedRequests.last['src'], 'alpha.txt');
      expect(movedRequests.last['dest'], 'beta.txt');

      // Russian rename
      final okRu = await controller.renameItem(item, 'бета.txt', l10nRu);
      expect(okRu, isTrue);
      expect(
        controller.operationMessage,
        l10nRu.renamedOldToNew('alpha.txt', 'бета.txt'),
      );
      expect(movedRequests.last['dest'], 'бета.txt');

      controller.disposeController();
      controller.dispose();
    });

    test('Nested file rename preserves parent directory path in dest query parameter', () async {
      final item = makeItem(name: 'child.doc', path: 'nested/deep/child.doc');
      final movedRequests = <Map<String, String>>[];

      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/files/move') {
            movedRequests.add(Map<String, String>.from(req.url.queryParameters));
            return http.Response('ok', 200);
          }
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      final ok = await controller.renameItem(item, 'renamed_child.doc', l10nEn);
      expect(ok, isTrue);
      expect(
        controller.operationMessage,
        l10nEn.renamedOldToNew('child.doc', 'renamed_child.doc'),
      );
      expect(movedRequests.last['src'], 'nested/deep/child.doc');
      expect(movedRequests.last['dest'], 'nested/deep/renamed_child.doc');

      controller.disposeController();
      controller.dispose();
    });

    test('Rename HTTP errors (400, 403, 404, 409, 500) produce localized failure message in EN and RU', () async {
      final item = makeItem(name: 'conflict.txt', path: 'conflict.txt');
      final errorCodes = [400, 403, 404, 409, 500];

      for (final code in errorCodes) {
        final controller = await createMockController(
          handler: (req) async {
            if (req.url.path == '/api/files/move') {
              return http.Response('conflict', code);
            }
            return http.Response(jsonEncode({'entries': []}), 200);
          },
        );

        // EN
        final okEn = await controller.renameItem(item, 'new_conflict.txt', l10nEn);
        expect(okEn, isFalse);
        expect(
          controller.operationMessage,
          l10nEn.failedToRenameWithStatus('conflict.txt', code),
        );

        // RU
        final okRu = await controller.renameItem(item, 'новое_имя.txt', l10nRu);
        expect(okRu, isFalse);
        expect(
          controller.operationMessage,
          l10nRu.failedToRenameWithStatus('conflict.txt', code),
        );

        controller.disposeController();
        controller.dispose();
      }
    });
  });

  group('ADVERSARIAL: Sequencing, Lifecycle Invalidation, and Interleaved Operations', () {
    test('Subsequent explicit reload clears operationMessage to null', () async {
      final item = makeItem(name: 'file.txt', path: 'file.txt');
      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/folders') return http.Response('{}', 200);
          if (req.url.path == '/api/files/move') return http.Response('{}', 200);
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      // 1. Create folder -> message is set
      await controller.createFolderAtPath('', 'Folder1', l10nEn);
      expect(controller.operationMessage, l10nEn.folderCreated);

      // 2. Explicit user reload / pull-to-refresh -> message is reset to null
      await controller.reload();
      expect(controller.operationMessage, isNull);

      // 3. Rename item -> message is set
      await controller.renameItem(item, 'file_renamed.txt', l10nRu);
      expect(
        controller.operationMessage,
        l10nRu.renamedOldToNew('file.txt', 'file_renamed.txt'),
      );

      // 4. Another reload -> message is reset to null
      await controller.reload();
      expect(controller.operationMessage, isNull);

      controller.disposeController();
      controller.dispose();
    });

    test('Chained sequence: Create Folder -> Rename Item -> Move Selected without explicit reload between calls', () async {
      final item = makeItem(name: 'test.txt', path: 'test.txt');

      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/folders') return http.Response('{}', 200);
          if (req.url.path == '/api/files/move') return http.Response('{}', 200);
          if (req.url.path == '/api/files' && req.method == 'GET') return http.Response('data', 200);
          if (req.url.path == '/api/files' && req.method == 'POST') return http.Response('ok', 200);
          if (req.url.path == '/api/files' && req.method == 'DELETE') return http.Response('deleted', 200);
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      // Step 1: Create Folder
      await controller.createFolderAtPath('', 'ProjectA', l10nEn);
      expect(controller.operationMessage, l10nEn.folderCreated);

      // Step 2: Rename Item replaces message immediately
      await controller.renameItem(item, 'test_v2.txt', l10nEn);
      expect(controller.operationMessage, l10nEn.renamedOldToNew('test.txt', 'test_v2.txt'));

      // Step 3: Move Selected replaces message immediately
      controller.toggleSelection(item);
      await controller.moveSelectedToFolder('ProjectA', l10nRu);
      expect(controller.operationMessage, l10nRu.movedNItems(1));

      controller.disposeController();
      controller.dispose();
    });
  });

  group('ADVERSARIAL: Operation Message Listeners and Notifications', () {
    test('createFolderAtPath notifies listeners and exposes operationMessage in Russian and English', () async {
      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/folders') return http.Response('{}', 200);
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      var notified = 0;
      controller.addListener(() {
        notified++;
      });

      // RU folder creation
      await controller.createFolderAtPath('', 'Новая Папка', l10nRu);
      expect(controller.operationMessage, l10nRu.folderCreated);
      expect(notified, greaterThanOrEqualTo(1));

      // EN folder creation
      await controller.createFolderAtPath('', 'New Folder', l10nEn);
      expect(controller.operationMessage, l10nEn.folderCreated);

      controller.disposeController();
      controller.dispose();
    });

    test('renameItem notifies listeners and exposes localized operationMessage', () async {
      final item = makeItem(name: 'report.docx', path: 'report.docx');
      final controller = await createMockController(
        handler: (req) async {
          if (req.url.path == '/api/files/move') return http.Response('{}', 200);
          return http.Response(jsonEncode({'entries': []}), 200);
        },
      );

      var notified = 0;
      controller.addListener(() {
        notified++;
      });

      await controller.renameItem(item, 'annual_report.docx', l10nEn);
      expect(
        controller.operationMessage,
        l10nEn.renamedOldToNew('report.docx', 'annual_report.docx'),
      );
      expect(notified, greaterThanOrEqualTo(1));

      controller.disposeController();
      controller.dispose();
    });
  });
}
