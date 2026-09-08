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
import 'dart:math' as math;

import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/asset_size_cache.dart';
import 'package:crowleys_cloud/category_data_cache.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// File sorting criteria (name, modified date, file size, or file extension type).
enum SortBy { name, date, size, type }

/// Strategy interface for loading file items based on category (MediaStore vs FileWalk vs Directory).
abstract class FileLoadStrategy {
  /// Asynchronously loads file items matching category, search query, and hidden file criteria.
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
  });
}

/// Strategy loading media assets (photos, videos, audio) using system [PhotoManager] APIs.
class MediaStoreLoadStrategy implements FileLoadStrategy {
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
    PermissionState perm;
    try {
      perm = await PhotoManager.requestPermissionExtend();
    } catch (_) {
      onChunk?.call([], isInitialBatch: true, isComplete: true);
      return [];
    }
    if (isCancelled?.call() ?? false) return [];
    if (!perm.hasAccess) {
      onChunk?.call([], isInitialBatch: true, isComplete: true);
      return [];
    }

    final type = switch (categoryName) {
      'Photos' => RequestType.image,
      'Videos' => RequestType.video,
      'Audio' => RequestType.audio,
      _ => RequestType.common,
    };

    final effectiveSortAscending = sortAscending ?? true;
    final orderOption = OrderOption(
      type: OrderOptionType.createDate,
      asc: effectiveSortAscending,
    );

    final filterOption = FilterOptionGroup(
      imageOption: const FilterOption(needTitle: true),
      videoOption: const FilterOption(needTitle: true),
      audioOption: const FilterOption(needTitle: true),
      orders: [orderOption],
    );

    List<AssetPathEntity> albums;
    try {
      albums = await PhotoManager.getAssetPathList(
        type: type,
        hasAll: true,
        onlyAll: false,
        filterOption: filterOption,
      );
    } catch (_) {
      onChunk?.call([], isInitialBatch: true, isComplete: true);
      return [];
    }
    if (isCancelled?.call() ?? false) return [];
    if (albums.isEmpty) {
      onChunk?.call([], isInitialBatch: true, isComplete: true);
      return [];
    }

    final allAlbum = albums.firstWhere(
      (a) => a.isAll,
      orElse: () => albums.first,
    );
    int total;
    try {
      total = await allAlbum.assetCountAsync;
    } catch (_) {
      onChunk?.call([], isInitialBatch: true, isComplete: true);
      return [];
    }
    if (isCancelled?.call() ?? false) return [];
    if (total == 0) {
      onChunk?.call([], isInitialBatch: true, isComplete: true);
      return [];
    }

    const initialChunkSize = 100;
    List<AssetEntity> firstAssets;
    try {
      firstAssets = await allAlbum.getAssetListPaged(
        page: 0,
        size: initialChunkSize,
      );
    } catch (_) {
      onChunk?.call([], isInitialBatch: true, isComplete: true);
      return [];
    }
    if (isCancelled?.call() ?? false) return [];

    final initialItems = firstAssets
        .map(FileItem.fromAsset)
        .where((item) => matchesSearch(item.name, searchQuery))
        .toList();

    final isInitialComplete =
        firstAssets.length >= total || firstAssets.length < initialChunkSize;
    onChunk?.call(
      initialItems,
      isInitialBatch: true,
      isComplete: isInitialComplete,
    );

    if (isInitialComplete) {
      return initialItems;
    }

    final allLoaded = List<FileItem>.of(initialItems);
    final seenIds = initialItems.map((item) => item.pathSync).toSet();
    const pageSize = 100;
    var currentOffset = firstAssets.length;
    var hasEmittedComplete = false;

