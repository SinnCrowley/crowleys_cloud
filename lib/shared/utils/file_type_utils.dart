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

import 'package:flutter/material.dart';
import 'file_icon_utils.dart';

/// File category data containing associated icon.
class FileCategoryInfo {
  const FileCategoryInfo(this.icon);

  final IconData icon;
}

/// Centralized utility for file type and category identification.
abstract final class FileTypeUtils {
  static String _cleanExtension(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('.')) {
      final parts = trimmed.split('.').where((p) => p.isNotEmpty);
      if (parts.isEmpty) return '';
      return parts.last;
    }
    return trimmed;
  }

  /// Resolves the file category info (icon) for a file name or extension.
  static FileCategoryInfo categoryForFile(String filenameOrExtension) {
    final ext = _cleanExtension(filenameOrExtension);
    return FileCategoryInfo(FileIconUtils.iconForExtension(ext));
  }

  /// Checks if an extension or filename belongs to an image file.
  static bool isImage(String extensionOrFilename) {
    final ext = _cleanExtension(extensionOrFilename);
    return const {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'bmp',
      'heic',
      'avif',
      'heif',
    }.contains(ext);
  }

  /// Checks if an extension or filename belongs to a video file.
  static bool isVideo(String extensionOrFilename) {
    final ext = _cleanExtension(extensionOrFilename);
    return const {'mp4', 'mkv', 'avi', 'mov', 'webm', 'flv'}.contains(ext);
  }

  /// Checks if an extension or filename belongs to an audio file.
  static bool isAudio(String extensionOrFilename) {
    final ext = _cleanExtension(extensionOrFilename);
    return const {'mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac'}.contains(ext);
  }

  /// Checks if an extension or filename belongs to a PDF file.
  static bool isPdf(String extensionOrFilename) {
    final ext = _cleanExtension(extensionOrFilename);
    return ext == 'pdf';
  }

  /// Checks if an extension or filename belongs to a text file.
  static bool isText(String extensionOrFilename) {
    final ext = _cleanExtension(extensionOrFilename);
    return const {
      'txt',
      'md',
      'json',
      'yaml',
      'yml',
      'xml',
      'log',
      'csv',
      'js',
      'ts',
      'html',
      'css',
      'dart',
      'cpp',
      'c',
      'h',
      'hpp',
      'py',
      'sh',
    }.contains(ext);
  }

  /// Checks if an extension or filename belongs to an archive file.
  static bool isArchive(String extensionOrFilename) {
    final ext = _cleanExtension(extensionOrFilename);
    return const {'zip', 'tar', 'gz', '7z', 'rar', 'bz2', 'xz'}.contains(ext);
  }
}
