import 'package:flutter/material.dart';

/// Centralized utility for resolving Material icons and colors based on file extensions.
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
      'zip' || 'tar' || 'gz' || '7z' || 'rar' => Icons.folder_zip,
      'mp3' || 'wav' || 'ogg' || 'flac' => Icons.audiotrack,
      'mp4' || 'mkv' || 'avi' || 'mov' => Icons.movie,
      'jpg' || 'jpeg' || 'png' || 'webp' || 'gif' => Icons.image,
      'txt' || 'md' || 'json' || 'yaml' || 'xml' => Icons.article,
      _ => Icons.insert_drive_file,
    };
  }

  /// Returns the category background color for a given file extension.
  static Color colorForExtension(String extension) {
    final ext = extension.startsWith('.')
        ? extension.substring(1).toLowerCase()
        : extension.toLowerCase();

    return switch (ext) {
      'jpg' || 'jpeg' || 'png' || 'webp' || 'gif' => Colors.purple.shade400,
      'mp4' || 'mkv' || 'avi' || 'mov' => Colors.blue.shade400,
      'mp3' || 'wav' || 'ogg' || 'flac' => Colors.orange.shade400,
      'pdf' ||
      'doc' ||
      'docx' ||
      'txt' ||
      'md' ||
      'xls' ||
      'xlsx' ||
      'ppt' ||
      'pptx' ||
      'json' ||
      'yaml' ||
      'xml' => Colors.teal.shade400,
      'zip' || 'tar' || 'gz' || '7z' || 'rar' => Colors.amber.shade700,
      _ => Colors.grey.shade400,
    };
  }
}
