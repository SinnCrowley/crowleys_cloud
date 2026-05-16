import 'dart:typed_data';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:flutter/material.dart';
import 'file_item.dart';
import 'thumbnail_service.dart';
import 'package:photo_manager/photo_manager.dart';

class _FileType {
  final IconData icon;
  final Color color;
  const _FileType(this.icon, this.color);
}

_FileType _fileTypeOf(String ext) {
  return switch (ext) {
    'pdf' => _FileType(Icons.picture_as_pdf, appAccent),
    'doc' || 'docx' => _FileType(Icons.description, appAccent),
    'xls' || 'xlsx' => _FileType(Icons.table_chart, appAccent),
    'ppt' || 'pptx' => _FileType(Icons.slideshow, appAccent),
    'zip' || 'rar' || '7z' || 'tar' => _FileType(Icons.folder_zip, appAccent),
    'apk' => _FileType(Icons.android, appAccent),
    'mp3' ||
    'flac' ||
    'aac' ||
    'wav' ||
    'm4a' => _FileType(Icons.audio_file, appAccent),
    'txt' || 'md' => _FileType(Icons.text_snippet, appAccent),
    _ => _FileType(Icons.insert_drive_file, appAccent),
  };
}

// ── Главный виджет ───────────────────────────────────────────────

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
  late final Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    final px = (widget.size * widget.dpr).toInt();
    // Напрямую через photo_manager — никакого поиска по индексу
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
  late final Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    final px = (widget.size * widget.dpr).toInt();
    _future = ThumbnailService.instance.getFsThumbnail(widget.item, size: px);
  }

  @override
  Widget build(BuildContext context) =>
      _ThumbnailFuture(future: _future, size: widget.size);
}

// ── Общий FutureBuilder для обоих типов ──────────────────────────

class _ThumbnailFuture extends StatelessWidget {
  final Future<Uint8List?> future;
  final double size;

  const _ThumbnailFuture({required this.future, required this.size});

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
          );
        }
        return _Placeholder(
          size: size,
          icon: Icons.image_outlined,
          color: Colors.white24,
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

  const _Placeholder({
    required this.size,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
