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

import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as p;
import 'package:crowleys_cloud/asset_size_cache.dart';
import 'package:crowleys_cloud/server_file_item.dart';

class FileItem {
  final AssetEntity? asset;
  final FileSystemEntity? fsEntity;
  final ServerFileItem? serverFile;
  final String _identity;
  String? _cachedPath;

  FileItem.fromAsset(AssetEntity this.asset)
    : fsEntity = null,
      serverFile = null,
      _identity = asset.id;
  FileItem.fromEntity(FileSystemEntity this.fsEntity)
    : asset = null,
      serverFile = null,
      _identity = fsEntity.path;
  FileItem.fromServer(ServerFileItem this.serverFile)
    : asset = null,
      fsEntity = null,
      _identity = serverFile.path;

  bool get isDirectory => serverFile?.isDir ?? fsEntity is Directory;
  bool get isAsset => asset != null;
  bool get isRemote => serverFile != null;

  String get name {
    if (serverFile != null) return serverFile!.name;
    if (asset != null) return asset!.title ?? asset!.id;
    return p.basename(fsEntity!.path);
  }

  Future<String> get path async {
    if (_cachedPath != null) return _cachedPath!;
    if (fsEntity != null) return _cachedPath = fsEntity!.path;
    if (serverFile != null) return _cachedPath ?? '';
    final file = await asset!.originFile;
    return _cachedPath = file?.path ?? '';
  }

  // Setter to cache the path once downloaded
  set cachedPath(String newPath) {
    _cachedPath = newPath;
  }

  String get pathSync {
    if (_cachedPath != null) return _cachedPath!;
    if (serverFile != null) return serverFile!.path;
    if (fsEntity != null) return fsEntity!.path;
    return asset!.id;
  }

  DateTime get modifiedDate {
    if (serverFile != null) return serverFile!.modifiedAt;
    if (asset != null) return asset!.modifiedDateTime;
    final stat = fsEntity?.statSync();
    return stat?.modified ?? DateTime(0);
  }

  int get size {
    if (serverFile != null) return serverFile!.size;
    if (fsEntity != null) {
      try {
        return fsEntity!.statSync().size;
      } catch (_) {
        return 0;
      }
    }
    return AssetSizeCache.getSize(_identity, modifiedDate) ?? 0;
  }

  String get type {
    if (serverFile != null) return serverFile!.extension;
    if (fsEntity != null) return p.extension(fsEntity!.path).toLowerCase();
    final title = asset?.title ?? '';
    return p.extension(title).toLowerCase();
  }

  @override
  bool operator ==(Object other) {
    return other is FileItem && other._identity == _identity;
  }

  @override
  int get hashCode => _identity.hashCode;
}
