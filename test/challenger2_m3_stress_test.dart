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
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:protobuf/protobuf.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Challenger 2 M3 Protobuf Wire Format & BlurHash Empirical Suite', () {
    const sampleBlurHash = 'L6Pj0^jE.AyE_3t7t7R**0o#DgR4';

    test(
      '1. Wire Format Exact Tag 10 Binary Serialization and Dart Deserialization',
      () {
        final entry = DirEntry(
          name: 'test_photo.jpg',
          path: '/photos/test_photo.jpg',
          isDir: false,
          size: Int64(1048576),
          modifiedAt: Int64(1725134000),
          type: 'photo',
          mimeType: 'image/jpeg',
          thumbnailUrl: '/api/thumb?path=%2Fphotos%2Ftest_photo.jpg&s=256',
          id: Int64(12345),
          blurhash: sampleBlurHash,
        );

        final response = DirResponse(entries: [entry]);
        final Uint8List buffer = response.writeToBuffer();

        // Check Tag 10 field key: (10 << 3) | 2 = 82 = 0x52
        final tagIndex = buffer.indexOf(0x52);
        expect(
          tagIndex,
          isNonNegative,
          reason: 'Field tag 10 wire key 0x52 must exist in serialized bytes',
        );

        final stringLength = buffer[tagIndex + 1];
        expect(stringLength, sampleBlurHash.length);

        final extractedStr = utf8.decode(
          buffer.sublist(tagIndex + 2, tagIndex + 2 + stringLength),
        );
        expect(extractedStr, equals(sampleBlurHash));

        // Decode back via Dart protobuf
        final decodedResponse = DirResponse.fromBuffer(buffer);
        expect(decodedResponse.entries.length, 1);
        final decodedEntry = decodedResponse.entries.first;
        expect(decodedEntry.name, equals('test_photo.jpg'));
        expect(decodedEntry.blurhash, equals(sampleBlurHash));
        expect(decodedEntry.id, equals(Int64(12345)));
        expect(decodedEntry.size, equals(Int64(1048576)));
      },
    );

    test(
      '2. Deserialization of Large Directory with Mixed Non-Image and Image Entries',
      () {
        const totalEntries = 2000;
        final entries = <DirEntry>[];

        for (var i = 0; i < totalEntries; i++) {
          final isFolder = i % 5 == 0;
          final isDocument = i % 5 == 1;
          final isPhoto = i % 5 >= 3;

          entries.add(
            DirEntry(
              name: isFolder
                  ? 'folder_$i'
                  : (isPhoto
                        ? 'photo_$i.jpg'
                        : (isDocument ? 'doc_$i.pdf' : 'track_$i.mp3')),
              path: '/items/$i',
              isDir: isFolder,
              size: isFolder ? Int64(0) : Int64(1000 + i * 100),
              modifiedAt: Int64(1725134000 + i),
              type: isFolder
                  ? 'folder'
                  : (isPhoto ? 'photo' : (isDocument ? 'document' : 'audio')),
              mimeType: isFolder
                  ? 'inode/directory'
                  : (isPhoto
                        ? 'image/jpeg'
                        : (isDocument ? 'application/pdf' : 'audio/mpeg')),
              thumbnailUrl: isPhoto ? '/api/thumb?path=/items/$i&s=256' : '',
              id: Int64(i),
              blurhash: isPhoto ? sampleBlurHash : '',
            ),
          );
        }

        final bigResponse = DirResponse(entries: entries);
        final stopwatch = Stopwatch()..start();
        final wireBytes = bigResponse.writeToBuffer();
        final serializeTimeMs = stopwatch.elapsedMilliseconds;

        stopwatch.reset();
        final parsed = DirResponse.fromBuffer(wireBytes);
        final deserializeTimeMs = stopwatch.elapsedMilliseconds;

        expect(parsed.entries.length, totalEntries);
        debugPrint(
          '2,000 entries Protobuf wire size: ${wireBytes.length} bytes, '
          'serialize: ${serializeTimeMs}ms, deserialize: ${deserializeTimeMs}ms',
        );

        // Convert to ServerFileItem list
        final items = parsed.entries
            .map(
              (e) => ServerFileItem(
                name: e.name,
                size: e.size.toInt(),
                modifiedAt: DateTime.fromMillisecondsSinceEpoch(
                  e.modifiedAt.toInt(),
                  isUtc: true,
                ),
                type: e.type,
                mimeType: e.mimeType,
                thumbnailUrl: e.thumbnailUrl.isNotEmpty ? e.thumbnailUrl : null,
                isDir: e.isDir,
                path: e.path,
                id: e.id != 0 ? e.id.toInt() : null,
                blurhash: e.blurhash.isNotEmpty ? e.blurhash : null,
              ),
            )
            .toList();

        for (var i = 0; i < totalEntries; i++) {
          final item = items[i];
          if (i % 5 >= 3) {
            expect(item.blurhash, equals(sampleBlurHash));
            expect(item.thumbnailUrl, isNotNull);
          } else {
            expect(
              item.blurhash,
              isNull,
              reason: 'Non-image item $i must have blurhash == null',
            );
            if (item.isDir) {
              expect(item.thumbnailUrl, isNull);
            }
          }
        }
      },
    );

    test('3. Malformed and Truncated Protobuf Wire Byte Handling', () {
      final validEntry = DirEntry(
        name: 'sample.png',
        path: '/sample.png',
        blurhash: sampleBlurHash,
      );
      final validBytes = DirResponse(entries: [validEntry]).writeToBuffer();

      // Truncate bytes in the middle of tag 10
      final truncatedBytes = validBytes.sublist(0, validBytes.length - 10);
      expect(
        () => DirResponse.fromBuffer(truncatedBytes),
        throwsA(isA<InvalidProtocolBufferException>()),
      );

      // Empty byte array -> yields empty DirResponse
      final emptyResponse = DirResponse.fromBuffer(Uint8List(0));
      expect(emptyResponse.entries, isEmpty);
    });

    test(
      '4. JSON API Directory Serialization, Deserialization and Special Type Handling',
      () {
        final testCases = [
          {
            'rawJson': {
              'name': 'image1.png',
              'size': 5000,
              'modified_at': 1725134000,
              'type': 'photo',
              'mime_type': 'image/png',
              'path': '/image1.png',
              'blurhash': sampleBlurHash,
            },
            'expectedBlurhash': sampleBlurHash,
          },
          {
            'rawJson': {
              'name': 'image2.png',
              'size': 5000,
              'modified_at': 1725134000,
              'type': 'photo',
              'mime_type': 'image/png',
              'path': '/image2.png',
              'blurhash': '',
            },
            'expectedBlurhash': null,
          },
          {
            'rawJson': {
              'name': 'image3.png',
              'size': 5000,
              'modified_at': 1725134000,
              'type': 'photo',
              'mime_type': 'image/png',
              'path': '/image3.png',
              'blurhash': null,
            },
            'expectedBlurhash': null,
          },
          {
            'rawJson': {
              'name': 'archive.zip',
              'size': 500000,
              'modified_at': 1725134000,
              'type': 'archive',
              'mime_type': 'application/zip',
              'path': '/archive.zip',
            },
            'expectedBlurhash': null,
          },
        ];

        for (final tc in testCases) {
          final raw = tc['rawJson'] as Map<String, Object?>;
          final expected = tc['expectedBlurhash'] as String?;
          final item = ServerFileItem.fromJson(raw);
          expect(item.blurhash, equals(expected));

          final jsonOut = item.toJson();
          if (expected != null) {
            expect(jsonOut['blurhash'], equals(expected));
          } else {
            expect(jsonOut.containsKey('blurhash'), isFalse);
          }
        }
      },
    );

    testWidgets(
      '5. UI Rendering Stability with Mixed Null, Empty, and Valid BlurHash Items',
      (WidgetTester tester) async {
        final items = [
          ServerFileItem(
            name: 'folder_item',
            size: 0,
            modifiedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            type: 'folder',
            mimeType: 'inode/directory',
            thumbnailUrl: null,
            isDir: true,
            path: '/folder_item',
            blurhash: null,
          ),
          ServerFileItem(
            name: 'doc_item.pdf',
            size: 1024,
            modifiedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            type: 'document',
            mimeType: 'application/pdf',
            thumbnailUrl: null,
            isDir: false,
            path: '/doc_item.pdf',
            blurhash: null,
          ),
          ServerFileItem(
            name: 'photo_with_blurhash.jpg',
            size: 2048,
            modifiedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            type: 'photo',
            mimeType: 'image/jpeg',
            thumbnailUrl: '/api/thumb?path=/photo_with_blurhash.jpg',
            isDir: false,
            path: '/photo_with_blurhash.jpg',
            blurhash: sampleBlurHash,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.blurhash ?? 'no-blurhash'),
                    trailing: item.blurhash != null
                        ? const Icon(Icons.image, key: Key('has_blurhash_icon'))
                        : const Icon(
                            Icons.insert_drive_file,
                            key: Key('no_blurhash_icon'),
                          ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('folder_item'), findsOneWidget);
        expect(find.text('doc_item.pdf'), findsOneWidget);
        expect(find.text('photo_with_blurhash.jpg'), findsOneWidget);
        expect(find.text(sampleBlurHash), findsOneWidget);
        expect(find.text('no-blurhash'), findsNWidgets(2));
        expect(find.byKey(const Key('has_blurhash_icon')), findsOneWidget);
        expect(find.byKey(const Key('no_blurhash_icon')), findsNWidgets(2));
      },
    );

    test(
      '6. ServerBrowserController End-to-End Protobuf & Filter by Category with BlurHash',
      () async {
        final store = InMemorySecretStore();
        await store.saveTokens(
          serverId: 'srv_test',
          accessToken: 'mock_token',
          refreshToken: 'mock_refresh',
        );

        final protoResponse = DirResponse(
          entries: [
            DirEntry(
              name: 'vacation.jpg',
              path: 'vacation.jpg',
              isDir: false,
              size: Int64(3000000),
              modifiedAt: Int64(1725134000),
              type: 'photo',
              mimeType: 'image/jpeg',
              thumbnailUrl: '/api/thumb?path=vacation.jpg&s=256',
              blurhash: sampleBlurHash,
            ),
            DirEntry(
              name: 'music.flac',
              path: 'music.flac',
              isDir: false,
              size: Int64(25000000),
              modifiedAt: Int64(1725134000),
              type: 'audio',
              mimeType: 'audio/flac',
            ),
            DirEntry(
              name: 'docs',
              path: 'docs',
              isDir: true,
              size: Int64(0),
              modifiedAt: Int64(1725134000),
              type: 'folder',
              mimeType: 'inode/directory',
            ),
          ],
        );

        final mockClient = MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/api/dir') || path == '/api/dir') {
            final accept =
                request.headers['accept'] ?? request.headers['Accept'] ?? '';
            if (accept.contains('application/x-protobuf')) {
              return http.Response.bytes(
                protoResponse.writeToBuffer(),
                200,
                headers: {'content-type': 'application/x-protobuf'},
              );
            }
            var returnedEntries = [
              {
                'name': 'vacation.jpg',
                'path': 'vacation.jpg',
                'is_dir': false,
                'size': 3000000,
                'modified_at': 1725134000,
                'type': 'photo',
                'mime_type': 'image/jpeg',
                'thumbnail_url': '/api/thumb?path=vacation.jpg&s=256',
                'blurhash': sampleBlurHash,
              },
              {
                'name': 'music.flac',
                'path': 'music.flac',
                'is_dir': false,
                'size': 25000000,
                'modified_at': 1725134000,
                'type': 'audio',
                'mime_type': 'audio/flac',
              },
              {
                'name': 'docs',
                'path': 'docs',
                'is_dir': true,
                'size': 0,
                'modified_at': 1725134000,
                'type': 'folder',
                'mime_type': 'inode/directory',
              },
            ];
            final typeFilter = request.url.queryParameters['type'];
            if (typeFilter != null &&
                typeFilter.isNotEmpty &&
                typeFilter != 'all') {
              returnedEntries = returnedEntries
                  .where((e) => e['type'] == typeFilter)
                  .toList();
            }
            return http.Response(
              jsonEncode({'entries': returnedEntries}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (path.endsWith('/api/account/stats') ||
              path == '/api/account/stats') {
            return http.Response(jsonEncode({}), 200);
          }
          return http.Response('Not Found', 404);
        });

        final controller = ServerBrowserController(
          profile: ServerProfile(
            id: 'srv_test',
            displayName: 'Test Server',
            baseUrl: 'http://127.0.0.1:8080',
            authMode: 'login',
            lastUsedAt: DateTime.now().toUtc(),
            syncPrefs: const {},
          ),
          serverId: 'srv_test',
          authService: AuthService(secretStore: store),
          client: mockClient,
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.files.length, 3);
        final photo = controller.files.firstWhere(
          (f) => f.name == 'vacation.jpg',
        );
        expect(photo.blurhash, equals(sampleBlurHash));
        expect(
          photo.thumbnailUrl,
          equals('/api/thumb?path=vacation.jpg&s=256'),
        );

        final audio = controller.files.firstWhere(
          (f) => f.name == 'music.flac',
        );
        expect(audio.blurhash, isNull);

        final folder = controller.files.firstWhere((f) => f.name == 'docs');
        expect(folder.blurhash, isNull);

        // Filter by photos
        controller.setCategory('photo');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(controller.files.length, 1);
        expect(controller.files.first.name, 'vacation.jpg');
        expect(controller.files.first.blurhash, equals(sampleBlurHash));

        // Filter by documents -> 0 matches
        controller.setCategory('document');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(controller.files.length, 0);

        // Reset filter
        controller.setCategory('all');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(controller.files.length, 3);

        controller.disposeController();
        controller.dispose();
      },
    );
  });
}
