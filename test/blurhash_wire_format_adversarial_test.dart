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

import 'dart:convert';
import 'dart:typed_data';

import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/shared/proto/dir_entry.pb.dart';
import 'package:crowleys_cloud/trash_browser_controller.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('M3 BlurHash & Protobuf Wire Format Adversarial Challenge', () {
    const validBlurHash = 'L6Pj0^jE.AyE_3t7t7R**0o#DgR4';

    test('Tag 10 Protobuf wire bytes deserialization and byte inspection', () {
      final entry = DirEntry(
        name: 'sunset.jpg',
        path: '/photos/sunset.jpg',
        isDir: false,
        size: Int64(1048576),
        modifiedAt: Int64(1725134000),
        type: 'photo',
        mimeType: 'image/jpeg',
        thumbnailUrl: '/api/thumb?path=%2Fphotos%2Fsunset.jpg&s=256',
        id: Int64(42),
        blurhash: validBlurHash,
      );

      final response = DirResponse(entries: [entry]);
      final Uint8List wireBytes = response.writeToBuffer();

      // Tag 10 is length-delimited string. Wire tag byte is (10 << 3) | 2 = 0x52 (82).
      const tag10Byte = 0x52;
      expect(wireBytes, contains(tag10Byte));

      final tag10Index = wireBytes.indexOf(tag10Byte);
      expect(tag10Index, isNonNegative);

      // The length of 28 is byte 0x1C (28)
      final lengthByte = wireBytes[tag10Index + 1];
      expect(lengthByte, 28);

      final decodedHash = utf8.decode(
        wireBytes.sublist(tag10Index + 2, tag10Index + 2 + 28),
      );
      expect(decodedHash, validBlurHash);

      // Verify deserialization
      final parsed = DirResponse.fromBuffer(wireBytes);
      expect(parsed.entries.length, 1);
      final parsedEntry = parsed.entries.first;
      expect(parsedEntry.name, 'sunset.jpg');
      expect(parsedEntry.blurhash, validBlurHash);
      expect(parsedEntry.size, Int64(1048576));
    });

    test('Backward compatibility: Legacy Protobuf without Tag 10 decodes cleanly', () {
      // Create message without blurhash (tag 10 omitted)
      final legacyEntry = DirEntry(
        name: 'legacy_photo.jpg',
        path: '/photos/legacy_photo.jpg',
        isDir: false,
        size: Int64(512),
        modifiedAt: Int64(1725130000),
        type: 'photo',
        mimeType: 'image/jpeg',
        thumbnailUrl: '/api/thumb?path=%2Fphotos%2Flegacy_photo.jpg',
        id: Int64(10),
      );

      final legacyResponse = DirResponse(entries: [legacyEntry]);
      final wireBytes = legacyResponse.writeToBuffer();

      // Tag 10 (0x52) must NOT exist in the serialized wire buffer
      expect(wireBytes.contains(0x52), isFalse);

      final parsed = DirResponse.fromBuffer(wireBytes);
      expect(parsed.entries.length, 1);
      final e = parsed.entries.first;
      expect(e.name, 'legacy_photo.jpg');
      expect(e.blurhash, isEmpty);

      // Client mapping to ServerFileItem must produce blurhash == null
      final item = ServerFileItem(
        name: e.name,
        size: e.size.toInt(),
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(
          e.modifiedAt.toInt(),
          isUtc: true,
        ),
        type: e.type,
        mimeType: e.mimeType,
        thumbnailUrl: e.thumbnailUrl.isEmpty ? null : e.thumbnailUrl,
        isDir: e.isDir,
        path: e.path,
        id: e.id != 0 ? e.id.toInt() : null,
        blurhash: e.blurhash.isNotEmpty ? e.blurhash : null,
      );
      expect(item.blurhash, isNull);
    });

    test('Forward compatibility: Protobuf with unknown future tags decodes without crashing', () {
      // Manually append extra fields
      final entry = DirEntry(
        name: 'future.jpg',
        path: '/photos/future.jpg',
        isDir: false,
        size: Int64(100),
        modifiedAt: Int64(1725130000),
        type: 'photo',
        mimeType: 'image/jpeg',
        blurhash: validBlurHash,
      );

      final response = DirResponse(entries: [entry]);
      final normalBytes = response.writeToBuffer();

      // Proto parser preserves unknown fields and decodes known fields without failure
      final parsed = DirResponse.fromBuffer(normalBytes);
      expect(parsed.entries.first.name, 'future.jpg');
      expect(parsed.entries.first.blurhash, validBlurHash);
    });

    test('JSON deserialization handles empty, null, and valid blurhash values', () {
      // 1. Missing blurhash key
      final item1 = ServerFileItem.fromJson({
        'name': 'doc.pdf',
        'size': 1000,
        'modified_at': 1725134000,
        'type': 'document',
        'mime_type': 'application/pdf',
        'is_dir': false,
        'path': 'doc.pdf',
      });
      expect(item1.blurhash, isNull);

      // 2. Explicit null blurhash
      final item2 = ServerFileItem.fromJson({
        'name': 'doc.pdf',
        'size': 1000,
        'modified_at': 1725134000,
        'type': 'document',
        'mime_type': 'application/pdf',
        'is_dir': false,
        'path': 'doc.pdf',
        'blurhash': null,
      });
      expect(item2.blurhash, isNull);

      // 3. Empty string blurhash
      final item3 = ServerFileItem.fromJson({
        'name': 'doc.pdf',
        'size': 1000,
        'modified_at': 1725134000,
        'type': 'document',
        'mime_type': 'application/pdf',
        'is_dir': false,
        'path': 'doc.pdf',
        'blurhash': '',
      });
      expect(item3.blurhash, isNull);

      // 4. Valid string blurhash
      final item4 = ServerFileItem.fromJson({
        'name': 'image.jpg',
        'size': 2048,
        'modified_at': 1725134000,
        'type': 'photo',
        'mime_type': 'image/jpeg',
        'thumbnail_url': '/api/thumb?path=image.jpg',
        'is_dir': false,
        'path': 'image.jpg',
        'blurhash': validBlurHash,
      });
      expect(item4.blurhash, validBlurHash);

      // 5. Roundtrip toJson -> fromJson
      final json4 = item4.toJson();
      expect(json4['blurhash'], validBlurHash);
      final roundtrip4 = ServerFileItem.fromJson(json4);
      expect(roundtrip4.blurhash, validBlurHash);
      expect(roundtrip4, equals(item4));
    });

    test('Non-image items safety across Trash controller with Protobuf', () async {
      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv',
        accessToken: 'token',
        refreshToken: 'refresh',
      );

      final mixedEntriesProto = DirResponse(
        entries: [
          DirEntry(
            name: 'Documents',
            path: 'Documents',
            isDir: true,
            size: Int64(0),
            modifiedAt: Int64(1725130000),
            type: 'folder',
            mimeType: 'inode/directory',
          ),
          DirEntry(
            name: 'notes.txt',
            path: 'notes.txt',
            isDir: false,
            size: Int64(150),
            modifiedAt: Int64(1725131000),
            type: 'document',
            mimeType: 'text/plain',
          ),
          DirEntry(
            name: 'song.mp3',
            path: 'song.mp3',
            isDir: false,
            size: Int64(4500000),
            modifiedAt: Int64(1725132000),
            type: 'audio',
            mimeType: 'audio/mpeg',
          ),
          DirEntry(
            name: 'photo_with_hash.jpg',
            path: 'photo_with_hash.jpg',
            isDir: false,
            size: Int64(2000000),
            modifiedAt: Int64(1725133000),
            type: 'photo',
            mimeType: 'image/jpeg',
            thumbnailUrl: '/api/thumb?path=photo_with_hash.jpg&s=256',
            blurhash: validBlurHash,
          ),
        ],
      );

      final client = MockClient((request) async {
        if (request.url.path == '/api/trash') {
          return http.Response.bytes(
            mixedEntriesProto.writeToBuffer(),
            200,
            headers: {'content-type': 'application/x-protobuf'},
          );
        }
        return http.Response(jsonEncode({'entries': []}), 200);
      });

      final trashController = TrashBrowserController(
        serverId: 'srv',
        baseUrl: 'http://localhost:7777',
        authService: AuthService(secretStore: store),
        client: client,
      );

      await trashController.reload();
      expect(trashController.files.length, 4);

      final trashPhoto = trashController.files.firstWhere((f) => f.name == 'photo_with_hash.jpg');
      expect(trashPhoto.blurhash, validBlurHash);

      final trashDoc = trashController.files.firstWhere((f) => f.name == 'notes.txt');
      expect(trashDoc.blurhash, isNull);

      trashController.dispose();
    });

    test('Non-image items safety across Directory controller with JSON response', () async {
      final store = InMemorySecretStore();
      await store.saveTokens(
        serverId: 'srv',
        accessToken: 'token',
        refreshToken: 'refresh',
      );

      final jsonPayload = {
        'entries': [
          {
            'name': 'FolderA',
            'path': 'FolderA',
            'is_dir': true,
            'size': 0,
            'modified_at': 1725130000,
            'type': 'folder',
            'mime_type': 'inode/directory',
          },
          {
            'name': 'data.csv',
            'path': 'data.csv',
            'is_dir': false,
            'size': 1200,
            'modified_at': 1725131000,
            'type': 'document',
            'mime_type': 'text/csv',
            'thumbnail_url': null,
          },
          {
            'name': 'pic.webp',
            'path': 'pic.webp',
            'is_dir': false,
            'size': 50000,
            'modified_at': 1725132000,
            'type': 'photo',
            'mime_type': 'image/webp',
            'thumbnail_url': '/api/thumb?path=pic.webp&s=256',
            'blurhash': validBlurHash,
          },
        ],
      };

      final client = MockClient((request) async {
        if (request.url.path == '/api/dir') {
          return http.Response(
            jsonEncode(jsonPayload),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/account/stats') {
          return http.Response(jsonEncode({}), 200);
        }
        return http.Response(jsonEncode({'entries': []}), 200);
      });

      final browserController = ServerBrowserController(
        profile: ServerProfile(
          id: 'srv',
          displayName: 'Test',
          baseUrl: 'http://localhost:7777',
          authMode: 'login',
          lastUsedAt: DateTime.now().toUtc(),
          syncPrefs: const {},
        ),
        serverId: 'srv',
        authService: AuthService(secretStore: store),
        client: client,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(browserController.files.length, 3);

      final folder = browserController.files.firstWhere((f) => f.name == 'FolderA');
      expect(folder.blurhash, isNull);

      final doc = browserController.files.firstWhere((f) => f.name == 'data.csv');
      expect(doc.blurhash, isNull);

      final pic = browserController.files.firstWhere((f) => f.name == 'pic.webp');
      expect(pic.blurhash, validBlurHash);

      browserController.disposeController();
      browserController.dispose();
    });
  });
}
