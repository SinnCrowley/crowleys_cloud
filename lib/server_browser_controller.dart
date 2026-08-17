import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/shared/utils/authenticated_http_client.dart';
import 'package:crowleys_cloud/shared/utils/url_utils.dart';
import 'package:crowleys_cloud/transfer_manager.dart';
import 'package:crowleys_cloud/shared/proto/dir_entry.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ServerSortBy { name, date, size, type }

/// Controller for managing remote server file browsing, stale-while-revalidate caching,
/// in-flight download deduplication, recursive folder transfers, and remote multi-selection.
class ServerBrowserController extends ChangeNotifier {
  static const _sortByPrefKey = 'serverSortBy';
  static const _sortAscendingPrefKey = 'serverSortAscending';

  ServerBrowserController({
    required this.profile,
    required this.serverId,
    required this.authService,
    this.onConnectionLost,
    this.transferManager,
    CacheService? cacheService,
    AppSettingsService? settingsService,
    http.Client? client,
  }) : _cacheService = cacheService ?? CacheService.instance,
       _settingsService = settingsService ?? AppSettingsService(),
       _client = client ?? http.Client() {
    unawaited(initialize());
  }

  final ServerProfile profile;
  final String serverId;
  final AuthService authService;
  final ValueChanged<String>? onConnectionLost;
  final TransferManager? transferManager;
  final CacheService _cacheService;
  final AppSettingsService _settingsService;
  final http.Client _client;

  final List<ServerFileItem> files = [];
  final Set<ServerFileItem> selectedFiles = {};
  final List<String> pathStack = [''];
  String scope = 'private';
  String selectedType = 'all';
  String searchQuery = '';
  ServerSortBy sortBy = ServerSortBy.name;
  bool sortAscending = true;
  bool isLoading = false;
  String? error;
  String? operationMessage;
  bool _showHiddenFiles = false;
  Map<String, Object?>? accountStats;

  Timer? _searchDebounce;
  int _opId = 0;
  final Map<String, Future<File?>> _downloadsInFlight = {};

  String get currentPath => pathStack.last;
  bool get canNavigateBack => selectedType == 'all' && pathStack.length > 1;
  bool get isSelectionMode => selectedFiles.isNotEmpty;

