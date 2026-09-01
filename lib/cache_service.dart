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
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Multi-tier caching engine managing RAM LRU thumbnail bytes (500 items max),
/// disk directory metadata JSON cache, disk thumbnail images, debounced manifest disk flushes (500ms),
/// and total cache size eviction policies.
class CacheService {
  CacheService._();

  static final CacheService instance = CacheService._();

  static const metadataTtlMinutesKey = 'cache.metadataTtlMinutes';
  static const metadataRetainDaysKey = 'cache.metadataRetainDays';
  static const thumbnailMaxBytesKey = 'cache.thumbnailMaxBytes';
  static const localThumbnailMaxBytesKey = 'cache.localThumbnailMaxBytes';

  static const defaultMetadataTtl = Duration(minutes: 5);
  static const defaultMetadataRetain = Duration(days: 14);
  static const defaultThumbnailMaxBytes = 256 * 1024 * 1024;

  final Map<String, Future<Uint8List?>> _thumbnailInFlight = {};
  final Set<String> _localThumbnailDirs = {};

  /// In-memory LRU cache for decoded thumbnail bytes (local & remote)
  /// to eliminate redundant disk reads and future recreation during scrolling.
  final Map<String, Uint8List> _memoryThumbnailCache = {};
  final List<String> _memoryThumbnailOrder = [];
  final Map<String, String> _filePathToMemoryKey = {};
  static const int _maxMemoryThumbnailCount = 500;

  /// Returns cached thumbnail bytes from RAM synchronously if available.
  Uint8List? getMemoryThumbnail(String key) {
    final cached = _memoryThumbnailCache[key];
    if (cached != null) {
      _memoryThumbnailOrder.remove(key);
      _memoryThumbnailOrder.add(key);
      return cached;
    }
    return null;
  }

  /// Saves thumbnail bytes in RAM cache with LRU eviction and optional file path mapping.
  void putMemoryThumbnail(String key, Uint8List bytes, {String? filePath}) {
    if (_memoryThumbnailCache.containsKey(key)) {
      _memoryThumbnailOrder.remove(key);
    } else if (_memoryThumbnailOrder.length >= _maxMemoryThumbnailCount) {
      final oldest = _memoryThumbnailOrder.removeAt(0);
      _memoryThumbnailCache.remove(oldest);
      _filePathToMemoryKey.removeWhere((_, v) => v == oldest);
    }
    _memoryThumbnailCache[key] = bytes;
    _memoryThumbnailOrder.add(key);
    if (filePath != null) {
      _filePathToMemoryKey[filePath] = key;
    }
  }

  /// Invalidates RAM cache entry if its underlying disk file is evicted/deleted.
  void invalidateMemoryThumbnailForPath(String filePath) {
    final key = _filePathToMemoryKey.remove(filePath);
    if (key != null) {
      _memoryThumbnailCache.remove(key);
      _memoryThumbnailOrder.remove(key);
    }
  }

  /// Unified entry point for thumbnail requests with in-memory caching and deduplication.
  Future<Uint8List?> getThumbnail({
    required String cacheKey,
    required Future<Uint8List?> Function() fetch,
  }) {
    final mem = getMemoryThumbnail(cacheKey);
    if (mem != null) return Future.value(mem);

    return _thumbnailInFlight.putIfAbsent(cacheKey, () async {
      try {
        final data = await fetch();
        if (data != null) {
          putMemoryThumbnail(cacheKey, data);
        }
        return data;
      } finally {
        _thumbnailInFlight.remove(cacheKey);
      }
    });
  }

  Directory? _metadataDir;
  Directory? _remoteThumbnailDir;
  File? _manifestFile;
  SharedPreferences? _prefs;
  bool _isReady = false;
  bool _manifestDirty = false;
  Timer? _manifestFlushTimer;

  bool get isReady => _isReady;

  void registerLocalThumbnailDirectory(Directory directory) {
    _localThumbnailDirs.add(directory.path);
    unawaited(evictThumbnails());
  }

