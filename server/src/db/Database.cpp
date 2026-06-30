#include "server/db/Database.hpp"

#include <sqlite3.h>

#include <stdexcept>

namespace server::db {

Database::Database(const std::string &path) {
  if (sqlite3_open(path.c_str(), &db_) != SQLITE_OK) {
    throw std::runtime_error("Cannot open sqlite db");
  }
  exec("PRAGMA foreign_keys = ON;");
}

Database::~Database() {
  if (db_ != nullptr) {
    sqlite3_close(db_);
  }
}

void Database::exec(const std::string &sql) {
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
      created_at INTEGER NOT NULL,
      email TEXT UNIQUE
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
      UNIQUE(owner_user_id, scope, rel_path)
    );

    CREATE INDEX IF NOT EXISTS idx_file_index_parent
      ON file_index(owner_user_id, scope, parent_path, is_deleted);
    CREATE INDEX IF NOT EXISTS idx_file_index_type
      ON file_index(owner_user_id, scope, type, is_deleted);
    CREATE INDEX IF NOT EXISTS idx_file_index_name
      ON file_index(owner_user_id, scope, name, is_deleted);

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
      FOREIGN KEY(owner_user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_trash_owner ON trash(owner_user_id);
  )");

  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(db_, "PRAGMA table_info(file_index)", -1, &stmt, nullptr);
  bool hasUploaderColumn = false;
  bool hasSha256Column = false;
  bool hasIsSharedColumn = false;
  bool hasDeletedAtColumn = false;
  while (sqlite3_step(stmt) == SQLITE_ROW) {
    const auto *nameRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
    if (nameRaw != nullptr) {
      std::string nameStr(nameRaw);
      if (nameStr == "uploader_user_id") {
        hasUploaderColumn = true;
      } else if (nameStr == "sha256") {
        hasSha256Column = true;
      } else if (nameStr == "is_shared") {
        hasIsSharedColumn = true;
      } else if (nameStr == "deleted_at") {
        hasDeletedAtColumn = true;
      }
    }
  }
  sqlite3_finalize(stmt);

  if (!hasUploaderColumn) {
    exec("ALTER TABLE file_index ADD COLUMN uploader_user_id INTEGER NOT NULL DEFAULT 0;");
  }
  if (!hasSha256Column) {
    exec("ALTER TABLE file_index ADD COLUMN sha256 TEXT NOT NULL DEFAULT '';");
  }
  if (!hasIsSharedColumn) {
    exec("ALTER TABLE file_index ADD COLUMN is_shared INTEGER NOT NULL DEFAULT 0;");
  }
  if (!hasDeletedAtColumn) {
    exec("ALTER TABLE file_index ADD COLUMN deleted_at INTEGER;");
  }
  exec("CREATE INDEX IF NOT EXISTS idx_file_index_sha256 ON file_index(owner_user_id, scope, sha256, is_deleted);");
  exec("CREATE INDEX IF NOT EXISTS idx_file_index_is_shared ON file_index(is_shared, is_deleted);");

  sqlite3_prepare_v2(db_, "PRAGMA table_info(users)", -1, &stmt, nullptr);
  bool hasEmailColumn = false;
  bool hasTrashRetention = false;
  while (sqlite3_step(stmt) == SQLITE_ROW) {
    const auto *nameRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
    if (nameRaw != nullptr) {
      std::string nameStr(nameRaw);
      if (nameStr == "email") {
        hasEmailColumn = true;
      } else if (nameStr == "trash_retention_days") {
        hasTrashRetention = true;
      }
    }
  }
  sqlite3_finalize(stmt);
  if (!hasEmailColumn) {
    exec("ALTER TABLE users ADD COLUMN email TEXT;");
    exec("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);");
  }
  if (!hasTrashRetention) {
    exec("ALTER TABLE users ADD COLUMN trash_retention_days INTEGER NOT NULL DEFAULT 7;");
  }
}

}  // namespace server::db
