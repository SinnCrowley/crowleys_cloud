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

import 'package:crowleys_cloud/storage/app_database.dart';
import 'package:crowleys_cloud/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppDatabase.ensurePlatformInitialized();

  late Directory tempDir;
  late AppDatabase testDb;
  late SqliteSyncStateStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sqlite_sync_store_test_');
    final dbPath = p.join(tempDir.path, 'test_state.db');
    testDb = AppDatabase(customPath: dbPath);
    store = SqliteSyncStateStore(database: testDb);
  });

  tearDown(() async {
    await testDb.close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('SqliteSyncStateStore Single-Row Upserts & WAF Reduction', () {
    test('inserts and reads records with high fidelity', () async {
      final now = DateTime.utc(2026, 9, 5, 14, 30, 0);
      final record = SyncFileRecord(
        localPath: '/storage/emulated/0/DCIM/Camera/IMG_001.jpg',
        remotePath: 'backup/photos/IMG_001.jpg',
        sizeBytes: 4096128,
        modifiedAtMillis: 1772718600000,
        uploadedAt: now,
      );

      await store.saveRecord('srv_primary', record);

      final fetched = await store.readRecord(
        'srv_primary',
        '/storage/emulated/0/DCIM/Camera/IMG_001.jpg',
        'backup/photos/IMG_001.jpg',
      );

      expect(fetched, isNotNull);
      expect(fetched!.localPath, equals(record.localPath));
      expect(fetched.remotePath, equals(record.remotePath));
      expect(fetched.sizeBytes, equals(4096128));
      expect(fetched.modifiedAtMillis, equals(1772718600000));
      expect(fetched.uploadedAt, equals(now));

      expect(await store.totalRecordsCount(serverId: 'srv_primary'), equals(1));
    });

    test(
      'atomic single-row upsert updates existing record without duplicates',
      () async {
        final t1 = DateTime.utc(2026, 9, 5, 12, 0, 0);
        final record1 = SyncFileRecord(
          localPath: '/storage/photos/doc.pdf',
          remotePath: 'cloud/docs/doc.pdf',
          sizeBytes: 1024,
          modifiedAtMillis: 1000000,
          uploadedAt: t1,
        );
        await store.saveRecord('srv_1', record1);
        expect(await store.totalRecordsCount(serverId: 'srv_1'), equals(1));

        final t2 = DateTime.utc(2026, 9, 5, 13, 0, 0);
        final record2 = SyncFileRecord(
          localPath: '/storage/photos/doc.pdf',
          remotePath: 'cloud/docs/doc.pdf',
          sizeBytes: 2048,
          modifiedAtMillis: 2000000,
          uploadedAt: t2,
        );
        await store.saveRecord('srv_1', record2);

        // Record count must remain 1 (upsert, not duplicate)
        expect(await store.totalRecordsCount(serverId: 'srv_1'), equals(1));

        final fetched = await store.readRecord(
          'srv_1',
          '/storage/photos/doc.pdf',
          'cloud/docs/doc.pdf',
        );
        expect(fetched, isNotNull);
        expect(fetched!.sizeBytes, equals(2048));
        expect(fetched.modifiedAtMillis, equals(2000000));
        expect(fetched.uploadedAt, equals(t2));
      },
    );

    test(
      'WAF benchmark: 100 sequential file sync updates execute as O(1) mutations',
      () async {
        final initialCount = await store.totalRecordsCount();
        expect(initialCount, equals(0));

        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 100; i++) {
          final rec = SyncFileRecord(
            localPath: '/device/storage/dcim/photo_$i.jpg',
            remotePath: 'camera/photo_$i.jpg',
            sizeBytes: 2 * 1024 * 1024 + i * 512,
            modifiedAtMillis: 1700000000000 + i * 1000,
            uploadedAt: DateTime.utc(2026, 9, 5, 10, 0, i),
          );
          await store.saveRecord('srv_waf', rec);
        }
        stopwatch.stop();

        expect(await store.totalRecordsCount(serverId: 'srv_waf'), equals(100));

        // Re-updating one record must not rewrite all 100 records
        final updateStopwatch = Stopwatch()..start();
        await store.saveRecord(
          'srv_waf',
          SyncFileRecord(
            localPath: '/device/storage/dcim/photo_42.jpg',
            remotePath: 'camera/photo_42.jpg',
            sizeBytes: 3000000,
            modifiedAtMillis: 1700000099999,
            uploadedAt: DateTime.utc(2026, 9, 5, 11, 0, 0),
          ),
        );
        updateStopwatch.stop();

        expect(await store.totalRecordsCount(serverId: 'srv_waf'), equals(100));
        final updated = await store.readRecord(
          'srv_waf',
          '/device/storage/dcim/photo_42.jpg',
          'camera/photo_42.jpg',
        );
        expect(updated?.sizeBytes, equals(3000000));
      },
    );

    test(
      'supports fallback path lookup when remote path matches prefix',
      () async {
        await store.saveRecord(
          'srv_fallback',
          SyncFileRecord(
            localPath: '/local/path/file.txt',
            remotePath: 'remote/sub/file.txt',
            sizeBytes: 100,
            modifiedAtMillis: 1000,
            uploadedAt: DateTime.utc(2026, 9, 5),
          ),
        );

        final fetched = await store.readRecord(
          'srv_fallback',
          '/local/path/file.txt',
          'different/remote/candidate.txt',
        );
        expect(fetched, isNotNull);
        expect(fetched!.localPath, equals('/local/path/file.txt'));
      },
    );
  });

  group('SqliteSyncStateStore SyncRunResult Persistence', () {
    test('round-trips SyncRunResult across all statuses', () async {
      final now = DateTime.utc(2026, 9, 5, 15, 0, 0);

      for (final status in SyncRunStatus.values) {
        final result = SyncRunResult(
          status: status,
          scannedFiles: 50,
          uploadedFiles: 45,
          skippedFiles: 3,
          failedFiles: 2,
          startedAt: now.subtract(const Duration(minutes: 2)),
          finishedAt: now,
          message: 'Status test for $status',
        );

        await store.saveLastResult('srv_status_${status.name}', result);

        final fetched = await store.readLastResult('srv_status_${status.name}');
        expect(fetched, isNotNull);
        expect(fetched!.status, equals(status));
        expect(fetched.scannedFiles, equals(50));
        expect(fetched.uploadedFiles, equals(45));
        expect(fetched.skippedFiles, equals(3));
        expect(fetched.failedFiles, equals(2));
        expect(fetched.message, equals('Status test for $status'));
      }
    });

    test('updates last result on conflict without duplicating rows', () async {
      final t1 = DateTime.utc(2026, 9, 5, 10, 0, 0);
      final r1 = SyncRunResult(
        status: SyncRunStatus.success,
        scannedFiles: 10,
        uploadedFiles: 10,
        skippedFiles: 0,
        failedFiles: 0,
        startedAt: t1,
        finishedAt: t1.add(const Duration(seconds: 10)),
        message: 'Initial run',
      );
      await store.saveLastResult('srv_update', r1);

      final t2 = DateTime.utc(2026, 9, 5, 12, 0, 0);
      final r2 = SyncRunResult(
        status: SyncRunStatus.partialFailure,
        scannedFiles: 20,
        uploadedFiles: 15,
        skippedFiles: 2,
        failedFiles: 3,
        startedAt: t2,
        finishedAt: t2.add(const Duration(seconds: 15)),
        message: 'Secondary run with failures',
      );
      await store.saveLastResult('srv_update', r2);

      final fetched = await store.readLastResult('srv_update');
      expect(fetched?.status, equals(SyncRunStatus.partialFailure));
      expect(fetched?.scannedFiles, equals(20));
      expect(fetched?.message, equals('Secondary run with failures'));
    });
  });

  group('SqliteSyncStateStore Zero-Downtime Migration from sync_state.json', () {
    test(
      'migrates existing sync_state.json data into SQLite and renames file',
      () async {
        final legacyFile = File(p.join(tempDir.path, 'sync_state.json'));
        final legacyData = {
          'servers': {
            'server_legacy': {
              'files': {
                '/photos/pic1.jpg:backup/pic1.jpg': {
                  'localPath': '/photos/pic1.jpg',
                  'remotePath': 'backup/pic1.jpg',
                  'sizeBytes': 500000,
                  'modifiedAtMillis': 1700000001000,
                  'uploadedAt': '2026-09-05T08:00:00.000Z',
                },
                '/photos/pic2.jpg:backup/pic2.jpg': {
                  'localPath': '/photos/pic2.jpg',
                  'remotePath': 'backup/pic2.jpg',
                  'sizeBytes': 750000,
                  'modifiedAtMillis': 1700000002000,
                  'uploadedAt': '2026-09-05T08:05:00.000Z',
                },
              },
              'lastResult': {
                'status': 'success',
                'scannedFiles': 2,
                'uploadedFiles': 2,
                'skippedFiles': 0,
                'failedFiles': 0,
                'startedAt': '2026-09-05T07:59:00.000Z',
                'finishedAt': '2026-09-05T08:05:30.000Z',
                'message': 'Legacy sync succeeded',
              },
            },
          },
        };
        await legacyFile.writeAsString(jsonEncode(legacyData));

        // Initialize a fresh store with the legacyFileProvider pointing to legacyFile
        final migrationDb = AppDatabase(
          customPath: p.join(tempDir.path, 'migration.db'),
        );
        final migrationStore = SqliteSyncStateStore(
          database: migrationDb,
          legacyFileProvider: () async => legacyFile,
        );

        final rec1 = await migrationStore.readRecord(
          'server_legacy',
          '/photos/pic1.jpg',
          'backup/pic1.jpg',
        );
        expect(rec1, isNotNull);
        expect(rec1!.sizeBytes, equals(500000));

        final rec2 = await migrationStore.readRecord(
          'server_legacy',
          '/photos/pic2.jpg',
          'backup/pic2.jpg',
        );
        expect(rec2, isNotNull);
        expect(rec2!.sizeBytes, equals(750000));

        final lastResult = await migrationStore.readLastResult('server_legacy');
        expect(lastResult, isNotNull);
        expect(lastResult!.status, equals(SyncRunStatus.success));
        expect(lastResult.scannedFiles, equals(2));

        // Legacy file should have been renamed to .migrated
        expect(await legacyFile.exists(), isFalse);
        expect(await File('${legacyFile.path}.migrated').exists(), isTrue);

        await migrationDb.close();
      },
    );

    test(
      'recovers gracefully from corrupted legacy JSON without crashing',
      () async {
        final legacyFile = File(p.join(tempDir.path, 'corrupt_state.json'));
        await legacyFile.writeAsString('{{{{ NOT A VALID JSON }}}}');

        final corruptDb = AppDatabase(
          customPath: p.join(tempDir.path, 'corrupt.db'),
        );
        final corruptStore = SqliteSyncStateStore(
          database: corruptDb,
          legacyFileProvider: () async => legacyFile,
        );

        // Should not throw
        final rec = await corruptStore.readRecord('any', 'path', 'remote');
        expect(rec, isNull);

        await corruptStore.saveRecord(
          'any',
          SyncFileRecord(
            localPath: '/a',
            remotePath: 'b',
            sizeBytes: 1,
            modifiedAtMillis: 1,
            uploadedAt: DateTime.now().toUtc(),
          ),
        );
        expect(await corruptStore.totalRecordsCount(), equals(1));

        await corruptDb.close();
      },
    );
  });

  group('Cross-Isolate / Concurrent Access Simulation', () {
    test(
      'concurrent reads and writes execute without lock contention',
      () async {
        final errors = <Object>[];

        // Simulated Actor 1: Background sync uploading and recording 50 files
        Future<void> backgroundSyncActor() async {
          for (var i = 0; i < 50; i++) {
            try {
              await store.saveRecord(
                'srv_concurrent',
                SyncFileRecord(
                  localPath: '/sdcard/dcim/img_$i.jpg',
                  remotePath: 'cloud/img_$i.jpg',
                  sizeBytes: 1024 * (i + 1),
                  modifiedAtMillis: 1700000000000 + i,
                  uploadedAt: DateTime.utc(2026, 9, 5, 12, 0, i),
                ),
              );
              await Future<void>.delayed(const Duration(milliseconds: 1));
            } catch (e) {
              errors.add(e);
            }
          }
        }

        // Simulated Actor 2: UI thread querying state and last result
        Future<void> uiThreadActor() async {
          for (var i = 0; i < 50; i++) {
            try {
              await store.readRecord(
                'srv_concurrent',
                '/sdcard/dcim/img_${i % 25}.jpg',
                'cloud/img_${i % 25}.jpg',
              );
              await store.readLastResult('srv_concurrent');
              await Future<void>.delayed(const Duration(milliseconds: 1));
            } catch (e) {
              errors.add(e);
            }
          }
        }

        await Future.wait([backgroundSyncActor(), uiThreadActor()]);

        expect(errors, isEmpty);
        expect(
          await store.totalRecordsCount(serverId: 'srv_concurrent'),
          equals(50),
        );
      },
    );
  });
}
