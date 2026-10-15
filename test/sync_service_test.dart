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
import 'dart:io';
import 'dart:typed_data';

import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/sync_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeScanner implements SyncFileScanner {
  _FakeScanner(this.candidates);

  final List<SyncCandidate> candidates;

  @override
  Future<List<SyncCandidate>> scan(ServerProfile server) async => candidates;
}

class _FakeApiClient implements SyncApiClient {
  final createdFolders = <String>[];
  final uploadedPaths = <String>[];
  final Map<String, Uint8List?> uploadedThumbnails = {};
  final existingPaths = <String>{};
  final Map<String, String> hashToExistingPath = {};
  String? failUploadPath;
  bool isServerUnreachable = false;
  bool authRequired = false;
  bool maintenance = false;

  @override
  Future<bool> ping({required ServerProfile server}) async {
    if (isServerUnreachable) return false;
    return true;
  }

  @override
  Future<void> createFolder({
    required ServerProfile server,
    required String remotePath,
  }) async {
    if (authRequired) throw const SyncException('Authentication required');
    createdFolders.add(remotePath);
  }

  @override
  Future<void> uploadFile({
    required ServerProfile server,
    required String remotePath,
    required File file,
    Uint8List? thumbnailBytes,
  }) async {
    if (authRequired) throw const SyncException('Authentication required');
    if (maintenance) {
      throw const SyncException('Maintenance', isMaintenance: true);
    }
    if (remotePath == failUploadPath) {
      throw const SyncException('Upload failed');
    }
    uploadedPaths.add(remotePath);
    uploadedThumbnails[remotePath] = thumbnailBytes;
  }

  @override
  Future<bool> fileExists({
    required ServerProfile server,
    required String remotePath,
  }) async {
    if (authRequired) throw const SyncException('Authentication required');
    return existingPaths.contains(remotePath) ||
        uploadedPaths.contains(remotePath);
  }

  @override
  Future<Map<String, String>> checkHashes({
    required ServerProfile server,
    required List<String> hashes,
  }) async {
    if (authRequired) throw const SyncException('Authentication required');
    final result = <String, String>{};
    for (final hash in hashes) {
      if (hashToExistingPath.containsKey(hash)) {
        result[hash] = hashToExistingPath[hash]!;
      }
    }
    return result;
  }

  @override
  Future<int> getUploadStatus({
    required ServerProfile server,
    required String remotePath,
  }) async {
    if (authRequired) throw const SyncException('Authentication required');
    return 0;
  }
}

