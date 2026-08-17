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

#include "server/services/ShareService.hpp"

#include "server/utils/Crypto.hpp"
#include "server/utils/TimeUtils.hpp"

#include <sqlite3.h>
#include <stdexcept>

namespace server::services {

ShareService::ShareService(db::Database &db) : db_(db) {}

std::string ShareService::createShare(std::int64_t ownerUserId,
                                      const std::string &scope,
                                      const std::string &relPath,
                                      std::optional<std::int64_t> expiresAt) {
  const auto token = utils::randomTokenHex(16);
  auto stmtGuard = db_.getStatement(
      "INSERT INTO share_links(token, owner_user_id, scope, rel_path, expires_at, created_at) VALUES(?, ?, ?, ?, ?, ?)");
  auto *stmt = stmtGuard.get();

  sqlite3_bind_text(stmt, 1, token.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 2, ownerUserId);
  sqlite3_bind_text(stmt, 3, scope.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 4, relPath.c_str(), -1, SQLITE_TRANSIENT);
  if (expiresAt.has_value()) {
    sqlite3_bind_int64(stmt, 5, *expiresAt);
  } else {
    sqlite3_bind_null(stmt, 5);
  }
  sqlite3_bind_int64(stmt, 6, utils::nowSeconds());
  const auto stepRc = sqlite3_step(stmt);
  if (stepRc != SQLITE_DONE) {
    throw std::runtime_error("Failed to persist share link");
  }
  return token;
}

std::optional<ShareRecord> ShareService::resolveShare(const std::string &token) {
  auto stmtGuard = db_.getStatement(
      "SELECT owner_user_id, scope, rel_path, expires_at, disabled_at FROM share_links WHERE token = ?");
  auto *stmt = stmtGuard.get();

  sqlite3_bind_text(stmt, 1, token.c_str(), -1, SQLITE_TRANSIENT);
  if (sqlite3_step(stmt) != SQLITE_ROW) {
    return std::nullopt;
  }

  const auto ownerUserId = sqlite3_column_int64(stmt, 0);
  const auto *scopeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
  const auto *relPathRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
  const std::string scope = scopeRaw == nullptr ? "" : std::string(scopeRaw);
  const std::string relPath = relPathRaw == nullptr ? "" : std::string(relPathRaw);
  const auto expiresAt = sqlite3_column_type(stmt, 3) == SQLITE_NULL ? 0 : sqlite3_column_int64(stmt, 3);
  const auto disabledAt = sqlite3_column_type(stmt, 4) == SQLITE_NULL ? 0 : sqlite3_column_int64(stmt, 4);

  const auto now = utils::nowSeconds();
  if (disabledAt > 0 || (expiresAt > 0 && expiresAt <= now)) {
    return std::nullopt;
  }

  return ShareRecord{.token = token,
                     .ownerUserId = ownerUserId,
                     .scope = scope,
                     .relPath = relPath};
}

}  // namespace server::services
