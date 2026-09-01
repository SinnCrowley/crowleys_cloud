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

import 'dart:typed_data';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:flutter/material.dart';
import 'file_item.dart';
import 'thumbnail_service.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:crowleys_cloud/shared/utils/blurhash_decoder.dart';
import 'package:crowleys_cloud/shared/utils/file_icon_utils.dart';

class _FileType {
  final IconData icon;
  final Color color;
  const _FileType(this.icon, this.color);
}

_FileType _fileTypeOf(String ext) {
  return _FileType(FileIconUtils.iconForExtension(ext), appAccent);
}

// ── Главный виджет ───────────────────────────────────────────────

/// SmartThumbnail displays image/video thumbnails or file category icons
/// for [FileItem] objects in grid/list views.
///
/// Performance optimizations:
/// - Memoizes thumbnail Futures in widget state to prevent re-triggering disk/network I/O on scroll.
/// - Handles widget updates via [didUpdateWidget] when layout size or item properties change.
/// - Integrates with [ThumbnailService] and [CacheService] for consolidated RAM + disk caching.
class SmartThumbnail extends StatelessWidget {
  final FileItem item;
  final bool isList;

  const SmartThumbnail({super.key, required this.item, this.isList = false});

  @override
  Widget build(BuildContext context) {
    final size = isList ? 50.0 : 120.0;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    // Папка
    if (item.isDirectory) {
      return Icon(Icons.folder, color: appAccent, size: size);
    }

    // AssetEntity (Photos / Videos / Audio) — всегда медиа, грузим напрямую
    if (item.isAsset) {
      if (item.asset!.type == AssetType.audio) {
        return Icon(Icons.audio_file, color: appAccent, size: size);
      }
      return _AssetThumbnail(
        key: ValueKey(item.pathSync),
        item: item,
        size: size,
        dpr: dpr,
      );
    }

    // FileSystemEntity — проверяем расширение
    final ext = item.type; // уже lowercase с точкой, напр. ".jpg"
    final lower = item.pathSync.toLowerCase();

    final isMedia =
        photoExtensions.any(lower.endsWith) ||
        videoExtensions.any(lower.endsWith);

    if (isMedia) {
      return _FsThumbnail(
        key: ValueKey(item.pathSync),
        item: item,
        size: size,
        dpr: dpr,
      );
    }

    // Иконка по расширению
    final cleanExt = ext.startsWith('.') ? ext.substring(1) : ext;
    final type = _fileTypeOf(cleanExt);
    return Icon(type.icon, color: type.color, size: size);
  }
}

// ── Миниатюра для AssetEntity (мгновенно, без IO) ────────────────

class _AssetThumbnail extends StatefulWidget {
  final FileItem item;
  final double size;
  final double dpr;

  const _AssetThumbnail({
    super.key,
    required this.item,
    required this.size,
    required this.dpr,
  });

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _loadFuture();
  }

  @override
  void didUpdateWidget(covariant _AssetThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.pathSync != widget.item.pathSync ||
        oldWidget.size != widget.size ||
        oldWidget.dpr != widget.dpr) {
      _loadFuture();
    }
  }

  void _loadFuture() {
    final px = (widget.size * widget.dpr).toInt();
    _future = ThumbnailService.instance.getAssetThumbnail(
      widget.item,
      size: px,
    );
  }

  @override
  Widget build(BuildContext context) =>
      _ThumbnailFuture(future: _future, size: widget.size);
}

// ── Миниатюра для File на диске (через ThumbnailService) ─────────

class _FsThumbnail extends StatefulWidget {
  final FileItem item;
  final double size;
  final double dpr;

  const _FsThumbnail({
    super.key,
    required this.item,
    required this.size,
    required this.dpr,
  });

  @override
  State<_FsThumbnail> createState() => _FsThumbnailState();
}

class _FsThumbnailState extends State<_FsThumbnail> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _loadFuture();
  }

  @override
  void didUpdateWidget(covariant _FsThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.pathSync != widget.item.pathSync ||
        oldWidget.size != widget.size ||
        oldWidget.dpr != widget.dpr) {
      _loadFuture();
    }
  }

  void _loadFuture() {
    final px = (widget.size * widget.dpr).toInt();
    _future = ThumbnailService.instance.getFsThumbnail(widget.item, size: px);
  }

  @override
  Widget build(BuildContext context) => _ThumbnailFuture(
    future: _future,
    size: widget.size,
    blurhash: widget.item.serverFile?.blurhash,
  );
}

// ── Общий FutureBuilder для обоих типов ──────────────────────────

class _ThumbnailFuture extends StatelessWidget {
  final Future<Uint8List?>? future;
  final double size;
  final String? blurhash;

  const _ThumbnailFuture({
    required this.future,
    required this.size,
    this.blurhash,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.data != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                snap.data!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            );
          }
          return _Placeholder(
            size: size,
            icon: Icons.broken_image,
            color: Colors.red.shade300,
            blurhash: blurhash,
          );
        }
        return _Placeholder(
          size: size,
          icon: Icons.image_outlined,
          color: Colors.white24,
          blurhash: blurhash,
        );
      },
    );
  }
}

// ── Заглушка ─────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  final double size;
  final IconData icon;
  final Color color;
  final String? blurhash;

  const _Placeholder({
    required this.size,
    required this.icon,
    required this.color,
    this.blurhash,
  });

  @override
  Widget build(BuildContext context) {
    if (blurhash != null && BlurHashDecoder.isValid(blurhash)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BlurHashWidget(
          blurhash: blurhash!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(icon, color: color, size: size / 2.5),
      ),
    );
  }
}
