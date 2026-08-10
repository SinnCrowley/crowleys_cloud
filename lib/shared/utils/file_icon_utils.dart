import 'package:flutter/material.dart';

/// Centralized utility for resolving Material icons based on file extensions.
abstract final class FileIconUtils {
  /// Returns the corresponding [IconData] for a file extension.
  static IconData iconForExtension(String extension) {
    final ext = extension.startsWith('.')
        ? extension.substring(1).toLowerCase()
        : extension.toLowerCase();

    return switch (ext) {
      'pdf' => Icons.picture_as_pdf,
      'doc' || 'docx' => Icons.description,
      'xls' || 'xlsx' => Icons.table_chart,
      'ppt' || 'pptx' => Icons.slideshow,
      'zip' || 'tar' || 'gz' || '7z' || 'rar' || 'bz2' || 'xz' => Icons.folder_zip,
      'mp3' || 'wav' || 'ogg' || 'flac' || 'm4a' || 'aac' => Icons.audiotrack,
      'mp4' || 'mkv' || 'avi' || 'mov' || 'webm' || 'flv' => Icons.movie,
      'jpg' ||
      'jpeg' ||
      'png' ||
      'webp' ||
      'gif' ||
      'bmp' ||
      'heic' ||
      'avif' ||
      'heif' => Icons.image,
      'txt' ||
      'md' ||
      'json' ||
      'yaml' ||
      'yml' ||
      'xml' ||
      'log' ||
      'csv' ||
      'js' ||
      'ts' ||
      'html' ||
      'css' ||
      'dart' ||
      'cpp' ||
      'c' ||
      'h' ||
      'hpp' ||
      'py' ||
      'sh' => Icons.article,
      _ => Icons.insert_drive_file,
    };
  }
}
