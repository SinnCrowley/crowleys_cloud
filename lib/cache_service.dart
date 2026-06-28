import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Directory? _metadataDir;
  Directory? _remoteThumbnailDir;
  File? _manifestFile;
  SharedPreferences? _prefs;
  bool _isReady = false;

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
    await _readManifest();
    _isReady = true;
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
      await _touch(file, CacheKind.metadata, serverId);
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

  Future<Uint8List?> getRemoteThumbnail({
    required String serverId,
    required String cacheKey,
    required Future<Uint8List?> Function() fetch,
  }) {
    if (!_isReady || _remoteThumbnailDir == null) return fetch();
    final inFlightKey = '$serverId:$cacheKey';
    return _thumbnailInFlight.putIfAbsent(inFlightKey, () async {
      try {
        final file = _remoteThumbnailFile(serverId, cacheKey);
        if (await file.exists()) {
          await _touch(file, CacheKind.remoteThumbnail, serverId);
          return file.readAsBytes();
        }

        final data = await fetch();
        if (data == null) return null;
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data, flush: true);
        await _touch(file, CacheKind.remoteThumbnail, serverId);
        await evictThumbnails();
        return data;
      } finally {
        _thumbnailInFlight.remove(inFlightKey);
      }
    });
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
    var total = [
      ...remoteEntries,
      ...localEntries,
    ].fold<int>(0, (sum, e) => sum + e.size);
    if (total <= maxBytes) return;

    remoteEntries.sort((a, b) => a.lastAccess.compareTo(b.lastAccess));
    localEntries.sort((a, b) => a.lastAccess.compareTo(b.lastAccess));

    for (final entry in [...remoteEntries, ...localEntries]) {
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
    await _rebuildManifest();
    final entries = await _manifestEntries();
    final manifestTotal = entries.fold<int>(0, (sum, entry) {
      return sum + (File(entry.path).existsSync() ? entry.size : 0);
    });
    final localEntries = await _localThumbnailEntries();
    return manifestTotal +
        localEntries.fold<int>(0, (sum, entry) => sum + entry.size);
  }

  Future<void> clearAll() async {
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
    await _writeManifestEntries(const []);
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

  Future<Map<String, Object?>> _readManifest() async {
    final file = _manifestFile;
    if (file == null || !await file.exists()) return {'entries': <Object?>[]};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, Object?> && decoded['entries'] is List) {
        return decoded;
      }
    } catch (_) {}
    await _rebuildManifest();
    try {
      return jsonDecode(await file.readAsString()) as Map<String, Object?>;
    } catch (_) {
      return {'entries': <Object?>[]};
    }
  }

  Future<void> _writeManifestEntries(List<_CacheManifestEntry> entries) async {
    final file = _manifestFile;
    if (file == null) return;
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'entries': entries.map((e) => e.toJson()).toList(growable: false),
      }),
      flush: true,
    );
  }

  Future<List<_CacheManifestEntry>> _manifestEntries({CacheKind? kind}) async {
    final manifest = await _readManifest();
    final rawEntries = (manifest['entries'] as List?) ?? const [];
    final entries = rawEntries
        .whereType<Map>()
        .map((e) => _CacheManifestEntry.fromJson(Map<String, Object?>.from(e)))
        .where((e) => kind == null || e.kind == kind)
        .toList(growable: true);
    return entries;
  }

  Future<void> _touch(File file, CacheKind kind, String serverId) async {
    final now = DateTime.now().toUtc();
    final entries = await _manifestEntries();
    final path = file.path;
    final stat = await file.stat();
    final index = entries.indexWhere((e) => e.path == path);
    if (index >= 0) {
      entries[index] = entries[index].copyWith(
        size: stat.size,
        lastAccess: now,
        updatedAt: now,
      );
    } else {
      entries.add(
        _CacheManifestEntry(
          path: path,
          serverId: serverId,
          kind: kind,
          size: stat.size,
          createdAt: now,
          updatedAt: now,
          lastAccess: now,
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
    final entries = await _manifestEntries();
    entries.removeWhere((e) => e.path == file.path);
    await _writeManifestEntries(entries);
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
    await _writeManifestEntries(entries);
  }
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
  });

  final String path;
  final String serverId;
  final CacheKind kind;
  final int size;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastAccess;

  _CacheManifestEntry copyWith({
    int? size,
    DateTime? updatedAt,
    DateTime? lastAccess,
  }) {
    return _CacheManifestEntry(
      path: path,
      serverId: serverId,
      kind: kind,
      size: size ?? this.size,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccess: lastAccess ?? this.lastAccess,
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
    };
  }
}