  Future<void> fetchAccountStats() async {
    try {
      final uri = _apiUri('/account/stats');
      final response = await _authorizedGet(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        accountStats = jsonDecode(response.body) as Map<String, Object?>?;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> initialize() async {
    await _loadSortPreferences();
    unawaited(fetchAccountStats());
    await reload();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void disposeController() {
    _searchDebounce?.cancel();
  }

  void setCategory(String type) {
    selectedType = type;
    selectedFiles.clear();
    if (selectedType != 'all') {
      pathStack
        ..clear()
        ..add('');
    }
    unawaited(reload());
  }

  Future<void> setScope(String value) async {
    if (value != 'private' && value != 'shared') return;
    scope = value;
    pathStack
      ..clear()
      ..add('');
    selectedFiles.clear();
    await reload();
  }

  Future<void> updateSortBy(ServerSortBy value) async {
    sortBy = value;
    await _saveSortPreferences();
    await reload();
  }

  Future<void> toggleSortDirection() async {
    sortAscending = !sortAscending;
    await _saveSortPreferences();
    await reload();
  }

  void setSearchQueryDebounced(
    String query, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      searchQuery = query.trim();
      unawaited(reload());
    });
  }

  Future<void> _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    sortBy = ServerSortBy.values[prefs.getInt(_sortByPrefKey) ?? 0];
    sortAscending = prefs.getBool(_sortAscendingPrefKey) ?? true;
    notifyListeners();
  }

  Future<void> _saveSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortByPrefKey, sortBy.index);
    await prefs.setBool(_sortAscendingPrefKey, sortAscending);
  }

  Future<void> navigateInto(ServerFileItem dir) async {
    if (!dir.isDir || selectedType != 'all') return;
    pathStack.add(dir.path);
    selectedFiles.clear();
    await reload();
  }

  Future<void> navigateBack() async {
    if (!canNavigateBack || selectedType != 'all') return;
    pathStack.removeLast();
    selectedFiles.clear();
    await reload();
  }

  Future<void> navigateToPath(String path) async {
    if (selectedType != 'all') return;
    final normalized = path.trim();
    final index = pathStack.indexWhere((p) => p == normalized);
    if (index >= 0) {
      pathStack.removeRange(index + 1, pathStack.length);
    } else {
      pathStack
        ..clear()
        ..add(normalized);
    }
    selectedFiles.clear();
    await reload();
  }

  void toggleSelection(ServerFileItem item) {
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

  Future<void> reload() async {
    _opId++;
    final opId = _opId;
    isLoading = true;
    error = null;
    notifyListeners();

    _showHiddenFiles = await _settingsService.showHiddenFiles();
    if (opId != _opId) return;

    final requestPath = selectedType == 'all' ? currentPath : '';
    final cacheKey = _directoryCacheKey(path: requestPath);
    final cached = await _cacheService.readDirectory(
      serverId: serverId,
      cacheKey: cacheKey,
    );
    var renderedCachedData = false;
    if (opId != _opId) return;
    if (cached != null) {
      files
        ..clear()
        ..addAll(_filterHiddenEntries(cached.entries));
      if (selectedType != 'all') {
        files.removeWhere((item) => item.isDir);
      }
      operationMessage = cached.isStale ? 'Showing cached files.' : null;
      renderedCachedData = true;
      notifyListeners();
    }

    try {
      final uri = _apiUri('/dir').replace(
        queryParameters: {
          'scope': scope,
          'path': requestPath,
          if (searchQuery.isNotEmpty) 'q': searchQuery,
          if (selectedType != 'all') 'type': selectedType,
          'sort': sortBy.name,
          'order': sortAscending ? 'asc' : 'desc',
        },
      );
      final response = await _authorizedGet(uri);
      if (opId != _opId) return;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server error ${response.statusCode}');
      }

      final payload = jsonDecode(response.body) as Map<String, Object?>;
      final entries = (payload['entries'] as List?) ?? const [];
      files
        ..clear()
        ..addAll(
          _filterHiddenEntries(
            entries
                .whereType<Map>()
                .map(
                  (e) => ServerFileItem.fromJson(Map<String, Object?>.from(e)),
                )
                .toList(growable: false),
          ),
        );
      if (selectedType != 'all') {
        files.removeWhere((item) => item.isDir);
      }
      operationMessage = null;
      await _cacheService.writeDirectory(
        serverId: serverId,
        cacheKey: cacheKey,
        scope: scope,
        path: requestPath,
        entries: files,
      );
    } catch (e) {
      if (opId != _opId) return;
      error = e.toString();
      if (renderedCachedData) {
        operationMessage = 'Showing cached files. Refresh failed.';
      }
    } finally {
      if (opId == _opId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> invalidateCurrentDirectory({bool reloadAfter = false}) async {
    await _invalidateDirectory(scope: scope, path: currentPath);
    if (reloadAfter) await reload();
  }

  Future<File?> downloadTempForEdit(ServerFileItem item) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/${item.id ?? item.path.hashCode}_${item.name}',
    );

    if (await file.exists()) {
      try {
        if (await file.length() == item.size) {
          return file;
        }
      } catch (_) {}
    }

    final cacheKey = '${item.id ?? item.path}';
    return _downloadsInFlight.putIfAbsent(cacheKey, () async {
      try {
        final uri = _apiUri(
          '/files',
        ).replace(queryParameters: {'scope': scope, 'path': item.path});
        final response = await _authorizedGet(uri);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }

        await file.writeAsBytes(response.bodyBytes, flush: true);
        return file;
      } catch (_) {
        return null;
      } finally {
        _downloadsInFlight.remove(cacheKey);
      }
    });
  }

  Uri resolveThumbnailUrl(ServerFileItem item, {int size = 256}) {
    final raw = item.thumbnailUrl;
    if (raw != null && raw.isNotEmpty) {
      final parsed = Uri.parse(raw);
      if (parsed.hasScheme) return parsed;
      return _baseUri(raw);
    }
    return _apiUri('/thumb').replace(
      queryParameters: {'path': item.path, 's': '$size', 'scope': scope},
    );
  }

  Uri streamUri(ServerFileItem item) {
    return _apiUri(
      '/files',
    ).replace(queryParameters: {'scope': scope, 'path': item.path});
  }

  Future<void> downloadSelectedFiles() async {
    operationMessage = null;
    final downloadRoot = await _downloadRoot();
    final failed = <String>[];
    final selected = selectedFiles.toList();
    final plans = <_DownloadPlan>[];
    try {
      for (final item in selected) {
        final ok = await _collectDownloadPlans(item, downloadRoot, plans);
        if (!ok) failed.add(item.name);
      }
      if (plans.isNotEmpty && transferManager != null) {
        final transferItems = transferManager!.addItems(
          plans
              .map(
                (plan) => TransferItemDraft(
                  name: plan.item.path.isEmpty
                      ? plan.item.name
                      : plan.item.path,
                  direction: TransferDirection.download,
                  totalBytes: plan.item.size,
                ),
              )
              .toList(growable: false),
        );
        for (var i = 0; i < plans.length; i++) {
          plans[i].transferItem = transferItems[i];
        }
      }
      for (final plan in plans) {
        try {
          final ok = await _downloadSingleFile(
            plan.item,
            plan.targetPath,
            transferItem: plan.transferItem,
          );
          if (ok) {
            continue;
          } else {
            failed.add(plan.item.name);
          }
        } on TransferItemCanceledException {
          continue;
        }
      }
    } on TransferCanceledException {
      operationMessage = 'Download canceled.';
      selectedFiles.clear();
      notifyListeners();
      return;
    }
    final downloaded = plans.length - failed.length;
    final displayPath = _formatDisplayPath(downloadRoot.path);
    operationMessage = failed.isEmpty
        ? 'Downloaded $downloaded file(s) to $displayPath'
        : 'Downloaded $downloaded file(s), failed ${failed.length}: ${failed.first}';
    selectedFiles.clear();
    notifyListeners();
  }

  String _formatDisplayPath(String path) {
    const androidPrefix = '/storage/emulated/0';
    if (path.startsWith(androidPrefix)) {
      final sub = path.substring(androidPrefix.length);
      return sub.isEmpty ? 'Internal Storage' : sub;
    }
    return path;
  }

  Future<void> deleteSelectedFiles() async {
    operationMessage = null;
    var deleted = 0;
    var failed = 0;
    for (final item in selectedFiles.toList()) {
      final uri = _apiUri(
        '/files',
      ).replace(queryParameters: {'scope': scope, 'path': item.path});
      try {
        final response = await _authorizedDelete(uri);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          files.remove(item);
          deleted++;
          await _invalidateDirectory(
            scope: scope,
            path: _parentPath(item.path),
          );
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }
    operationMessage = failed == 0
        ? 'Deleted $deleted item(s).'
        : 'Deleted $deleted item(s), failed $failed.';
    selectedFiles.clear();
    notifyListeners();
  }

  Future<void> shareSelectedFiles() async {
    operationMessage = null;
    final sharedLinks = <String>[];
    for (final item in selectedFiles.toList()) {
      final uri = _apiUri('/share');
      try {
        final response = await _authorizedPostJson(uri, {
          'scope': scope,
          'path': item.path,
        });
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final payload = jsonDecode(response.body) as Map<String, Object?>;
          final rawUrl = (payload['url'] as String?) ?? '';
          if (rawUrl.isNotEmpty) {
            sharedLinks.add(_publicShareUri(rawUrl).toString());
          }
        }
      } catch (_) {}
    }
    if (sharedLinks.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(text: sharedLinks.join('\n')));
      operationMessage = 'Created ${sharedLinks.length} share link(s).';
    } else {
      operationMessage = 'Failed to create share link(s).';
    }
    selectedFiles.clear();
    notifyListeners();
  }

  Future<void> shareSelectedInServer() async {
    operationMessage = null;
    if (selectedFiles.isEmpty) return;
    if (scope == 'shared') {
      operationMessage = 'Already in shared scope.';
      notifyListeners();
      return;
    }

    var shared = 0;
    var failed = 0;
    for (final item in selectedFiles.toList()) {
      final uri = _apiUri(
        '/files/share',
      ).replace(queryParameters: {'path': item.path, 'shared': '1'});
      final response = await _authorizedPostBytes(uri, const []);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        shared++;
      } else {
        failed++;
      }
    }

    await _invalidateDirectory(scope: 'shared', path: '');

    operationMessage = failed == 0
        ? 'Shared $shared item(s) in server.'
        : 'Shared $shared item(s), failed $failed.';
    selectedFiles.clear();
    notifyListeners();
  }

  Future<void> createFolder(String name) async {
    await createFolderAtPath(currentPath, name);
  }

  Future<void> createFolderAtPath(String parentPath, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      operationMessage = 'Folder name cannot be empty.';
      notifyListeners();
      return;
    }
    final targetPath = parentPath.isEmpty
        ? trimmed
        : p.join(parentPath, trimmed);
    final uri = _apiUri(
      '/folders',
    ).replace(queryParameters: {'scope': scope, 'path': targetPath});
    final response = await _authorizedPostBytes(uri, const []);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      operationMessage = 'Folder created.';
      await _invalidateDirectory(scope: scope, path: parentPath);
      await reload();
      return;
    }
    operationMessage = 'Failed to create folder (${response.statusCode}).';
    notifyListeners();
  }

  Future<List<ServerFileItem>> listFoldersAt(String path) async {
    final showHiddenFiles = await _settingsService.showHiddenFiles();
    final entries = await _listDirAtScope(path, scope);
    return entries
        .where((e) => e.isDir && (showHiddenFiles || !e.name.startsWith('.')))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> moveSelectedToFolder(String destinationPath) async {
    operationMessage = null;
    if (selectedFiles.isEmpty) return;

    var moved = 0;
    var failed = 0;
    for (final item in selectedFiles.toList()) {
      final targetPath = destinationPath.isEmpty
          ? p.basename(item.path)
          : p.join(destinationPath, p.basename(item.path));
      if (item.isDir && destinationPath.startsWith('${item.path}/')) {
        failed++;
        continue;
      }
      final ok = await _copyItemWithinScope(
        item: item,
        sourceScope: scope,
        targetPath: targetPath,
      );
      if (!ok) {
        failed++;
        continue;
      }
      final deleteUri = _apiUri(
        '/files',
      ).replace(queryParameters: {'scope': scope, 'path': item.path});
      final delResp = await _authorizedDelete(deleteUri);
      if (delResp.statusCode >= 200 && delResp.statusCode < 300) {
        moved++;
        await _invalidateDirectory(scope: scope, path: _parentPath(item.path));
        await _invalidateDirectory(scope: scope, path: destinationPath);
      } else {
        failed++;
      }
    }
    operationMessage = failed == 0
        ? 'Moved $moved item(s).'
        : 'Moved $moved item(s), failed $failed.';
    selectedFiles.clear();
    await reload();
  }

  Future<bool> renameItem(ServerFileItem item, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == item.name) return false;

    final dirPath = _parentPath(item.path);
    final targetPath = dirPath.isEmpty ? trimmed : p.join(dirPath, trimmed);

    final uri = _apiUri('/files/move').replace(
      queryParameters: {'scope': scope, 'src': item.path, 'dest': targetPath},
    );

    final response = await _authorizedPostBytes(uri, const []);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      operationMessage = 'Renamed "${item.name}" to "$trimmed".';
      await _invalidateDirectory(scope: scope, path: dirPath);
      await reload();
      return true;
    }
    operationMessage =
        'Failed to rename "${item.name}" (${response.statusCode}).';
    notifyListeners();
    return false;
  }

  Future<Uint8List?> loadThumbnailWithRetry(
    ServerFileItem item, {
    int size = 256,
  }) async {
    final cacheKey = _thumbnailCacheKey(item, size: size);
    return _cacheService.getRemoteThumbnail(
      serverId: serverId,
      cacheKey: cacheKey,
      fetch: () => _loadThumbnailFromServer(item, size: size),
    );
  }

  Future<Uint8List?> _loadThumbnailFromServer(
    ServerFileItem item, {
    required int size,
  }) async {
    final uri = resolveThumbnailUrl(item, size: size);
    const delays = [
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
    ];
    for (var i = 0; i <= delays.length; i++) {
      final response = await _authorizedGet(uri);
      if (response.statusCode == 200) return response.bodyBytes;
      if (response.statusCode != 202 || i == delays.length) break;
      await Future<void>.delayed(delays[i]);
    }
    return null;
  }

  String _directoryCacheKey({required String path}) {
    return jsonEncode({
      'serverId': serverId,
      'scope': scope,
      'path': path,
      'selectedType': selectedType,
      'searchQuery': searchQuery,
      'sort': sortBy.name,
      'order': sortAscending ? 'asc' : 'desc',
      'showHiddenFiles': _showHiddenFiles,
    });
  }

  String _thumbnailCacheKey(ServerFileItem item, {required int size}) {
    return jsonEncode({
      'serverId': serverId,
      'scope': scope,
      'path': item.path,
      'modifiedAt': item.modifiedAt.toUtc().millisecondsSinceEpoch,
      'size': size,
    });
  }

  Future<void> _invalidateDirectory({
    required String scope,
    required String path,
  }) {
    return _cacheService.invalidateDirectory(
      serverId: serverId,
      scope: scope,
      path: path,
    );
  }

  String _parentPath(String path) {
    final normalized = p.dirname(path);
    return normalized == '.' ? '' : normalized;
  }

  Uri _baseUri(String path) =>
      UrlUtils.buildEndpoint(profile.connectionUrl, path);

  Uri _apiUri(String endpointPath) =>
      UrlUtils.buildApiEndpoint(profile.connectionUrl, endpointPath);

  Future<List<ServerFileItem>> _listDirAt(String relativePath) async {
    final uri = _apiUri(
      '/dir',
    ).replace(queryParameters: {'scope': scope, 'path': relativePath});
    final response = await _authorizedGet(
      uri,
      headers: {'Accept': 'application/x-protobuf'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/x-protobuf')) {
      final protoResponse = DirResponse.fromBuffer(response.bodyBytes);
      return protoResponse.entries
          .map(
            (e) => ServerFileItem(
              name: e.name,
              size: e.size.toInt(),
              modifiedAt: DateTime.fromMillisecondsSinceEpoch(
                e.modifiedAt.toInt(),
                isUtc: true,
              ),
              type: e.type,
              mimeType: e.mimeType,
              thumbnailUrl: e.thumbnailUrl.isEmpty ? null : e.thumbnailUrl,
              isDir: e.isDir,
              path: e.path,
            ),
          )
          .toList();
    }
    final payload = jsonDecode(response.body) as Map<String, Object?>;
    final entries = (payload['entries'] as List?) ?? const [];
    return entries
        .whereType<Map>()
        .map((e) => ServerFileItem.fromJson(Map<String, Object?>.from(e)))
        .toList();
  }

  Future<List<ServerFileItem>> _listDirAtScope(
    String relativePath,
    String requestedScope,
  ) async {
    final uri = _apiUri(
      '/dir',
    ).replace(queryParameters: {'scope': requestedScope, 'path': relativePath});
    final response = await _authorizedGet(
      uri,
      headers: {'Accept': 'application/x-protobuf'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/x-protobuf')) {
      final protoResponse = DirResponse.fromBuffer(response.bodyBytes);
      return protoResponse.entries
          .map(
            (e) => ServerFileItem(
              name: e.name,
              size: e.size.toInt(),
              modifiedAt: DateTime.fromMillisecondsSinceEpoch(
                e.modifiedAt.toInt(),
                isUtc: true,
              ),
              type: e.type,
              mimeType: e.mimeType,
              thumbnailUrl: e.thumbnailUrl.isEmpty ? null : e.thumbnailUrl,
              isDir: e.isDir,
              path: e.path,
            ),
          )
          .toList();
    }
    final payload = jsonDecode(response.body) as Map<String, Object?>;
    final entries = (payload['entries'] as List?) ?? const [];
    return entries
        .whereType<Map>()
        .map((e) => ServerFileItem.fromJson(Map<String, Object?>.from(e)))
        .toList();
  }

  Future<Directory> _downloadRoot() async {
    final configuredPath = await _settingsService.downloadDirectoryPath();
    if (configuredPath != null) {
      final configuredDir = Directory(configuredPath);
      await configuredDir.create(recursive: true);
      return configuredDir;
    }
    final external = await getExternalStorageDirectory();
    Directory baseDir;
    if (external != null) {
      final parts = p.split(external.path);
      final androidIndex = parts.indexOf('Android');
      if (androidIndex > 0) {
        baseDir = Directory(p.joinAll(parts.take(androidIndex)));
      } else {
        baseDir = external;
      }
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final dir = Directory(p.join(baseDir.path, 'CrowleysCloud'));
    await dir.create(recursive: true);
    return dir;
  }

  @visibleForTesting
  Future<Directory> downloadRootForTest() => _downloadRoot();

  List<ServerFileItem> _filterHiddenEntries(List<ServerFileItem> entries) {
    if (_showHiddenFiles) return entries;
    return entries
        .where((item) => !p.basename(item.path).startsWith('.'))
        .toList(growable: false);
  }

  Future<bool> _downloadSingleFile(
    ServerFileItem item,
    String targetPath, {
    TransferItem? transferItem,
  }) async {
    final uri = _apiUri(
      '/files',
    ).replace(queryParameters: {'scope': scope, 'path': item.path});
    if (transferItem != null) {
      transferManager?.throwIfItemCanceled(transferItem);
      transferManager?.startItem(transferItem);
    }
    final response = await _authorizedStreamedGet(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (transferItem != null) {
        transferManager?.failItem(transferItem, 'HTTP ${response.statusCode}');
      }
      return false;
    }
    final file = File(targetPath);
    try {
      await file.parent.create(recursive: true);
      final sink = file.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        transferManager?.throwIfCanceled();
        if (transferItem != null) {
          transferManager?.throwIfItemCanceled(transferItem);
        }
        await transferManager?.waitIfPaused();
        if (transferItem != null) {
          transferManager?.throwIfItemCanceled(transferItem);
        }
        sink.add(chunk);
        received += chunk.length;
        if (transferItem != null) {
          transferManager?.updateItem(transferItem, received);
        }
      }
      await sink.flush();
      await sink.close();
      if (transferItem != null) {
        transferManager?.throwIfItemCanceled(transferItem);
      }
      if (transferItem != null) transferManager?.completeItem(transferItem);
      return true;
    } on TransferItemCanceledException {
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      rethrow;
    } on TransferCanceledException {
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      rethrow;
    } catch (_) {
      if (transferItem != null) {
        transferManager?.failItem(transferItem, 'Download failed');
      }
      return false;
    }
  }

  Future<bool> _collectDownloadPlans(
    ServerFileItem item,
    Directory root,
    List<_DownloadPlan> plans,
  ) async {
    if (!item.isDir) {
      plans.add(
        _DownloadPlan(item: item, targetPath: p.join(root.path, item.path)),
      );
      return true;
    }
    final folderTarget = Directory(p.join(root.path, item.path));
    try {
      await folderTarget.create(recursive: true);
    } catch (_) {
      return false;
    }
    var allOk = true;
    final children = await _listDirAt(item.path);
    for (final child in children) {
      final ok = await _collectDownloadPlans(child, root, plans);
      allOk = allOk && ok;
    }
    return allOk;
  }

  Future<bool> _copyItemWithinScope({
    required ServerFileItem item,
    required String sourceScope,
    required String targetPath,
  }) async {
    if (item.isDir) {
      final createFolderUri = _apiUri(
        '/folders',
      ).replace(queryParameters: {'scope': sourceScope, 'path': targetPath});
      final createFolderResponse = await _authorizedPostBytes(
        createFolderUri,
        const [],
      );
      if (createFolderResponse.statusCode < 200 ||
          createFolderResponse.statusCode >= 300) {
        return false;
      }
      final children = await _listDirAtScope(item.path, sourceScope);
      var allOk = true;
      for (final child in children) {
        final childTargetPath = p.join(targetPath, p.basename(child.path));
        final ok = await _copyItemWithinScope(
          item: child,
          sourceScope: sourceScope,
          targetPath: childTargetPath,
        );
        allOk = allOk && ok;
      }
      return allOk;
    }

    final downloadUri = _apiUri(
      '/files',
    ).replace(queryParameters: {'scope': sourceScope, 'path': item.path});
    final downloadResponse = await _authorizedGet(downloadUri);
    if (downloadResponse.statusCode < 200 ||
        downloadResponse.statusCode >= 300) {
      return false;
    }

    final uploadUri = _apiUri(
      '/files',
    ).replace(queryParameters: {'scope': sourceScope, 'path': targetPath});
    final uploadResponse = await _authorizedPostBytes(
      uploadUri,
      downloadResponse.bodyBytes,
    );
    return uploadResponse.statusCode >= 200 && uploadResponse.statusCode < 300;
  }

  Uri _publicShareUri(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Uri.parse(trimmed);
    }
    if (trimmed.startsWith('/')) {
      final raw = profile.connectionUrl.trim();
      final withScheme = raw.contains('://') ? raw : 'http://$raw';
      final base = Uri.parse(withScheme);
      var prefix = base.path;
      if (prefix.isEmpty) prefix = '/';
      if (prefix.endsWith('/')) {
        prefix = prefix.substring(0, prefix.length - 1);
      }
      final publicPath = prefix == '/' ? trimmed : '$prefix$trimmed';
      return base.replace(path: publicPath, query: null, fragment: null);
    }
    return _baseUri(trimmed);
  }

  late final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient(
    authService: authService,
    serverId: serverId,
    baseUrl: profile.connectionUrl,
    client: _client,
    onConnectionLost: onConnectionLost,
  );

  Future<http.Response> _authorizedGet(
    Uri uri, {
    Map<String, String>? headers,
  }) => _httpClient.get(uri, headers: headers);

  Future<http.StreamedResponse> _authorizedStreamedGet(Uri uri) =>
      _httpClient.streamedGet(uri);

  Future<http.Response> _authorizedDelete(Uri uri) => _httpClient.delete(uri);

  Future<http.Response> _authorizedPostJson(
    Uri uri,
    Map<String, Object?> payload,
  ) => _httpClient.postJson(uri, payload);

  Future<http.Response> _authorizedPostBytes(Uri uri, List<int> body) =>
      _httpClient.postBytes(uri, body);
}

class _DownloadPlan {
  _DownloadPlan({required this.item, required this.targetPath});

  final ServerFileItem item;
  final String targetPath;
  TransferItem? transferItem;
}

bool isEditableType(String mimeType, String extension) {
  const editableExt = {'.docx', '.xlsx', '.pptx', '.odt', '.ods', '.odp'};
  if (editableExt.contains(extension)) return true;
  return mimeType ==
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
      mimeType ==
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ||
      mimeType ==
          'application/vnd.openxmlformats-officedocument.presentationml.presentation';
}

bool isViewableType(String type) {
  return type == 'photo' ||
      type == 'video' ||
      type == 'audio' ||
      type == 'document';
}
