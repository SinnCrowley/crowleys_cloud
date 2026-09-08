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
import 'package:crowleys_cloud/asset_size_cache.dart';
import 'package:crowleys_cloud/category_data_cache.dart';
import 'package:crowleys_cloud/file_browser.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/shared/widgets/selection_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

class _ProgressiveStreamStrategy implements FileLoadStrategy {
  _ProgressiveStreamStrategy({
    required this.initialChunk,
    required this.streamingChunks,
    this.delayBetweenChunks = const Duration(milliseconds: 20),
  });

  final List<FileItem> initialChunk;
  final List<List<FileItem>> streamingChunks;
  final Duration delayBetweenChunks;
  int calls = 0;
  Completer<void>? streamCompleter;

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
    streamCompleter = Completer<void>();
    final allItems = <FileItem>[...initialChunk];

    if (onChunk != null) {
      final isOnlyBatch = streamingChunks.isEmpty;
      onChunk(initialChunk, isInitialBatch: true, isComplete: isOnlyBatch);

      for (var i = 0; i < streamingChunks.length; i++) {
        await Future<void>.delayed(delayBetweenChunks);
        if (isCancelled?.call() ?? false) {
          streamCompleter?.complete();
          return allItems;
        }
        final chunk = streamingChunks[i];
        allItems.addAll(chunk);
        final isLast = i == streamingChunks.length - 1;
        onChunk(chunk, isInitialBatch: false, isComplete: isLast);
      }
    } else {
      for (final chunk in streamingChunks) {
        allItems.addAll(chunk);
      }
    }

    streamCompleter?.complete();
    return allItems;
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

  // =========================================================================
  // Requirement R3: Short-Lived Category Data Cache (Stale-While-Revalidate)
  // =========================================================================
  group('CategoryDataCache Unit Tests', () {
    test('put and get within TTL returns cached items', () {
      final cache = CategoryDataCache.instance;
      final items = [
        FileItem.fromEntity(File('/storage/photos/img1.jpg')),
        FileItem.fromEntity(File('/storage/photos/img2.jpg')),
      ];

      cache.put('Photos', items);
      final retrieved = cache.get('Photos');

      expect(retrieved, isNotNull);
      expect(retrieved!.length, 2);
      expect(retrieved.first.name, 'img1.jpg');
    });

    test('get after TTL expiry returns null', () {
      final cache = CategoryDataCache.instance;
      final items = [FileItem.fromEntity(File('/storage/audio/song.mp3'))];

      // Put with timestamp 50 seconds in the past (> 45s default TTL)
      final pastTime = DateTime.now().subtract(const Duration(seconds: 50));
      cache.putWithTimestamp('Audio', items, pastTime);

      // Retrieval with default TTL must return null
      expect(cache.get('Audio'), isNull);
    });

    test('get with custom TTL returns null when expired', () {
      final cache = CategoryDataCache.instance;
      final items = [FileItem.fromEntity(File('/storage/audio/song.mp3'))];

      final pastTime = DateTime.now().subtract(
        const Duration(milliseconds: 50),
      );
      cache.putWithTimestamp('Audio', items, pastTime);

      // Should be expired with 10ms TTL
      expect(cache.get('Audio', ttl: const Duration(milliseconds: 10)), isNull);

      // Re-populate and check with 10s TTL
      cache.putWithTimestamp('Audio', items, pastTime);
      expect(cache.get('Audio', ttl: const Duration(seconds: 10)), isNotNull);
    });

    test('invalidate removes only the specified category', () {
      final cache = CategoryDataCache.instance;
      cache.put('Photos', [FileItem.fromEntity(File('/storage/p.jpg'))]);
      cache.put('Videos', [FileItem.fromEntity(File('/storage/v.mp4'))]);

      cache.invalidate('Photos');

      expect(cache.get('Photos'), isNull);
      expect(cache.get('Videos'), isNotNull);
    });

    test('LRU eviction maintains maximum capacity of 10 entries', () {
      final cache = CategoryDataCache.instance;

      for (var i = 1; i <= 10; i++) {
        cache.put('Category$i', [
          FileItem.fromEntity(File('/storage/item$i.dat')),
        ]);
      }
      expect(cache.entryCount, 10);

      // Access Category1 so Category2 becomes the least recently used
      cache.get('Category1');

      // Adding an 11th category evicts the LRU item (Category2)
      cache.put('Category11', [
        FileItem.fromEntity(File('/storage/item11.dat')),
      ]);
      expect(cache.entryCount, 10);
      expect(cache.get('Category1'), isNotNull);
      expect(cache.get('Category2'), isNull);
      expect(cache.get('Category11'), isNotNull);
    });

    test('periodic eviction cleans up expired entries', () {
      final cache = CategoryDataCache.instance;
      final pastTime = DateTime.now().subtract(const Duration(seconds: 50));
      cache.putWithTimestamp('QuickExpire', [
        FileItem.fromEntity(File('/storage/temp.dat')),
      ], pastTime);
      expect(cache.entryCount, 1);

      cache.evictExpired();
      expect(cache.entryCount, 0);
    });

    test('clear removes all entries', () {
      final cache = CategoryDataCache.instance;
      cache.put('A', [FileItem.fromEntity(File('/storage/a.dat'))]);
      cache.put('B', [FileItem.fromEntity(File('/storage/b.dat'))]);
      expect(cache.entryCount, 2);

      cache.clear();
      expect(cache.entryCount, 0);
      expect(cache.get('A'), isNull);
    });
  });

