#include "server/services/ShareService.hpp"

#include "server/utils/Crypto.hpp"

#include <chrono>
#include <sqlite3.h>

namespace server::services {
namespace {
std::int64_t nowSeconds() {
  return std::chrono::duration_cast<std::chrono::seconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}
}  // namespace

ShareService::ShareService(db::Database &db) : db_(db) {}

std::string ShareService::createShare(std::int64_t ownerUserId,
                                      const std::string &scope,
                                      const std::string &relPath,
                                      std::optional<std::int64_t> expiresAt) {
  const auto token = utils::randomTokenHex(16);
  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(db_.raw(),
                     "INSERT INTO share_links(token, owner_user_id, scope, rel_path, expires_at, created_at) VALUES(?, ?, ?, ?, ?, ?)",
                     -1,
                     &stmt,
                     nullptr);

  sqlite3_bind_text(stmt, 1, token.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 2, ownerUserId);
  sqlite3_bind_text(stmt, 3, scope.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 4, relPath.c_str(), -1, SQLITE_TRANSIENT);
  if (expiresAt.has_value()) {
    sqlite3_bind_int64(stmt, 5, *expiresAt);
  } else {
    sqlite3_bind_null(stmt, 5);
  }
  sqlite3_bind_int64(stmt, 6, nowSeconds());
  sqlite3_step(stmt);
  sqlite3_finalize(stmt);
  return token;
}

std::optional<ShareRecord> ShareService::resolveShare(const std::string &token) {
  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(db_.raw(),
                     "SELECT owner_user_id, scope, rel_path, expires_at, disabled_at FROM share_links WHERE token = ?",
                     -1,
                     &stmt,
                     nullptr);
  sqlite3_bind_text(stmt, 1, token.c_str(), -1, SQLITE_TRANSIENT);
  if (sqlite3_step(stmt) != SQLITE_ROW) {
    sqlite3_finalize(stmt);
    return std::nullopt;
  }

  const auto ownerUserId = sqlite3_column_int64(stmt, 0);
  const auto *scope = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
  const auto *relPath = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
  const auto expiresAt = sqlite3_column_type(stmt, 3) == SQLITE_NULL ? 0 : sqlite3_column_int64(stmt, 3);
  const auto disabledAt = sqlite3_column_type(stmt, 4) == SQLITE_NULL ? 0 : sqlite3_column_int64(stmt, 4);
  sqlite3_finalize(stmt);

  const auto now = nowSeconds();
  if (disabledAt > 0 || (expiresAt > 0 && expiresAt <= now)) {
    return std::nullopt;
  }

  return ShareRecord{.token = token,
                     .ownerUserId = ownerUserId,
                     .scope = std::string(scope == nullptr ? "" : scope),
                     .relPath = std::string(relPath == nullptr ? "" : relPath)};
}

}  // namespace server::services
