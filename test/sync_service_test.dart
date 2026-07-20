import 'dart:io';

import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeScanner implements SyncFileScanner {
  _FakeScanner(this.candidates);

  final List<SyncCandidate> candidates;

  @override
  Future<List<SyncCandidate>> scan(ServerProfile server) async => candidates;
}

class _FakeApiClient implements SyncApiClient {
  final createdFolders = <String>[];
  final uploadedPaths = <String>[];
  final existingPaths = <String>{};
  final Map<String, String> hashToExistingPath = {};
  String? failUploadPath;
  bool isServerUnreachable = false;
  bool authRequired = false;

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
  }) async {
    if (authRequired) throw const SyncException('Authentication required');
    if (remotePath == failUploadPath) {
      throw const SyncException('Upload failed');
    }
    uploadedPaths.add(remotePath);
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

  test('aborts early and returns serverUnreachable status if ping fails', () async {
    final file = await writeTestFile(tempDir, 'photo.jpg', 'some content');
    final stateFile = File('${tempDir.path}/state.json');
    final stateStore = FileSyncStateStore(fileProvider: () async => stateFile);
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
  });
}
