#include "server/services/UserService.hpp"

#include "server/utils/Crypto.hpp"

#include <sqlite3.h>

#include <chrono>
#include <sstream>
#include <vector>

namespace server::services {
namespace {
std::int64_t nowSeconds() {
  return std::chrono::duration_cast<std::chrono::seconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}
}  // namespace

UserService::UserService(db::Database &db, const utils::Config &config)
    : db_(db), config_(config) {}

std::string UserService::passwordHash(const std::string &password) const {
  // Placeholder hash; switch to bcrypt/argon2 in production hardening pass.
  return utils::sha256Hex("pw|" + password);
}

bool UserService::verifyPassword(const std::string &password, const std::string &storedHash) const {
  return passwordHash(password) == storedHash;
}

std::optional<UserRecord> UserService::registerUser(const std::string &username,
                                                    const std::string &password,
                                                    std::string &error) {
  sqlite3_stmt *countStmt = nullptr;
  sqlite3_prepare_v2(db_.raw(), "SELECT COUNT(*) FROM users", -1, &countStmt, nullptr);
  sqlite3_step(countStmt);
  const auto userCount = sqlite3_column_int64(countStmt, 0);
  sqlite3_finalize(countStmt);

  sqlite3_stmt *stmt = nullptr;
  const char *sql = "INSERT INTO users(username, password_hash, role, created_at) VALUES(?, ?, ?, ?)";
  sqlite3_prepare_v2(db_.raw(), sql, -1, &stmt, nullptr);
  sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
  const auto hash = passwordHash(password);
  sqlite3_bind_text(stmt, 2, hash.c_str(), -1, SQLITE_TRANSIENT);
  const auto role = userCount == 0 ? "owner" : "user";
  sqlite3_bind_text(stmt, 3, role, -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 4, nowSeconds());

  if (sqlite3_step(stmt) != SQLITE_DONE) {
    error = "Username already exists";
    sqlite3_finalize(stmt);
    return std::nullopt;
  }
  sqlite3_finalize(stmt);

  const auto id = sqlite3_last_insert_rowid(db_.raw());
  return UserRecord{.id = id, .username = username, .role = role};
}

std::optional<UserRecord> UserService::authenticate(const std::string &username,
                                                    const std::string &password) {
  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(db_.raw(), "SELECT id, password_hash, role FROM users WHERE username = ?", -1, &stmt, nullptr);
  sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
  if (sqlite3_step(stmt) != SQLITE_ROW) {
    sqlite3_finalize(stmt);
    return std::nullopt;
  }

  const auto id = sqlite3_column_int64(stmt, 0);
  const auto *hash = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
  const auto *role = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
  const auto hashStr = std::string(hash == nullptr ? "" : hash);
  const auto roleStr = std::string(role == nullptr ? "user" : role);
  sqlite3_finalize(stmt);

  if (!verifyPassword(password, hashStr)) {
    return std::nullopt;
  }

  return UserRecord{.id = id, .username = username, .role = roleStr};
}

std::string UserService::makeAccessToken(const UserRecord &user) const {
  const auto now = nowSeconds();
  const auto exp = now + config_.accessTokenTtlSeconds;
  const auto payload = std::to_string(user.id) + "|" + user.role + "|" + std::to_string(exp);
  const auto sig = utils::hmacSha256Hex(config_.jwtSecret, payload);
  return payload + "|" + sig;
}

std::string UserService::makeRefreshToken() const {
  return utils::randomTokenHex();
}

AuthTokens UserService::issueTokens(const UserRecord &user) {
  const auto refresh = makeRefreshToken();
  const auto refreshHash = utils::sha256Hex(refresh);
  const auto now = nowSeconds();

  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(db_.raw(),
                     "INSERT INTO refresh_tokens(user_id, token_hash, expires_at, created_at) VALUES(?, ?, ?, ?)",
                     -1,
                     &stmt,
                     nullptr);
  sqlite3_bind_int64(stmt, 1, user.id);
  sqlite3_bind_text(stmt, 2, refreshHash.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 3, now + config_.refreshTokenTtlSeconds);
  sqlite3_bind_int64(stmt, 4, now);
  sqlite3_step(stmt);
  sqlite3_finalize(stmt);

  return AuthTokens{.accessToken = makeAccessToken(user), .refreshToken = refresh};
}

std::optional<AuthTokens> UserService::refreshAccessToken(const std::string &refreshToken) {
  const auto refreshHash = utils::sha256Hex(refreshToken);
  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(
      db_.raw(),
      "SELECT id, user_id, expires_at, revoked_at FROM refresh_tokens WHERE token_hash = ?",
      -1,
      &stmt,
      nullptr);
  sqlite3_bind_text(stmt, 1, refreshHash.c_str(), -1, SQLITE_TRANSIENT);

  if (sqlite3_step(stmt) != SQLITE_ROW) {
    sqlite3_finalize(stmt);
    return std::nullopt;
  }

  const auto tokenId = sqlite3_column_int64(stmt, 0);
  const auto userId = sqlite3_column_int64(stmt, 1);
  const auto expiresAt = sqlite3_column_int64(stmt, 2);
  const auto revokedAt = sqlite3_column_type(stmt, 3) == SQLITE_NULL ? 0 : sqlite3_column_int64(stmt, 3);
  sqlite3_finalize(stmt);

  const auto now = nowSeconds();
  if (revokedAt > 0 || expiresAt <= now) {
    return std::nullopt;
  }

  const auto user = getUserById(userId);
  if (!user.has_value()) {
    return std::nullopt;
  }

  const auto newRefresh = makeRefreshToken();
  const auto newRefreshHash = utils::sha256Hex(newRefresh);

  sqlite3_exec(db_.raw(), "BEGIN IMMEDIATE TRANSACTION", nullptr, nullptr, nullptr);

  sqlite3_stmt *insertStmt = nullptr;
  sqlite3_prepare_v2(db_.raw(),
                     "INSERT INTO refresh_tokens(user_id, token_hash, expires_at, created_at) VALUES(?, ?, ?, ?)",
                     -1,
                     &insertStmt,
                     nullptr);
  sqlite3_bind_int64(insertStmt, 1, userId);
  sqlite3_bind_text(insertStmt, 2, newRefreshHash.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(insertStmt, 3, now + config_.refreshTokenTtlSeconds);
  sqlite3_bind_int64(insertStmt, 4, now);
  sqlite3_step(insertStmt);
  sqlite3_finalize(insertStmt);

  sqlite3_stmt *updateStmt = nullptr;
  sqlite3_prepare_v2(db_.raw(),
                     "UPDATE refresh_tokens SET revoked_at = ?, replaced_by_token_hash = ?, last_used_at = ? WHERE id = ?",
                     -1,
                     &updateStmt,
                     nullptr);
  sqlite3_bind_int64(updateStmt, 1, now);
  sqlite3_bind_text(updateStmt, 2, newRefreshHash.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(updateStmt, 3, now);
  sqlite3_bind_int64(updateStmt, 4, tokenId);
  sqlite3_step(updateStmt);
  sqlite3_finalize(updateStmt);

  sqlite3_exec(db_.raw(), "COMMIT", nullptr, nullptr, nullptr);

  return AuthTokens{.accessToken = makeAccessToken(*user), .refreshToken = newRefresh};
}

bool UserService::logout(const std::string &refreshToken) {
  const auto refreshHash = utils::sha256Hex(refreshToken);
  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(db_.raw(), "UPDATE refresh_tokens SET revoked_at = ? WHERE token_hash = ? AND revoked_at IS NULL", -1, &stmt, nullptr);
  sqlite3_bind_int64(stmt, 1, nowSeconds());
  sqlite3_bind_text(stmt, 2, refreshHash.c_str(), -1, SQLITE_TRANSIENT);
  const auto rc = sqlite3_step(stmt);
  const auto changes = sqlite3_changes(db_.raw());
  sqlite3_finalize(stmt);
  return rc == SQLITE_DONE && changes > 0;
}

std::optional<AccessClaims> UserService::verifyAccessToken(const std::string &accessToken) const {
  std::vector<std::string> parts;
  std::stringstream ss(accessToken);
  std::string part;
  while (std::getline(ss, part, '|')) {
    parts.push_back(part);
  }
  if (parts.size() != 4) return std::nullopt;

  const auto payload = parts[0] + "|" + parts[1] + "|" + parts[2];
  const auto sig = utils::hmacSha256Hex(config_.jwtSecret, payload);
  if (sig != parts[3]) return std::nullopt;

  const auto exp = std::stoll(parts[2]);
  if (exp <= nowSeconds()) return std::nullopt;

  return AccessClaims{.userId = std::stoll(parts[0]), .role = parts[1]};
}

void UserService::revokeAllRefreshTokens(std::int64_t userId) {
  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(db_.raw(), "UPDATE refresh_tokens SET revoked_at = ? WHERE user_id = ? AND revoked_at IS NULL", -1, &stmt, nullptr);
  sqlite3_bind_int64(stmt, 1, nowSeconds());
  sqlite3_bind_int64(stmt, 2, userId);
  sqlite3_step(stmt);
  sqlite3_finalize(stmt);
}

std::optional<UserRecord> UserService::getUserById(std::int64_t userId) {
  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(db_.raw(), "SELECT username, role FROM users WHERE id = ?", -1, &stmt, nullptr);
  sqlite3_bind_int64(stmt, 1, userId);
  if (sqlite3_step(stmt) != SQLITE_ROW) {
    sqlite3_finalize(stmt);
    return std::nullopt;
  }

  const auto *name = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
  const auto *role = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
  UserRecord user{.id = userId,
                  .username = std::string(name == nullptr ? "" : name),
                  .role = std::string(role == nullptr ? "user" : role)};
  sqlite3_finalize(stmt);
  return user;
}

bool UserService::changePassword(std::int64_t userId, const std::string &newPassword) {
  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(db_.raw(), "UPDATE users SET password_hash = ? WHERE id = ?", -1, &stmt, nullptr);
  const auto hash = passwordHash(newPassword);
  sqlite3_bind_text(stmt, 1, hash.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 2, userId);
  const auto rc = sqlite3_step(stmt);
  const auto changes = sqlite3_changes(db_.raw());
  sqlite3_finalize(stmt);
  if (rc != SQLITE_DONE || changes == 0) return false;
  revokeAllRefreshTokens(userId);
  return true;
}

bool UserService::deleteAccount(std::int64_t userId) {
  revokeAllRefreshTokens(userId);
  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(db_.raw(), "DELETE FROM users WHERE id = ?", -1, &stmt, nullptr);
  sqlite3_bind_int64(stmt, 1, userId);
  const auto rc = sqlite3_step(stmt);
  const auto changes = sqlite3_changes(db_.raw());
  sqlite3_finalize(stmt);
  return rc == SQLITE_DONE && changes > 0;
}

}  // namespace server::services
