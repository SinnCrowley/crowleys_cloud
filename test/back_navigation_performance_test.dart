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

import 'dart:async';
import 'dart:io';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/category_data_cache.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TrackingStrategy implements FileLoadStrategy {
  int reloadCount = 0;
  Completer<void>? reloadCompleter;

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
    reloadCount++;
    if (reloadCompleter != null) {
      await reloadCompleter!.future;
    }
    return [FileItem.fromEntity(File('/storage/photos/test.jpg'))];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CategoryDataCache.instance.clear();
  });

  tearDown(() {
    CategoryDataCache.instance.clear();
  });

  group('Back Navigation Performance & Fast Category Exit', () {
    test(
      'Navigating back does not trigger redundant setSearchQuery reload on closing controller',
      () async {
        final trackingStrategy = _TrackingStrategy();
        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          mediaStoreStrategy: trackingStrategy,
          loadOnInit: false,
        );

        await controller.reload();
        expect(trackingStrategy.reloadCount, 1);

        // Simulate search text active
        controller.searchQuery = 'vacation';

        // When navigating back: controller is detached first, search text is cleared,
        // and controllerToDispose is disposed directly without awaiting a setSearchQuery('') reload.
        final controllerToDispose = controller;
        controllerToDispose.disposeController();
        controllerToDispose.dispose();

        // reloadCount must remain 1 - no additional reload was awaited or fired on the exiting controller
        expect(trackingStrategy.reloadCount, 1);
      },
    );

    test(
      'Slow in-flight reload is cleanly cancelled immediately upon disposal',
      () async {
        final trackingStrategy = _TrackingStrategy();
        final slowCompleter = Completer<void>();
        trackingStrategy.reloadCompleter = slowCompleter;

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          mediaStoreStrategy: trackingStrategy,
          loadOnInit: false,
        );

        // Start reload which hangs on slowCompleter
        final reloadFuture = controller.reload();
        expect(controller.isLoading, isTrue);

        // User hits Back immediately
        controller.disposeController();
        controller.dispose();

        // Let the slow background query complete afterwards
        slowCompleter.complete();
        await reloadFuture;

        // Disposed controller must have cancelled notifications and ignored result
        expect(controller.isDisposed, isTrue);
      },
    );

    test(
      'Subfolder back navigation clears searchQuery without double reload',
      () async {
        final trackingStrategy = _TrackingStrategy();
        final controller = FileBrowserController(
          category: const FileCategory('All files', Icons.folder),
          directoryStrategy: trackingStrategy,
          loadOnInit: false,
        );

        final dir1 = Directory('/storage/root');
        final dir2 = Directory('/storage/root/sub');
        controller.directoryHistory.addAll([dir1, dir2]);
        expect(controller.canNavigateBack, isTrue);

        await controller.reload();
        expect(trackingStrategy.reloadCount, 1);

        // Active search in subfolder
        controller.searchQuery = 'doc';

        // When navigating back from subfolder: clear searchQuery property without calling setSearchQuery(''),
        // then navigateBack() executes exactly once
        controller.searchQuery = '';
        await controller.navigateBack();

        // Exactly 1 additional reload for the parent directory, not 2
        expect(trackingStrategy.reloadCount, 2);
        expect(controller.directoryHistory.length, 1);
        expect(controller.searchQuery, isEmpty);

        controller.dispose();
      },
    );
  });
}
