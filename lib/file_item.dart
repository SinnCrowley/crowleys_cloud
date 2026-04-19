import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as p;

class FileItem {
  final AssetEntity? asset;
  final FileSystemEntity? fsEntity;
  String? _cachedPath;

  FileItem.fromAsset(AssetEntity this.asset) : fsEntity = null;
  FileItem.fromEntity(FileSystemEntity this.fsEntity) : asset = null;

  bool get isDirectory => fsEntity is Directory;
  bool get isAsset => asset != null;

  String get name {
    if (asset != null) return asset!.title ?? asset!.id;
    return p.basename(fsEntity!.path);
  }

  Future<String> get path async {
    if (_cachedPath != null) return _cachedPath!;
    if (fsEntity != null) return _cachedPath = fsEntity!.path;
    final file = await asset!.originFile;
    return _cachedPath = file?.path ?? '';
  }

  String get pathSync {
    if (_cachedPath != null) return _cachedPath!;
    if (fsEntity != null) return fsEntity!.path;
    return asset!.id;
  }

  DateTime get modifiedDate {
    if (asset != null) return asset!.modifiedDateTime;
    final stat = fsEntity?.statSync();
    return stat?.modified ?? DateTime(0);
  }

  int get size {
    if (fsEntity != null) return fsEntity!.statSync().size;
    return 0; // для asset размер недоступен без originFile
  }

  String get type {
    if (fsEntity != null) return p.extension(fsEntity!.path).toLowerCase();
    final title = asset?.title ?? '';
    return p.extension(title).toLowerCase();
  }
}