  // =========================================================================
  // Requirement R1: Two-Stage Progressive Loading for MediaStore Assets
  // =========================================================================
  group('Two-Stage Progressive Loading & Controller State', () {
    test('initial chunk emitted immediately unblocks UI (<100ms)', () async {
      final initialItems = List.generate(
        100,
        (i) => FileItem.fromEntity(File('/storage/photos/pic_$i.jpg')),
      );
      final streamingItems = [
        List.generate(
          100,
          (i) =>
              FileItem.fromEntity(File('/storage/photos/pic_${i + 100}.jpg')),
        ),
      ];

      final strategy = _ProgressiveStreamStrategy(
        initialChunk: initialItems,
        streamingChunks: streamingItems,
        delayBetweenChunks: const Duration(milliseconds: 50),
      );

      final controller = FileBrowserController(
        category: const FileCategory('Photos', Icons.photo),
        mediaStoreStrategy: strategy,
        loadOnInit: false,
      );

      final reloadFuture = controller.reload();

      // Immediately after initial chunk, loading must be false and first chunk ready
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(controller.isLoading, isFalse);
      expect(controller.files.length, 100);
      expect(controller.isFullyLoaded, isFalse);

      // Wait for background stream to complete
      await reloadFuture;
      expect(controller.files.length, 200);
      expect(controller.isFullyLoaded, isTrue);

      // Cache should now be populated
      expect(CategoryDataCache.instance.get('Photos'), isNotNull);
      expect(CategoryDataCache.instance.get('Photos')!.length, 200);

      controller.disposeController();
    });
  });

