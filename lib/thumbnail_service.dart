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
import 'dart:convert';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail_plus/video_thumbnail_plus.dart';
import 'file_item.dart';

class ThumbnailService {
  ThumbnailService._();
  static final instance = ThumbnailService._();

  final Map<String, AssetEntity> _nameIndex = {};
  final Map<String, AssetEntity> _pathIndex = {};

  Directory? _cacheDir;

  // ═══════════════════════════════════════════════════════════════════════════
  // Инициализация
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> init() async {
    try {
      _cacheDir = Directory(
        '${(await getTemporaryDirectory()).path}/thumb_cache',
      );
      await _cacheDir!.create(recursive: true);
      CacheService.instance.registerLocalThumbnailDirectory(_cacheDir!);
    } catch (e) {
      debugPrint('[ThumbnailService] init cache directory failed: $e');
    }

    // Populate name index in background so startup is never blocked
    unawaited(_buildNameIndex());
  }

  Future<void> _buildNameIndex() async {
    try {
      final perm = await PhotoManager.requestPermissionExtend();
      if (!perm.hasAccess) return;

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );
      if (albums.isEmpty) return;

      final allAlbum = albums.firstWhere(
        (a) => a.isAll,
        orElse: () => albums.first,
      );
      final total = await allAlbum.assetCountAsync;

      for (var page = 0; page * 500 < total; page++) {
        final assets = await allAlbum.getAssetListPaged(page: page, size: 500);
        for (final asset in assets) {
          final key = (asset.title ?? asset.id).toLowerCase();
          _nameIndex[key] = asset;
        }
      }
    } catch (e) {
      debugPrint('[ThumbnailService] _buildNameIndex error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Публичное API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches an asset thumbnail with consolidated in-memory LRU + disk caching.
  Future<Uint8List?> getAssetThumbnail(FileItem item, {int size = 300}) {
    assert(item.isAsset, 'getAssetThumbnail: item must be an asset');
    final cacheKey = 'asset:${item.pathSync}@$size';
    return CacheService.instance.getThumbnail(
      cacheKey: cacheKey,
      fetch: () async {
        final cached = await _fromDiskCache(item.pathSync, size);
        if (cached != null) return cached;

        final data = await item.asset!.thumbnailDataWithSize(
          ThumbnailSize.square(size),
          quality: 88,
        );
        if (data != null) await _saveDiskCache(item.pathSync, size, data);
        return data;
      },
    );
  }

  /// Fetches a filesystem thumbnail with consolidated in-memory LRU + disk caching.
  Future<Uint8List?> getFsThumbnail(FileItem item, {int size = 300}) {
    assert(!item.isAsset, 'getFsThumbnail: item must be a FS entity');
    final path = item.pathSync;
    final cacheKey = 'fs:$path@$size';
    return CacheService.instance.getThumbnail(
      cacheKey: cacheKey,
      fetch: () async {
        final cached = await _fromDiskCache(path, size);
        if (cached != null) return cached;

        Uint8List? data;

        if (_isImage(path)) {
          final asset = await _findFsAsset(path);
          data = await asset?.thumbnailDataWithSize(
            ThumbnailSize.square(size),
            quality: 88,
          );
          data ??= await File(path).readAsBytes();
        } else if (_isVideo(path)) {
          final asset = await _findFsAsset(path);
          data = await asset?.thumbnailDataWithSize(
            ThumbnailSize.square(size),
            quality: 88,
          );
          data ??= await VideoThumbnailPlus.thumbnailData(
            video: path,
            imageFormat: ImageFormat.PNG,
            maxWidth: size,
            quality: 85,
          );
        }

        if (data != null) await _saveDiskCache(path, size, data);
        return data;
      },
    );
  }

  Future<AssetEntity?> _findFsAsset(String filePath) async {
    if (_pathIndex.containsKey(filePath)) return _pathIndex[filePath];

    final fileName = filePath.split('/').last.toLowerCase();
    final candidate = _nameIndex[fileName];

    if (candidate != null) {
      final origin = await candidate.originFile;
      if (origin != null) {
        _pathIndex[origin.path] = candidate;
        if (origin.path == filePath) return candidate;
      }
    }

    for (final asset in _nameIndex.values) {
      if ((asset.title ?? '').toLowerCase() == fileName) {
        final origin = await asset.originFile;
        if (origin?.path == filePath) {
          _pathIndex[filePath] = asset;
          return asset;
        }
      }
    }

    return null;
  }

  String _diskKey(String path, int size) {
    final hash = md5.convert(utf8.encode(path)).toString();
    return '${hash}_$size';
  }

  Future<Uint8List?> _fromDiskCache(String path, int size) async {
    if (_cacheDir == null) return null;
    final f = File('${_cacheDir!.path}/${_diskKey(path, size)}');
    return await f.exists() ? f.readAsBytes() : null;
  }

  Future<void> _saveDiskCache(String path, int size, Uint8List data) async {
    if (_cacheDir == null) return;
    final f = File('${_cacheDir!.path}/${_diskKey(path, size)}');
    await f.writeAsBytes(data, flush: true);
  }

  /// Extracts a video poster frame, clamped to [maxDimension] (default 512px)
  /// and encoded as lossy WebP (default [quality] = 80).
  ///
  /// Guarantees:
  /// - Aspect ratio is strictly preserved.
  /// - Max dimension <= [maxDimension].
  /// - Output is always valid WebP bytes (`RIFF....WEBP`).
  /// - Guarded by a strict [timeout] (default 4 seconds) to protect background tasks.
  /// - Gracefully catches all errors/timeouts and returns null on failure. Never throws.
  Future<Uint8List?> extractVideoPoster(
    String videoPath, {
    int maxDimension = 512,
    int quality = 80,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (videoPath.isEmpty || !_isVideo(videoPath)) return null;

    try {
      final file = File(videoPath);
      if (!await file.exists()) return null;

      return await _extractVideoPosterInternal(
        videoPath,
        maxDimension: maxDimension,
        quality: quality,
      ).timeout(timeout);
    } catch (e) {
      debugPrint(
        '[ThumbnailService] extractVideoPoster error for $videoPath: $e',
      );
      return null;
    }
  }

  Future<Uint8List?> _extractVideoPosterInternal(
    String videoPath, {
    required int maxDimension,
    required int quality,
  }) async {
    final cached = await _fromDiskCache('poster:$videoPath', maxDimension);
    if (cached != null && _isWebP(cached)) {
      return cached;
    }

    Uint8List? rawBytes;

    // 1. Primary: Native video decoder via VideoThumbnailPlus
    try {
      rawBytes = await VideoThumbnailPlus.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.WEBP,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        quality: quality,
      );
    } catch (e) {
      debugPrint(
        '[ThumbnailService] VideoThumbnailPlus failed for $videoPath: $e',
      );
    }

    // 2. Secondary fallback: PhotoManager asset if indexed
    if (rawBytes == null) {
      try {
        final asset = await _findFsAsset(videoPath);
        if (asset != null) {
          rawBytes = await asset.thumbnailDataWithSize(
            ThumbnailSize.square(maxDimension),
            quality: quality,
          );
        }
      } catch (e) {
        debugPrint(
          '[ThumbnailService] Asset fallback failed for $videoPath: $e',
        );
      }
    }

    if (rawBytes == null || rawBytes.isEmpty) {
      return null;
    }

    Uint8List? webpBytes;

    // 3. Format & Clamping:
    // Android natively produces lossy WebP <= maxDimension.
    // iOS produces PNG. Any non-WebP (or oversized) payload is decoded and re-encoded.
    if (_isWebP(rawBytes) && rawBytes.length <= 48000) {
      try {
        final decoded = img.decodeImage(rawBytes);
        if (decoded != null &&
            decoded.width <= maxDimension &&
            decoded.height <= maxDimension) {
          webpBytes = rawBytes;
        }
      } catch (_) {}
    }

    if (webpBytes == null) {
      try {
        final decoded = img.decodeImage(rawBytes);
        if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
          return null;
        }

        img.Image clamped = decoded;
        if (decoded.width > maxDimension || decoded.height > maxDimension) {
          if (decoded.width >= decoded.height) {
            final targetH = (maxDimension * (decoded.height / decoded.width))
                .round();
            clamped = img.copyResize(
              decoded,
              width: maxDimension,
              height: targetH > 0 ? targetH : 1,
            );
          } else {
            final targetW = (maxDimension * (decoded.width / decoded.height))
                .round();
            clamped = img.copyResize(
              decoded,
              width: targetW > 0 ? targetW : 1,
              height: maxDimension,
            );
          }
        }

        webpBytes = img.encodeWebP(clamped, lossless: false, quality: quality);
      } catch (e) {
        debugPrint('[ThumbnailService] Pure-Dart WebP re-encoding error: $e');
        return null;
      }
    }

    if (webpBytes.isNotEmpty) {
      unawaited(_saveDiskCache('poster:$videoPath', maxDimension, webpBytes));
    }

    return webpBytes;
  }

  /// Fast container validation for WebP RIFF/WEBP magic bytes.
  bool _isWebP(Uint8List bytes) {
    if (bytes.length < 12) return false;
    return bytes[0] == 0x52 && // 'R'
        bytes[1] == 0x49 && // 'I'
        bytes[2] == 0x46 && // 'F'
        bytes[3] == 0x46 && // 'F'
        bytes[8] == 0x57 && // 'W'
        bytes[9] == 0x45 && // 'E'
        bytes[10] == 0x42 && // 'B'
        bytes[11] == 0x50; // 'P'
  }

  bool _isImage(String p) =>
      photoExtensions.any((e) => p.toLowerCase().endsWith(e));
  bool _isVideo(String p) =>
      videoExtensions.any((e) => p.toLowerCase().endsWith(e));
}
