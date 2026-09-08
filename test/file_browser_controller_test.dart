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
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStrategy implements FileLoadStrategy {
  _FakeStrategy(this.returnItems);

  final List<FileItem> returnItems;
  int calls = 0;

  @override
  Future<List<FileItem>> load({
    required String categoryName,
    required String searchQuery,
    Directory? baseDirectory,
    required String? tempPath,
    required bool showHiddenFiles,
    SortBy? sortBy,
    bool? sortAscending,
    void Function(
      List<FileItem> chunk, {
      required bool isInitialBatch,
      required bool isComplete,
    })?
    onChunk,
    bool Function()? isCancelled,
  }) async {
    calls++;
    return returnItems;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileBrowserController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('search debounce triggers one reload with latest value', () async {
      final fake = _FakeStrategy([]);
      final controller = FileBrowserController(
        category: const FileCategory('Documents', Icons.description),
        fileWalkStrategy: fake,
        loadOnInit: false,
      );

      controller.setSearchQueryDebounced(
        'one',
        delay: const Duration(milliseconds: 10),
      );
      controller.setSearchQueryDebounced(
        'two',
        delay: const Duration(milliseconds: 10),
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(controller.searchQuery, 'two');
      expect(fake.calls, 1);
    });

    test('selection add/remove/select-all/clear works', () {
      final a = FileItem.fromEntity(File('/tmp/a.txt'));
      final b = FileItem.fromEntity(File('/tmp/b.txt'));
      final controller = FileBrowserController(
        category: const FileCategory('Documents', Icons.description),
        loadOnInit: false,
      );

      controller.setViewStateForTest(visibleFiles: [a, b], loading: false);
      controller.toggleSelection(a);
      expect(controller.selectedFiles.contains(a), true);

      controller.toggleSelection(a);
      expect(controller.selectedFiles.contains(a), false);

      controller.selectAll();
      expect(controller.selectedFiles.length, 2);

      controller.clearSelection();
      expect(controller.selectedFiles, isEmpty);
    });

    test('selection survives file list refresh with recreated items', () {
      final controller = FileBrowserController(
        category: const FileCategory('Documents', Icons.description),
        loadOnInit: false,
      );
      final first = FileItem.fromEntity(File('/tmp/a.txt'));
      final refreshed = FileItem.fromEntity(File('/tmp/a.txt'));

      controller.setViewStateForTest(visibleFiles: [first], loading: false);
      controller.toggleSelection(first);

      controller.setViewStateForTest(visibleFiles: [refreshed], loading: false);

      expect(controller.selectedFiles, contains(refreshed));
      expect(controller.selectedFiles.length, 1);
    });

    test('all files back navigation rule follows directory stack', () async {
      final fake = _FakeStrategy([]);
      final controller = FileBrowserController(
        category: const FileCategory('All files', Icons.folder),
        directoryStrategy: fake,
        loadOnInit: false,
      );
      controller.directoryHistory.addAll([Directory('/'), Directory('/tmp')]);

      expect(controller.canNavigateBack, true);
      await controller.navigateBack();
      expect(controller.directoryHistory.length, 1);
      expect(controller.canNavigateBack, false);
    });

    test('strategy selection by category', () {
      final media = _FakeStrategy([]);
      final walk = _FakeStrategy([]);
      final dir = _FakeStrategy([]);

      final photos = FileBrowserController(
        category: const FileCategory('Photos', Icons.photo),
        mediaStoreStrategy: media,
        fileWalkStrategy: walk,
        directoryStrategy: dir,
        loadOnInit: false,
      );
      final documents = FileBrowserController(
        category: const FileCategory('Documents', Icons.description),
        mediaStoreStrategy: media,
        fileWalkStrategy: walk,
        directoryStrategy: dir,
        loadOnInit: false,
      );
      final allFiles = FileBrowserController(
        category: const FileCategory('All files', Icons.folder),
        mediaStoreStrategy: media,
        fileWalkStrategy: walk,
        directoryStrategy: dir,
        loadOnInit: false,
      );

      expect(photos.strategyTypeForTest(), '_FakeStrategy');
      expect(documents.strategyTypeForTest(), '_FakeStrategy');
      expect(allFiles.strategyTypeForTest(), '_FakeStrategy');
    });

    test('hidden paths are excluded only when setting is disabled', () {
      expect(
        isPathExcluded(
          '/storage/emulated/0/.hidden/file.txt',
          null,
          const {},
          showHiddenFiles: false,
        ),
        true,
      );
      expect(
        isPathExcluded(
          '/storage/emulated/0/.hidden/file.txt',
          null,
          const {},
          showHiddenFiles: true,
        ),
        false,
      );
    });

    test(
      'FileItem.fromEntity returns pre-fetched size and modifiedDate non-blocking',
      () {
        final now = DateTime.now();
        final item = FileItem.fromEntity(
          File('/virtual/nonexistent/test.txt'),
          size: 12345,
          modifiedDate: now,
        );

        expect(item.size, 12345);
        expect(item.modifiedDate, now);
        expect(item.isDirectory, false);
        expect(item.name, 'test.txt');
      },
    );

    test(
      'FileItem.fromEntity fallback defaults when size and date are omitted',
      () {
        final item = FileItem.fromEntity(
          File('/virtual/nonexistent/fallback.txt'),
        );

        expect(item.size, 0);
        expect(item.modifiedDate, DateTime(0));
        expect(item.name, 'fallback.txt');
      },
    );

    test(
      'DirectoryLoadStrategy pre-queries stat asynchronously during load',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'dir_strategy_test',
        );
        try {
          final fileA = File('${tempDir.path}/test_a.txt');
          await fileA.writeAsString('hello world test a');

          final fileB = File('${tempDir.path}/test_b.txt');
          await fileB.writeAsString('longer test string content b');

          final strategy = DirectoryLoadStrategy();
          final items = await strategy.load(
            categoryName: 'All files',
            searchQuery: '',
            baseDirectory: tempDir,
            tempPath: null,
            showHiddenFiles: true,
          );

          expect(items.length, 2);
          final itemA = items.firstWhere((i) => i.name == 'test_a.txt');
          final itemB = items.firstWhere((i) => i.name == 'test_b.txt');

          expect(itemA.size, (await fileA.stat()).size);
          expect(itemA.modifiedDate, (await fileA.stat()).modified);
          expect(itemB.size, (await fileB.stat()).size);
          expect(itemB.modifiedDate, (await fileB.stat()).modified);
        } finally {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );
  });
}
