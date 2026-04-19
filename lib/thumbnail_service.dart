import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'file_item.dart';

class ThumbnailService {
  ThumbnailService._();
  static final instance = ThumbnailService._();

  // ─── Индекс только для FS-файлов ────────────────────────────────────────
  // title.toLowerCase() → AssetEntity
  final Map<String, AssetEntity> _nameIndex = {};
  // realPath → AssetEntity (заполняется лениво через originFile)
  final Map<String, AssetEntity> _pathIndex = {};

  // Дедупликация параллельных запросов
  final Map<String, Future<Uint8List?>> _inFlight = {};

  Directory? _cacheDir;

  // ═══════════════════════════════════════════════════════════════════════════
  // Инициализация
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> init() async {
    _cacheDir = Directory(
      '${(await getTemporaryDirectory()).path}/thumb_cache',
    );
    await _cacheDir!.create(recursive: true);

    // Индекс нужен только для FS-файлов (Documents / Other / All files).
    // MediaStore-ассеты обращаются напрямую через asset.thumbnailDataWithSize.
    await _buildNameIndex();
  }

  Future<void> _buildNameIndex() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) return;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );
    if (albums.isEmpty) return;

    final allAlbum =
    albums.firstWhere((a) => a.isAll, orElse: () => albums.first);
    final total = await allAlbum.assetCountAsync;

    for (var page = 0; page * 500 < total; page++) {
      final assets =
      await allAlbum.getAssetListPaged(page: page, size: 500);
      for (final asset in assets) {
        final key = (asset.title ?? asset.id).toLowerCase();
        _nameIndex[key] = asset;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Публичное API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Для [FileItem.fromAsset] — ассет уже известен, идём напрямую.
  /// Никакого поиска по индексу → миниатюры мгновенные.
  Future<Uint8List?> getAssetThumbnail(FileItem item, {int size = 300}) {
    assert(item.isAsset, 'getAssetThumbnail: item must be an asset');
    final key = '${item.pathSync}@$size';
    return _inFlight.putIfAbsent(key, () async {
      try {
        // Диск-кэш (необязателен для ассетов, но экономит повторные вызовы)
        final cached = await _fromDiskCache(item.pathSync, size);
        if (cached != null) return cached;

        final data = await item.asset!.thumbnailDataWithSize(
          ThumbnailSize.square(size),
          quality: 88,
        );
        if (data != null) await _saveDiskCache(item.pathSync, size, data);
        return data;
      } finally {
        _inFlight.remove(key);
      }
    });
  }

  /// Для [FileItem.fromEntity] — ищем ассет по имени/пути,
  /// фоллбэк на video_thumbnail или прямое чтение файла.
  Future<Uint8List?> getFsThumbnail(FileItem item, {int size = 300}) {
    assert(!item.isAsset, 'getFsThumbnail: item must be a FS entity');
    final path = item.pathSync;
    final key = '$path@$size';
    return _inFlight.putIfAbsent(key, () async {
      try {
        final cached = await _fromDiskCache(path, size);
        if (cached != null) return cached;

        Uint8List? data;

        if (_isImage(path)) {
          final asset = await _findFsAsset(path);
          data = await asset?.thumbnailDataWithSize(
            ThumbnailSize.square(size),
            quality: 88,
          );
          // Фоллбэк: читаем файл напрямую (для изображений вне MediaStore)
          data ??= await File(path).readAsBytes();
        } else if (_isVideo(path)) {
          final asset = await _findFsAsset(path);
          data = await asset?.thumbnailDataWithSize(
            ThumbnailSize.square(size),
            quality: 88,
          );
          // Фоллбэк: video_thumbnail
          data ??= await VideoThumbnail.thumbnailData(
            video: path,
            imageFormat: ImageFormat.PNG,
            maxWidth: size,
            quality: 85,
          );
        }

        if (data != null) await _saveDiskCache(path, size, data);
        return data;
      } finally {
        _inFlight.remove(key);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Поиск AssetEntity по пути на диске (только для FS-файлов)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<AssetEntity?> _findFsAsset(String filePath) async {
    // 1. Уже нашли раньше
    if (_pathIndex.containsKey(filePath)) return _pathIndex[filePath];

    // 2. Быстрый поиск по имени файла
    final fileName = filePath.split('/').last.toLowerCase();
    final candidate = _nameIndex[fileName];

    if (candidate != null) {
      final origin = await candidate.originFile;
      if (origin != null) {
        _pathIndex[origin.path] = candidate;
        if (origin.path == filePath) return candidate;
      }
    }

    // 3. Фоллбэк: несколько файлов с одинаковым именем в разных папках
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Диск-кэш
  // ═══════════════════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════════════════
  // Хелперы
  // ═══════════════════════════════════════════════════════════════════════════

  static const _imageExts = {
    '.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.heic', '.heif', '.avif',
  };
  static const _videoExts = {
    '.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv',
  };

  bool _isImage(String p) =>
      _imageExts.any((e) => p.toLowerCase().endsWith(e));
  bool _isVideo(String p) =>
      _videoExts.any((e) => p.toLowerCase().endsWith(e));
}