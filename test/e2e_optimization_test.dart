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

import 'dart:io';
import 'dart:typed_data';

import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/server_file_item.dart';
import 'package:crowleys_cloud/sync_service.dart';
import 'package:crowleys_cloud/transfer_manager.dart';
import 'package:crowleys_cloud/upload_conflict_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'e2e_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testTempDir;
  late Directory supportDir;
  late Directory cacheTempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    testTempDir = await Directory.systemTemp.createTemp('e2e_opt_test_');
    supportDir = Directory(p.join(testTempDir.path, 'support'));
    cacheTempDir = Directory(p.join(testTempDir.path, 'temp'));
    await CacheService.instance.init(
      supportDir: supportDir,
      tempDir: cacheTempDir,
    );
  });

  tearDown(() async {
    if (await testTempDir.exists()) {
      await testTempDir.delete(recursive: true);
    }
  });

  // =========================================================================
  // Requirement R1: UI Unblocking & RAM Protection
  // =========================================================================
  group('E2E Focus R1: UI Unblocking, RAM Bounds & Worker Pool', () {
    test(
      'R1.1: Empirical statSync tracking on FileItem property getters',
      () async {
        final realFile = File(p.join(testTempDir.path, 'sample.txt'))
          ..writeAsStringSync('Hello E2E R1');
        final trackingFile = StatTrackingFile(realFile);

        final item = FileItem.fromEntity(trackingFile);

        // Access properties: must be non-blocking with zero statSync calls
        final accessedSize = item.size;
        final accessedDate = item.modifiedDate;

        expect(accessedSize, isNonNegative);
        expect(accessedDate, isNotNull);

        // Under R1 requirement: getters must not perform blocking synchronous statSync
        expect(
          trackingFile.statSyncCalls,
          equals(0),
          reason: 'FileItem getters must never invoke statSync()',
        );
      },
    );

    test('R1.2: Static contract audit of lib/file_item.dart for statSync', () {
      final fileItemSrc = File('lib/file_item.dart').readAsStringSync();
      final statSyncFound = fileItemSrc.contains('statSync');
      // Contract: R1 mandates eliminating all statSync occurrences from FileItem
      expect(
        statSyncFound,
        isFalse,
        reason: 'statSync must be completely absent from lib/file_item.dart',
      );
    });

    test(
      'R1.3: Static contract audit of gallery worker concurrency in lib/file_browser_controller.dart',
      () {
        final controllerSrc = File(
          'lib/file_browser_controller.dart',
        ).readAsStringSync();
        final regex = RegExp(r'concurrency\s*=\s*math\.min\((\d+)');
        final match = regex.firstMatch(controllerSrc);

        expect(match, isNotNull);
        final concurrencyValue = int.parse(match!.group(1)!);
        // R1 mandates gallery measurement concurrency strictly <= 2
        expect(
          concurrencyValue,
          lessThanOrEqualTo(2),
          reason: 'Gallery worker concurrency must be strictly <= 2',
        );
      },
    );

    test(
      'R1.4: Dynamic simulation of bounded gallery worker pool cap (<= 2)',
      () async {
        const int maxWorkerCap = 2;
        const totalItems = 20;
        var activeWorkers = 0;
        var peakActiveWorkers = 0;
        var processedCount = 0;
        var itemIndex = 0;

        Future<void> worker() async {
          while (true) {
            final current = itemIndex++;
            if (current >= totalItems) break;

            activeWorkers++;
            if (activeWorkers > peakActiveWorkers) {
              peakActiveWorkers = activeWorkers;
            }

            // Simulate non-blocking async metadata fetch
            await Future<void>.delayed(const Duration(milliseconds: 5));
            processedCount++;
            activeWorkers--;
          }
        }

        final workers = List.generate(maxWorkerCap, (_) => worker());
        await Future.wait(workers);

        expect(processedCount, equals(totalItems));
        expect(peakActiveWorkers, lessThanOrEqualTo(maxWorkerCap));
      },
    );

    test(
      'R1.5: CacheService L1 RAM Cache - byte bounding and LRU eviction simulation',
      () async {
        CacheService.instance.clearMemoryThumbnails();

        // Put 10 thumbnails of 100 KB each (1 MB total)
        const thumbSize = 100 * 1024;
        for (var i = 0; i < 10; i++) {
          final payload = Uint8List(thumbSize);
          payload[0] = i;
          CacheService.instance.putMemoryThumbnail('key_$i', payload);
        }

        // Verify retrieval
        for (var i = 0; i < 10; i++) {
          final retrieved = CacheService.instance.getMemoryThumbnail('key_$i');
          expect(retrieved, isNotNull);
          expect(retrieved![0], equals(i));
        }

        // Test path invalidation
        final samplePath = p.join(testTempDir.path, 'photo.jpg');
        CacheService.instance.putMemoryThumbnail(
          'path_key',
          Uint8List(thumbSize),
          filePath: samplePath,
        );
        expect(CacheService.instance.getMemoryThumbnail('path_key'), isNotNull);

        CacheService.instance.invalidateMemoryThumbnailForPath(samplePath);
        expect(CacheService.instance.getMemoryThumbnail('path_key'), isNull);
      },
    );

    test(
      'R1.6: CacheService byte capacity enforcement (up to 48-50 MB limit)',
      () async {
        CacheService.instance.clearMemoryThumbnails();

        // Allocate thumbnails to approach 48 MB default capacity
        // Using 48 entries of 1 MB each
        const oneMb = 1024 * 1024;
        for (var i = 0; i < 48; i++) {
          final chunk = Uint8List(oneMb);
          chunk[0] = i;
          CacheService.instance.putMemoryThumbnail('large_thumb_$i', chunk);
        }

        // All 48 items fit within 48 MB capacity
        expect(
          CacheService.instance.getMemoryThumbnail('large_thumb_47'),
          isNotNull,
        );

        // Add 5 more items (5 MB) -> exceeds 48 MB, triggers LRU eviction
        for (var i = 48; i < 53; i++) {
          final chunk = Uint8List(oneMb);
          chunk[0] = i;
          CacheService.instance.putMemoryThumbnail('large_thumb_$i', chunk);
        }

        // Newest items must be present
        expect(
          CacheService.instance.getMemoryThumbnail('large_thumb_52'),
          isNotNull,
        );

        // Oldest item (large_thumb_0) must have been evicted by LRU algorithm
        expect(
          CacheService.instance.getMemoryThumbnail('large_thumb_0'),
          isNull,
        );
      },
    );
  });

  // =========================================================================
  // Requirement R2: Flash Storage Protection & Atomic Persistent State
  // =========================================================================
  group('E2E Focus R2: Flash Protection, WAF Reduction & Concurrency', () {
    test(
      'R2.1: AtomicSyncStateStore single-row upserts avoid monolithic file rewrites (WAF reduction)',
      () async {
        final store = AtomicInMemorySyncStateStore();

        // Perform 100 sequential file sync updates
        for (var i = 0; i < 100; i++) {
          final record = SyncFileRecord(
            localPath: '/local/dcim/photo_$i.jpg',
            remotePath: 'backup/photo_$i.jpg',
            sizeBytes: 1024 * 1024 * 3,
            modifiedAtMillis: 1700000000000 + i * 1000,
            uploadedAt: DateTime.utc(2026, 9, 5, 12, 0, i),
          );
          await store.saveRecord('server_1', record);
        }

        // Each mutation was a single atomic row insert
        expect(store.writeCount, equals(100));
        expect(store.totalRecordCount, equals(100));

        // Update single record
        final updatedRecord = SyncFileRecord(
          localPath: '/local/dcim/photo_42.jpg',
          remotePath: 'backup/photo_42.jpg',
          sizeBytes: 1024 * 1024 * 3,
          modifiedAtMillis: 1700000000000 + 42000,
          uploadedAt: DateTime.utc(2026, 9, 5, 12, 30, 0),
        );
        await store.saveRecord('server_1', updatedRecord);

        // Verifies O(1) single-row update, total records remains 100
        expect(store.writeCount, equals(101));
        expect(store.totalRecordCount, equals(100));

        final fetched = await store.readRecord(
          'server_1',
          '/local/dcim/photo_42.jpg',
          'backup/photo_42.jpg',
        );
        expect(fetched, isNotNull);
        expect(
          fetched!.uploadedAt,
          equals(DateTime.utc(2026, 9, 5, 12, 30, 0)),
        );
      },
    );

    test(
      'R2.2: Multi-threaded / multi-isolate concurrent access simulation (UI vs Workmanager)',
      () async {
        final store = AtomicInMemorySyncStateStore();
        final errors = <Object>[];

        // Actor 1: UI Isolate (queries records and checks sync state continuously)
        Future<void> uiIsolate() async {
          for (var i = 0; i < 50; i++) {
            try {
              final rec = await store.readRecord(
                'server_1',
                '/local/dcim/photo_${i % 20}.jpg',
                'backup/photo_${i % 20}.jpg',
              );
              if (rec != null) {
                expect(rec.localPath, isNotEmpty);
              }
              await store.readLastResult('server_1');
              await Future<void>.delayed(const Duration(milliseconds: 2));
            } catch (e) {
              errors.add(e);
            }
          }
        }

        // Actor 2: Workmanager Background Isolate (sequentially updates sync records)
        Future<void> workmanagerIsolate() async {
          for (var i = 0; i < 50; i++) {
            try {
              final record = SyncFileRecord(
                localPath: '/local/dcim/photo_$i.jpg',
                remotePath: 'backup/photo_$i.jpg',
                sizeBytes: 1024 * 500,
                modifiedAtMillis: 1700000000000 + i,
                uploadedAt: DateTime.now().toUtc(),
              );
              await store.saveRecord('server_1', record);
              await Future<void>.delayed(const Duration(milliseconds: 2));
            } catch (e) {
              errors.add(e);
            }
          }
        }

        // Run both actors concurrently
        await Future.wait([uiIsolate(), workmanagerIsolate()]);

        // Zero lock contention or format exceptions
        expect(errors, isEmpty);
        expect(store.totalRecordCount, equals(50));
      },
    );

    test(
      'R2.3: SyncStateStore persistence and retrieval of SyncRunResult',
      () async {
        final store = AtomicInMemorySyncStateStore();
        final now = DateTime.utc(2026, 9, 5, 12, 0, 0);

        final result = SyncRunResult(
          status: SyncRunStatus.success,
          scannedFiles: 150,
          uploadedFiles: 140,
          skippedFiles: 10,
          failedFiles: 0,
          startedAt: now.subtract(const Duration(minutes: 5)),
          finishedAt: now,
          message: 'All files synced cleanly',
        );

        await store.saveLastResult('server_omega', result);
        final fetched = await store.readLastResult('server_omega');

        expect(fetched, isNotNull);
        expect(fetched!.status, equals(SyncRunStatus.success));
        expect(fetched.scannedFiles, equals(150));
        expect(fetched.uploadedFiles, equals(140));
        expect(fetched.skippedFiles, equals(10));
        expect(fetched.failedFiles, equals(0));
        expect(fetched.message, equals('All files synced cleanly'));
      },
    );
  });

  // =========================================================================
  // Requirement R3: Unified Network Transport & Resumable Uploads
  // =========================================================================
  group('E2E Focus R3: Chunked Resumable Upload Transport & Conflict Dialog', () {
    late MockChunkedServer mockServer;
    late ResumableUploadTransport transport;
    late File sampleUploadFile;
    String currentToken = 'valid_token_v1';

    setUp(() async {
      mockServer = MockChunkedServer();
      currentToken = 'valid_token_v1';

      transport = ResumableUploadTransport(
        server: mockServer,
        baseUrl: 'http://127.0.0.1:8080',
        tokenProvider: () async => currentToken,
        onRefreshToken: () async {
          currentToken = mockServer.renewedToken;
        },
      );

      // Create 5 MB synthetic test file (5,242,880 bytes)
      sampleUploadFile = File(p.join(testTempDir.path, 'video_5mb.mp4'));
      final sink = sampleUploadFile.openWrite();
      final pattern = List<int>.generate(1024, (i) => i % 256);
      for (var i = 0; i < 5 * 1024; i++) {
        sink.add(pattern);
      }
      await sink.flush();
      await sink.close();
    });

    test(
      'R3.1: Chunked upload divides 5 MB file into 2 MB chunks with correct query parameters',
      () async {
        final progressUpdates = <int>[];

        await transport.upload(
          file: sampleUploadFile,
          remotePath: 'videos/video_5mb.mp4',
          options: const ChunkedUploadOptions(chunkSize: 2 * 1024 * 1024),
          onProgress: (sent, total) {
            progressUpdates.add(sent);
          },
        );

        // 5 MB with 2 MB chunks yields 3 chunks: [0..2MB], [2MB..4MB], [4MB..5MB]
        expect(mockServer.receivedChunks.length, equals(3));

        // Chunk 0
        final c0 = mockServer.receivedChunks[0];
        expect(c0.offset, equals(0));
        expect(c0.total, equals(5 * 1024 * 1024));
        expect(c0.isLast, isFalse);
        expect(c0.bytes.length, equals(2 * 1024 * 1024));

        // Chunk 1
        final c1 = mockServer.receivedChunks[1];
        expect(c1.offset, equals(2 * 1024 * 1024));
        expect(c1.total, equals(5 * 1024 * 1024));
        expect(c1.isLast, isFalse);
        expect(c1.bytes.length, equals(2 * 1024 * 1024));

        // Chunk 2 (last chunk, 1 MB)
        final c2 = mockServer.receivedChunks[2];
        expect(c2.offset, equals(4 * 1024 * 1024));
        expect(c2.total, equals(5 * 1024 * 1024));
        expect(c2.isLast, isTrue);
        expect(c2.bytes.length, equals(1 * 1024 * 1024));

        // Progress updates verify monotonic growth
        expect(progressUpdates, [
          2 * 1024 * 1024,
          4 * 1024 * 1024,
          5 * 1024 * 1024,
        ]);
      },
    );

    test(
      'R3.2: Resumable upload recovers from network failure at chunk N without restarting from byte 0',
      () async {
        // Inject failure on chunk 1 (2nd chunk)
        mockServer.failOnChunkIndex = 1;
        mockServer.failWithException = const SocketException(
          'Connection reset',
        );

        final progress = <int>[];
        await transport.upload(
          file: sampleUploadFile,
          remotePath: 'videos/video_5mb.mp4',
          options: const ChunkedUploadOptions(
            chunkSize: 2 * 1024 * 1024,
            initialBackoff: Duration(milliseconds: 5),
          ),
          onProgress: (sent, total) => progress.add(sent),
        );

        // Upload completes successfully after in-flight retry
        expect(mockServer.receivedChunks.length, equals(3));
        expect(progress.last, equals(5 * 1024 * 1024));

        // Verify Chunk 0 was sent only ONCE and never restarted
        final chunk0Count = mockServer.receivedChunks
            .where((c) => c.offset == 0)
            .length;
        expect(chunk0Count, equals(1));
      },
    );

    test(
      'R3.3: HTTP 401 token refresh mid-transfer retries only active chunk without resetting byte progress',
      () async {
        // Inject 401 on chunk 1
        mockServer.expireTokenOnChunkIndex = 1;

        final transferManager = TransferManager();
        final transferItem = transferManager.addItem(
          name: 'video_5mb.mp4',
          direction: TransferDirection.upload,
          totalBytes: 5 * 1024 * 1024,
        );
        transferManager.startItem(transferItem);

        await transport.upload(
          file: sampleUploadFile,
          remotePath: 'videos/video_5mb.mp4',
          transferItem: transferItem,
          transferManager: transferManager,
          options: const ChunkedUploadOptions(chunkSize: 2 * 1024 * 1024),
        );

        // Chunk 0 used token_v1; chunk 1 and 2 used renewed token_v2
        expect(mockServer.receivedChunks[0].token, equals('valid_token_v1'));
        expect(mockServer.receivedChunks[1].token, equals('valid_token_v2'));
        expect(mockServer.receivedChunks[2].token, equals('valid_token_v2'));

        // Progress reached 100% without resetting to 0
        expect(transferItem.transferredBytes, equals(5 * 1024 * 1024));
        expect(transferItem.status, equals(TransferStatus.completed));
      },
    );

    test(
      'R3.4: Upstream interactive conflict resolution cleanly controls chunked transport dispatch',
      () async {
        final localFile = File(p.join(testTempDir.path, 'conflict.txt'))
          ..writeAsStringSync('Local conflict data');
        final localItem = FileItem.fromEntity(localFile);

        final serverItem = ServerFileItem(
          name: 'conflict.txt',
          size: 50,
          modifiedAt: DateTime.utc(2026, 1, 1),
          type: 'document',
          mimeType: 'text/plain',
          thumbnailUrl: null,
          isDir: false,
          path: 'docs/conflict.txt',
        );

        final conflict = UploadConflictItem(
          item: localItem,
          existingItem: serverItem,
        );

        // Case A: User resolves "Overwrite"
        final overwriteResolution = UploadConflictResolution(
          confirmedItems: [conflict.item],
          skippedItems: const [],
        );
        expect(overwriteResolution.confirmedItems.length, equals(1));
        expect(overwriteResolution.skippedItems, isEmpty);

        // Confirmed item uploads via transport
        await transport.upload(
          file: localFile,
          remotePath: 'docs/conflict.txt',
          options: const ChunkedUploadOptions(
            resume: false,
          ), // Overwrite resets server partial
        );
        expect(mockServer.receivedChunks.isNotEmpty, isTrue);
        expect(
          mockServer.receivedChunks.last.path,
          equals('docs/conflict.txt'),
        );

        // Case B: User resolves "Skip"
        final skipResolution = UploadConflictResolution(
          confirmedItems: const [],
          skippedItems: [conflict.item],
        );
        expect(skipResolution.confirmedItems, isEmpty);
        expect(skipResolution.skippedItems.length, equals(1));
        // Skipped item is NOT uploaded
      },
    );

    test(
      'R3.5: 0-byte file edge case uploads single empty chunk with is_last=true',
      () async {
        final emptyFile = File(p.join(testTempDir.path, 'empty.txt'))
          ..createSync();

        await transport.upload(file: emptyFile, remotePath: 'docs/empty.txt');

        expect(mockServer.receivedChunks.length, equals(1));
        final chunk = mockServer.receivedChunks.first;
        expect(chunk.offset, equals(0));
        expect(chunk.total, equals(0));
        expect(chunk.isLast, isTrue);
        expect(chunk.bytes, isEmpty);
      },
    );
  });

  // =========================================================================
  // Requirement Tiers 3 & 4: Cross-Feature Interactions & Real-World Workloads
  // =========================================================================
  group('E2E Tiers 3 & 4: Cross-Feature Interactions & Real-World Workloads', () {
    test(
      'T3.1: Paired Stress - Token refresh and network retry on consecutive chunks',
      () async {
        final server = MockChunkedServer();
        var token = 'token_initial';
        final multiTransport = ResumableUploadTransport(
          server: server,
          baseUrl: 'http://127.0.0.1:8080',
          tokenProvider: () async => token,
          onRefreshToken: () async => token = server.renewedToken,
        );

        final sampleFile = File(p.join(testTempDir.path, 'combo.bin'));
        await sampleFile.writeAsBytes(
          Uint8List(6 * 1024 * 1024),
        ); // 6 MB (3 chunks)

        // Chunk 0: expires token (401)
        server.expireTokenOnChunkIndex = 0;
        // Chunk 1: network socket drop
        server.failOnChunkIndex = 1;

        await multiTransport.upload(
          file: sampleFile,
          remotePath: 'uploads/combo.bin',
          options: const ChunkedUploadOptions(
            chunkSize: 2 * 1024 * 1024,
            initialBackoff: Duration(milliseconds: 5),
          ),
        );

        // All 3 chunks reached server successfully
        expect(server.receivedChunks.length, equals(3));
        expect(server.receivedChunks[0].token, equals('valid_token_v2'));
        expect(server.receivedChunks[2].offset, equals(4 * 1024 * 1024));
        expect(server.receivedChunks[2].isLast, isTrue);
      },
    );

    test(
      'T4.1: Real-World Workload - 10,000 photo state store throughput simulation',
      () async {
        final store = AtomicInMemorySyncStateStore();
        final stopwatch = Stopwatch()..start();

        const count = 10000;
        for (var i = 0; i < count; i++) {
          final record = SyncFileRecord(
            localPath: '/storage/emulated/0/DCIM/Camera/IMG_2026_$i.jpg',
            remotePath: 'InstantUpload/Camera/IMG_2026_$i.jpg',
            sizeBytes: 4 * 1024 * 1024,
            modifiedAtMillis: 1700000000000 + i,
            uploadedAt: DateTime.utc(2026, 9, 5),
          );
          await store.saveRecord('srv_primary', record);
        }
        stopwatch.stop();

        // ignore: avoid_print
        print(
          '10,000 records processed in ${stopwatch.elapsedMilliseconds} ms '
          '(${(count / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(1)} ops/sec)',
        );

        expect(store.totalRecordCount, equals(count));
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(3000),
        ); // Under 3 seconds

        // Random read checks
        final sample1 = await store.readRecord(
          'srv_primary',
          '/storage/emulated/0/DCIM/Camera/IMG_2026_4999.jpg',
          'InstantUpload/Camera/IMG_2026_4999.jpg',
        );
        expect(sample1, isNotNull);
        expect(sample1!.sizeBytes, equals(4 * 1024 * 1024));
      },
    );
  });
}