  Future<void> init({
    Directory? supportDir,
    Directory? tempDir,
    SharedPreferences? prefs,
  }) async {
    // Flush dirty manifest before re-initialization if already initialized
    if (_manifestDirty && _manifestFile != null) {
      await flushManifest(immediate: true);
    }
    _manifestFlushTimer?.cancel();
    _manifestFlushTimer = null;
    _cachedManifestEntries = null;
    _manifestDirty = false;
    _isReady = false;
    _memoryThumbnailCache.clear();
    _memoryThumbnailOrder.clear();
    _filePathToMemoryKey.clear();

    _prefs = prefs ?? await SharedPreferences.getInstance();
    await _ensureDefaultPreferences(_prefs!);

    final support = supportDir ?? await getApplicationSupportDirectory();
    final temp = tempDir ?? await getTemporaryDirectory();
    final root = Directory(p.join(support.path, 'cache'));
    _metadataDir = Directory(p.join(root.path, 'metadata'));
    _remoteThumbnailDir = Directory(
      p.join(temp.path, 'crowleys_cloud_cache', 'remote_thumbnails'),
    );
    _manifestFile = File(p.join(root.path, 'manifest.json'));

    await _metadataDir!.create(recursive: true);
    await _remoteThumbnailDir!.create(recursive: true);
    await _manifestFile!.parent.create(recursive: true);
    await _manifestEntries();
    _isReady = true;
  }

  void _scheduleManifestFlush() {
    _manifestFlushTimer ??= Timer(const Duration(milliseconds: 500), () {
      _manifestFlushTimer = null;
      unawaited(flushManifest(immediate: true));
    });
  }