    while (currentOffset < total) {
      if (isCancelled?.call() ?? false) return allLoaded;

      // Yield briefly to event loop to keep UI thread unblocked (<100ms)
      await Future<void>.delayed(Duration.zero);
      if (isCancelled?.call() ?? false) return allLoaded;

      final page = currentOffset ~/ pageSize;
      List<AssetEntity> assets;
      try {
        assets = await allAlbum.getAssetListPaged(page: page, size: pageSize);
      } catch (_) {
        onChunk?.call([], isInitialBatch: false, isComplete: true);
        hasEmittedComplete = true;
        return allLoaded;
      }
      if (isCancelled?.call() ?? false) return allLoaded;
      if (assets.isEmpty) {
        onChunk?.call([], isInitialBatch: false, isComplete: true);
        hasEmittedComplete = true;
        break;
      }

      final chunk = assets
          .map(FileItem.fromAsset)
          .where((item) => matchesSearch(item.name, searchQuery))
          .where((item) => seenIds.add(item.pathSync))
          .toList();

      currentOffset += assets.length;
      final isComplete = currentOffset >= total || assets.length < pageSize;
      allLoaded.addAll(chunk);

      onChunk?.call(chunk, isInitialBatch: false, isComplete: isComplete);

      if (isComplete) {
        hasEmittedComplete = true;
        break;
      }
    }

    if (!hasEmittedComplete && !(isCancelled?.call() ?? false)) {
      onChunk?.call([], isInitialBatch: false, isComplete: true);
    }

    return allLoaded;
  }
}

class FileWalkLoadStrategy implements FileLoadStrategy {
  static const _excludedFolders = {'backups', 'mob', 'log', 'notifications'};

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
    final storageDirs = await getExternalStorageDirectories();
    if (storageDirs == null ||
        storageDirs.isEmpty ||
        (isCancelled?.call() ?? false)) {
      onChunk?.call([], isInitialBatch: true, isComplete: true);
      return [];
    }

    final rootPath = extractRootPath(storageDirs.first.path);
    if (rootPath == null || (isCancelled?.call() ?? false)) {
      onChunk?.call([], isInitialBatch: true, isComplete: true);
      return [];
    }

    final files = <FileItem>[];

    Future<void> walkDir(Directory dir) async {
      if (isCancelled?.call() ?? false) return;
      List<FileSystemEntity> entries;
      try {
        entries = await dir.list(recursive: false).toList();
      } catch (_) {
        return;
      }
      if (isCancelled?.call() ?? false) return;

      final subDirs = <Directory>[];
      final candidateFiles = <File>[];

      for (final entity in entries) {
        if (isCancelled?.call() ?? false) return;
        if (entity is Directory) {
          if (!isPathExcluded(
            entity.path,
            tempPath,
            _excludedFolders,
            showHiddenFiles: showHiddenFiles,
          )) {
            subDirs.add(entity);
          }
          continue;
        }
        if (entity is! File) continue;
        if (isPathExcluded(
          entity.path,
          tempPath,
          _excludedFolders,
          showHiddenFiles: showHiddenFiles,
        )) {
          continue;
        }
        if (!entityMatchesCategory(entity, categoryName)) continue;
        candidateFiles.add(entity);
      }

      if (isCancelled?.call() ?? false) return;

      final items = await Future.wait(
        candidateFiles.map((file) async {
          FileStat? stat;
          try {
            stat = await file.stat();
          } catch (_) {}
          return FileItem.fromEntity(
            file,
            size: stat?.size,
            modifiedDate: stat?.modified,
          );
        }),
      );

      if (isCancelled?.call() ?? false) return;

      for (final item in items) {
        if (matchesSearch(item.name, searchQuery)) {
          files.add(item);
        }
      }

      for (final subDir in subDirs) {
        if (isCancelled?.call() ?? false) return;
        await walkDir(subDir);
      }
    }

    await walkDir(Directory(rootPath));
    if (isCancelled?.call() ?? false) return [];
    onChunk?.call(files, isInitialBatch: true, isComplete: true);
    return files;
  }
}

class DirectoryLoadStrategy implements FileLoadStrategy {
  static const _excludedFolders = {'backups', 'mob', 'log', 'notifications'};

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
    if (baseDirectory == null || (isCancelled?.call() ?? false)) {
      onChunk?.call([], isInitialBatch: true, isComplete: true);
      return [];
    }

    final files = <FileItem>[];

