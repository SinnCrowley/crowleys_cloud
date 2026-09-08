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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// High-performance SQLite-backed implementation of [SyncStateStore].
///
/// Features:
/// - Atomic single-row upserts eliminating monolithic JSON serialization (WAF ~ 1.0x).
/// - Safe cross-isolate concurrent reading and writing under SQLite WAL mode.
/// - Zero-downtime automatic migration from legacy `sync_state.json`.
class SqliteSyncStateStore implements SyncStateStore {
  const SqliteSyncStateStore({
    AppDatabase? database,
    Future<File> Function()? legacyFileProvider,
  }) : _database = database,
       _legacyFileProvider = legacyFileProvider;

  final AppDatabase? _database;
  final Future<File> Function()? _legacyFileProvider;

  static final Set<String> _migratedPaths = <String>{};

  Future<Database> _getDatabase() async {
    final db = await (_database ?? AppDatabase.instance).database;
    await _checkMigrateLegacy(db);
    return db;
  }

  @override
  Future<SyncFileRecord?> readRecord(
    String serverId,
    String localPath,
    String remotePath,
  ) async {
    final db = await _getDatabase();
    final rows = await db.query(
      'sync_records',
      where: 'server_id = ? AND local_path = ? AND remote_path = ?',
      whereArgs: [serverId, localPath, remotePath],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return _recordFromRow(rows.first);
    }

    // Fallback lookup matching server_id and local_path for path resolution compatibility
    final prefixRows = await db.query(
      'sync_records',
      where: 'server_id = ? AND local_path = ?',
      whereArgs: [serverId, localPath],
      limit: 1,
    );

    if (prefixRows.isNotEmpty) {
      return _recordFromRow(prefixRows.first);
    }

    return null;
  }

  @override
  Future<void> saveRecord(String serverId, SyncFileRecord record) async {
    final db = await _getDatabase();
    await db.rawInsert(
      '''
      INSERT INTO sync_records (
        server_id, local_path, remote_path, size_bytes, modified_at_millis, uploaded_at
      ) VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(server_id, local_path, remote_path) DO UPDATE SET
        size_bytes = excluded.size_bytes,
        modified_at_millis = excluded.modified_at_millis,
        uploaded_at = excluded.uploaded_at
      ''',
      [
        serverId,
        record.localPath,
        record.remotePath,
        record.sizeBytes,
        record.modifiedAtMillis,
        record.uploadedAt.toIso8601String(),
      ],
    );
  }

