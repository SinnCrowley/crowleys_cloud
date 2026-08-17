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

#pragma once

#include <sqlite3.h>

#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>

namespace server::db {

/**
 * Thread-safe Database wrapper around an embedded SQLite3 database.
 * Manages schema migrations, connection pragmas, performance indexing,
 * and thread-safe prepared statement caching across Drogon worker threads.
 */
class Database {
 public:
  explicit Database(const std::string &path);
  ~Database();

  Database(const Database &) = delete;
  Database &operator=(const Database &) = delete;

  sqlite3 *raw() const { return db_; }

  void migrate();

  /**
   * RAII guard for a cached prepared statement.
   * Holds a per-statement mutex lock during usage to ensure thread safety
   * across concurrent Drogon worker threads. On destruction, resets the statement
   * and clears parameter bindings before releasing the lock.
   */
  class StatementGuard {
   public:
    StatementGuard() = default;
    StatementGuard(sqlite3_stmt *stmt, std::unique_lock<std::mutex> lock)
        : stmt_(stmt), lock_(std::move(lock)) {}

    ~StatementGuard() {
      if (stmt_) {
        sqlite3_reset(stmt_);
        sqlite3_clear_bindings(stmt_);
      }
    }

    StatementGuard(StatementGuard &&other) noexcept
        : stmt_(other.stmt_), lock_(std::move(other.lock_)) {
      other.stmt_ = nullptr;
    }

    StatementGuard &operator=(StatementGuard &&other) noexcept {
      if (this != &other) {
        if (stmt_) {
          sqlite3_reset(stmt_);
          sqlite3_clear_bindings(stmt_);
        }
        stmt_ = other.stmt_;
        lock_ = std::move(other.lock_);
        other.stmt_ = nullptr;
      }
      return *this;
    }

    StatementGuard(const StatementGuard &) = delete;
    StatementGuard &operator=(const StatementGuard &) = delete;

    sqlite3_stmt *get() const { return stmt_; }
    sqlite3_stmt *operator->() const { return stmt_; }
    explicit operator bool() const { return stmt_ != nullptr; }

   private:
    sqlite3_stmt *stmt_{nullptr};
    std::unique_lock<std::mutex> lock_;
  };

  /**
   * RAII guard for database transactions.
   * Begins a transaction ("BEGIN IMMEDIATE TRANSACTION;" by default) on construction,
   * and automatically issues a "ROLLBACK;" on destruction unless commit() has been called.
   */
  class TransactionGuard {
   public:
    explicit TransactionGuard(Database &db, bool immediate = true);
    ~TransactionGuard();

    /**
     * Commits the active transaction. Subsequent calls or destruction will be a no-op.
     */
    void commit();

    TransactionGuard(const TransactionGuard &) = delete;
    TransactionGuard &operator=(const TransactionGuard &) = delete;
    TransactionGuard(TransactionGuard &&) = delete;
    TransactionGuard &operator=(TransactionGuard &&) = delete;

   private:
    Database &db_;
    bool committed_{false};
  };

  /**
   * Retrieves a cached prepared statement wrapper for the given SQL query string.
   * Prepares the statement on first invocation and reuses it safely across subsequent requests.
   */
  StatementGuard getStatement(const std::string &sql);

  /**
   * Finalizes and clears all cached prepared statements.
   */
  void clearStatementCache();

 private:
  struct CachedStmt {
    sqlite3_stmt *stmt{nullptr};
    std::mutex mutex;
  };

  sqlite3 *db_{nullptr};
  mutable std::mutex cacheMutex_;
  std::unordered_map<std::string, std::shared_ptr<CachedStmt>> stmtCache_;

  void exec(const std::string &sql);
};

}  // namespace server::db
