#include "server/services/UserService.hpp"

#include "server/utils/Crypto.hpp"
#include "server/utils/TimeUtils.hpp"

#include <sqlite3.h>

#include <chrono>
#include <filesystem>
#include <sstream>
#include <vector>

namespace server::services {

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
  auto stmtGuard = db_.getStatement("INSERT INTO users(username, password_hash, role, created_at) VALUES(?, ?, ?, ?)");
  auto *stmt = stmtGuard.get();

  sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
  const auto hash = passwordHash(password);
  sqlite3_bind_text(stmt, 2, hash.c_str(), -1, SQLITE_TRANSIENT);
  const auto role = "user";
  sqlite3_bind_text(stmt, 3, role, -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 4, utils::nowSeconds());

  if (sqlite3_step(stmt) != SQLITE_DONE) {
    error = "Username already exists";
    return std::nullopt;
  }

  const auto id = sqlite3_last_insert_rowid(db_.raw());
  return UserRecord{.id = id, .username = username, .role = role};
}

std::optional<UserRecord> UserService::authenticate(const std::string &username,
                                                    const std::string &password) {
  auto stmtGuard = db_.getStatement("SELECT id, password_hash, role FROM users WHERE username = ?");
  auto *stmt = stmtGuard.get();

  sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
  if (sqlite3_step(stmt) != SQLITE_ROW) {
    return std::nullopt;
  }

  const auto id = sqlite3_column_int64(stmt, 0);
  const auto *hash = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
  const auto *role = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
  const auto hashStr = std::string(hash == nullptr ? "" : hash);
  const auto roleStr = std::string(role == nullptr ? "user" : role);

  if (!verifyPassword(password, hashStr)) {
    return std::nullopt;
  }

  return UserRecord{.id = id, .username = username, .role = roleStr};
}

std::string UserService::makeAccessToken(const UserRecord &user) const {
  const auto now = utils::nowSeconds();
  const auto exp = now + config_.accessTokenTtlSeconds;
  const auto payload = std::to_string(user.id) + "|" + user.role + "|" + std::to_string(exp);
  const auto sig = utils::hmacSha256Hex(config_.jwtSecret, payload);
  return payload + "|" + sig;
}

std::string UserService::makeSyncToken(std::int64_t userId) const {
  const auto now = utils::nowSeconds();
  const auto exp = now + 365 * 24 * 60 * 60; // 365 days
  const auto payload = std::to_string(userId) + "|sync|" + std::to_string(exp);
  const auto sig = utils::hmacSha256Hex(config_.jwtSecret, payload);
  return payload + "|" + sig;
}

std::string UserService::makeRefreshToken() const {
  return utils::randomTokenHex();
}

AuthTokens UserService::issueTokens(const UserRecord &user) {
  const auto refresh = makeRefreshToken();
  const auto refreshHash = utils::sha256Hex(refresh);
  const auto now = utils::nowSeconds();

  auto stmtGuard = db_.getStatement(
      "INSERT INTO refresh_tokens(user_id, token_hash, expires_at, created_at) VALUES(?, ?, ?, ?)");
  auto *stmt = stmtGuard.get();

  sqlite3_bind_int64(stmt, 1, user.id);
  sqlite3_bind_text(stmt, 2, refreshHash.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 3, now + config_.refreshTokenTtlSeconds);
  sqlite3_bind_int64(stmt, 4, now);
  sqlite3_step(stmt);

  return AuthTokens{.accessToken = makeAccessToken(user), .refreshToken = refresh};
}

