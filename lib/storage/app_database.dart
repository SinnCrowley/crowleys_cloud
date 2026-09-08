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

import 'dart:io' show Directory, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Embedded SQLite database manager for Crowley's Cloud state and cache.
///
/// Configured with SQLite Write-Ahead Logging (WAL) and concurrency pragmas:
/// - PRAGMA journal_mode = WAL;
/// - PRAGMA busy_timeout = 5000;
/// - PRAGMA synchronous = NORMAL;
/// - PRAGMA temp_store = MEMORY;
/// - PRAGMA foreign_keys = ON;
///
/// Ensures safe cross-isolate concurrency between Flutter UI and background Workmanager isolates.
class AppDatabase {
  AppDatabase({String? customPath}) : _customPath = customPath;

  /// Default singleton database instance.
  static final AppDatabase instance = AppDatabase();

  final String? _customPath;
  Database? _db;
  Future<Database>? _openingFuture;

  static bool _platformInitialized = false;

  /// Ensures platform-appropriate database factories are initialized.
  /// Uses FFI on desktop/unit-test environments and native factories on mobile.
  static void ensurePlatformInitialized() {
    if (_platformInitialized) return;
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _platformInitialized = true;
  }

  /// Returns the open [Database] instance, initializing it if necessary.
  Future<Database> get database async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;
    return _openingFuture ??= _open();
  }

  Future<Database> _open() async {
    ensurePlatformInitialized();
    final dbPath = await _resolvePath();

    final db = await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        await db.execute('PRAGMA synchronous = NORMAL;');
        await db.execute('PRAGMA temp_store = MEMORY;');
        // On Android, PRAGMAs that return results (like PRAGMA busy_timeout = 5000; or PRAGMA journal_mode;)
        // cannot be run via SQLiteDatabase.execSQL (which db.execute uses).
        // They must either be queried via rawQuery or wrapped safely.
        try {
          await db.rawQuery('PRAGMA busy_timeout = 5000;');
        } catch (_) {}
        if (dbPath != inMemoryDatabasePath) {
          try {
            await db.rawQuery('PRAGMA journal_mode = WAL;');
          } catch (_) {}
        }
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onOpen: (db) async {
        await _createTables(db);
      },
    );

    _db = db;
    _openingFuture = null;
    return db;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_records (
        server_id TEXT NOT NULL,
        local_path TEXT NOT NULL,
        remote_path TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        modified_at_millis INTEGER NOT NULL,
        uploaded_at TEXT NOT NULL,
        PRIMARY KEY (server_id, local_path, remote_path)
      );
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_records_lookup 
        ON sync_records (server_id, local_path);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_records_server 
        ON sync_records (server_id);
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_results (
        server_id TEXT PRIMARY KEY,
        status TEXT NOT NULL,
        scanned_files INTEGER NOT NULL,
        uploaded_files INTEGER NOT NULL,
        skipped_files INTEGER NOT NULL,
        failed_files INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        finished_at TEXT NOT NULL,
        message TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache_entries (
        path TEXT PRIMARY KEY,
        server_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        size INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_access TEXT NOT NULL,
        etag TEXT
      );
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cache_lru 
        ON cache_entries (kind, last_access ASC);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cache_server 
        ON cache_entries (server_id);
    ''');
  }

  Future<String> _resolvePath() async {
    final custom = _customPath;
    if (custom != null) {
      if (custom != inMemoryDatabasePath) {
        final parent = Directory(p.dirname(custom));
        if (!await parent.exists()) {
          await parent.create(recursive: true);
        }
      }
      return custom;
    }

    try {
      final supportDir = await getApplicationSupportDirectory();
      final dbDir = Directory(p.join(supportDir.path, 'databases'));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      return p.join(dbDir.path, 'crowleys_cloud_state.db');
    } catch (_) {
      final dbDir = await getDatabasesPath();
      final dir = Directory(dbDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return p.join(dbDir, 'crowleys_cloud_state.db');
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = _db;
    _db = null;
    _openingFuture = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