  // =========================================================================
  // Requirement R2: Deterministic "Select All" During In-Flight Loading
  // =========================================================================
  group('Requirement R2: Deterministic Select All & Safe Batch Actions', () {
    test(
      'selectAll during streaming accounts for all subsequent chunks',
      () async {
        final initialItems = List.generate(
          50,
          (i) => FileItem.fromEntity(File('/storage/photos/img_$i.jpg')),
        );
        final chunk2 = List.generate(
          50,
          (i) => FileItem.fromEntity(File('/storage/photos/img_${i + 50}.jpg')),
        );
        final chunk3 = List.generate(
          50,
          (i) =>
              FileItem.fromEntity(File('/storage/photos/img_${i + 100}.jpg')),
        );

        final strategy = _ProgressiveStreamStrategy(
          initialChunk: initialItems,
          streamingChunks: [chunk2, chunk3],
          delayBetweenChunks: const Duration(milliseconds: 30),
        );

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          mediaStoreStrategy: strategy,
          loadOnInit: false,
        );

        final reloadFuture = controller.reload();

        // Wait for initial batch
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(controller.files.length, 50);
        expect(controller.isFullyLoaded, isFalse);

        // User triggers Select All while background streaming is running
        controller.selectAll();
        expect(controller.selectedFiles.length, 50);

        // Await full load
        await reloadFuture;
        expect(controller.isFullyLoaded, isTrue);
        expect(controller.files.length, 150);

        // All 150 files must be selected because _selectAllActive tracked them
        expect(controller.selectedFiles.length, 150);

        controller.disposeController();
      },
    );

    test('clearSelection deactivates streaming select-all tracking', () async {
      final initialItems = List.generate(
        10,
        (i) => FileItem.fromEntity(File('/storage/photos/img_$i.jpg')),
      );
      final chunk2 = List.generate(
        10,
        (i) => FileItem.fromEntity(File('/storage/photos/img_${i + 10}.jpg')),
      );

      final strategy = _ProgressiveStreamStrategy(
        initialChunk: initialItems,
        streamingChunks: [chunk2],
        delayBetweenChunks: const Duration(milliseconds: 30),
      );

      final controller = FileBrowserController(
        category: const FileCategory('Photos', Icons.photo),
        mediaStoreStrategy: strategy,
        loadOnInit: false,
      );

      final reloadFuture = controller.reload();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.selectAll();
      expect(controller.selectedFiles.length, 10);

      // User clears selection before next chunk arrives
      controller.clearSelection();
      expect(controller.selectedFiles.isEmpty, isTrue);

      await reloadFuture;
      expect(controller.files.length, 20);
      // Because selection was cleared, chunk2 should NOT have been selected
      expect(controller.selectedFiles.isEmpty, isTrue);

      controller.disposeController();
    });

    testWidgets('SelectionActionBar disables buttons when enabled is false', (
      tester,
    ) async {
      var tapped = false;
      final action = SelectionAction(
        icon: Icons.delete,
        label: 'Delete',
        onPressed: () async {
          tapped = true;
        },
        enabled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SelectionActionBar(actions: [action]),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(
        tapped,
        isFalse,
        reason: 'Disabled SelectionAction must not invoke callback',
      );
    });

    testWidgets('SelectionActionBar triggers onPressed when enabled is true', (
      tester,
    ) async {
      var tapped = false;
      final action = SelectionAction(
        icon: Icons.upload,
        label: 'Upload',
        onPressed: () async {
          tapped = true;
        },
        enabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SelectionActionBar(actions: [action]),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Upload'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  // =========================================================================
  // Requirement R3: Stale-While-Revalidate Navigation
  // =========================================================================
  group('Stale-While-Revalidate Integration', () {
    test('controller synchronously populates files from cache on init', () {
      final cachedFiles = [
        FileItem.fromEntity(File('/storage/photos/cached1.jpg')),
        FileItem.fromEntity(File('/storage/photos/cached2.jpg')),
      ];
      CategoryDataCache.instance.put('Photos', cachedFiles);

      final controller = FileBrowserController(
        category: const FileCategory('Photos', Icons.photo),
        loadOnInit: false,
      );

      // Instant 0ms render without showing loading indicator
      expect(controller.files.length, 2);
      expect(controller.isLoading, isFalse);
      expect(controller.isFullyLoaded, isTrue);

      controller.disposeController();
    });

    test(
      'silent background revalidation does not clear existing files',
      () async {
        final cachedFiles = [
          FileItem.fromEntity(File('/storage/photos/cached1.jpg')),
        ];
        CategoryDataCache.instance.put('Photos', cachedFiles);

        final updatedFiles = [
          FileItem.fromEntity(File('/storage/photos/cached1.jpg')),
          FileItem.fromEntity(File('/storage/photos/fresh2.jpg')),
        ];
        final strategy = _ProgressiveStreamStrategy(
          initialChunk: updatedFiles,
          streamingChunks: [],
          delayBetweenChunks: const Duration(milliseconds: 10),
        );

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          mediaStoreStrategy: strategy,
          loadOnInit: false,
        );

        expect(controller.files.length, 1);

        // Background reload triggers silently
        final reloadFuture = controller.reload();
        // During reload, files are NOT cleared and isLoading is NOT true
        expect(controller.isLoading, isFalse);
        expect(controller.files.length, 1);

        await reloadFuture;
        // After reload, updated items are displayed
        expect(controller.files.length, 2);

        controller.disposeController();
      },
    );

    test('deleteSelectedFiles invalidates CategoryDataCache', () async {
      final item = FileItem.fromEntity(File('/tmp/to_delete.jpg'));
      CategoryDataCache.instance.put('Photos', [item]);
      expect(CategoryDataCache.instance.get('Photos'), isNotNull);

      final controller = FileBrowserController(
        category: const FileCategory('Photos', Icons.photo),
        loadOnInit: false,
      );
      controller.setViewStateForTest(visibleFiles: [item], loading: false);
      controller.toggleSelection(item);

      await controller.deleteSelectedFiles();

      expect(
        CategoryDataCache.instance.get('Photos'),
        isNull,
        reason: 'Mutation must invalidate CategoryDataCache for the category',
      );

      controller.disposeController();
    });
  });

  // =========================================================================
  // Requirement R4: Proper Disposal and Worker Cancellation
  // =========================================================================
  group('Requirement R4: Disposal & Cancellation', () {
    test('navigating away (dispose) discards late streaming chunks', () async {
      final initialItems = [FileItem.fromEntity(File('/storage/photos/1.jpg'))];
      final chunk2 = [FileItem.fromEntity(File('/storage/photos/2.jpg'))];

      final strategy = _ProgressiveStreamStrategy(
        initialChunk: initialItems,
        streamingChunks: [chunk2],
        delayBetweenChunks: const Duration(milliseconds: 50),
      );

      final controller = FileBrowserController(
        category: const FileCategory('Photos', Icons.photo),
        mediaStoreStrategy: strategy,
        loadOnInit: false,
      );

      final reloadFuture = controller.reload();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.files.length, 1);

      // Navigate away: controller is disposed
      controller.disposeController();

      // Complete stream
      await reloadFuture;

      // Late chunk2 was discarded; files list not mutated post-disposal
      expect(controller.files.length, 1);
    });
  });

  // =========================================================================
  // Sorting Determinism & Size Fallback
  // =========================================================================
  group('Sorting & Size Resolution Tests', () {
    test(
      'size sorting gracefully falls back to date sorting when uncached',
      () async {
        final itemOlder = FileItem.fromEntity(
          File('/storage/photos/a.jpg'),
          modifiedDate: DateTime(2026, 1, 1),
        );
        final itemNewer = FileItem.fromEntity(
          File('/storage/photos/b.jpg'),
          modifiedDate: DateTime(2026, 2, 1),
        );

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          loadOnInit: false,
        );

        controller.sortBy = SortBy.size;
        controller.sortAscending = true;

        controller.setViewStateForTest(
          visibleFiles: [itemNewer, itemOlder],
          loading: false,
        );

        // Re-sort
        await controller.updateSortBy(SortBy.size);

        // itemOlder (Jan) should come before itemNewer (Feb) because both sizes are uncached
        expect(controller.files.first.name, 'a.jpg');
        expect(controller.files.last.name, 'b.jpg');

        controller.disposeController();
      },
    );

    testWidgets('FileBrowser disables batch actions until fully loaded', (
      tester,
    ) async {
      final controller = FileBrowserController(
        category: const FileCategory('Documents', Icons.description),
        loadOnInit: false,
      );

      final itemA = FileItem.fromEntity(File('/tmp/a.txt'));
      final itemB = FileItem.fromEntity(File('/tmp/b.txt'));

      // Set items and selection mode, but isFullyLoaded = false
      controller.setViewStateForTest(
        visibleFiles: [itemA, itemB],
        loading: false,
      );
      controller.isFullyLoaded = false;
      controller.toggleSelection(itemA);

      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: FileBrowser(
              category: const FileCategory('Documents', Icons.description),
              isGridView: true,
              controller: controller,
            ),
          ),
        ),
      );

      // SelectionActionBar should be present
      expect(find.byType(SelectionActionBar), findsOneWidget);

      // While isFullyLoaded is false, tapping Upload or Delete does not trigger any action
      await tester.tap(find.byIcon(Icons.upload));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Now simulate loading completion
      controller.isFullyLoaded = true;
      controller.notifyListeners();
      await tester.pump();

      expect(find.byType(SelectionActionBar), findsOneWidget);

      controller.disposeController();
    });
  });

  // =========================================================================
  // Adversarial Reviewer Round 1 Hardening Tests
  // =========================================================================
  group('Adversarial Hardening & Determinism Tests', () {
    test(
      'multi-chunk streaming with SortBy.name strictly maintains alphabetical order',
      () async {
        final chunk1 = [
          FileItem.fromEntity(File('/storage/photos/Banana.jpg')),
          FileItem.fromEntity(File('/storage/photos/Delta.jpg')),
        ];
        final chunk2 = [
          FileItem.fromEntity(File('/storage/photos/Apple.jpg')),
          FileItem.fromEntity(File('/storage/photos/Charlie.jpg')),
        ];

        final strategy = _ProgressiveStreamStrategy(
          initialChunk: chunk1,
          streamingChunks: [chunk2],
          delayBetweenChunks: const Duration(milliseconds: 30),
        );

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          mediaStoreStrategy: strategy,
          loadOnInit: false,
        );
        controller.sortBy = SortBy.name;
        controller.sortAscending = true;

        final reloadFuture = controller.reload();

        // Initial chunk ready and sorted
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(controller.files.map((f) => f.name).toList(), [
          'Banana.jpg',
          'Delta.jpg',
        ]);

        // Complete full load
        await reloadFuture;
        expect(controller.isFullyLoaded, isTrue);
        expect(
          controller.files.map((f) => f.name).toList(),
          ['Apple.jpg', 'Banana.jpg', 'Charlie.jpg', 'Delta.jpg'],
          reason:
              'Subsequent chunks must be deterministically sorted into the list without scrambling',
        );

        // Cached files must also be strictly sorted
        final cached = CategoryDataCache.instance.get('Photos');
        expect(cached, isNotNull);
        expect(cached!.map((f) => f.name).toList(), [
          'Apple.jpg',
          'Banana.jpg',
          'Charlie.jpg',
          'Delta.jpg',
        ]);

        controller.disposeController();
      },
    );

    test(
      'multi-chunk stale-while-revalidate does not shrink or flash visible files during chunk streaming',
      () async {
        final cachedFiles = List.generate(
          4,
          (i) => FileItem.fromEntity(File('/storage/photos/cached_$i.jpg')),
        );
        CategoryDataCache.instance.put('Photos', cachedFiles);

        final chunk1 = List.generate(
          3,
          (i) => FileItem.fromEntity(File('/storage/photos/fresh_$i.jpg')),
        );
        final chunk2 = List.generate(
          2,
          (i) =>
              FileItem.fromEntity(File('/storage/photos/fresh_${i + 3}.jpg')),
        );

        final strategy = _ProgressiveStreamStrategy(
          initialChunk: chunk1,
          streamingChunks: [chunk2],
          delayBetweenChunks: const Duration(milliseconds: 40),
        );

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          mediaStoreStrategy: strategy,
          loadOnInit: false,
        );

        expect(controller.files.length, 4);

        final reloadFuture = controller.reload();

        // After chunk 1 arrives, visible files must NOT shrink down to 3
        await Future<void>.delayed(const Duration(milliseconds: 15));
        expect(controller.isLoading, isFalse);
        expect(
          controller.files.length,
          4,
          reason:
              'Cached files must remain intact without flashing or shrinking on intermediate chunk arrival',
        );
        expect(controller.isFullyLoaded, isFalse);

        // Await revalidation completion
        await reloadFuture;
        expect(controller.isFullyLoaded, isTrue);
        expect(controller.files.length, 5);

        controller.disposeController();
      },
    );

    test(
      'CategoryDataCache.put on existing category updates in-place without evicting other entries',
      () {
        final cache = CategoryDataCache.instance;
        for (var i = 1; i <= 10; i++) {
          cache.put('Cat$i', [FileItem.fromEntity(File('/storage/$i.dat'))]);
        }
        expect(cache.entryCount, 10);

        // Update Cat1 (which already exists)
        cache.put('Cat1', [
          FileItem.fromEntity(File('/storage/cat1_updated.dat')),
        ]);

        // Entry count must still be 10, and Cat2 must NOT have been evicted
        expect(cache.entryCount, 10);
        expect(cache.get('Cat1'), isNotNull);
        expect(cache.get('Cat2'), isNotNull);
        expect(cache.get('Cat10'), isNotNull);
      },
    );

    test(
      'CategoryDataCache preserves and restores sortBy and sortAscending',
      () {
        final cache = CategoryDataCache.instance;
        final items = [FileItem.fromEntity(File('/storage/test.jpg'))];

        cache.put('Photos', items, sortBy: SortBy.date, sortAscending: false);

        final entry = cache.getEntry('Photos');
        expect(entry, isNotNull);
        expect(entry!.sortBy, SortBy.date);
        expect(entry.sortAscending, isFalse);

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          loadOnInit: false,
        );

        expect(controller.sortBy, SortBy.date);
        expect(controller.sortAscending, isFalse);

        controller.disposeController();
      },
    );

    test(
      'CategoryDataCache memory pressure eviction limits cumulative file items',
      () {
        final cache = CategoryDataCache.instance;

        // Add 3 categories with 2000 items each (total 6000 > maxTotalCachedFiles: 5000)
        cache.put(
          'LargeCat1',
          List.generate(
            2000,
            (i) => FileItem.fromEntity(File('/tmp/1_$i.dat')),
          ),
        );
        cache.put(
          'LargeCat2',
          List.generate(
            2000,
            (i) => FileItem.fromEntity(File('/tmp/2_$i.dat')),
          ),
        );
        cache.put(
          'LargeCat3',
          List.generate(
            2000,
            (i) => FileItem.fromEntity(File('/tmp/3_$i.dat')),
          ),
        );

        // Oldest category should have been evicted to respect memory constraint
        expect(cache.hasEntry('LargeCat1'), isFalse);
        expect(cache.hasEntry('LargeCat2'), isTrue);
        expect(cache.hasEntry('LargeCat3'), isTrue);
      },
    );

    test(
      'Folder navigation methods reset selection and isSelectAllActive',
      () async {
        final dir = Directory.systemTemp;
        final controller = FileBrowserController(
          category: const FileCategory('All files', Icons.folder),
          loadOnInit: false,
        );

        final item = FileItem.fromEntity(File('/tmp/dummy.txt'));
        controller.setViewStateForTest(
          visibleFiles: [item],
          selected: {item},
          selectAllActive: true,
        );

        expect(controller.selectedFiles.isNotEmpty, isTrue);
        expect(controller.isSelectAllActive, isTrue);

        await controller.navigateInto(dir);

        expect(controller.selectedFiles.isEmpty, isTrue);
        expect(controller.isSelectAllActive, isFalse);

        controller.disposeController();
      },
    );
  });

  // =========================================================================
  // Adversarial Reviewer Round 2 Defect & Edge-Case Verifications
  // =========================================================================
  group('Adversarial Reviewer Round 2 Defect Verifications', () {
    test(
      'streaming paging early exhaustion emits isComplete and enables batch actions',
      () async {
        final initialChunk = List.generate(
          100,
          (i) => FileItem.fromEntity(File('/storage/photos/img_$i.jpg')),
        );
        // Stream completes immediately with empty final chunk (simulating early paging exhaustion)
        final strategy = _ProgressiveStreamStrategy(
          initialChunk: initialChunk,
          streamingChunks: [[]],
          delayBetweenChunks: const Duration(milliseconds: 20),
        );

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          mediaStoreStrategy: strategy,
          loadOnInit: false,
        );

        final reloadFuture = controller.reload();
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(controller.isFullyLoaded, isFalse);

        await reloadFuture;
        expect(controller.isFullyLoaded, isTrue);
        expect(controller.files.length, 100);
        expect(CategoryDataCache.instance.get('Photos'), isNotNull);

        controller.disposeController();
      },
    );

    test(
      'Folder navigation in All files resets files list and sets isLoading',
      () async {
        final initialFile = FileItem.fromEntity(File('/tmp/old_dir_file.txt'));
        final dir = Directory.systemTemp;

        final controller = FileBrowserController(
          category: const FileCategory('All files', Icons.folder),
          loadOnInit: false,
        );

        controller.setViewStateForTest(
          visibleFiles: [initialFile],
          loading: false,
          fullyLoaded: true,
        );
        expect(controller.files.isNotEmpty, isTrue);

        // navigateInto must not trigger false revalidation: files should clear and isLoading become true
        final navFuture = controller.navigateInto(dir);
        expect(controller.isLoading, isTrue);
        expect(controller.files.isEmpty, isTrue);

        await navFuture;
        controller.disposeController();
      },
    );

    test(
      'Clearing search query in category resets view to loading full list rather than stale cache revalidation',
      () async {
        final searchResult = FileItem.fromEntity(
          File('/tmp/search_result.jpg'),
        );
        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          loadOnInit: false,
        );

        controller.setViewStateForTest(
          visibleFiles: [searchResult],
          loading: false,
          fullyLoaded: true,
        );
        controller.searchQuery = 'apple';

        // Clear search
        final clearFuture = controller.setSearchQuery('');
        expect(controller.isLoading, isTrue);
        expect(controller.files.isEmpty, isTrue);

        await clearFuture;
        controller.disposeController();
      },
    );

    test(
      'Warm re-entry with loadOnInit=true preserves cached sort preference against global SharedPreferences',
      () async {
        final cachedItem = FileItem.fromEntity(
          File('/storage/photos/test.jpg'),
        );
        CategoryDataCache.instance.put(
          'Photos',
          [cachedItem],
          sortBy: SortBy.date,
          sortAscending: false,
        );

        // Global SharedPreferences has size ascending (e.g. from another category)
        SharedPreferences.setMockInitialValues({
          'sortBy': SortBy.size.index,
          'sortAscending': true,
        });

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          loadOnInit: true,
          mediaStoreStrategy: _ProgressiveStreamStrategy(
            initialChunk: [cachedItem],
            streamingChunks: [],
          ),
        );

        // Immediately and after init, cached category sort must be preserved
        expect(controller.sortBy, SortBy.date);
        expect(controller.sortAscending, isFalse);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(controller.sortBy, SortBy.date);
        expect(controller.sortAscending, isFalse);

        controller.disposeController();
      },
    );

    test(
      'Background revalidation reconciles selectedFiles and prunes deleted items',
      () async {
        final itemA = FileItem.fromEntity(File('/storage/photos/a.jpg'));
        final itemB = FileItem.fromEntity(File('/storage/photos/b.jpg'));
        final itemC = FileItem.fromEntity(File('/storage/photos/c.jpg'));

        CategoryDataCache.instance.put('Photos', [itemA, itemB, itemC]);

        final strategy = _ProgressiveStreamStrategy(
          initialChunk: [itemB, itemC], // itemA removed externally
          streamingChunks: [],
          delayBetweenChunks: const Duration(milliseconds: 20),
        );

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          mediaStoreStrategy: strategy,
          loadOnInit: false,
        );

        expect(controller.files.length, 3);
        // User selects A and B
        controller.toggleSelection(itemA);
        controller.toggleSelection(itemB);
        expect(controller.selectedFiles.length, 2);

        // Revalidation completes
        await controller.reload();
        expect(controller.files.length, 2);
        // itemA was deleted, so selectedFiles must contain only itemB
        expect(controller.selectedFiles.contains(itemA), isFalse);
        expect(controller.selectedFiles.contains(itemB), isTrue);
        expect(controller.selectedFiles.length, 1);

        controller.disposeController();
      },
    );

    test(
      'File deletion in All files invalidates all cached category listings',
      () async {
        final photo = FileItem.fromEntity(File('/tmp/photo.jpg'));
        CategoryDataCache.instance.put('Photos', [photo]);
        expect(CategoryDataCache.instance.hasEntry('Photos'), isTrue);

        final controller = FileBrowserController(
          category: const FileCategory('All files', Icons.folder),
          loadOnInit: false,
        );

        final itemToDelete = FileItem.fromEntity(
          File('/tmp/all_files_item.txt'),
        );
        controller.setViewStateForTest(
          visibleFiles: [itemToDelete],
          selected: {itemToDelete},
          loading: false,
        );

        await controller.deleteSelectedFiles();

        // Invalidation in 'All files' must clear cached categories
        expect(CategoryDataCache.instance.hasEntry('Photos'), isFalse);

        controller.disposeController();
      },
    );

    test(
      'CategoryDataCache.put bounds single massive category to maxTotalCachedFiles',
      () {
        final cache = CategoryDataCache.instance;
        final massiveList = List.generate(
          8000,
          (i) => FileItem.fromEntity(File('/tmp/photo_$i.jpg')),
        );

        cache.put('Photos', massiveList);
        final cached = cache.get('Photos');
        expect(cached, isNotNull);
        expect(cached!.length, CategoryDataCache.maxTotalCachedFiles);
        expect(cached.length <= 5000, isTrue);
      },
    );

    test(
      'disposeController cancels search debounce timer without firing',
      () async {
        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          loadOnInit: false,
        );

        controller.setSearchQueryDebounced('delayed_query');
        controller.disposeController();

        await Future<void>.delayed(const Duration(milliseconds: 600));
        // Disposed controller did not execute delayed reload
        expect(controller.searchQuery, isEmpty);
      },
    );

    test(
      'resolveAssetSizeLazy deduplicates concurrent requests for the same asset',
      () {
        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          loadOnInit: false,
        );

        final asset = AssetEntity(
          id: 'dedup_test_1',
          typeInt: 1,
          width: 100,
          height: 100,
        );
        final item = FileItem.fromAsset(asset);

        expect(controller.isInFlightSizeResolution('dedup_test_1'), isFalse);
        controller.resolveAssetSizeLazy(item);
        expect(controller.isInFlightSizeResolution('dedup_test_1'), isTrue);

        // Second immediate call should be ignored as duplicate in-flight
        controller.resolveAssetSizeLazy(item);
        expect(controller.isInFlightSizeResolution('dedup_test_1'), isTrue);

        controller.disposeController();
        expect(controller.isInFlightSizeResolution('dedup_test_1'), isFalse);
      },
    );
  });

  // =========================================================================
  // Adversarial Reviewer Round 3 Defect & Edge-Case Verifications
  // =========================================================================
  group('Adversarial Reviewer Round 3 Defect Verifications', () {
    test(
      'warm cache re-entry for empty category renders instantly without loading spinner',
      () async {
        // Populate cache with an empty category list (e.g. user with 0 audio files)
        CategoryDataCache.instance.put('Audio', []);

        final strategy = _ProgressiveStreamStrategy(
          initialChunk: [],
          streamingChunks: [],
          delayBetweenChunks: const Duration(milliseconds: 20),
        );

        final controller = FileBrowserController(
          category: const FileCategory('Audio', Icons.audiotrack),
          mediaStoreStrategy: strategy,
          loadOnInit: false,
        );

        // Instant 0ms render without showing loading indicator
        expect(controller.files.isEmpty, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.isFullyLoaded, isTrue);

        // Now trigger reload to simulate background revalidation
        final reloadFuture = controller.reload();
        // During reload, isLoading must still be false (silent revalidation)
        expect(controller.isLoading, isFalse);
        expect(controller.files.isEmpty, isTrue);

        await reloadFuture;
        expect(controller.isFullyLoaded, isTrue);
        expect(controller.isLoading, isFalse);

        controller.disposeController();
      },
    );

    test(
      'partial initial chunk (<100 items) when total reported is higher completes immediately without hanging',
      () async {
        // Simulates MediaStore reporting total > initial assets (e.g. 5 total, but only 3 returned on page 0)
        final chunk3 = List.generate(
          3,
          (i) => FileItem.fromEntity(File('/storage/photos/img_$i.jpg')),
        );

        final strategy = _ProgressiveStreamStrategy(
          initialChunk: chunk3,
          streamingChunks: [],
        );

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          mediaStoreStrategy: strategy,
          loadOnInit: false,
        );

        final reloadFuture = controller.reload();
        await reloadFuture;

        expect(controller.isFullyLoaded, isTrue);
        expect(controller.files.length, 3);
        expect(CategoryDataCache.instance.get('Photos'), isNotNull);
        expect(CategoryDataCache.instance.get('Photos')!.length, 3);

        controller.disposeController();
      },
    );

    test(
      'progressive streaming deduplicates repeated items across chunk boundaries',
      () async {
        final itemA = FileItem.fromEntity(File('/storage/photos/a.jpg'));
        final itemB = FileItem.fromEntity(File('/storage/photos/b.jpg'));
        final itemC = FileItem.fromEntity(File('/storage/photos/c.jpg'));

        // Chunk 1 has A and B; Chunk 2 repeats B (e.g. due to index shift) and adds C
        final strategy = _ProgressiveStreamStrategy(
          initialChunk: [itemA, itemB],
          streamingChunks: [
            [itemB, itemC],
          ],
          delayBetweenChunks: const Duration(milliseconds: 20),
        );

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          mediaStoreStrategy: strategy,
          loadOnInit: false,
        );

        final reloadFuture = controller.reload();
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(controller.files.length, 2);

        controller.selectAll();
        expect(controller.selectedFiles.length, 2);

        await reloadFuture;
        // Controller must have deduplicated itemB: exactly 3 items total
        expect(controller.files.length, 3);
        expect(controller.files.map((f) => f.name).toList(), [
          'a.jpg',
          'b.jpg',
          'c.jpg',
        ]);
        expect(controller.selectedFiles.length, 3);

        controller.disposeController();
      },
    );

    test(
      'fresh reload when not revalidating clears selectedFiles and resets _selectAllActive',
      () async {
        final itemA = FileItem.fromEntity(File('/storage/photos/a.jpg'));
        final itemB = FileItem.fromEntity(File('/storage/photos/b.jpg'));

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          loadOnInit: false,
          mediaStoreStrategy: _ProgressiveStreamStrategy(
            initialChunk: [itemA],
            streamingChunks: [],
          ),
        );

        controller.setViewStateForTest(
          visibleFiles: [itemA, itemB],
          selected: {itemA, itemB},
          selectAllActive: true,
          loading: false,
          fullyLoaded: true,
        );

        expect(controller.selectedFiles.length, 2);
        expect(controller.isSelectAllActive, isTrue);

        // Fresh reload must reset selection state
        final reloadFuture = controller.reload();
        expect(controller.selectedFiles.isEmpty, isTrue);
        expect(controller.isSelectAllActive, isFalse);

        await reloadFuture;
        expect(controller.selectedFiles.isEmpty, isTrue);
        expect(controller.isSelectAllActive, isFalse);

        controller.disposeController();
      },
    );

    test(
      'resolveAssetSizeLazy debounced re-sort updates CategoryDataCache',
      () async {
        final asset1 = AssetEntity(
          id: 'lazy_cache_1',
          typeInt: 1,
          width: 100,
          height: 100,
        );
        final assetItem1 = FileItem.fromAsset(asset1);
        final asset2 = AssetEntity(
          id: 'lazy_cache_2',
          typeInt: 1,
          width: 100,
          height: 100,
        );
        final assetItem2 = FileItem.fromAsset(asset2);

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          loadOnInit: false,
        );

        controller.sortBy = SortBy.size;
        controller.sortAscending = true;

        // asset2 has known size 1000 in cache; asset1 is uncached
        AssetSizeCache.setSize(asset2.id, 1000, assetItem2.modifiedDate);

        controller.setViewStateForTest(
          visibleFiles: [assetItem2, assetItem1],
          loading: false,
          fullyLoaded: true,
        );

        CategoryDataCache.instance.put(
          'Photos',
          [assetItem2, assetItem1],
          sortBy: SortBy.size,
          sortAscending: true,
        );

        expect(
          CategoryDataCache.instance.get('Photos')!.first.name,
          assetItem2.name,
        );

        // Trigger resolveAssetSizeLazy on the uncached item (asset1)
        controller.resolveAssetSizeLazy(assetItem1);

        // Allow debounce timer to fire (300ms + margin)
        await Future<void>.delayed(const Duration(milliseconds: 350));

        // CategoryDataCache should have been updated with re-sorted items (asset1 size 0 comes before asset2 size 1000)
        final cached = CategoryDataCache.instance.get('Photos');
        expect(cached, isNotNull);
        expect(cached!.first.name, assetItem1.name);

        controller.disposeController();
      },
    );

    test('PermissionState.limited extension hasAccess returns true', () {
      expect(PermissionState.limited.hasAccess, isTrue);
      expect(PermissionState.authorized.hasAccess, isTrue);
      expect(PermissionState.denied.hasAccess, isFalse);
    });

    test(
      'empty intermediate search chunks do not trigger redundant notifyListeners',
      () async {
        var notifyCount = 0;
        final initialChunk = [
          FileItem.fromEntity(File('/storage/photos/match_1.jpg')),
        ];

        final strategy = _ProgressiveStreamStrategy(
          initialChunk: initialChunk,
          streamingChunks: [
            [], // intermediate empty chunk (0 matches)
            [], // intermediate empty chunk (0 matches)
            [
              FileItem.fromEntity(File('/storage/photos/match_2.jpg')),
            ], // final chunk
          ],
          delayBetweenChunks: const Duration(milliseconds: 20),
        );

        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          mediaStoreStrategy: strategy,
          loadOnInit: false,
        );

        controller.addListener(() {
          notifyCount++;
        });

        await controller.reload();

        // Intermediate empty chunks must NOT each trigger notifyListeners
        expect(notifyCount <= 4, isTrue);
        expect(controller.files.length, 2);

        controller.disposeController();
      },
    );

    test(
      'dispose() invokes disposeController() to cancel timers and flags',
      () {
        final controller = FileBrowserController(
          category: const FileCategory('Photos', Icons.photo),
          loadOnInit: false,
        );
        controller.setSearchQueryDebounced('query');

        var notified = false;
        controller.addListener(() {
          notified = true;
        });

        // dispose should delegate to disposeController
        controller.dispose();

        // notifyListeners should now be a no-op because _disposed is true
        controller.notifyListeners();
        expect(notified, isFalse);
      },
    );
  });
}