    Future<void> walk(Directory dir, {required bool recursive}) async {
      if (isCancelled?.call() ?? false) return;
      List<FileSystemEntity> entries;
      try {
        entries = await dir.list(recursive: false, followLinks: false).toList();
      } catch (_) {
        return;
      }
      if (isCancelled?.call() ?? false) return;

      final validEntries = entries
          .where(
            (entity) => !isPathExcluded(
              entity.path,
              tempPath,
              _excludedFolders,
              showHiddenFiles: showHiddenFiles,
            ),
          )
          .toList();

      if (isCancelled?.call() ?? false) return;

      final items = await Future.wait(
        validEntries.map((entity) async {
          FileStat? stat;
          try {
            stat = await entity.stat();
          } catch (_) {}
          return (
            entity: entity,
            item: FileItem.fromEntity(
              entity,
              size: stat?.size,
              modifiedDate: stat?.modified,
            ),
          );
        }),
      );

      if (isCancelled?.call() ?? false) return;

      for (final pair in items) {
        if (matchesSearch(pair.item.name, searchQuery)) {
          files.add(pair.item);
        }
        if (recursive && pair.entity is Directory) {
          if (isCancelled?.call() ?? false) return;
          await walk(pair.entity as Directory, recursive: true);
        }
      }
    }

    await walk(baseDirectory, recursive: searchQuery.isNotEmpty);
    if (isCancelled?.call() ?? false) return [];
    onChunk?.call(files, isInitialBatch: true, isComplete: true);
    return files;
  }
}

bool matchesSearch(String fileName, String query) {
  if (query.isEmpty) return true;
  final nameLower = fileName.toLowerCase();
  final queryLower = query.toLowerCase();
  if (nameLower.contains(queryLower)) return true;

  final queryWords = queryLower
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 1)
      .toList();
  if (queryWords.isEmpty) return false;
  var matches = 0;
  for (final word in queryWords) {
    if (nameLower.contains(word)) matches++;
  }
  return matches >= (queryWords.length / 2).ceil();
}

String? extractRootPath(String path) {
  final idx = path.indexOf('/Android/data');
  return idx != -1 ? path.substring(0, idx) : null;
}

bool isPathExcluded(
  String path,
  String? tempPath,
  Set<String> excludedFolders, {
  required bool showHiddenFiles,
}) {
  if (tempPath != null && path.startsWith(tempPath)) return true;
  final lower = path.toLowerCase();
  final segments = lower.split('/');
  if (!showHiddenFiles &&
      segments.any((s) => s.startsWith('.') && s.length > 1)) {
    return true;
  }
  if (excludedFolders.any(segments.contains)) return true;
  if (lower.contains('/android/data/') || lower.contains('/android/obb/')) {
    return true;
  }
  return false;
}

bool entityMatchesCategory(FileSystemEntity entity, String categoryName) {
  if (entity is! File) return false;
  final path = entity.path.toLowerCase();

  return switch (categoryName) {
    'Photos' => photoExtensions.any(path.endsWith),
    'Videos' => videoExtensions.any(path.endsWith),
    'Audio' => audioExtensions.any(path.endsWith),
    'Documents' => documentExtensions.any(path.endsWith),
    'Other' => () {
      final all = {
        ...photoExtensions,
        ...videoExtensions,
        ...audioExtensions,
        ...documentExtensions,
      };
      return !all.any(path.endsWith);
    }(),
    _ => false,
  };
}

/// Controller for managing local file system state, multi-selection, sorting,
/// strategy-based file loading, and asynchronous background size computation.
class FileBrowserController extends ChangeNotifier {
  static const _mediaStoreCategories = {'Photos', 'Videos', 'Audio'};

  FileBrowserController({
    required this.category,
    this.mediaStoreStrategy,
    this.fileWalkStrategy,
    this.directoryStrategy,
    AppSettingsService? settingsService,
    this.loadOnInit = true,
  }) : _settingsService = settingsService ?? AppSettingsService() {
    if (category.name != 'All files') {
      final cachedEntry = CategoryDataCache.instance.getEntry(category.name);
      if (cachedEntry != null) {
        files.addAll(cachedEntry.files);
        if (cachedEntry.sortBy != null) sortBy = cachedEntry.sortBy!;
        if (cachedEntry.sortAscending != null) {
          sortAscending = cachedEntry.sortAscending!;
        }
        isLoading = false;
        isFullyLoaded = !loadOnInit;
        _isRevalidatingCache = true;
      }
    }
    if (loadOnInit) {
      unawaited(initialize());
    }
  }

  final FileCategory category;
  final FileLoadStrategy? mediaStoreStrategy;
  final FileLoadStrategy? fileWalkStrategy;
  final FileLoadStrategy? directoryStrategy;
  final bool loadOnInit;
  final AppSettingsService _settingsService;