  Future<void> flushManifest({bool immediate = false}) async {
    if (!immediate) {
      _scheduleManifestFlush();
      return;
    }
    _manifestFlushTimer?.cancel();
    _manifestFlushTimer = null;
    if (!_manifestDirty) return;

    final file = _manifestFile;
    if (file == null) return;
    try {
      final entries = _cachedManifestEntries ?? <_CacheManifestEntry>[];
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'entries': entries.map((e) => e.toJson()).toList(growable: false),
        }),
        flush: true,
      );
      _manifestDirty = false;
    } catch (_) {}
  }

  void dispose() {
    _manifestFlushTimer?.cancel();
    _manifestFlushTimer = null;
    if (_manifestDirty) {
      unawaited(flushManifest(immediate: true));
    }
  }

  Future<CachedDirectoryListing?> readDirectory({
    required String serverId,
    required String cacheKey,
  }) async {
    if (!_isReady || _metadataDir == null) return null;
    final file = _metadataFile(serverId, cacheKey);
    if (!await file.exists()) return null;

    try {
      final payload =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(
        (payload['cached_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      );
      final entries = ((payload['entries'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => ServerFileItem.fromJson(Map<String, Object?>.from(e)))
          .toList(growable: false);
      await _touch(file, CacheKind.metadata, serverId, isRead: true);
      return CachedDirectoryListing(
        entries: entries,
        cachedAt: cachedAt,
        isStale: DateTime.now().toUtc().difference(cachedAt) > _metadataTtl,
      );
    } catch (_) {
      await _deleteQuietly(file);
      return null;
    }
  }

  Future<void> writeDirectory({
    required String serverId,
    required String cacheKey,
    required String scope,
    required String path,
    required List<ServerFileItem> entries,
  }) async {
    if (!_isReady || _metadataDir == null) return;
    final file = _metadataFile(serverId, cacheKey);
    final now = DateTime.now().toUtc();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'server_id': serverId,
        'cache_key': cacheKey,
        'scope': scope,
        'path': path,
        'cached_at': now.millisecondsSinceEpoch,
        'entries': entries.map((e) => e.toJson()).toList(growable: false),
      }),
      flush: true,
    );
    await _touch(file, CacheKind.metadata, serverId);
    await _evictExpiredMetadata();
  }

  Future<void> invalidateDirectory({
    required String serverId,
    String? scope,
    String? path,
  }) async {
    if (!_isReady || _metadataDir == null) return;
    final root = Directory(p.join(_metadataDir!.path, serverId));
    if (!await root.exists()) return;

    await for (final entity in root.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      if (scope == null && path == null) {
        await _deleteQuietly(entity);
        continue;
      }
      try {
        final payload =
            jsonDecode(await entity.readAsString()) as Map<String, Object?>;
        final cachedScope = payload['scope'] as String?;
        final cachedPath = (payload['path'] as String?) ?? '';
        final matchesScope = scope == null || cachedScope == scope;
        final matchesPath =
            path == null ||
            cachedPath == path ||
            cachedPath.startsWith('$path/');
        if (matchesScope && matchesPath) await _deleteQuietly(entity);
      } catch (_) {
        await _deleteQuietly(entity);
      }
    }
  }

  /// Retrieves the stored ETag for a cached remote thumbnail, or null if not cached.
  Future<String?> getThumbnailEtag({
    required String serverId,
    required String cacheKey,
  }) async {
    if (!_isReady || _remoteThumbnailDir == null) return null;
    final file = _remoteThumbnailFile(serverId, cacheKey);
    final entries = await _manifestEntries();
    final idx = entries.indexWhere((e) => e.path == file.path);
    if (idx >= 0) {
      return entries[idx].etag;
    }
    return null;
  }

  Future<Uint8List?> getRemoteThumbnail({
    required String serverId,
    required String cacheKey,
    required Function fetch,
  }) {
    final inFlightKey = '$serverId:$cacheKey';
    final mem = getMemoryThumbnail(inFlightKey);
    if (mem != null) return Future.value(mem);

    if (!_isReady || _remoteThumbnailDir == null) {
      return _invokeFetch(fetch, null).then((rawResult) {
        if (rawResult is ThumbnailFetchResult) return rawResult.bytes;
        if (rawResult is Uint8List) return rawResult;
        if (rawResult is List<int>) return Uint8List.fromList(rawResult);
        return null;
      });
    }

    return _thumbnailInFlight.putIfAbsent(inFlightKey, () async {
      try {
        final file = _remoteThumbnailFile(serverId, cacheKey);
        final fileExists = await file.exists();
        String? storedEtag;
        if (fileExists) {
          final entries = await _manifestEntries();
          final idx = entries.indexWhere((e) => e.path == file.path);
          if (idx >= 0) {
            storedEtag = entries[idx].etag;
          }
        }

        final dynamic rawResult = await _invokeFetch(fetch, storedEtag);

        if (rawResult is ThumbnailFetchResult) {
          if (rawResult.isNotModified) {
            // HTTP 304: Retain cached file on disk, update lastAccess & etag
            if (fileExists) {
              await _touch(
                file,
                CacheKind.remoteThumbnail,
                serverId,
                isRead: true,
                etag: rawResult.etag ?? storedEtag,
              );
              final bytes = await file.readAsBytes();
              putMemoryThumbnail(inFlightKey, bytes, filePath: file.path);
              return bytes;
            }
            return null;
          }

          final data = rawResult.bytes;
          if (data != null) {
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data, flush: true);
            await _touch(
              file,
              CacheKind.remoteThumbnail,
              serverId,
              etag: rawResult.etag,
            );
            await evictThumbnails();
            putMemoryThumbnail(inFlightKey, data, filePath: file.path);
            return data;
          }
        } else if (rawResult is Uint8List || rawResult is List<int>) {
          final data = rawResult is Uint8List
              ? rawResult
              : Uint8List.fromList(rawResult as List<int>);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data, flush: true);
          await _touch(file, CacheKind.remoteThumbnail, serverId);
          await evictThumbnails();
          putMemoryThumbnail(inFlightKey, data, filePath: file.path);
          return data;
        }

        // Offline fallback: if fetch failed but file exists on disk, return cached file
        if (fileExists) {
          try {
            final bytes = await file.readAsBytes();
            putMemoryThumbnail(inFlightKey, bytes, filePath: file.path);
            return bytes;
          } catch (_) {}
        }

        return null;
      } finally {
        _thumbnailInFlight.remove(inFlightKey);
      }
    });
  }

  static Future<dynamic> _invokeFetch(Function fetch, String? etag) async {
    if (fetch is FutureOr<dynamic> Function(String?)) {
      return await fetch(etag);
    } else if (fetch is FutureOr<dynamic> Function()) {
      return await fetch();
    } else {
      try {
        return await (fetch as dynamic)(etag);
      } catch (_) {
        return await (fetch as dynamic)();
      }
    }
  }

  Future<void> deleteServer(String serverId) async {
    if (!_isReady) return;
    for (final root in [_metadataDir, _remoteThumbnailDir]) {
      if (root == null) continue;
      final dir = Directory(p.join(root.path, serverId));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
    await _removeManifestEntriesForServer(serverId);
  }

  Future<void> evictThumbnails() async {
    if (!_isReady || _remoteThumbnailDir == null) return;
    final maxBytes =
        _prefs?.getInt(thumbnailMaxBytesKey) ?? defaultThumbnailMaxBytes;
    if (maxBytes < 0) return;
    final remoteEntries = await _manifestEntries(
      kind: CacheKind.remoteThumbnail,
    );
    final localEntries = await _localThumbnailEntries();
    final allEntries = [...remoteEntries, ...localEntries];
    var total = allEntries.fold<int>(0, (sum, e) => sum + e.size);
    if (total <= maxBytes) return;

    allEntries.sort((a, b) => a.lastAccess.compareTo(b.lastAccess));

    for (final entry in allEntries) {
      if (total <= maxBytes) break;
      final file = File(entry.path);
      if (await file.exists()) {
        await _deleteQuietly(file);
      }
      total -= entry.size;
    }
  }

  Future<int> cacheSizeBytes() async {
    if (!_isReady) return 0;
    final entries = await _manifestEntries();
    final manifestTotal = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.size,
    );
    final localEntries = await _localThumbnailEntries();
    return manifestTotal +
        localEntries.fold<int>(0, (sum, entry) => sum + entry.size);
  }

  Future<void> clearAll() async {
    _memoryThumbnailCache.clear();
    _memoryThumbnailOrder.clear();
    _filePathToMemoryKey.clear();
    if (!_isReady) return;
    for (final root in [_metadataDir, _remoteThumbnailDir]) {
      if (root == null || !await root.exists()) continue;
      await root.delete(recursive: true);
      await root.create(recursive: true);
    }
    for (final path in _localThumbnailDirs) {
      final root = Directory(path);
      if (!await root.exists()) continue;
      await for (final entity in root.list(recursive: true)) {
        if (entity is File) await _deleteQuietly(entity);
      }
    }
    await _writeManifestEntries(const [], immediate: true);
  }

  Future<void> setThumbnailMaxBytes(int value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setInt(thumbnailMaxBytesKey, value);
    await evictThumbnails();
  }

  Future<void> _ensureDefaultPreferences(SharedPreferences prefs) async {
    if (!prefs.containsKey(metadataTtlMinutesKey)) {
      await prefs.setInt(metadataTtlMinutesKey, defaultMetadataTtl.inMinutes);
    }
    if (!prefs.containsKey(metadataRetainDaysKey)) {
      await prefs.setInt(metadataRetainDaysKey, defaultMetadataRetain.inDays);
    }
    if (!prefs.containsKey(thumbnailMaxBytesKey)) {
      await prefs.setInt(thumbnailMaxBytesKey, defaultThumbnailMaxBytes);
    }
    if (!prefs.containsKey(localThumbnailMaxBytesKey)) {
      await prefs.setInt(localThumbnailMaxBytesKey, defaultThumbnailMaxBytes);
    }
  }

  Duration get _metadataTtl => Duration(
    minutes:
        _prefs?.getInt(metadataTtlMinutesKey) ?? defaultMetadataTtl.inMinutes,
  );

  Duration get _metadataRetain => Duration(
    days: _prefs?.getInt(metadataRetainDaysKey) ?? defaultMetadataRetain.inDays,
  );

  File _metadataFile(String serverId, String cacheKey) {
    final hash = _hash(cacheKey);
    return File(p.join(_metadataDir!.path, serverId, '$hash.json'));
  }

  File _remoteThumbnailFile(String serverId, String cacheKey) {
    final hash = _hash(cacheKey);
    return File(p.join(_remoteThumbnailDir!.path, serverId, hash));
  }

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();

  List<_CacheManifestEntry>? _cachedManifestEntries;

  Future<void> _writeManifestEntries(
    List<_CacheManifestEntry> entries, {
    bool immediate = false,
  }) async {
    _cachedManifestEntries = entries;
    _manifestDirty = true;
    if (immediate) {
      await flushManifest(immediate: true);
    } else {
      _scheduleManifestFlush();
    }
  }

  Future<List<_CacheManifestEntry>> _manifestEntries({CacheKind? kind}) async {
    if (_cachedManifestEntries == null) {
      final file = _manifestFile;
      if (file == null || !await file.exists()) {
        _cachedManifestEntries = <_CacheManifestEntry>[];
      } else {
        try {
          final decoded = jsonDecode(await file.readAsString());
          if (decoded is Map<String, Object?> && decoded['entries'] is List) {
            _cachedManifestEntries = (decoded['entries'] as List)
                .whereType<Map>()
                .map(
                  (e) => _CacheManifestEntry.fromJson(
                    Map<String, Object?>.from(e),
                  ),
                )
                .toList(growable: true);
          } else {
            _cachedManifestEntries = <_CacheManifestEntry>[];
          }
        } catch (_) {
          await flushManifest(immediate: true);
          await _rebuildManifest();
        }
      }
    }

    final entries = _cachedManifestEntries!;
    if (kind == null) return List.from(entries);
    return entries.where((e) => e.kind == kind).toList(growable: true);
  }

  Future<void> _touch(
    File file,
    CacheKind kind,
    String serverId, {
    bool isRead = false,
    String? etag,
  }) async {
    final now = DateTime.now().toUtc();
    final entries = await _manifestEntries();
    final path = file.path;
    final index = entries.indexWhere((e) => e.path == path);
    if (index >= 0) {
      final existing = entries[index];
      final updatedEtag = etag ?? existing.etag;
      // For read hits with unchanged etag, if the last access was less than 1 hour ago, update in memory only.
      if (isRead &&
          etag == null &&
          now.difference(existing.lastAccess) < const Duration(hours: 1)) {
        entries[index] = existing.copyWith(
          lastAccess: now,
          updatedAt: now,
        );
        return;
      }
      entries[index] = existing.copyWith(
        lastAccess: now,
        updatedAt: now,
        etag: updatedEtag,
      );
    } else {
      final stat = await file.stat();
      entries.add(
        _CacheManifestEntry(
          path: path,
          serverId: serverId,
          kind: kind,
          size: stat.size,
          createdAt: now,
          updatedAt: now,
          lastAccess: now,
          etag: etag,
        ),
      );
    }
    await _writeManifestEntries(entries);
  }

  Future<void> _removeManifestEntriesForServer(String serverId) async {
    final entries = await _manifestEntries();
    entries.removeWhere((e) => e.serverId == serverId);
    await _writeManifestEntries(entries);
  }

  Future<void> _evictExpiredMetadata() async {
    final retain = _metadataRetain;
    final now = DateTime.now().toUtc();
    final entries = await _manifestEntries();
    final retained = <_CacheManifestEntry>[];
    for (final entry in entries) {
      if (entry.kind == CacheKind.metadata &&
          now.difference(entry.lastAccess) > retain) {
        await _deleteQuietly(File(entry.path));
      } else {
        retained.add(entry);
      }
    }
    await _writeManifestEntries(retained);
  }

  Future<List<_CacheManifestEntry>> _localThumbnailEntries() async {
    final entries = <_CacheManifestEntry>[];
    for (final path in _localThumbnailDirs) {
      final root = Directory(path);
      if (!await root.exists()) continue;
      await for (final entity in root.list(recursive: true)) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        entries.add(
          _CacheManifestEntry(
            path: entity.path,
            serverId: '',
            kind: CacheKind.localThumbnail,
            size: stat.size,
            createdAt: stat.changed.toUtc(),
            updatedAt: stat.modified.toUtc(),
            lastAccess: stat.accessed.toUtc(),
          ),
        );
      }
    }
    return entries;
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
    invalidateMemoryThumbnailForPath(file.path);
    final entries = await _manifestEntries();
    final lenBefore = entries.length;
    entries.removeWhere((e) => e.path == file.path);
    if (entries.length != lenBefore) {
      await _writeManifestEntries(entries);
    }
  }

  Future<void> _rebuildManifest() async {
    final entries = <_CacheManifestEntry>[];
    for (final tuple in [
      (_metadataDir, CacheKind.metadata),
      (_remoteThumbnailDir, CacheKind.remoteThumbnail),
    ]) {
      final root = tuple.$1;
      final kind = tuple.$2;
      if (root == null || !await root.exists()) continue;
      await for (final entity in root.list(recursive: true)) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        final segments = p.split(p.relative(entity.path, from: root.path));
        final serverId = segments.isEmpty ? '' : segments.first;
        entries.add(
          _CacheManifestEntry(
            path: entity.path,
            serverId: serverId,
            kind: kind,
            size: stat.size,
            createdAt: stat.changed.toUtc(),
            updatedAt: stat.modified.toUtc(),
            lastAccess: stat.accessed.toUtc(),
          ),
        );
      }
    }
    await _writeManifestEntries(entries, immediate: true);
  }
}

