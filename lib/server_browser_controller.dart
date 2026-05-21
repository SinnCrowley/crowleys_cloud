import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ServerSortBy { name, date, size, type }

class ServerBrowserController extends ChangeNotifier {
  static const _sortByPrefKey = 'serverSortBy';
  static const _sortAscendingPrefKey = 'serverSortAscending';

  ServerBrowserController({
    required this.profile,
    required this.serverId,
    required this.authService,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    unawaited(initialize());
  }

  final ServerProfile profile;
  final String serverId;
  final AuthService authService;
  final http.Client _client;

  final List<ServerFileItem> files = [];
  final List<String> pathStack = [''];
  String selectedType = 'all';
  String searchQuery = '';
  ServerSortBy sortBy = ServerSortBy.name;
  bool sortAscending = true;
  bool isLoading = false;
  String? error;

  Timer? _searchDebounce;
  int _opId = 0;

  String get currentPath => pathStack.last;
  bool get canNavigateBack => pathStack.length > 1;

  Future<void> initialize() async {
    await _loadSortPreferences();
    await reload();
  }

  void disposeController() {
    _searchDebounce?.cancel();
  }

  void setCategory(String type) {
    selectedType = type;
    unawaited(reload());
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
    if (!dir.isDir) return;
    pathStack.add(dir.path);
    await reload();
  }

  Future<void> navigateBack() async {
    if (!canNavigateBack) return;
    pathStack.removeLast();
    await reload();
  }

  Future<void> reload() async {
    _opId++;
    final opId = _opId;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final token = await authService.readAccessToken(serverId);
      if (token == null || token.isEmpty) {
        throw Exception('No access token for server session');
      }

      final uri = _baseUri('/api/dir').replace(
        queryParameters: {
          'scope': 'private',
          'path': currentPath,
          if (searchQuery.isNotEmpty) 'q': searchQuery,
          if (selectedType != 'all') 'type': selectedType,
          'sort': sortBy.name,
          'order': sortAscending ? 'asc' : 'desc',
        },
      );
      final response = await _client.get(
        uri,
        headers: {'authorization': 'Bearer $token'},
      );
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
    final token = await authService.readAccessToken(serverId);
    if (token == null || token.isEmpty) return null;

    final uri = _baseUri(
      '/api/files',
    ).replace(queryParameters: {'scope': 'private', 'path': item.path});
    final response = await _client.get(
      uri,
      headers: {'authorization': 'Bearer $token'},
    );
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
    return _baseUri('/api/thumb').replace(
      queryParameters: {'path': item.path, 's': '$size', 'scope': 'private'},
    );
  }

  Uri streamUri(ServerFileItem item) {
    return _baseUri(
      '/api/files',
    ).replace(queryParameters: {'scope': 'private', 'path': item.path});
  }

  Future<Uint8List?> loadThumbnailWithRetry(
    ServerFileItem item, {
    int size = 256,
  }) async {
    final token = await authService.readAccessToken(serverId);
    if (token == null || token.isEmpty) return null;
    final uri = resolveThumbnailUrl(item, size: size);
    const delays = [
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
    ];
    for (var i = 0; i <= delays.length; i++) {
      final response = await _client.get(
        uri,
        headers: {'authorization': 'Bearer $token'},
      );
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
