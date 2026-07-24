import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crowleys_cloud/shared/utils/file_icon_utils.dart';
import 'package:crowleys_cloud/shared/utils/file_type_utils.dart';

void main() {
  group('FileIconUtils & FileTypeUtils', () {
    test('iconForExtension maps known extensions to icons', () {
      expect(FileIconUtils.iconForExtension('pdf'), Icons.picture_as_pdf);
      expect(FileIconUtils.iconForExtension('.docx'), Icons.description);
      expect(FileIconUtils.iconForExtension('png'), Icons.image);
      expect(FileIconUtils.iconForExtension('mp4'), Icons.movie);
      expect(FileIconUtils.iconForExtension('zip'), Icons.folder_zip);
      expect(FileIconUtils.iconForExtension('unknown_ext'), Icons.insert_drive_file);
    });

    test('categoryForFile resolves category info', () {
      final info = FileTypeUtils.categoryForFile('document.pdf');
      expect(info.icon, Icons.picture_as_pdf);
      expect(FileTypeUtils.isImage('.png'), isTrue);
      expect(FileTypeUtils.isVideo('.mp4'), isTrue);
      expect(FileTypeUtils.isAudio('.mp3'), isTrue);
    });
  });
}