Future<File> writeTestFile(
  Directory tempDir,
  String name,
  String contents,
) async {
  final file = File('${tempDir.path}/$name');
  await file.writeAsString(contents);
  return file;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ServerProfile server;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_service_test');
    server = ServerProfile(
      id: 'srv',
      displayName: 'Home',
      baseUrl: 'http://localhost',
      authMode: 'login',
      lastUsedAt: DateTime.utc(2026, 6),
      syncPrefs: const {'syncEnabled': true},
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('uploads files and records successful manifest state', () async {
    final file = await writeTestFile(tempDir, 'photo.jpg', 'image');
    final api = _FakeApiClient();
    final stateFile = File('${tempDir.path}/state.json');
    final stateStore = FileSyncStateStore(fileProvider: () async => stateFile);
    final service = SyncService(
      scanner: _FakeScanner([
        SyncCandidate(file: file, remotePath: 'backup/photos/photo.jpg'),
      ]),
      apiClient: api,
      stateStore: stateStore,
    );

    final result = await service.syncServer(server);

    expect(result.status, SyncRunStatus.success);
    expect(result.uploadedFiles, 1);
    expect(api.createdFolders, ['backup', 'backup/photos']);
    expect(api.uploadedPaths, ['backup/photos/photo.jpg']);
    final record = await stateStore.readRecord(
      server.id,
      file.absolute.path,
      'backup/photos/photo.jpg',
    );
    expect(record?.remotePath, 'backup/photos/photo.jpg');
  });

  test('skips unchanged files from manifest', () async {
    final file = await writeTestFile(tempDir, 'doc.txt', 'same');
    final stateFile = File('${tempDir.path}/state.json');
    final stateStore = FileSyncStateStore(fileProvider: () async => stateFile);
    final stat = await file.stat();
    await stateStore.saveRecord(
      server.id,
      SyncFileRecord(
        localPath: file.absolute.path,
        remotePath: 'backup/documents/doc.txt',
        sizeBytes: stat.size,
        modifiedAtMillis: stat.modified.toUtc().millisecondsSinceEpoch,
        uploadedAt: DateTime.now().toUtc(),
      ),
    );
    final api = _FakeApiClient()..existingPaths.add('backup/documents/doc.txt');
    final service = SyncService(
      scanner: _FakeScanner([
        SyncCandidate(file: file, remotePath: 'backup/documents/doc.txt'),
      ]),
      apiClient: api,
      stateStore: stateStore,
    );

    final result = await service.syncServer(server);

    expect(result.status, SyncRunStatus.success);
    expect(result.skippedFiles, 1);
    expect(api.uploadedPaths, isEmpty);
  });

  test(
    'maintenance defers unconfirmed files and retries them next run',
    () async {
      final file = await writeTestFile(tempDir, 'pending.txt', 'content');
      final api = _FakeApiClient()..maintenance = true;
      final stateStore = FileSyncStateStore(
        fileProvider: () async => File('${tempDir.path}/state.json'),
      );
      final service = SyncService(
        scanner: _FakeScanner([
          SyncCandidate(file: file, remotePath: 'pending.txt'),
        ]),
        apiClient: api,
        stateStore: stateStore,
      );
      final deferred = await service.syncServer(server);
      expect(deferred.status, SyncRunStatus.maintenance);
      expect(deferred.uploadedFiles, 0);
      expect(
        await stateStore.readRecord(
          server.id,
          file.absolute.path,
          'pending.txt',
        ),
        null,
      );
      api.maintenance = false;
      final retried = await service.syncServer(server);
      expect(retried.status, SyncRunStatus.success);
      expect(api.uploadedPaths, ['pending.txt']);
      expect(
        await stateStore.readRecord(
          server.id,
          file.absolute.path,
          'pending.txt',
        ),
        isNotNull,
      );
    },
  );

  test('keeps prior manifest when upload fails', () async {
    final file = await writeTestFile(tempDir, 'video.mp4', 'new');
    final api = _FakeApiClient()..failUploadPath = 'backup/videos/video.mp4';
    final stateStore = FileSyncStateStore(
      fileProvider: () async => File('${tempDir.path}/state.json'),
    );
    final service = SyncService(
      scanner: _FakeScanner([
        SyncCandidate(file: file, remotePath: 'backup/videos/video.mp4'),
      ]),
      apiClient: api,
      stateStore: stateStore,
    );

    final result = await service.syncServer(server);

    expect(result.status, SyncRunStatus.partialFailure);
    expect(result.failedFiles, 1);
    expect(
      await stateStore.readRecord(
        server.id,
        file.absolute.path,
        'backup/videos/video.mp4',
      ),
      null,
    );
  });

  test('stops with authRequired when API has no usable session', () async {
    final file = await writeTestFile(tempDir, 'photo.jpg', 'image');
    final api = _FakeApiClient()..authRequired = true;
    final stateStore = FileSyncStateStore(
      fileProvider: () async => File('${tempDir.path}/state.json'),
    );
    final service = SyncService(
      scanner: _FakeScanner([
        SyncCandidate(file: file, remotePath: 'backup/photos/photo.jpg'),
      ]),
      apiClient: api,
      stateStore: stateStore,
    );

    final result = await service.syncServer(server);

    expect(result.status, SyncRunStatus.authRequired);
    expect(result.uploadedFiles, 0);
  });

  test('scanner deduplicates category and explicit folder matches', () async {
    final root = Directory('${tempDir.path}/storage/emulated/0');
    final appDir = Directory('${root.path}/Android/data/app/files');
    final photosDir = Directory('${root.path}/DCIM');
    await appDir.create(recursive: true);
    await photosDir.create(recursive: true);
    final photo = File('${photosDir.path}/same.jpg');
    await photo.writeAsString('image');
    final scanner = DeviceSyncFileScanner(
      externalStorageDirectoriesProvider: () async => [appDir],
    );
    final scanServer = server.copyWith(
      syncPrefs: {
        'backupTargetDirectory': '/backup/device',
        'syncCategories': ['photos'],
        'syncFolders': [photosDir.path],
      },
    );

    final candidates = await scanner.scan(scanServer);

    expect(candidates.length, 1);
    expect(candidates.single.remotePath, 'backup/device/DCIM/same.jpg');
  });

  test(
    'scanner ignores Android/data and Android/obb directories completely',
    () async {
      final root = Directory('${tempDir.path}/storage/emulated/0');
      final appDir = Directory('${root.path}/Android/data/app/files');
      final dataPhotoDir = Directory('${root.path}/Android/data/app/photos');
      final obbPhotoDir = Directory('${root.path}/Android/obb/app/photos');
      final otherPhotoDir = Directory('${root.path}/DCIM');
      await dataPhotoDir.create(recursive: true);
      await obbPhotoDir.create(recursive: true);
      await otherPhotoDir.create(recursive: true);

      final dataPhoto = File('${dataPhotoDir.path}/data_img.jpg');
      final obbPhoto = File('${obbPhotoDir.path}/obb_img.jpg');
      final otherPhoto = File('${otherPhotoDir.path}/other_img.jpg');
      await dataPhoto.writeAsString('data image');
      await obbPhoto.writeAsString('obb image');
      await otherPhoto.writeAsString('other image');

      final scanner = DeviceSyncFileScanner(
        externalStorageDirectoriesProvider: () async => [appDir],
      );
      final scanServer = server.copyWith(
        syncPrefs: {
          'backupTargetDirectory': '/backup/device',
          'syncCategories': ['photos'],
          'syncFolders': <String>[],
        },
      );

      final candidates = await scanner.scan(scanServer);

      expect(candidates.length, 1);
      expect(
        candidates.single.remotePath,
        'backup/device/photos/other_img.jpg',
      );
    },
  );

  test('scanner gracefully handles directory listing exceptions', () async {
    final root = Directory('${tempDir.path}/storage/emulated/0');
    final appDir = Directory('${root.path}/Android/data/app/files');
    final badDir = Directory('${root.path}/RestrictedDir');
    final goodDir = Directory('${root.path}/AllowedDir');
    await badDir.create(recursive: true);
    await goodDir.create(recursive: true);

    final goodPhoto = File('${goodDir.path}/good_img.jpg');
    await goodPhoto.writeAsString('good image');

    final badPhoto = File('${badDir.path}/bad_img.jpg');
    await badPhoto.writeAsString('bad image');

    final scanner = DeviceSyncFileScanner(
      externalStorageDirectoriesProvider: () async => [appDir],
    );
    final scanServer = server.copyWith(
      syncPrefs: {
        'backupTargetDirectory': '/backup/device',
        'syncCategories': ['photos'],
        'syncFolders': <String>[],
      },
    );

    // Delete badDir to simulate a listing issue during scanning
    await badDir.delete(recursive: true);

    final candidates = await scanner.scan(scanServer);
    expect(candidates.length, 1);
    expect(candidates.single.remotePath, 'backup/device/photos/good_img.jpg');
  });

  test('syncServer invokes onProgress callback with correct values', () async {
    final file1 = await writeTestFile(tempDir, 'photo1.jpg', 'image1');
    final file2 = await writeTestFile(tempDir, 'photo2.jpg', 'image2');
    final api = _FakeApiClient();
    final stateFile = File('${tempDir.path}/state.json');
    final stateStore = FileSyncStateStore(fileProvider: () async => stateFile);
    final service = SyncService(
      scanner: _FakeScanner([
        SyncCandidate(file: file1, remotePath: 'backup/photos/photo1.jpg'),
        SyncCandidate(file: file2, remotePath: 'backup/photos/photo2.jpg'),
      ]),
      apiClient: api,
      stateStore: stateStore,
    );

    final progressMessages = <String>[];
    final progressValues = <double?>[];

    final result = await service.syncServer(
      server,
      onProgress: (message, progress) {
        progressMessages.add(message);
        progressValues.add(progress);
      },
    );

    expect(result.status, SyncRunStatus.success);
    expect(progressMessages, contains('Scanning files on device...'));
    expect(progressMessages, contains('Syncing (1/2): photo1.jpg'));
    expect(progressMessages, contains('Syncing (2/2): photo2.jpg'));
    expect(progressMessages, contains('Completing synchronization...'));

    expect(progressValues.first, isNull); // Scanning files
    expect(progressValues.contains(0.0), isTrue);
    expect(progressValues.contains(0.5), isTrue);
    expect(progressValues.last, 1.0); // Completing
  });

  test('skips upload if file hash exists on server at different path', () async {
    final file = await writeTestFile(
      tempDir,
      'photo.jpg',
      'same-content-different-name',
    );
    final stateFile = File('${tempDir.path}/state.json');
    final stateStore = FileSyncStateStore(fileProvider: () async => stateFile);
    final api = _FakeApiClient();

    final service = SyncService(
      scanner: _FakeScanner([
        SyncCandidate(file: file, remotePath: 'backup/photos/photo.jpg'),
      ]),
      apiClient: api,
      stateStore: stateStore,
    );
    final fileHash = await service.calculateSha256(file);

    // Register the hash as existing on the server under a completely different path
    api.hashToExistingPath[fileHash] = 'manual_uploads/archived_photo.jpg';

    final result = await service.syncServer(server);

    expect(result.status, SyncRunStatus.success);
    expect(result.skippedFiles, 1);
    expect(result.uploadedFiles, 0);
    expect(api.uploadedPaths, isEmpty);

    // Verify it saved a sync record pointing to the existing server path
    final record = await stateStore.readRecord(
      server.id,
      file.absolute.path,
      'backup/photos/photo.jpg',
    );
    expect(record, isNotNull);
    expect(record?.remotePath, 'manual_uploads/archived_photo.jpg');
  });

  test(
    'aborts early and returns serverUnreachable status if ping fails',
    () async {
      final file = await writeTestFile(tempDir, 'photo.jpg', 'some content');
      final stateFile = File('${tempDir.path}/state.json');
      final stateStore = FileSyncStateStore(
        fileProvider: () async => stateFile,
      );
      final api = _FakeApiClient()..isServerUnreachable = true;

      final service = SyncService(
        scanner: _FakeScanner([
          SyncCandidate(file: file, remotePath: 'backup/photos/photo.jpg'),
        ]),
        apiClient: api,
        stateStore: stateStore,
      );

      final result = await service.syncServer(server);

      expect(result.status, SyncRunStatus.serverUnreachable);
      expect(result.uploadedFiles, 0);
      expect(api.uploadedPaths, isEmpty);
      expect(result.message, contains('Could not connect'));
    },
  );

  test(
    'returns localized Russian connection lost message when l10n is provided',
    () async {
      final stateFile = File('${tempDir.path}/state.json');
      final stateStore = FileSyncStateStore(
        fileProvider: () async => stateFile,
      );
      final api = _FakeApiClient()..isServerUnreachable = true;
      final service = SyncService(
        scanner: _FakeScanner([]),
        apiClient: api,
        stateStore: stateStore,
      );

      final l10nRu = lookupAppLocalizations(const Locale('ru'));
      final result = await service.syncServer(server, l10n: l10nRu);

      expect(result.status, SyncRunStatus.serverUnreachable);
      expect(
        result.message,
        l10nRu.syncStatusConnectionLost(server.displayName),
      );
    },
  );

  test('emits localized Russian progress messages during sync run', () async {
    final file = await writeTestFile(tempDir, 'photo.jpg', 'some content');
    final stateFile = File('${tempDir.path}/state.json');
    final stateStore = FileSyncStateStore(fileProvider: () async => stateFile);
    final api = _FakeApiClient();
    final service = SyncService(
      scanner: _FakeScanner([
        SyncCandidate(file: file, remotePath: 'backup/photos/photo.jpg'),
      ]),
      apiClient: api,
      stateStore: stateStore,
    );

    final l10nRu = lookupAppLocalizations(const Locale('ru'));
    final progressMessages = <String>[];
    final result = await service.syncServer(
      server,
      l10n: l10nRu,
      onProgress: (message, progress) => progressMessages.add(message),
    );

    expect(result.status, SyncRunStatus.success);
    expect(progressMessages, contains('Подключение к серверу...'));
    expect(progressMessages, contains('Сканирование файлов на устройстве...'));
    expect(progressMessages, contains('Проверка дубликатов на сервере...'));
    expect(progressMessages, contains('Завершение синхронизации...'));
  });

  test(
    'scanner falls back to application documents directory when not on Android',
    () async {
      final docsDir = Directory('${tempDir.path}/app_docs');
      final photosDir = Directory('${docsDir.path}/Pictures');
      await photosDir.create(recursive: true);
      final photo = File('${photosDir.path}/ios_photo.jpg');
      await photo.writeAsString('ios photo data');

      final scanner = DeviceSyncFileScanner(
        applicationDocumentsDirectoryProvider: () async => docsDir,
      );
      final scanServer = server.copyWith(
        syncPrefs: {
          'backupTargetDirectory': '/backup/device',
          'syncCategories': ['photos'],
          'syncFolders': <String>[],
        },
      );

      final candidates = await scanner.scan(scanServer);
      expect(candidates.length, 1);
      expect(
        candidates.single.remotePath,
        'backup/device/photos/ios_photo.jpg',
      );
    },
  );

  test(
    'scanner falls back to application documents when externalStorage throws',
    () async {
      final docsDir = Directory('${tempDir.path}/app_docs_fallback');
      final docsSubDir = Directory('${docsDir.path}/Documents');
      await docsSubDir.create(recursive: true);
      final doc = File('${docsSubDir.path}/note.pdf');
      await doc.writeAsString('document content');

      final scanner = DeviceSyncFileScanner(
        externalStorageDirectoriesProvider: () async =>
            throw UnsupportedError('Not supported on iOS'),
        applicationDocumentsDirectoryProvider: () async => docsDir,
      );
      final scanServer = server.copyWith(
        syncPrefs: {
          'backupTargetDirectory': '/backup/device',
          'syncCategories': ['documents'],
          'syncFolders': <String>[],
        },
      );

      final candidates = await scanner.scan(scanServer);
      expect(candidates.length, 1);
      expect(candidates.single.remotePath, 'backup/device/documents/note.pdf');
    },
  );

  test(
    'syncServer safely stops processing candidates when deadline expires',
    () async {
      final file1 = await writeTestFile(tempDir, 'file1.jpg', 'content 1');
      final file2 = await writeTestFile(tempDir, 'file2.jpg', 'content 2');
      final stateFile = File('${tempDir.path}/state.json');
      final stateStore = FileSyncStateStore(
        fileProvider: () async => stateFile,
      );
      final api = _FakeApiClient();
      final service = SyncService(
        scanner: _FakeScanner([
          SyncCandidate(file: file1, remotePath: 'backup/photos/file1.jpg'),
          SyncCandidate(file: file2, remotePath: 'backup/photos/file2.jpg'),
        ]),
        apiClient: api,
        stateStore: stateStore,
      );

      // Provide a deadline that is already in the past
      final pastDeadline = DateTime.now().subtract(const Duration(seconds: 5));
      final result = await service.syncServer(server, deadline: pastDeadline);

      // Candidates were scanned, but upload loop stopped before processing files
      expect(result.scannedFiles, 2);
      expect(result.uploadedFiles, 0);
      expect(api.uploadedPaths, isEmpty);

      // Verify last result was persisted despite early exit
      final lastResult = await stateStore.readLastResult(server.id);
      expect(lastResult, isNotNull);
      expect(lastResult?.scannedFiles, 2);
      expect(lastResult?.uploadedFiles, 0);
    },
  );

  test(
    'scanner queries mediaAssetsProvider when photos or videos categories selected',
    () async {
      final photoFile = await writeTestFile(tempDir, 'photo.jpg', 'photo data');
      final videoFile = await writeTestFile(tempDir, 'clip.mp4', 'video data');
      final docsDir = Directory('${tempDir.path}/docs')
        ..createSync(recursive: true);

      var mediaScanned = false;
      final scanner = DeviceSyncFileScanner(
        applicationDocumentsDirectoryProvider: () async => docsDir,
        mediaAssetsProvider:
            ({
              required selectedCategories,
              required target,
              required selectedFolders,
            }) async {
              mediaScanned = true;
              return [
                SyncCandidate(
                  file: photoFile,
                  remotePath: '$target/photos/photo.jpg',
                ),
                SyncCandidate(
                  file: videoFile,
                  remotePath: '$target/videos/clip.mp4',
                ),
              ];
            },
        isIos: true,
      );

      final scanServer = server.copyWith(
        syncPrefs: {
          'backupTargetDirectory': '/backup/ios',
          'syncCategories': ['photos', 'videos'],
          'syncFolders': <String>[],
        },
      );

      final candidates = await scanner.scan(scanServer);
      expect(mediaScanned, isTrue);
      expect(candidates.length, 2);
      expect(candidates[0].remotePath, 'backup/ios/photos/photo.jpg');
      expect(candidates[1].remotePath, 'backup/ios/videos/clip.mp4');
    },
  );

  test(
    'scanner does not query mediaAssetsProvider when photos and videos are not selected',
    () async {
      final docsDir = Directory('${tempDir.path}/docs')
        ..createSync(recursive: true);
      await writeTestFile(docsDir, 'doc.pdf', 'pdf data');

      var mediaScanned = false;
      final scanner = DeviceSyncFileScanner(
        applicationDocumentsDirectoryProvider: () async => docsDir,
        mediaAssetsProvider:
            ({
              required selectedCategories,
              required target,
              required selectedFolders,
            }) async {
              mediaScanned = true;
              return [];
            },
        isIos: true,
      );

      final scanServer = server.copyWith(
        syncPrefs: {
          'backupTargetDirectory': '/backup/ios',
          'syncCategories': ['documents'],
          'syncFolders': <String>[],
        },
      );

      final candidates = await scanner.scan(scanServer);
      expect(mediaScanned, isFalse);
      expect(candidates.length, 1);
      expect(candidates.single.remotePath, 'backup/ios/documents/doc.pdf');
    },
  );

  group('Video thumbnail sync integration', () {
    test(
      'passes extracted video thumbnailBytes when syncing video files',
      () async {
        final videoFile = await writeTestFile(
          tempDir,
          'sample_video.mp4',
          'dummy video',
        );
        final dummyThumbnail = Uint8List.fromList([
          0x52,
          0x49,
          0x46,
          0x46,
          0x00,
          0x00,
          0x00,
          0x00,
          0x57,
          0x45,
          0x42,
          0x50,
        ]);
        final api = _FakeApiClient();
        final stateStore = FileSyncStateStore(
          fileProvider: () async => File('${tempDir.path}/state.json'),
        );
        final service = SyncService(
          scanner: _FakeScanner([
            SyncCandidate(
              file: videoFile,
              remotePath: 'backup/videos/sample_video.mp4',
            ),
          ]),
          apiClient: api,
          stateStore: stateStore,
          videoPosterExtractor: (path) async => dummyThumbnail,
        );

        final result = await service.syncServer(server);

        expect(result.status, SyncRunStatus.success);
        expect(result.uploadedFiles, 1);
        expect(api.uploadedPaths, ['backup/videos/sample_video.mp4']);
        expect(
          api.uploadedThumbnails['backup/videos/sample_video.mp4'],
          equals(dummyThumbnail),
        );
      },
    );

    test(
      'passes null thumbnailBytes when syncing non-video files (photos, documents)',
      () async {
        final photoFile = await writeTestFile(
          tempDir,
          'photo.jpg',
          'jpeg content',
        );
        final docFile = await writeTestFile(
          tempDir,
          'report.pdf',
          'pdf content',
        );
        final dummyThumbnail = Uint8List.fromList([1, 2, 3, 4]);
        final api = _FakeApiClient();
        final stateStore = FileSyncStateStore(
          fileProvider: () async => File('${tempDir.path}/state.json'),
        );
        final service = SyncService(
          scanner: _FakeScanner([
            SyncCandidate(
              file: photoFile,
              remotePath: 'backup/photos/photo.jpg',
            ),
            SyncCandidate(file: docFile, remotePath: 'backup/docs/report.pdf'),
          ]),
          apiClient: api,
          stateStore: stateStore,
          videoPosterExtractor: (path) async => dummyThumbnail,
        );

        final result = await service.syncServer(server);

        expect(result.status, SyncRunStatus.success);
        expect(result.uploadedFiles, 2);
        expect(api.uploadedThumbnails['backup/photos/photo.jpg'], isNull);
        expect(api.uploadedThumbnails['backup/docs/report.pdf'], isNull);
      },
    );

    test(
      'gracefully continues video upload with null thumbnail if extraction fails or throws',
      () async {
        final videoFile = await writeTestFile(
          tempDir,
          'corrupt.mp4',
          'broken video',
        );
        final api = _FakeApiClient();
        final stateStore = FileSyncStateStore(
          fileProvider: () async => File('${tempDir.path}/state.json'),
        );
        final service = SyncService(
          scanner: _FakeScanner([
            SyncCandidate(
              file: videoFile,
              remotePath: 'backup/videos/corrupt.mp4',
            ),
          ]),
          apiClient: api,
          stateStore: stateStore,
          videoPosterExtractor: (path) async =>
              throw Exception('Extraction crashed'),
        );

        final result = await service.syncServer(server);

        expect(result.status, SyncRunStatus.success);
        expect(result.uploadedFiles, 1);
        expect(api.uploadedPaths, ['backup/videos/corrupt.mp4']);
        expect(api.uploadedThumbnails['backup/videos/corrupt.mp4'], isNull);
      },
    );

    test(
      'HttpSyncApiClient attaches X-Thumbnail header on terminal chunk and 0-byte upload',
      () async {
        final thumbBytes = Uint8List.fromList([
          0x52,
          0x49,
          0x46,
          0x46,
          0x00,
          0x00,
          0x00,
          0x00,
          0x57,
          0x45,
          0x42,
          0x50,
        ]);
        final capturedHeaders = <Map<String, String>>[];

        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/files/upload-status') {
            return http.Response(jsonEncode({'bytes_received': 0}), 200);
          }
          if (request.url.path == '/api/files') {
            capturedHeaders.add(Map.from(request.headers));
            return http.Response('', 200);
          }
          return http.Response('', 404);
        });

        final secretStore = InMemorySecretStore();
        await secretStore.saveSyncToken(
          serverId: 'srv',
          syncToken: 'test_sync_token',
        );
        final authService = AuthService(secretStore: secretStore);
        final syncApiClient = HttpSyncApiClient(
          authService: authService,
          client: mockClient,
        );

        // 1. Test chunked upload: file size 3 MB (> 2 MB chunk size)
        final largeVideoFile = await writeTestFile(
          tempDir,
          'large_video.mp4',
          'a' * (3 * 1024 * 1024),
        );
        await syncApiClient.uploadFile(
          server: server,
          remotePath: 'backup/videos/large_video.mp4',
          file: largeVideoFile,
          thumbnailBytes: thumbBytes,
        );

        expect(capturedHeaders.length, 2);
        // First chunk (intermediate, is_last=false) must NOT have x-thumbnail
        expect(capturedHeaders[0].containsKey('x-thumbnail'), isFalse);
        // Second chunk (terminal, is_last=true) MUST have x-thumbnail
        expect(
          capturedHeaders[1]['x-thumbnail'],
          equals(base64Encode(thumbBytes)),
        );

        // 2. Test 0-byte file: attaches x-thumbnail
        capturedHeaders.clear();
        final emptyVideoFile = await writeTestFile(
          tempDir,
          'empty_video.mp4',
          '',
        );
        await syncApiClient.uploadFile(
          server: server,
          remotePath: 'backup/videos/empty_video.mp4',
          file: emptyVideoFile,
          thumbnailBytes: thumbBytes,
        );

        expect(capturedHeaders.length, 1);
        expect(
          capturedHeaders[0]['x-thumbnail'],
          equals(base64Encode(thumbBytes)),
        );

        // 3. Test upload without thumbnail: no x-thumbnail header
        capturedHeaders.clear();
        await syncApiClient.uploadFile(
          server: server,
          remotePath: 'backup/videos/empty_video.mp4',
          file: emptyVideoFile,
          thumbnailBytes: null,
        );

        expect(capturedHeaders.length, 1);
        expect(capturedHeaders[0].containsKey('x-thumbnail'), isFalse);
      },
    );
  });
}
