// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later
#include "server/services/QuotaService.hpp"
#include "server/utils/TimeUtils.hpp"
#include <algorithm>
#include <stdexcept>

namespace server::services {
QuotaUsage QuotaService::usage(std::int64_t userId) const {
  auto guard = db_.getStatement(
      "SELECT COALESCE(quota_bytes, ?), "
      "(SELECT COALESCE(SUM(size_bytes),0) FROM file_index WHERE is_deleted = 0 AND type != 'directory' "
      "AND CASE WHEN owner_user_id != 0 THEN owner_user_id ELSE uploader_user_id END = users.id) + "
      "(SELECT COALESCE(SUM(size_bytes),0) FROM trash WHERE owner_user_id = users.id), "
      "(SELECT COALESCE(SUM(bytes),0) FROM upload_reservations WHERE user_id = users.id AND expires_at > ?) "
      "FROM users WHERE id = ?");
  sqlite3_bind_int64(guard.get(), 1, config_.defaultQuotaBytes);
  sqlite3_bind_int64(guard.get(), 2, utils::nowSeconds());
  sqlite3_bind_int64(guard.get(), 3, userId);
  if (sqlite3_step(guard.get()) != SQLITE_ROW) throw std::runtime_error("user_not_found");
  return {sqlite3_column_int64(guard.get(), 1), sqlite3_column_int64(guard.get(), 2), sqlite3_column_int64(guard.get(), 0)};
}

void QuotaService::reserve(std::int64_t userId, const std::string &scope, const std::string &path, std::int64_t size) {
  if (size < 0) throw std::runtime_error("invalid_upload_size");
  db::Database::TransactionGuard transaction(db_);
  std::int64_t oldSize = 0, oldReservation = 0;
  {
    auto guard = db_.getStatement("SELECT size_bytes, type, CASE WHEN owner_user_id != 0 THEN owner_user_id ELSE uploader_user_id END "
        "FROM file_index WHERE owner_user_id = ? AND scope = ? AND rel_path = ? AND is_deleted = 0");
    sqlite3_bind_int64(guard.get(), 1, scope == "shared" ? 0 : userId);
    sqlite3_bind_text(guard.get(), 2, scope.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(guard.get(), 3, path.c_str(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(guard.get()) == SQLITE_ROW) {
      if (std::string(reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 1))) == "directory")
        throw std::runtime_error("path_is_directory");
      if (sqlite3_column_int64(guard.get(), 2) == userId) oldSize = sqlite3_column_int64(guard.get(), 0);
    }
  }
  {
    auto guard = db_.getStatement("SELECT bytes FROM upload_reservations WHERE user_id = ? AND scope = ? AND rel_path = ? AND expires_at > ?");
    sqlite3_bind_int64(guard.get(), 1, userId);
    sqlite3_bind_text(guard.get(), 2, scope.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(guard.get(), 3, path.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(guard.get(), 4, utils::nowSeconds());
    if (sqlite3_step(guard.get()) == SQLITE_ROW) oldReservation = sqlite3_column_int64(guard.get(), 0);
  }
  const auto bytes = std::max<std::int64_t>(0, size - oldSize);
  const auto current = usage(userId);
  if (bytes > 0 && current.limit > 0 &&
      (current.used > current.limit || current.reserved - oldReservation > current.limit - current.used ||
       bytes > current.limit - current.used - (current.reserved - oldReservation)))
    throw std::runtime_error("quota_exceeded");
  auto guard = db_.getStatement("INSERT INTO upload_reservations(user_id, scope, rel_path, bytes, expires_at) VALUES(?, ?, ?, ?, ?) "
      "ON CONFLICT(user_id, scope, rel_path) DO UPDATE SET bytes = excluded.bytes, expires_at = excluded.expires_at");
  sqlite3_bind_int64(guard.get(), 1, userId);
  sqlite3_bind_text(guard.get(), 2, scope.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(guard.get(), 3, path.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(guard.get(), 4, bytes);
  sqlite3_bind_int64(guard.get(), 5, utils::nowSeconds() + 86400);
  if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot reserve quota");
  transaction.commit();
}

void QuotaService::release(std::int64_t userId, const std::string &scope, const std::string &path) {
  auto guard = db_.getStatement("DELETE FROM upload_reservations WHERE user_id = ? AND scope = ? AND rel_path = ?");
  sqlite3_bind_int64(guard.get(), 1, userId);
  sqlite3_bind_text(guard.get(), 2, scope.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(guard.get(), 3, path.c_str(), -1, SQLITE_TRANSIENT);
  if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot release quota");
}
}
