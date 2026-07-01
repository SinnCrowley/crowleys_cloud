import 'dart:async';
import 'dart:io';

import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/asset_size_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortBy { name, date, size, type }

abstract class FileLoadStrategy {
  Future<List<FileItem>> load({
    required String categoryName,
    required String searchQuery,
    Directory? baseDirectory,
    required String? tempPath,
    required bool showHiddenFiles,
  });
}

class MediaStoreLoadStrategy implements FileLoadStrategy {
  @override
  Future<List<FileItem>> load({
    required String categoryName,
    required String searchQuery,
    Directory? baseDirectory,
    required String? tempPath,
    required bool showHiddenFiles,
  }) async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) return [];

    final type = switch (categoryName) {
      'Photos' => RequestType.image,
      'Videos' => RequestType.video,
      'Audio' => RequestType.audio,
      _ => RequestType.common,
    };

    final albums = await PhotoManager.getAssetPathList(
      type: type,
      hasAll: true,
      onlyAll: false,
    );
    if (albums.isEmpty) return [];

    final allAlbum = albums.firstWhere(
      (a) => a.isAll,
      orElse: () => albums.first,
    );
    final total = await allAlbum.assetCountAsync;

    const pageSize = 2000;
    final result = <FileItem>[];

    for (var page = 0; page * pageSize < total; page++) {
      final assets = await allAlbum.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      result.addAll(
        assets
            .map(FileItem.fromAsset)
            .where((item) => matchesSearch(item.name, searchQuery)),
      );
    }

    return result;
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
  }) async {
    final storageDirs = await getExternalStorageDirectories();
    if (storageDirs == null || storageDirs.isEmpty) return [];

    final rootPath = extractRootPath(storageDirs.first.path);
    if (rootPath == null) return [];

    final files = <FileItem>[];

    Future<void> walkDir(Directory dir) async {
      List<FileSystemEntity> entries;
      try {
        entries = await dir.list(recursive: false).toList();
      } catch (_) {
        return;
      }

      for (final entity in entries) {
        if (entity is Directory) {
          if (!isPathExcluded(
            entity.path,
            tempPath,
            _excludedFolders,
            showHiddenFiles: showHiddenFiles,
          )) {
            await walkDir(entity);
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

        final item = FileItem.fromEntity(entity);
        if (matchesSearch(item.name, searchQuery)) {
          files.add(item);
        }
      }
    }

    await walkDir(Directory(rootPath));
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
  }) async {
    if (baseDirectory == null) return [];

    final files = <FileItem>[];

    Future<void> walk(Directory dir, {required bool recursive}) async {
      List<FileSystemEntity> entries;
      try {
        entries = await dir.list(recursive: false, followLinks: false).toList();
      } catch (_) {
        return;
      }

      for (final entity in entries) {
        if (isPathExcluded(
          entity.path,
          tempPath,
          _excludedFolders,
          showHiddenFiles: showHiddenFiles,
        )) {
          continue;
        }
        final item = FileItem.fromEntity(entity);
        if (matchesSearch(item.name, searchQuery)) {
          files.add(item);
        }
        if (recursive && entity is Directory) {
          await walk(entity, recursive: true);
        }
      }
    }

    await walk(baseDirectory, recursive: searchQuery.isNotEmpty);
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
  String? error;
  final List<FileItem> files = [];
  final Set<FileItem> selectedFiles = {};
  final List<Directory> directoryHistory = [];

  SortBy sortBy = SortBy.name;
  bool sortAscending = true;
  String searchQuery = '';

  String? _tempPath;
  int _operationId = 0;
  Timer? _searchDebounce;

  bool get isSelectionMode => selectedFiles.isNotEmpty;
  bool get canNavigateBack =>
      category.name == 'All files' && directoryHistory.length > 1;
  Directory? get currentDirectory =>
      directoryHistory.isEmpty ? null : directoryHistory.last;

  @visibleForTesting
  void setViewStateForTest({
    bool? loading,
    String? errorMessage,
    List<FileItem>? visibleFiles,
    Set<FileItem>? selected,
  }) {
    if (loading != null) isLoading = loading;
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
    await _loadSortPreferences();
    await reload();
  }

  void disposeController() {
    _searchDebounce?.cancel();
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
    searchQuery = query.trim();
    await reload();
  }

  void toggleSelection(FileItem item) {
    if (selectedFiles.contains(item)) {
      selectedFiles.remove(item);
    } else {
      selectedFiles.add(item);
    }
    notifyListeners();
  }

  void selectAll() {
    selectedFiles
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  void clearSelection() {
    selectedFiles.clear();
    notifyListeners();
  }

  Future<void> updateSortBy(SortBy value) async {
    sortBy = value;
    _sortFiles();
    notifyListeners();
    await _saveSortPreferences();
  }

  Future<void> toggleSortDirection() async {
    sortAscending = !sortAscending;
    _sortFiles();
    notifyListeners();
    await _saveSortPreferences();
  }

  Future<void> navigateInto(Directory dir) async {
    directoryHistory.add(dir);
    await reload();
  }

  Future<void> navigateBack() async {
    if (!canNavigateBack) return;
    directoryHistory.removeLast();
    await reload();
  }

  Future<void> navigateToDirectory(Directory dir) async {
    if (category.name != 'All files') return;
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

    isLoading = true;
    error = null;
    files.clear();
    notifyListeners();

    try {
      if (_tempPath == null) {
        try {
          _tempPath = (await getTemporaryDirectory()).path;
        } catch (_) {
          _tempPath = '';
        }
      }
      if (opId != _operationId) return;

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
      final loaded = await strategy.load(
        categoryName: category.name,
        searchQuery: searchQuery,
        baseDirectory: category.name == 'All files'
            ? (directoryHistory.isEmpty ? null : directoryHistory.last)
            : null,
        tempPath: _tempPath,
        showHiddenFiles: showHiddenFiles,
      );

      if (opId != _operationId) return;
      files
        ..clear()
        ..addAll(loaded);
      _sortFiles();

      final needsSizeLoading = sortBy == SortBy.size &&
          files.any((f) => f.isAsset && AssetSizeCache.getSize(f.asset!.id, f.modifiedDate) == null);

      if (needsSizeLoading) {
        await _startBackgroundSizeLoading(opId);
      } else {
        unawaited(_startBackgroundSizeLoading(opId));
      }
    } catch (e) {
      if (opId != _operationId) return;
      error = e.toString();
    } finally {
      if (opId == _operationId) {
        isLoading = false;
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

  Future<void> _startBackgroundSizeLoading(int opId) async {
    final activeAssetIds = files.where((f) => f.isAsset).map((f) => f.asset!.id).toList();
    AssetSizeCache.pruneOldEntries(activeIds: activeAssetIds);

    final assetsToFetch = files
        .where((f) => f.isAsset && AssetSizeCache.getSize(f.asset!.id, f.modifiedDate) == null)
        .toList();

    if (assetsToFetch.isEmpty) return;

    // Load sizes in parallel with a limited concurrency (e.g., 8 at a time)
    const concurrency = 8;
    var index = 0;
    var resolvedCount = 0;

    Future<void> worker() async {
      while (true) {
        if (opId != _operationId) return;
        
        final currentIdx = index++;
        if (currentIdx >= assetsToFetch.length) break;

        final item = assetsToFetch[currentIdx];
        final asset = item.asset!;
        
        try {
          final file = await asset.originFile ?? await asset.file;
          if (file != null) {
            final size = await file.length();
            AssetSizeCache.setSize(asset.id, size, item.modifiedDate);
            resolvedCount++;
            
            // Re-sort and notify UI periodically (every 10 resolved items or on complete)
            if (resolvedCount % 10 == 0 || resolvedCount == assetsToFetch.length) {
              if (opId == _operationId) {
                _sortFiles();
                notifyListeners();
              }
            }
          }
        } catch (_) {
          // Cache 0 on error to avoid endless retries
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
      SortBy.date => a.modifiedDate.compareTo(b.modifiedDate),
      SortBy.size => a.size.compareTo(b.size),
      SortBy.type => a.type.compareTo(b.type),
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

    files.removeWhere(selectedFiles.contains);
    selectedFiles.clear();
    notifyListeners();
  }

  Future<void> openFileExternally(FileItem item) async {
    final filePath = await item.path;
    if (filePath.isNotEmpty) {
      await OpenFile.open(filePath);
    }
  }

  Future<String?> createFolder(String name) async {
    if (category.name != 'All files') {
      return 'Folder creation is only available in All files.';
    }
    if (directoryHistory.isEmpty) {
      return 'Current directory is unavailable.';
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Folder name cannot be empty.';
    }

    final target = Directory('${directoryHistory.last.path}/$trimmed');
    if (await target.exists()) {
      return 'Folder already exists.';
    }
    try {
      await target.create(recursive: true);
      await reload();
      return null;
    } catch (e) {
      return 'Failed to create folder: $e';
    }
  }

  Future<String?> createFolderAtPath(String parentPath, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Folder name cannot be empty.';
    final target = Directory('$parentPath/$trimmed');
    if (await target.exists()) return 'Folder already exists.';
    try {
      await target.create(recursive: true);
      await reload();
      return null;
    } catch (e) {
      return 'Failed to create folder: $e';
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

  Future<String?> moveSelectedToFolder(String destinationPath) async {
    if (selectedFiles.isEmpty) return 'Nothing selected.';
    final destination = Directory(destinationPath);
    if (!await destination.exists()) {
      return 'Destination folder does not exist.';
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
        firstError ??= 'Cannot move folder "$name" into itself.';
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
        firstError ??= 'Failed to move $name: $e';
      }
    }

    if (moved > 0) {
      selectedFiles.clear();
      await reload();
    }

    if (failed > 0) {
      if (moved > 0) return 'Moved $moved item(s), failed $failed.';
      return firstError ?? 'Failed to move selected items.';
    }
    if (moved == 0 && skipped > 0) {
      return 'No files were moved.';
    }
    return null;
  }
}
