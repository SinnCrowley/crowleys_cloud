import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/shared/utils/authenticated_http_client.dart';
import 'package:crowleys_cloud/shared/utils/url_utils.dart';

import 'package:crowleys_cloud/shared/proto/dir_entry.pb.dart';

class TrashBrowserController extends ChangeNotifier {
  TrashBrowserController({
    required this.serverId,
    required this.baseUrl,
    required this.authService,
    CacheService? cacheService,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _cacheService = cacheService ?? CacheService.instance;

  final String serverId;
  final String baseUrl;
  final AuthService authService;
  final CacheService _cacheService;
  final http.Client _client;

  late final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient(
    authService: authService,
    serverId: serverId,
    baseUrl: baseUrl,
    client: _client,
  );

  bool isLoading = false;
  String? error;
  List<ServerFileItem> files = [];
  final List<ServerFileItem> selectedFiles = [];
  String searchQuery = '';
  String? operationMessage;
  TrashSortBy sortBy = TrashSortBy.date;
  bool sortAscending = false;

  final Map<String, Future<File?>> _downloadsInFlight = {};

  Uri _baseUri(String path) => UrlUtils.buildEndpoint(baseUrl, path);

  Uri _apiUri(String endpointPath) => UrlUtils.buildApiEndpoint(baseUrl, endpointPath);

  Future<http.Response> _authorizedGet(Uri uri, {Map<String, String>? headers}) =>
      _httpClient.get(uri, headers: headers);

  Future<http.Response> _authorizedPostJson(
    Uri uri,
    Map<String, Object?> payload,
  ) =>
      _httpClient.postJson(uri, payload);

  Future<http.Response> _authorizedDeleteJson(
    Uri uri,
    Map<String, Object?> payload,
  ) =>
      _httpClient.deleteJson(uri, payload);

  Future<void> reload() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final queryParams = {'scope': 'private'};
      if (searchQuery.isNotEmpty) {
        queryParams['q'] = searchQuery;
      }
      final uri = _apiUri('/trash').replace(queryParameters: queryParams);
      final response = await _authorizedGet(uri, headers: {'Accept': 'application/x-protobuf'});
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server error ${response.statusCode}');
      }

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('application/x-protobuf')) {
        final protoResponse = DirResponse.fromBuffer(response.bodyBytes);
        files = protoResponse.entries
            .map(
              (e) => ServerFileItem(
                name: e.name,
                size: e.size.toInt(),
                modifiedAt: DateTime.fromMillisecondsSinceEpoch(e.modifiedAt.toInt(), isUtc: true),
                type: e.type,
                mimeType: e.mimeType,
                thumbnailUrl: e.thumbnailUrl.isEmpty ? null : e.thumbnailUrl,
                isDir: e.isDir,
                path: e.path,
                id: e.id != 0 ? e.id.toInt() : null,
              ),
            )
            .toList();
      } else {
        final payload = jsonDecode(response.body) as Map<String, Object?>;
        final entries = (payload['entries'] as List?) ?? const [];
        files = entries
            .whereType<Map>()
            .map((e) => ServerFileItem.fromJson(Map<String, Object?>.from(e)))
            .toList();
      }
      sortFilesInternal();
      operationMessage = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
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

  Future<void> restoreSelected() async {
    if (selectedFiles.isEmpty) return;
    isLoading = true;
    notifyListeners();

    try {
      final ids = selectedFiles.map((f) => f.id).whereType<int>().toList();
      final uri = _apiUri('/trash/restore');
      final response = await _authorizedPostJson(uri, {'ids': ids});
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server error ${response.statusCode}');
      }
      selectedFiles.clear();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      await reload();
    }
  }

  Future<void> deleteSelected() async {
    if (selectedFiles.isEmpty) return;
    isLoading = true;
    notifyListeners();

    try {
      final ids = selectedFiles.map((f) => f.id).whereType<int>().toList();
      final uri = _apiUri('/trash');
      final response = await _authorizedDeleteJson(uri, {'ids': ids});
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server error ${response.statusCode}');
      }
      selectedFiles.clear();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      await reload();
    }
  }

  Uri resolveThumbnailUrl(ServerFileItem item, {int size = 256}) {
    final raw = item.thumbnailUrl;
    if (raw != null && raw.isNotEmpty) {
      final parsed = Uri.parse(raw);
      if (parsed.hasScheme) return parsed;
      return _baseUri(raw);
    }
    return _apiUri(
      '/thumb',
    ).replace(queryParameters: {'trash_id': '${item.id}', 's': '$size'});
  }

  Future<Uint8List?> loadThumbnailWithRetry(
    ServerFileItem item, {
    int size = 256,
  }) async {
    final cacheKey = 'trash_${item.id}_$size';
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

  void sortFilesInternal() {
    files.sort((a, b) {
      int cmp;
      switch (sortBy) {
        case TrashSortBy.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case TrashSortBy.date:
          cmp = a.modifiedAt.compareTo(b.modifiedAt);
          break;
        case TrashSortBy.size:
          cmp = a.size.compareTo(b.size);
          break;
        case TrashSortBy.type:
          cmp = a.type.toLowerCase().compareTo(b.type.toLowerCase());
          break;
      }
      return sortAscending ? cmp : -cmp;
    });
  }

  Future<void> updateSortBy(TrashSortBy newSort) async {
    sortBy = newSort;
    sortFilesInternal();
    notifyListeners();
  }

  Future<void> toggleSortDirection() async {
    sortAscending = !sortAscending;
    sortFilesInternal();
    notifyListeners();
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
        ).replace(queryParameters: {'trash_id': '${item.id}'});
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

  Future<void> updateSearchQuery(String query) async {
    searchQuery = query;
    await reload();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}

enum TrashSortBy { name, date, size, type }