  bool isLoading = true;
  bool isFullyLoaded = false;
  String? error;
  String? operationMessage;
  final List<FileItem> files = [];
  final Set<FileItem> selectedFiles = {};
  final List<Directory> directoryHistory = [];

  SortBy sortBy = SortBy.name;
  bool sortAscending = true;
  String searchQuery = '';

  bool _selectAllActive = false;
  bool get isSelectAllActive => _selectAllActive;

  bool _isRevalidatingCache = false;
  final Set<String> _inFlightSizeResolutions = {};

  String? _tempPath;
  int _operationId = 0;
  Timer? _searchDebounce;
  Timer? _lazySizeDebounce;

  bool get isSelectionMode => selectedFiles.isNotEmpty;
  bool get canNavigateBack =>
      category.name == 'All files' && directoryHistory.length > 1;
  Directory? get currentDirectory =>
      directoryHistory.isEmpty ? null : directoryHistory.last;

  @visibleForTesting
  void setViewStateForTest({
    bool? loading,
    bool? fullyLoaded,
    String? errorMessage,
    List<FileItem>? visibleFiles,
    Set<FileItem>? selected,
    bool? selectAllActive,
  }) {
    if (loading != null) isLoading = loading;
    if (fullyLoaded != null) isFullyLoaded = fullyLoaded;
    if (selectAllActive != null) _selectAllActive = selectAllActive;
    error = errorMessage;
    if (visibleFiles != null) {
      files
        ..clear()
        ..addAll(visibleFiles);
    }
    if (selected != null) {
      selectedFiles
        ..clear()
        ..addAll(selected);
    }
    notifyListeners();
  }

  Future<void> initialize() async {
    await AssetSizeCache.load();
    if (!_isRevalidatingCache) {
      await _loadSortPreferences();
    }
    await reload();
  }

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void disposeController() {
    _disposed = true;
    _operationId++;
    _searchDebounce?.cancel();
    _lazySizeDebounce?.cancel();
    _inFlightSizeResolutions.clear();
  }

