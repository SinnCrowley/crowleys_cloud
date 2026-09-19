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

// Database implementation for embedded SQLite3 database management.
// Concurrency Model: Thread-safe prepared statement caching via StatementGuard (global map lock + per-statement mutex lock).
// PRAGMA Performance Tuning: Enables WAL journal mode, NORMAL sync, memory temp store, 64MB cache, 5s busy timeout.
// Migration Mechanics: Executes baseline CREATE TABLE/INDEX DDL statements followed by dynamic PRAGMA table_info inspections.
// RAII Transaction Safety: TransactionGuard manages BEGIN (IMMEDIATE) / COMMIT / ROLLBACK lifetime safely across exceptions.

#include "server/db/Database.hpp"

#include <sqlite3.h>

#include <stdexcept>

namespace server::db {

Database::Database(const std::string &path) {
  // Open SQLite database connection
  if (sqlite3_open(path.c_str(), &db_) != SQLITE_OK) {
    throw std::runtime_error("Cannot open sqlite db");
  }

  // Set busy handler timeout immediately to handle lock contention during PRAGMAs
  sqlite3_busy_timeout(db_, 5000);

  // PRAGMA Configuration Tuning:
  // 1. Enforce SQLite foreign key constraint checks.
  exec("PRAGMA foreign_keys = ON;");
  // 2. Enable Write-Ahead Logging (WAL) mode for concurrent readers and single writer.
  exec("PRAGMA journal_mode = WAL;");
  // Administrative journals must survive power loss before filesystem cleanup.
  exec("PRAGMA synchronous = FULL;");
  // 4. Store temporary tables and indices in memory.
  exec("PRAGMA temp_store = MEMORY;");
  // 5. Configure page cache size to ~64MB (-64000 KB).
  exec("PRAGMA cache_size = -64000;");
  // 6. Set busy timeout to 5000 ms to handle lock contention gracefully.
  exec("PRAGMA busy_timeout = 5000;");
}

Database::~Database() {
  // Finalize all prepared statements before closing connection
  clearStatementCache();
  if (db_ != nullptr) {
    sqlite3_close(db_);
  }
}

Database::TransactionGuard::TransactionGuard(Database &db, bool immediate) : db_(db), lock_(db.connectionMutex_) {
  // Begin transaction (IMMEDIATE acquires write lock immediately to prevent deadlocks)
  if (immediate) {
    db_.exec("BEGIN IMMEDIATE TRANSACTION;");
  } else {
    db_.exec("BEGIN TRANSACTION;");
  }
}

Database::TransactionGuard::~TransactionGuard() {
  // Auto-rollback if not explicitly committed
  if (!committed_) {
    try {
      db_.exec("ROLLBACK;");
    } catch (...) {
      // Suppress exceptions during unwinding destructor
    }
  }
}

void Database::TransactionGuard::commit() {
  if (!committed_) {
    db_.exec("COMMIT;");
    committed_ = true;
  }
}

void Database::clearStatementCache() {
  std::lock_guard<std::recursive_mutex> connectionLock(connectionMutex_);
  // Protect statement cache map during teardown
  std::lock_guard<std::mutex> lock(cacheMutex_);
  for (auto &[sql, cached] : stmtCache_) {
    if (cached) {
      // Acquire individual statement lock before finalizing
      std::lock_guard<std::mutex> stmtLock(cached->mutex);
      if (cached->stmt) {
        sqlite3_finalize(cached->stmt);
        cached->stmt = nullptr;
      }
    }
  }
  stmtCache_.clear();
}

Database::StatementGuard Database::getStatement(const std::string &sql) {
  std::unique_lock<std::recursive_mutex> connectionLock(connectionMutex_);
  std::shared_ptr<CachedStmt> cached;
  {
    // Step 1: Look up or create cached prepared statement object under cacheMutex_
    std::lock_guard<std::mutex> lock(cacheMutex_);
    auto it = stmtCache_.find(sql);
    if (it != stmtCache_.end()) {
      cached = it->second;
    } else {
      sqlite3_stmt *stmt = nullptr;
      if (sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt, nullptr) != SQLITE_OK) {
        const char *err = sqlite3_errmsg(db_);
        throw std::runtime_error(err ? err : "Failed to prepare sqlite statement");
      }
      cached = std::make_shared<CachedStmt>();
      cached->stmt = stmt;
      stmtCache_[sql] = cached;
    }
  }

