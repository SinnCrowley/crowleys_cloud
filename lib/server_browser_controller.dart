import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ServerSortBy { name, date, size, type }

class ServerBrowserController extends ChangeNotifier {
  static const _sortByPrefKey = 'serverSortBy';
  static const _sortAscendingPrefKey = 'serverSortAscending';

  ServerBrowserController({
    required this.profile,
    required this.serverId,
    required this.authService,
    this.onConnectionLost,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    unawaited(initialize());
  }

  final ServerProfile profile;
  final String serverId;
  final AuthService authService;
  final ValueChanged<String>? onConnectionLost;
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

  Timer? _searchDebounce;
  int _opId = 0;

  String get currentPath => pathStack.last;
  bool get canNavigateBack => selectedType == 'all' && pathStack.length > 1;
  bool get isSelectionMode => selectedFiles.isNotEmpty;

  Future<void> initialize() async {
    await _loadSortPreferences();
    await reload();
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

    try {
      final requestPath = selectedType == 'all' ? currentPath : '';
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
          entries.whereType<Map>().map(
            (e) => ServerFileItem.fromJson(Map<String, Object?>.from(e)),
          ),
        );
      if (selectedType != 'all') {
        files.removeWhere((item) => item.isDir);
      }
    } catch (e) {
      if (opId != _opId) return;
      error = e.toString();
    } finally {
      if (opId == _opId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<File?> downloadTempForEdit(ServerFileItem item) async {
    final uri = _apiUri(
      '/files',
    ).replace(queryParameters: {'scope': scope, 'path': item.path});
    final response = await _authorizedGet(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${item.name}');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
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
    var downloaded = 0;
    final failed = <String>[];
    for (final item in selectedFiles.toList()) {
      final ok = await _downloadItemRecursive(item, downloadRoot);
      if (ok) {
        downloaded++;
      } else {
        failed.add(item.name);
      }
    }
    operationMessage = failed.isEmpty
        ? 'Downloaded $downloaded item(s) to ${downloadRoot.path}'
        : 'Downloaded $downloaded item(s), failed ${failed.length}: ${failed.first}';
    selectedFiles.clear();
    notifyListeners();
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
      final ok = await _copyItemToShared(
        item: item,
        sourceScope: scope,
        targetPath: item.path,
      );
      if (ok) {
        shared++;
      } else {
        failed++;
      }
    }

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
      await reload();
      return;
    }
    operationMessage = 'Failed to create folder (${response.statusCode}).';
    notifyListeners();
  }

  Future<List<ServerFileItem>> listFoldersAt(String path) async {
    final entries = await _listDirAtScope(path, scope);
    return entries.where((e) => e.isDir && !e.name.startsWith('.')).toList()
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

  Future<Uint8List?> loadThumbnailWithRetry(
    ServerFileItem item, {
    int size = 256,
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

  Uri _baseUri(String path) {
    final raw = profile.baseUrl.trim();
    final withScheme = raw.contains('://') ? raw : 'http://$raw';
    final base = Uri.parse(withScheme);
    final basePath = base.path.isEmpty
        ? '/'
        : (base.path.endsWith('/') ? base.path : '${base.path}/');
    final normalizedBase = base.replace(path: basePath);
    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    return normalizedBase.resolve(relativePath);
  }

  Uri _apiUri(String endpointPath) {
    final raw = profile.baseUrl.trim();
    final withScheme = raw.contains('://') ? raw : 'http://$raw';
    final base = Uri.parse(withScheme);

    var basePath = base.path;
    if (basePath.isEmpty) basePath = '/';
    if (basePath.endsWith('/')) {
      basePath = basePath.substring(0, basePath.length - 1);
    }

    final endpoint = endpointPath.startsWith('/')
        ? endpointPath
        : '/$endpointPath';
    final hasApiSuffix = basePath == '/api' || basePath.endsWith('/api');
    final apiPath = hasApiSuffix
        ? '$basePath$endpoint'
        : '$basePath/api$endpoint';
    return base.replace(path: apiPath, query: null, fragment: null);
  }

  Future<List<ServerFileItem>> _listDirAt(String relativePath) async {
    final uri = _apiUri(
      '/dir',
    ).replace(queryParameters: {'scope': scope, 'path': relativePath});
    final response = await _authorizedGet(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
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
    final response = await _authorizedGet(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }
    final payload = jsonDecode(response.body) as Map<String, Object?>;
    final entries = (payload['entries'] as List?) ?? const [];
    return entries
        .whereType<Map>()
        .map((e) => ServerFileItem.fromJson(Map<String, Object?>.from(e)))
        .toList();
  }

  Future<Directory> _downloadRoot() async {
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

  Future<bool> _downloadItemRecursive(
    ServerFileItem item,
    Directory root,
  ) async {
    if (!item.isDir) {
      return _downloadSingleFile(item, p.join(root.path, item.path));
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
      final ok = await _downloadItemRecursive(child, root);
      allOk = allOk && ok;
    }
    return allOk;
  }

  Future<bool> _downloadSingleFile(
    ServerFileItem item,
    String targetPath,
  ) async {
    final uri = _apiUri(
      '/files',
    ).replace(queryParameters: {'scope': scope, 'path': item.path});
    final response = await _authorizedGet(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) return false;
    final file = File(targetPath);
    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _copyItemToShared({
    required ServerFileItem item,
    required String sourceScope,
    required String targetPath,
  }) async {
    if (item.isDir) {
      final createFolderUri = _apiUri(
        '/folders',
      ).replace(queryParameters: {'scope': 'shared', 'path': targetPath});
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
        final ok = await _copyItemToShared(
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
    ).replace(queryParameters: {'scope': 'shared', 'path': targetPath});
    final uploadResponse = await _authorizedPostBytes(
      uploadUri,
      downloadResponse.bodyBytes,
    );
    return uploadResponse.statusCode >= 200 && uploadResponse.statusCode < 300;
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
      final raw = profile.baseUrl.trim();
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

  Future<http.Response> _authorizedGet(Uri uri) async {
    var token = await authService.readAccessToken(serverId);
    if (token == null || token.isEmpty) return http.Response('', 401);
    var response = await _safeRequest(
      () => _client.get(uri, headers: {'authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 401) return response;

    try {
      await authService.refreshSession(
        serverId: serverId,
        baseUrl: profile.baseUrl,
      );
      token = await authService.readAccessToken(serverId);
      if (token == null || token.isEmpty) return response;
      response = await _safeRequest(
        () => _client.get(uri, headers: {'authorization': 'Bearer $token'}),
      );
    } catch (_) {}
    return response;
  }

  Future<http.Response> _authorizedDelete(Uri uri) async {
    var token = await authService.readAccessToken(serverId);
    if (token == null || token.isEmpty) return http.Response('', 401);
    var response = await _safeRequest(
      () => _client.delete(uri, headers: {'authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 401) return response;

    try {
      await authService.refreshSession(
        serverId: serverId,
        baseUrl: profile.baseUrl,
      );
      token = await authService.readAccessToken(serverId);
      if (token == null || token.isEmpty) return response;
      response = await _safeRequest(
        () => _client.delete(uri, headers: {'authorization': 'Bearer $token'}),
      );
    } catch (_) {}
    return response;
  }

  Future<http.Response> _authorizedPostJson(
    Uri uri,
    Map<String, Object?> payload,
  ) async {
    var token = await authService.readAccessToken(serverId);
    if (token == null || token.isEmpty) return http.Response('', 401);
    var response = await _safeRequest(
      () => _client.post(
        uri,
        headers: {
          'authorization': 'Bearer $token',
          'content-type': 'application/json',
        },
        body: jsonEncode(payload),
      ),
    );
    if (response.statusCode != 401) return response;

    try {
      await authService.refreshSession(
        serverId: serverId,
        baseUrl: profile.baseUrl,
      );
      token = await authService.readAccessToken(serverId);
      if (token == null || token.isEmpty) return response;
      response = await _safeRequest(
        () => _client.post(
          uri,
          headers: {
            'authorization': 'Bearer $token',
            'content-type': 'application/json',
          },
          body: jsonEncode(payload),
        ),
      );
    } catch (_) {}
    return response;
  }

  Future<http.Response> _authorizedPostBytes(Uri uri, List<int> body) async {
    var token = await authService.readAccessToken(serverId);
    if (token == null || token.isEmpty) return http.Response('', 401);
    var response = await _safeRequest(
      () => _client.post(
        uri,
        headers: {
          'authorization': 'Bearer $token',
          'content-type': 'application/octet-stream',
        },
        body: body,
      ),
    );
    if (response.statusCode != 401) return response;

    try {
      await authService.refreshSession(
        serverId: serverId,
        baseUrl: profile.baseUrl,
      );
      token = await authService.readAccessToken(serverId);
      if (token == null || token.isEmpty) return response;
      response = await _safeRequest(
        () => _client.post(
          uri,
          headers: {
            'authorization': 'Bearer $token',
            'content-type': 'application/octet-stream',
          },
          body: body,
        ),
      );
    } catch (_) {}
    return response;
  }

  Future<http.Response> _safeRequest(
    Future<http.Response> Function() send,
  ) async {
    try {
      final response = await send();
      if (_isConnectionUnavailableStatus(response.statusCode)) {
        _notifyConnectionLost('Server is unreachable.');
      }
      return response;
    } on SocketException {
      _notifyConnectionLost('Server is unreachable.');
      return http.Response('', 503);
    } on HandshakeException {
      _notifyConnectionLost('Server is unreachable.');
      return http.Response('', 503);
    } on HttpException {
      _notifyConnectionLost('Server is unreachable.');
      return http.Response('', 503);
    } on http.ClientException {
      _notifyConnectionLost('Server is unreachable.');
      return http.Response('', 503);
    } on TimeoutException {
      _notifyConnectionLost('Server is unreachable.');
      return http.Response('', 503);
    }
  }

  bool _isConnectionUnavailableStatus(int statusCode) {
    return statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  void _notifyConnectionLost(String message) {
    onConnectionLost?.call(message);
  }
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