  @override
  Future<SyncRunResult?> readLastResult(String serverId) async {
    final db = await _getDatabase();
    final rows = await db.query(
      'sync_results',
      where: 'server_id = ?',
      whereArgs: [serverId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final row = rows.first;
    return SyncRunResult(
      status: SyncRunStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => SyncRunStatus.failed,
      ),
      scannedFiles: (row['scanned_files'] as num).toInt(),
      uploadedFiles: (row['uploaded_files'] as num).toInt(),
      skippedFiles: (row['skipped_files'] as num).toInt(),
      failedFiles: (row['failed_files'] as num).toInt(),
      startedAt: DateTime.parse(row['started_at'] as String),
      finishedAt: DateTime.parse(row['finished_at'] as String),
      message: row['message'] as String?,
    );
  }

  @override
  Future<void> saveLastResult(String serverId, SyncRunResult result) async {
    final db = await _getDatabase();
    await db.rawInsert(
      '''
      INSERT INTO sync_results (
        server_id, status, scanned_files, uploaded_files, skipped_files, failed_files, started_at, finished_at, message
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(server_id) DO UPDATE SET
        status = excluded.status,
        scanned_files = excluded.scanned_files,
        uploaded_files = excluded.uploaded_files,
        skipped_files = excluded.skipped_files,
        failed_files = excluded.failed_files,
        started_at = excluded.started_at,
        finished_at = excluded.finished_at,
        message = excluded.message
      ''',
      [
        serverId,
        result.status.name,
        result.scannedFiles,
        result.uploadedFiles,
        result.skippedFiles,
        result.failedFiles,
        result.startedAt.toIso8601String(),
        result.finishedAt.toIso8601String(),
        result.message,
      ],
    );
  }

  /// Returns the total count of synchronized file records, optionally filtered by [serverId].
  Future<int> totalRecordsCount({String? serverId}) async {
    final db = await _getDatabase();
    final result = serverId == null
        ? await db.rawQuery('SELECT COUNT(*) as cnt FROM sync_records')
        : await db.rawQuery(
            'SELECT COUNT(*) as cnt FROM sync_records WHERE server_id = ?',
            [serverId],
          );
    if (result.isEmpty) return 0;
    return (result.first['cnt'] as num?)?.toInt() ?? 0;
  }

  /// Removes all sync records and results from SQLite (primarily for testing).
  Future<void> clear() async {
    final db = await _getDatabase();
    await db.execute('DELETE FROM sync_records;');
    await db.execute('DELETE FROM sync_results;');
  }

  SyncFileRecord _recordFromRow(Map<String, Object?> row) {
    return SyncFileRecord(
      localPath: row['local_path'] as String,
      remotePath: row['remote_path'] as String,
      sizeBytes: (row['size_bytes'] as num).toInt(),
      modifiedAtMillis: (row['modified_at_millis'] as num).toInt(),
      uploadedAt: DateTime.parse(row['uploaded_at'] as String),
    );
  }

  Future<void> _checkMigrateLegacy(Database db) async {
    try {
      final legacyFile = await _resolveLegacyFile();
      final path = legacyFile.path;
      if (_migratedPaths.contains(path)) return;
      _migratedPaths.add(path);

      if (!await legacyFile.exists()) return;

      final raw = await legacyFile.readAsString();
      if (raw.trim().isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      final servers = decoded['servers'];
      if (servers is! Map) return;

      final batch = db.batch();

      for (final serverEntry in servers.entries) {
        final serverId = serverEntry.key.toString();
        final serverData = serverEntry.value;
        if (serverData is! Map) continue;

        final files = serverData['files'];
        if (files is Map) {
          for (final fileEntry in files.entries) {
            final fileVal = fileEntry.value;
            if (fileVal is! Map) continue;
            try {
              final rec = SyncFileRecord.fromJson(
                Map<String, Object?>.from(fileVal),
              );
              if (rec != null) {
                batch.rawInsert(
                  '''
                  INSERT INTO sync_records (
                    server_id, local_path, remote_path, size_bytes, modified_at_millis, uploaded_at
                  ) VALUES (?, ?, ?, ?, ?, ?)
                  ON CONFLICT(server_id, local_path, remote_path) DO UPDATE SET
                    size_bytes = excluded.size_bytes,
                    modified_at_millis = excluded.modified_at_millis,
                    uploaded_at = excluded.uploaded_at
                  ''',
                  [
                    serverId,
                    rec.localPath,
                    rec.remotePath,
                    rec.sizeBytes,
                    rec.modifiedAtMillis,
                    rec.uploadedAt.toIso8601String(),
                  ],
                );
              }
            } catch (_) {}
          }
        }

        final lastResultRaw = serverData['lastResult'];
        if (lastResultRaw is Map) {
          try {
            final res = SyncRunResult.fromJson(
              Map<String, Object?>.from(lastResultRaw),
            );
            if (res != null) {
              batch.rawInsert(
                '''
                INSERT INTO sync_results (
                  server_id, status, scanned_files, uploaded_files, skipped_files, failed_files, started_at, finished_at, message
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(server_id) DO UPDATE SET
                  status = excluded.status,
                  scanned_files = excluded.scanned_files,
                  uploaded_files = excluded.uploaded_files,
                  skipped_files = excluded.skipped_files,
                  failed_files = excluded.failed_files,
                  started_at = excluded.started_at,
                  finished_at = excluded.finished_at,
                  message = excluded.message
                ''',
                [
                  serverId,
                  res.status.name,
                  res.scannedFiles,
                  res.uploadedFiles,
                  res.skippedFiles,
                  res.failedFiles,
                  res.startedAt.toIso8601String(),
                  res.finishedAt.toIso8601String(),
                  res.message,
                ],
              );
            }
          } catch (_) {}
        }
      }

      await batch.commit(noResult: true);

      // Rename legacy sync_state.json so migration runs only once
      try {
        final migratedFile = File('${legacyFile.path}.migrated');
        await legacyFile.rename(migratedFile.path);
      } catch (_) {}
    } catch (_) {}
  }

  Future<File> _resolveLegacyFile() async {
    final legacyProvider = _legacyFileProvider;
    if (legacyProvider != null) return legacyProvider();
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File(p.join(dir.path, 'sync_state.json'));
    } catch (_) {
      return File('sync_state.json');
    }
  }
}