  // Step 2: Acquire per-statement unique lock to guarantee thread isolation while active
  std::unique_lock<std::mutex> stmtLock(cached->mutex);
  return StatementGuard(cached->stmt, std::move(stmtLock), std::move(connectionLock));
}

void Database::exec(const std::string &sql) {
  std::lock_guard<std::recursive_mutex> connectionLock(connectionMutex_);
  char *err = nullptr;
  if (sqlite3_exec(db_, sql.c_str(), nullptr, nullptr, &err) != SQLITE_OK) {
    std::string msg = err == nullptr ? "sqlite error" : err;
    sqlite3_free(err);
    throw std::runtime_error(msg);
  }
}

void Database::migrate() {
  exec(R"(
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'user',
      created_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS password_resets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      code TEXT NOT NULL,
      expires_at INTEGER NOT NULL,
      used_at INTEGER,
      created_at INTEGER NOT NULL,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_password_resets_user_code
      ON password_resets(user_id, code);

    CREATE TABLE IF NOT EXISTS refresh_tokens (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      token_hash TEXT NOT NULL UNIQUE,
      expires_at INTEGER NOT NULL,
      revoked_at INTEGER,
      replaced_by_token_hash TEXT,
      created_at INTEGER NOT NULL,
      last_used_at INTEGER,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS share_links (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      token TEXT NOT NULL UNIQUE,
      owner_user_id INTEGER NOT NULL,
      scope TEXT NOT NULL,
      rel_path TEXT NOT NULL,
      expires_at INTEGER,
      disabled_at INTEGER,
      created_at INTEGER NOT NULL,
      FOREIGN KEY(owner_user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_share_links_owner_rel
      ON share_links(owner_user_id, rel_path);

    CREATE TABLE IF NOT EXISTS file_index (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      owner_user_id INTEGER NOT NULL,
      scope TEXT NOT NULL,
      rel_path TEXT NOT NULL,
      parent_path TEXT NOT NULL,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      mime_type TEXT NOT NULL,
      size_bytes INTEGER NOT NULL,
      modified_at INTEGER NOT NULL,
      uploaded_at INTEGER NOT NULL,
      thumbnail_path TEXT NOT NULL DEFAULT '',
      thumbnail_updated_at INTEGER,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      uploader_user_id INTEGER NOT NULL DEFAULT 0,
      sha256 TEXT NOT NULL DEFAULT '',
      is_shared INTEGER NOT NULL DEFAULT 0,
      is_explicit_shared INTEGER NOT NULL DEFAULT 0,
      blurhash TEXT NOT NULL DEFAULT '',
      deleted_at INTEGER,
      UNIQUE(owner_user_id, scope, rel_path)
    );

    CREATE INDEX IF NOT EXISTS idx_file_index_parent
      ON file_index(owner_user_id, scope, parent_path, is_deleted);
    CREATE INDEX IF NOT EXISTS idx_file_index_type
      ON file_index(owner_user_id, scope, type, is_deleted);
    CREATE INDEX IF NOT EXISTS idx_file_index_name
      ON file_index(owner_user_id, scope, name, is_deleted);
    CREATE INDEX IF NOT EXISTS idx_file_index_rel_path
      ON file_index(owner_user_id, scope, rel_path, is_deleted);
    CREATE INDEX IF NOT EXISTS idx_file_index_rel_path_shared
      ON file_index(rel_path, is_deleted, is_shared);
    CREATE INDEX IF NOT EXISTS idx_file_index_shared_type
      ON file_index(is_shared, is_deleted, type);
    CREATE INDEX IF NOT EXISTS idx_file_index_sha256
      ON file_index(owner_user_id, scope, sha256, is_deleted);
    CREATE INDEX IF NOT EXISTS idx_file_index_is_shared
      ON file_index(is_shared, is_deleted);

    CREATE TABLE IF NOT EXISTS trash (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      owner_user_id INTEGER NOT NULL,
      scope TEXT NOT NULL,
      original_path TEXT NOT NULL,
      name TEXT NOT NULL,
      is_dir INTEGER NOT NULL,
      size_bytes INTEGER NOT NULL,
      type TEXT NOT NULL,
      mime_type TEXT NOT NULL,
      deleted_at INTEGER NOT NULL,
      sha256 TEXT NOT NULL DEFAULT '',
      FOREIGN KEY(owner_user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_trash_owner ON trash(owner_user_id);
  )");

  // Dynamic schema migration: add blurhash column to file_index if missing
  {
    bool hasBlurhash = false;
    sqlite3_stmt *stmt = nullptr;
    if (sqlite3_prepare_v2(db_, "PRAGMA table_info(file_index);", -1, &stmt, nullptr) == SQLITE_OK) {
      while (sqlite3_step(stmt) == SQLITE_ROW) {
        const auto *colName = sqlite3_column_text(stmt, 1);
        if (colName != nullptr && std::string(reinterpret_cast<const char *>(colName)) == "blurhash") {
          hasBlurhash = true;
          break;
        }
      }
      sqlite3_finalize(stmt);
    }
    if (!hasBlurhash) {
      try {
        exec("ALTER TABLE file_index ADD COLUMN blurhash TEXT NOT NULL DEFAULT '';");
      } catch (...) {
        // Silently handle if table does not exist or column was added concurrently
      }
    }
  }

  TransactionGuard transaction(*this);
  exec("CREATE TABLE IF NOT EXISTS schema_migrations(name TEXT PRIMARY KEY)");
  bool adminMigrated = false;
  {
    auto guard = getStatement("SELECT 1 FROM schema_migrations WHERE name = 'administration_v1'");
    adminMigrated = sqlite3_step(guard.get()) == SQLITE_ROW;
  }
  if (!adminMigrated) {
    exec("ALTER TABLE users ADD COLUMN status TEXT NOT NULL DEFAULT 'active'");
    exec("ALTER TABLE users ADD COLUMN quota_bytes INTEGER DEFAULT NULL CHECK(quota_bytes IS NULL OR quota_bytes >= 0)");
    exec("ALTER TABLE users ADD COLUMN auth_version INTEGER NOT NULL DEFAULT 0");
    exec("ALTER TABLE users ADD COLUMN password_reset_required INTEGER NOT NULL DEFAULT 0");
    exec("ALTER TABLE password_resets ADD COLUMN attempts INTEGER NOT NULL DEFAULT 0");
    // Previous recovery codes were plaintext; invalidate them at the upgrade boundary.
    exec("DELETE FROM password_resets");
    exec("UPDATE users SET role = 'admin' WHERE id = (SELECT id FROM users ORDER BY created_at, id LIMIT 1) "
         "AND NOT EXISTS(SELECT 1 FROM users WHERE role = 'admin')");
    exec("INSERT INTO schema_migrations(name) VALUES('administration_v1')");
  }
  exec(R"(
    CREATE TABLE IF NOT EXISTS encryption_rotation (
      id INTEGER PRIMARY KEY CHECK(id = 1), job_id TEXT NOT NULL,
      phase TEXT NOT NULL, actor_user_id INTEGER NOT NULL,
      created_at INTEGER NOT NULL, error_code TEXT NOT NULL DEFAULT ''
    );
    CREATE TABLE IF NOT EXISTS encryption_objects (
      name TEXT PRIMARY KEY, state TEXT NOT NULL DEFAULT 'pending',
      cipher_bytes INTEGER NOT NULL, plain_bytes INTEGER NOT NULL DEFAULT 0,
      old_digest TEXT NOT NULL DEFAULT '', new_digest TEXT NOT NULL DEFAULT ''
    );
    CREATE TABLE IF NOT EXISTS upload_reservations (
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      scope TEXT NOT NULL,
      rel_path TEXT NOT NULL,
      bytes INTEGER NOT NULL CHECK(bytes >= 0),
      expires_at INTEGER NOT NULL,
      PRIMARY KEY(user_id, scope, rel_path)
    );
    CREATE TABLE IF NOT EXISTS admin_audit (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      actor_user_id INTEGER NOT NULL,
      action TEXT NOT NULL,
      target_user_id INTEGER,
      created_at INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS account_deletions (
      user_id INTEGER PRIMARY KEY,
      recipient_user_id INTEGER NOT NULL,
      manifest TEXT NOT NULL,
      phase TEXT NOT NULL DEFAULT 'copying',
      created_at INTEGER NOT NULL
    );
  )");
  transaction.commit();

}

}  // namespace server::db