/// Encapsulates the result of a network thumbnail fetch, distinguishing between
/// 200 OK (with byte payload and optional ETag) and 304 Not Modified (with refreshed ETag).
class ThumbnailFetchResult {
  const ThumbnailFetchResult.bytes(Uint8List this.bytes, {this.etag})
      : isNotModified = false;

  const ThumbnailFetchResult.notModified({this.etag})
      : bytes = null,
        isNotModified = true;

  final Uint8List? bytes;
  final String? etag;
  final bool isNotModified;
}

class CachedDirectoryListing {
  const CachedDirectoryListing({
    required this.entries,
    required this.cachedAt,
    required this.isStale,
  });

  final List<ServerFileItem> entries;
  final DateTime cachedAt;
  final bool isStale;
}

enum CacheKind {
  metadata('metadata'),
  remoteThumbnail('remote_thumbnail'),
  localThumbnail('local_thumbnail');

  const CacheKind(this.value);
  final String value;

  static CacheKind fromValue(String value) {
    return CacheKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => CacheKind.metadata,
    );
  }
}

class _CacheManifestEntry {
  const _CacheManifestEntry({
    required this.path,
    required this.serverId,
    required this.kind,
    required this.size,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAccess,
    this.etag,
  });

  final String path;
  final String serverId;
  final CacheKind kind;
  final int size;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastAccess;
  final String? etag;

  _CacheManifestEntry copyWith({
    int? size,
    DateTime? updatedAt,
    DateTime? lastAccess,
    String? etag,
  }) {
    return _CacheManifestEntry(
      path: path,
      serverId: serverId,
      kind: kind,
      size: size ?? this.size,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccess: lastAccess ?? this.lastAccess,
      etag: etag ?? this.etag,
    );
  }

  factory _CacheManifestEntry.fromJson(Map<String, Object?> json) {
    DateTime readTime(String key) => DateTime.fromMillisecondsSinceEpoch(
      (json[key] as num?)?.toInt() ?? 0,
      isUtc: true,
    );

    return _CacheManifestEntry(
      path: (json['path'] ?? '') as String,
      serverId: (json['server_id'] ?? '') as String,
      kind: CacheKind.fromValue((json['kind'] ?? '') as String),
      size: (json['size'] as num?)?.toInt() ?? 0,
      createdAt: readTime('created_at'),
      updatedAt: readTime('updated_at'),
      lastAccess: readTime('last_access'),
      etag: json['etag'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'path': path,
      'server_id': serverId,
      'kind': kind.value,
      'size': size,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'last_access': lastAccess.millisecondsSinceEpoch,
      if (etag != null) 'etag': etag,
    };
  }
}