  Future<void> _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    sortBy = SortBy.values[prefs.getInt('sortBy') ?? 0];
    sortAscending = prefs.getBool('sortAscending') ?? true;
    notifyListeners();
  }

  Future<void> _saveSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortBy', sortBy.index);
    await prefs.setBool('sortAscending', sortAscending);
  }

  void setSearchQueryDebounced(
    String query, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      unawaited(setSearchQuery(query));
    });
  }

  Future<void> setSearchQuery(String query) async {
    _isRevalidatingCache = false;
    clearSelection();
    searchQuery = query.trim();
    await reload();
  }

  void toggleSelection(FileItem item) {
    if (selectedFiles.contains(item)) {
      _selectAllActive = false;
      selectedFiles.remove(item);
    } else {
      selectedFiles.add(item);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectAllActive = true;
    selectedFiles
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  void clearSelection() {
    _selectAllActive = false;
    selectedFiles.clear();
    notifyListeners();
  }

  Future<void> updateSortBy(SortBy value) async {
    _isRevalidatingCache = false;
    sortBy = value;
    _sortFiles();
    notifyListeners();
    await _saveSortPreferences();

    if (category.name != 'All files' && searchQuery.isEmpty && isFullyLoaded) {
      CategoryDataCache.instance.put(
        category.name,
        files,
        sortBy: sortBy,
        sortAscending: sortAscending,
      );
    }
  }

  Future<void> toggleSortDirection() async {
    _isRevalidatingCache = false;
    sortAscending = !sortAscending;
    _sortFiles();
    notifyListeners();
    await _saveSortPreferences();

    if (category.name != 'All files' && searchQuery.isEmpty && isFullyLoaded) {
      CategoryDataCache.instance.put(
        category.name,
        files,
        sortBy: sortBy,
        sortAscending: sortAscending,
      );
    }
  }

  Future<void> navigateInto(Directory dir) async {
    _isRevalidatingCache = false;
    clearSelection();
    directoryHistory.add(dir);
    await reload();
  }

  Future<void> navigateBack() async {
    if (!canNavigateBack) return;
    _isRevalidatingCache = false;
    clearSelection();
    directoryHistory.removeLast();
    await reload();
  }

  Future<void> navigateToDirectory(Directory dir) async {
    if (category.name != 'All files') return;
    _isRevalidatingCache = false;
    clearSelection();
    final index = directoryHistory.indexWhere((d) => d.path == dir.path);
    if (index >= 0) {
      directoryHistory.removeRange(index + 1, directoryHistory.length);
    } else {
      directoryHistory
        ..clear()
        ..add(dir);
    }
    await reload();
  }

  Future<void> reload() async {
    _operationId++;
    final opId = _operationId;

    final isRevalidating = _isRevalidatingCache && searchQuery.isEmpty;
    if (!isRevalidating) {
      _isRevalidatingCache = false;
      isLoading = true;
      isFullyLoaded = false;
      files.clear();
      selectedFiles.clear();
      _selectAllActive = false;
      notifyListeners();
    } else {
      isFullyLoaded = false;
      error = null;
      notifyListeners();
    }

    try {
      if (_tempPath == null) {
        try {
          _tempPath = (await getTemporaryDirectory()).path;
        } catch (_) {
          _tempPath = '';
        }
      }
      if (_disposed || opId != _operationId) return;

      if (category.name == 'All files' && directoryHistory.isEmpty) {
        final storageDirs = await getExternalStorageDirectories();
        final rootDir = storageDirs?.first;
        if (rootDir != null) {
          final rootPath = extractRootPath(rootDir.path);
          if (rootPath != null) {
            directoryHistory.add(Directory(rootPath));
          }
        }
      }

      final strategy = _pickStrategy();
      final showHiddenFiles = await _settingsService.showHiddenFiles();
      if (_disposed || opId != _operationId) return;

      var streamHandled = false;
      final revalidatedFiles = <FileItem>[];

      final loaded = await strategy.load(
        categoryName: category.name,
        searchQuery: searchQuery,
        baseDirectory: category.name == 'All files'
            ? (directoryHistory.isEmpty ? null : directoryHistory.last)
            : null,
        tempPath: _tempPath,
        showHiddenFiles: showHiddenFiles,
        sortBy: sortBy,
        sortAscending: sortAscending,
        isCancelled: () => _disposed || opId != _operationId,
        onChunk:
            (chunk, {required bool isInitialBatch, required bool isComplete}) {
              if (_disposed || opId != _operationId) return;
              streamHandled = true;

              if (isRevalidating) {
                final existingRevalIds = revalidatedFiles
                    .map((f) => f.pathSync)
                    .toSet();
                final newItems = chunk
                    .where((f) => !existingRevalIds.contains(f.pathSync))
                    .toList();
                revalidatedFiles.addAll(newItems);
                if (isComplete) {
                  _isRevalidatingCache = false;
                  files
                    ..clear()
                    ..addAll(revalidatedFiles);
                  _sortFiles();
                  if (_selectAllActive) {
                    selectedFiles
                      ..clear()
                      ..addAll(files);
                  } else {
                    selectedFiles.retainWhere(files.contains);
                  }
                  if (selectedFiles.isEmpty) {
                    _selectAllActive = false;
                  }
                  isFullyLoaded = true;
                  notifyListeners();

                  if (category.name != 'All files' && searchQuery.isEmpty) {
                    CategoryDataCache.instance.put(
                      category.name,
                      files,
                      sortBy: sortBy,
                      sortAscending: sortAscending,
                    );
                  }
                }
              } else {
                var listChanged = false;
                if (isInitialBatch) {
                  isLoading = false;
                  files
                    ..clear()
                    ..addAll(chunk);
                  listChanged = true;
                } else if (chunk.isNotEmpty) {
                  final existingIds = files.map((f) => f.pathSync).toSet();
                  final newItems = chunk
                      .where((item) => !existingIds.contains(item.pathSync))
                      .toList();
                  if (newItems.isNotEmpty) {
                    files.addAll(newItems);
                    listChanged = true;
                  }
                }

                if (listChanged) {
                  _sortFiles();
                }

                if (_selectAllActive && chunk.isNotEmpty) {
                  selectedFiles.addAll(chunk);
                }

                isFullyLoaded = isComplete;
                if (listChanged || isComplete) {
                  notifyListeners();
                }

                if (isComplete &&
                    category.name != 'All files' &&
                    searchQuery.isEmpty) {
                  CategoryDataCache.instance.put(
                    category.name,
                    files,
                    sortBy: sortBy,
                    sortAscending: sortAscending,
                  );
                }
              }
            },
      );

      if (_disposed || opId != _operationId) return;

      if (!streamHandled) {
        _isRevalidatingCache = false;
        files
          ..clear()
          ..addAll(loaded);
        _sortFiles();

        if (_selectAllActive) {
          selectedFiles
            ..clear()
            ..addAll(files);
        } else {
          selectedFiles.retainWhere(files.contains);
        }
        if (selectedFiles.isEmpty) {
          _selectAllActive = false;
        }

        isFullyLoaded = true;
        if (category.name != 'All files' && searchQuery.isEmpty) {
          CategoryDataCache.instance.put(
            category.name,
            files,
            sortBy: sortBy,
            sortAscending: sortAscending,
          );
        }
      }
    } catch (e) {
      if (_disposed || opId != _operationId) return;
      if (!isRevalidating) {
        error = e.toString();
      }
    } finally {
      if (!_disposed && opId == _operationId) {
        isLoading = false;
        if (isRevalidating) {
          _isRevalidatingCache = false;
          isFullyLoaded = true;
        }
        notifyListeners();
      }
    }
  }

  FileLoadStrategy _pickStrategy() {
    if (category.name == 'All files') {
      return directoryStrategy ?? DirectoryLoadStrategy();
    }
    if (_mediaStoreCategories.contains(category.name)) {
      return mediaStoreStrategy ?? MediaStoreLoadStrategy();
    }
    return fileWalkStrategy ?? FileWalkLoadStrategy();
  }

  @visibleForTesting
  String strategyTypeForTest() {
    return _pickStrategy().runtimeType.toString();
  }

  void _sortFiles() {
    files.sort(_compare);
  }

  /// Non-blocking on-viewport resolution helper for individual asset sizes.
  void resolveAssetSizeLazy(FileItem item) {
    if (!item.isAsset || _disposed) return;
    final asset = item.asset!;
    if (AssetSizeCache.getSize(asset.id, item.modifiedDate) != null) return;
    if (_inFlightSizeResolutions.contains(asset.id)) return;
    _inFlightSizeResolutions.add(asset.id);
    unawaited(() async {
      try {
        final size = await asset.fileSize;
        if (_disposed) return;
        AssetSizeCache.setSize(asset.id, size, item.modifiedDate);
      } catch (_) {
        AssetSizeCache.setSize(asset.id, 0, item.modifiedDate);
      } finally {
        _inFlightSizeResolutions.remove(asset.id);
      }
      if (_disposed) return;
      if (sortBy == SortBy.size) {
        _lazySizeDebounce?.cancel();
        _lazySizeDebounce = Timer(const Duration(milliseconds: 300), () {
          if (!_disposed) {
            _sortFiles();
            notifyListeners();
            if (category.name != 'All files' &&
                searchQuery.isEmpty &&
                isFullyLoaded) {
              CategoryDataCache.instance.put(
                category.name,
                files,
                sortBy: sortBy,
                sortAscending: sortAscending,
              );
            }
          }
        });
      }
    }());
  }

  @visibleForTesting
  bool isInFlightSizeResolution(String assetId) =>
      _inFlightSizeResolutions.contains(assetId);

  /// Bounded background worker pool for asset size resolution.
  /// Gallery measurement concurrency is strictly capped at <= 2 to prevent CPU throttling.
  @visibleForTesting
  Future<void> startBackgroundSizeLoading([int? opId]) async {
    final currentOp = opId ?? _operationId;
    final activeAssetIds = files
        .where((f) => f.isAsset)
        .map((f) => f.asset!.id)
        .toList();
    AssetSizeCache.pruneOldEntries(activeIds: activeAssetIds);

    final assetsToFetch = files
        .where(
          (f) =>
              f.isAsset &&
              AssetSizeCache.getSize(f.asset!.id, f.modifiedDate) == null,
        )
        .toList();

    if (assetsToFetch.isEmpty) return;

    final concurrency = math.min(2, assetsToFetch.length);
    var index = 0;
    var resolvedCount = 0;

    Future<void> worker() async {
      while (true) {
        if (_disposed || currentOp != _operationId) return;

        final currentIdx = index++;
        if (currentIdx >= assetsToFetch.length) break;

        final item = assetsToFetch[currentIdx];
        final asset = item.asset!;

        try {
          final size = await asset.fileSize;
          if (_disposed || currentOp != _operationId) return;
          AssetSizeCache.setSize(asset.id, size, item.modifiedDate);
          resolvedCount++;

          if (resolvedCount % 10 == 0 ||
              resolvedCount == assetsToFetch.length) {
            if (!_disposed && currentOp == _operationId) {
              _sortFiles();
              notifyListeners();
            }
          }
        } catch (_) {
          AssetSizeCache.setSize(asset.id, 0, item.modifiedDate);
        }
      }
    }

    final workers = List.generate(concurrency, (_) => worker());
    await Future.wait(workers);
  }

  int _compare(FileItem a, FileItem b) {
    if (a.isDirectory && !b.isDirectory) return -1;
    if (!a.isDirectory && b.isDirectory) return 1;

    final result = switch (sortBy) {
      SortBy.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      SortBy.date => () {
        final cmp = (a.isAsset && b.isAsset)
            ? a.asset!.createDateTime.compareTo(b.asset!.createDateTime)
            : a.modifiedDate.compareTo(b.modifiedDate);
        if (cmp != 0) return cmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }(),
      SortBy.size => () {
        final aSize = a.isAsset
            ? AssetSizeCache.getSize(a.asset!.id, a.modifiedDate)
            : a.size;
        final bSize = b.isAsset
            ? AssetSizeCache.getSize(b.asset!.id, b.modifiedDate)
            : b.size;
        if (aSize != null && bSize != null) {
          final cmp = aSize.compareTo(bSize);
          if (cmp != 0) return cmp;
        } else if (aSize != null) {
          return 1;
        } else if (bSize != null) {
          return -1;
        }
        // Fallback gracefully to date sorting if uncached
        final dateCmp = (a.isAsset && b.isAsset)
            ? a.asset!.createDateTime.compareTo(b.asset!.createDateTime)
            : a.modifiedDate.compareTo(b.modifiedDate);
        if (dateCmp != 0) return dateCmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }(),
      SortBy.type => () {
        final cmp = a.type.compareTo(b.type);
        if (cmp != 0) return cmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }(),
    };

    return sortAscending ? result : -result;
  }

  Future<void> shareSelectedFiles() async {
    final filesToShare = <XFile>[];
    for (final item in selectedFiles) {
      final path = await item.path;
      if (path.isNotEmpty) filesToShare.add(XFile(path));
    }
    if (filesToShare.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(files: filesToShare));
    }
    selectedFiles.clear();
    notifyListeners();
  }

  Future<void> deleteSelectedFiles() async {
    for (final item in selectedFiles.toList()) {
      try {
        if (item.isAsset) {
          final file = await item.asset!.originFile;
          if (file != null && await file.exists()) {
            await file.delete();
          }
          AssetSizeCache.remove(item.asset!.id);
        } else if (item.fsEntity != null) {
          if (item.fsEntity is Directory) {
            await item.fsEntity!.delete(recursive: true);
          } else {
            await item.fsEntity!.delete();
          }
        }
      } catch (_) {
        // Best-effort delete; UI handles user messaging.
      }
    }

    _invalidateCategoryCache();
    files.removeWhere(selectedFiles.contains);
    selectedFiles.clear();
    _selectAllActive = false;
    notifyListeners();
  }

  void _invalidateCategoryCache() {
    if (category.name == 'All files') {
      CategoryDataCache.instance.clear();
    } else {
      CategoryDataCache.instance.invalidate(category.name);
    }
  }

  Future<void> openFileExternally(FileItem item) async {
    final filePath = await item.path;
    if (filePath.isNotEmpty) {
      await OpenFile.open(filePath);
    }
  }

  AppLocalizations _getL10n([AppLocalizations? l10n]) {
    if (l10n != null) return l10n;
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      if (AppLocalizations.supportedLocales.any(
        (loc) => loc.languageCode == locale.languageCode,
      )) {
        return lookupAppLocalizations(Locale(locale.languageCode));
      }
    } catch (_) {}
    return lookupAppLocalizations(const Locale('en'));
  }

  Future<String?> createFolder(String name, [AppLocalizations? l10n]) async {
    final local = _getL10n(l10n);
    if (category.name != 'All files') {
      return local.folderCreationOnlyInAllFiles;
    }
    if (directoryHistory.isEmpty) {
      return local.currentDirectoryUnavailable;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return local.folderNameCannotBeEmpty;
    }

    final target = Directory('${directoryHistory.last.path}/$trimmed');
    if (await target.exists()) {
      return local.folderAlreadyExists;
    }
    try {
      await target.create(recursive: true);
      await reload();
      return null;
    } catch (e) {
      return local.failedToCreateFolder(e.toString());
    }
  }

  Future<String?> createFolderAtPath(
    String parentPath,
    String name, [
    AppLocalizations? l10n,
  ]) async {
    final local = _getL10n(l10n);
    final trimmed = name.trim();
    if (trimmed.isEmpty) return local.folderNameCannotBeEmpty;
    final target = Directory('$parentPath/$trimmed');
    if (await target.exists()) return local.folderAlreadyExists;
    try {
      await target.create(recursive: true);
      await reload();
      return null;
    } catch (e) {
      return local.failedToCreateFolder(e.toString());
    }
  }

  Future<List<Directory>> listDirectoriesAt(String path) async {
    try {
      final entries = await Directory(
        path,
      ).list(recursive: false, followLinks: false).toList();
      return entries
          .whereType<Directory>()
          .where((d) => !p.basename(d.path).startsWith('.'))
          .toList()
        ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    } catch (_) {
      return const [];
    }
  }

  Future<String?> moveSelectedToFolder(
    String destinationPath, [
    AppLocalizations? l10n,
  ]) async {
    final local = _getL10n(l10n);
    if (selectedFiles.isEmpty) return local.nothingSelected;
    final destination = Directory(destinationPath);
    if (!await destination.exists()) {
      return local.destinationFolderDoesNotExist;
    }

    final selected = selectedFiles.toList();
    var moved = 0;
    var failed = 0;
    var skipped = 0;
    String? firstError;

    for (final item in selected) {
      final srcPath = item.fsEntity?.path.isNotEmpty == true
          ? item.fsEntity!.path
          : await item.path;
      if (srcPath.isEmpty) {
        skipped++;
        continue;
      }

      final name = item.name;
      final targetPath = p.join(destinationPath, name);
      if (srcPath == targetPath) {
        skipped++;
        continue;
      }
      if (item.isDirectory &&
          destinationPath.startsWith('$srcPath${Platform.pathSeparator}')) {
        failed++;
        firstError ??= local.cannotMoveFolderIntoItself(name);
        continue;
      }

      try {
        if (item.fsEntity != null) {
          await item.fsEntity!.rename(targetPath);
        } else {
          await File(srcPath).rename(targetPath);
        }
        moved++;
      } catch (e) {
        failed++;
        firstError ??= local.failedToMoveItem(name, e.toString());
      }
    }

    if (moved > 0) {
      _invalidateCategoryCache();
      selectedFiles.clear();
      _selectAllActive = false;
      await reload();
    }

    if (failed > 0) {
      if (moved > 0) return local.movedNItemsFailedM(moved, failed);
      return firstError ?? local.failedToMoveSelectedItems;
    }
    if (moved == 0 && skipped > 0) {
      return local.noFilesWereMoved;
    }
    return null;
  }

  Future<bool> renameItem(
    FileItem item,
    String newName, [
    AppLocalizations? l10n,
  ]) async {
    final local = _getL10n(l10n);
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == item.name) return false;

    final itemPath = await item.path;
    if (itemPath.isEmpty) return false;

    final dirPath = p.dirname(itemPath);
    final targetPath = p.join(dirPath, trimmed);

    if (await File(targetPath).exists() ||
        await Directory(targetPath).exists()) {
      operationMessage = local.renameConflictAlreadyExists;
      notifyListeners();
      return false;
    }

    try {
      if (item.fsEntity != null) {
        await item.fsEntity!.rename(targetPath);
      } else if (item.isDirectory) {
        await Directory(itemPath).rename(targetPath);
      } else {
        await File(itemPath).rename(targetPath);
      }
      operationMessage = local.renamedOldToNew(item.name, trimmed);
      _invalidateCategoryCache();
      selectedFiles.clear();
      _selectAllActive = false;
      await reload();
      return true;
    } catch (e) {
      operationMessage = local.failedToRenameWithError(item.name, e.toString());
      notifyListeners();
      return false;
    }
  }
}