std::optional<AuthTokens> UserService::refreshAccessToken(const std::string &refreshToken) {
  const auto refreshHash = utils::sha256Hex(refreshToken);
  std::int64_t tokenId = 0;
  std::int64_t userId = 0;
  std::int64_t expiresAt = 0;
  std::int64_t revokedAt = 0;

  {
    auto selectGuard = db_.getStatement(
        "SELECT id, user_id, expires_at, revoked_at FROM refresh_tokens WHERE token_hash = ?");
    auto *stmt = selectGuard.get();
    sqlite3_bind_text(stmt, 1, refreshHash.c_str(), -1, SQLITE_TRANSIENT);

    if (sqlite3_step(stmt) != SQLITE_ROW) {
      return std::nullopt;
    }

    tokenId = sqlite3_column_int64(stmt, 0);
    userId = sqlite3_column_int64(stmt, 1);
    expiresAt = sqlite3_column_int64(stmt, 2);
    revokedAt = sqlite3_column_type(stmt, 3) == SQLITE_NULL ? 0 : sqlite3_column_int64(stmt, 3);
  }

  const auto now = utils::nowSeconds();
  if (revokedAt > 0 || expiresAt <= now) {
    return std::nullopt;
  }

  const auto user = getUserById(userId);
  if (!user.has_value()) {
    return std::nullopt;
  }

  const auto newRefresh = makeRefreshToken();
  const auto newRefreshHash = utils::sha256Hex(newRefresh);

  // RAII Transaction Management
  db::Database::TransactionGuard transaction(db_);

  {
    auto insertGuard = db_.getStatement(
        "INSERT INTO refresh_tokens(user_id, token_hash, expires_at, created_at) VALUES(?, ?, ?, ?)");
    auto *insertStmt = insertGuard.get();
    sqlite3_bind_int64(insertStmt, 1, userId);
    sqlite3_bind_text(insertStmt, 2, newRefreshHash.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(insertStmt, 3, now + config_.refreshTokenTtlSeconds);
    sqlite3_bind_int64(insertStmt, 4, now);
    sqlite3_step(insertStmt);
  }

  {
    auto updateGuard = db_.getStatement(
        "UPDATE refresh_tokens SET revoked_at = ?, replaced_by_token_hash = ?, last_used_at = ? WHERE id = ?");
    auto *updateStmt = updateGuard.get();
    sqlite3_bind_int64(updateStmt, 1, now);
    sqlite3_bind_text(updateStmt, 2, newRefreshHash.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(updateStmt, 3, now);
    sqlite3_bind_int64(updateStmt, 4, tokenId);
    sqlite3_step(updateStmt);
  }

  transaction.commit();

  return AuthTokens{.accessToken = makeAccessToken(*user), .refreshToken = newRefresh};
}

bool UserService::logout(const std::string &refreshToken) {
  const auto refreshHash = utils::sha256Hex(refreshToken);
  auto stmtGuard = db_.getStatement("UPDATE refresh_tokens SET revoked_at = ? WHERE token_hash = ? AND revoked_at IS NULL");
  auto *stmt = stmtGuard.get();

  sqlite3_bind_int64(stmt, 1, utils::nowSeconds());
  sqlite3_bind_text(stmt, 2, refreshHash.c_str(), -1, SQLITE_TRANSIENT);
  const auto rc = sqlite3_step(stmt);
  const auto changes = sqlite3_changes(db_.raw());
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
  if (exp <= utils::nowSeconds()) return std::nullopt;

  return AccessClaims{.userId = std::stoll(parts[0]), .role = parts[1]};
}

void UserService::revokeAllRefreshTokens(std::int64_t userId) {
  auto stmtGuard = db_.getStatement("UPDATE refresh_tokens SET revoked_at = ? WHERE user_id = ? AND revoked_at IS NULL");
  auto *stmt = stmtGuard.get();

  sqlite3_bind_int64(stmt, 1, utils::nowSeconds());
  sqlite3_bind_int64(stmt, 2, userId);
  sqlite3_step(stmt);
}

std::optional<UserRecord> UserService::getUserById(std::int64_t userId) {
  auto stmtGuard = db_.getStatement("SELECT username, role FROM users WHERE id = ?");
  auto *stmt = stmtGuard.get();

  sqlite3_bind_int64(stmt, 1, userId);
  if (sqlite3_step(stmt) != SQLITE_ROW) {
    return std::nullopt;
  }

  const auto *name = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
  const auto *role = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
  UserRecord user{.id = userId,
                  .username = std::string(name == nullptr ? "" : name),
                  .role = std::string(role == nullptr ? "user" : role)};
  return user;
}

bool UserService::changePassword(std::int64_t userId, const std::string &newPassword) {
  auto stmtGuard = db_.getStatement("UPDATE users SET password_hash = ? WHERE id = ?");
  auto *stmt = stmtGuard.get();

  const auto hash = passwordHash(newPassword);
  sqlite3_bind_text(stmt, 1, hash.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 2, userId);
  const auto rc = sqlite3_step(stmt);
  const auto changes = sqlite3_changes(db_.raw());
  if (rc != SQLITE_DONE || changes == 0) return false;
  revokeAllRefreshTokens(userId);
  return true;
}

bool UserService::deleteAccount(std::int64_t userId) {
  revokeAllRefreshTokens(userId);

  {
    auto fileGuard = db_.getStatement("DELETE FROM file_index WHERE owner_user_id = ? OR uploader_user_id = ?");
    auto *fileStmt = fileGuard.get();
    sqlite3_bind_int64(fileStmt, 1, userId);
    sqlite3_bind_int64(fileStmt, 2, userId);
    sqlite3_step(fileStmt);
  }

  int changes = 0;
  int rc = 0;
  {
    auto stmtGuard = db_.getStatement("DELETE FROM users WHERE id = ?");
    auto *stmt = stmtGuard.get();
    sqlite3_bind_int64(stmt, 1, userId);
    rc = sqlite3_step(stmt);
    changes = sqlite3_changes(db_.raw());
  }

  if (rc != SQLITE_DONE || changes == 0) return false;

  std::error_code ec;
  std::filesystem::remove_all(std::filesystem::path(config_.storageRoot) / "users" / std::to_string(userId), ec);
  return true;
}

bool UserService::requestPasswordReset(const std::string &username, std::string &codeOut) {
  std::int64_t userId = 0;
  {
    auto stmtGuard = db_.getStatement("SELECT id FROM users WHERE username = ?");
    auto *stmt = stmtGuard.get();
    sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(stmt) != SQLITE_ROW) {
      return false;
    }
    userId = sqlite3_column_int64(stmt, 0);
  }

  std::srand(static_cast<unsigned int>(std::time(nullptr)));
  const int randomNum = 100000 + (std::rand() % 900000);
  const std::string code = std::to_string(randomNum);
  codeOut = code;

  const auto now = utils::nowSeconds();
  const auto expiresAt = now + 600;

  {
    auto insertGuard = db_.getStatement(
        "INSERT INTO password_resets(user_id, code, expires_at, created_at) VALUES(?, ?, ?, ?)");
    auto *insertStmt = insertGuard.get();
    sqlite3_bind_int64(insertStmt, 1, userId);
    sqlite3_bind_text(insertStmt, 2, code.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(insertStmt, 3, expiresAt);
    sqlite3_bind_int64(insertStmt, 4, now);
    sqlite3_step(insertStmt);
  }

  return true;
}

bool UserService::verifyPasswordReset(const std::string &username, const std::string &code, const std::string &newPassword) {
  std::int64_t userId = 0;
  {
    auto stmtGuard = db_.getStatement("SELECT id FROM users WHERE username = ?");
    auto *stmt = stmtGuard.get();
    sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(stmt) != SQLITE_ROW) {
      return false;
    }
    userId = sqlite3_column_int64(stmt, 0);
  }

  std::int64_t resetId = 0;
  {
    auto codeGuard = db_.getStatement(
        "SELECT id FROM password_resets WHERE user_id = ? AND code = ? AND expires_at > ? AND used_at IS NULL ORDER BY id DESC LIMIT 1");
    auto *codeStmt = codeGuard.get();
    sqlite3_bind_int64(codeStmt, 1, userId);
    sqlite3_bind_text(codeStmt, 2, code.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(codeStmt, 3, utils::nowSeconds());

    if (sqlite3_step(codeStmt) != SQLITE_ROW) {
      return false;
    }
    resetId = sqlite3_column_int64(codeStmt, 0);
  }

  {
    auto useGuard = db_.getStatement("UPDATE password_resets SET used_at = ? WHERE id = ?");
    auto *useStmt = useGuard.get();
    sqlite3_bind_int64(useStmt, 1, utils::nowSeconds());
    sqlite3_bind_int64(useStmt, 2, resetId);
    sqlite3_step(useStmt);
  }

  return changePassword(userId, newPassword);
}

}  // namespace server::services
