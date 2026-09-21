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

#include "server/services/UserService.hpp"

#include "server/utils/Crypto.hpp"
#include "server/utils/TimeUtils.hpp"
#include "server/AppContext.hpp"
#include "server/utils/PlatformUtils.hpp"
#include "server/utils/DurableFiles.hpp"
#include <fstream>

#include <trantor/utils/Logger.h>
#include <sqlite3.h>
#include <openssl/rand.h>
#include <openssl/crypto.h>
#include <limits>

#include <chrono>
#include <filesystem>
#include <sstream>
#include <vector>

namespace server::services {

UserService::UserService(db::Database &db, const utils::Config &config)
    : db_(db), config_(config) {}

std::string UserService::passwordHash(const std::string &password) const {
  return utils::hashPassword(password);
}

bool UserService::verifyPassword(const std::string &password, const std::string &storedHash) const {
  return utils::verifyPasswordHash(password, storedHash);
}

std::optional<UserRecord> UserService::registerUser(const std::string &username,
                                                    const std::string &password,
                                                    std::string &error) {
  if (username.empty() || username.size() > 128 || password.empty() || password.size() > 4096 ||
      username.find_first_of("\r\n\t") != std::string::npos) {
    error = "invalid_credentials";
    return std::nullopt;
  }
  const auto hash = passwordHash(password);
  db::Database::TransactionGuard transaction(db_);
  bool first;
  {
    auto guard = db_.getStatement("SELECT 1 FROM users LIMIT 1");
    first = sqlite3_step(guard.get()) != SQLITE_ROW;
  }
  if (!first && config_.registrationMode == "closed") {
    error = "registration_closed";
    return std::nullopt;
  }
  const std::string role = first ? "superuser" : "user";
  const std::string status = first || config_.registrationMode == "open" ? "active" : "pending";
  auto guard = db_.getStatement(
      "INSERT INTO users(username, password_hash, role, status, created_at) VALUES(?, ?, ?, ?, ?)");
  auto *stmt = guard.get();
  sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 2, hash.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, role.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 4, status.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 5, utils::nowSeconds());
  if (sqlite3_step(stmt) != SQLITE_DONE) {
    error = "username_exists";
    return std::nullopt;
  }
  const auto id = sqlite3_last_insert_rowid(db_.raw());
  transaction.commit();
  return UserRecord{.id = id, .username = username, .role = role, .status = status};
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
  const auto hashStr = std::string(hash == nullptr ? "" : hash);

  if (!verifyPassword(password, hashStr)) {
    return std::nullopt;
  }

  if (utils::isLegacyPasswordHash(hashStr)) {
    try {
      const auto newHash = passwordHash(password);
      auto updateGuard = db_.getStatement("UPDATE users SET password_hash = ? WHERE id = ?");
      auto *updateStmt = updateGuard.get();
      sqlite3_bind_text(updateStmt, 1, newHash.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_int64(updateStmt, 2, id);
      sqlite3_step(updateStmt);
      LOG_INFO << "Seamlessly upgraded legacy password hash to Argon2id for user: " << username;
    } catch (const std::exception &e) {
      LOG_WARN << "Failed to upgrade legacy password hash for user " << username << ": " << e.what();
    }
  }

  return getUserById(id);
}

std::string UserService::tokenSigningKey(std::int64_t userId) const {
  auto guard = db_.getStatement("SELECT password_hash, auth_version FROM users WHERE id = ? AND status = 'active' AND password_reset_required = 0");
  sqlite3_bind_int64(guard.get(), 1, userId);
  if (sqlite3_step(guard.get()) != SQLITE_ROW) throw std::runtime_error("User not found");
  const auto hash = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 0));
  const auto version = sqlite3_column_int64(guard.get(), 1);
  const auto material = std::string(hash ? hash : "") + (version == 0 ? "" : "|" + std::to_string(version));
  return utils::hmacSha256Hex(config_.jwtSecret, material);
}

std::string UserService::makeAccessToken(const UserRecord &user) const {
  const auto now = utils::nowSeconds();
  const auto exp = now + config_.accessTokenTtlSeconds;
  const auto payload = std::to_string(user.id) + "|" + user.role + "|" + std::to_string(exp);
  const auto sig = utils::hmacSha256Hex(tokenSigningKey(user.id), payload);
  return payload + "|" + sig;
}

std::string UserService::makeSyncToken(std::int64_t userId) const {
  const auto now = utils::nowSeconds();
  const auto exp = now + 365 * 24 * 60 * 60; // 365 days
  const auto payload = std::to_string(userId) + "|sync|" + std::to_string(exp);
  const auto sig = utils::hmacSha256Hex(tokenSigningKey(userId), payload);
  return payload + "|" + sig;
}

std::string UserService::makeRefreshToken() const {
  return utils::randomTokenHex();
}

AuthTokens UserService::issueTokens(const UserRecord &user) {
  db::Database::TransactionGuard transaction(db_);
  const auto current = getUserById(user.id);
  if (!current || current->status != "active" || current->passwordResetRequired)
    throw std::runtime_error("Account is not active");
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

  const auto access = makeAccessToken(*current);
  transaction.commit();
  return AuthTokens{.accessToken = access, .refreshToken = refresh};
}

std::optional<AuthTokens> UserService::refreshAccessToken(const std::string &refreshToken) {
  db::Database::TransactionGuard transaction(db_);
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
  if (!user || user->status != "active" || user->passwordResetRequired) {
    return std::nullopt;
  }

  const auto newRefresh = makeRefreshToken();
  const auto newRefreshHash = utils::sha256Hex(newRefresh);


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
  std::string sig;
  try { sig = utils::hmacSha256Hex(tokenSigningKey(std::stoll(parts[0])), payload); }
  catch (...) { return std::nullopt; }
  if (sig.size() != parts[3].size() || CRYPTO_memcmp(sig.data(), parts[3].data(), sig.size()) != 0) return std::nullopt;

  try {
    const auto exp = std::stoll(parts[2]);
    if (exp <= utils::nowSeconds()) return std::nullopt;
    const auto user = getUserById(std::stoll(parts[0]));
    if (!user || user->status != "active" || user->passwordResetRequired) return std::nullopt;
    if (parts[1] != "sync" && parts[1] != "user" && parts[1] != "admin" && parts[1] != "superuser") return std::nullopt;
    return AccessClaims{.userId = user->id, .role = parts[1] == "sync" ? "sync" : user->role};
  } catch (...) { return std::nullopt; }
}

void UserService::revokeAllRefreshTokens(std::int64_t userId) {
  auto stmtGuard = db_.getStatement("UPDATE refresh_tokens SET revoked_at = ? WHERE user_id = ? AND revoked_at IS NULL");
  auto *stmt = stmtGuard.get();

  sqlite3_bind_int64(stmt, 1, utils::nowSeconds());
  sqlite3_bind_int64(stmt, 2, userId);
  sqlite3_step(stmt);
}

std::optional<UserRecord> UserService::getUserById(std::int64_t userId) const {
  auto guard = db_.getStatement("SELECT username, role, status, quota_bytes, created_at, password_reset_required FROM users WHERE id = ?");
  auto *stmt = guard.get();
  sqlite3_bind_int64(stmt, 1, userId);
  if (sqlite3_step(stmt) != SQLITE_ROW) return std::nullopt;
  return UserRecord{
      .id = userId,
      .username = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0)),
      .role = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1)),
      .status = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2)),
      .quotaBytes = sqlite3_column_type(stmt, 3) == SQLITE_NULL ? std::nullopt : std::optional<std::int64_t>(sqlite3_column_int64(stmt, 3)),
      .createdAt = sqlite3_column_int64(stmt, 4),
      .passwordResetRequired = sqlite3_column_int(stmt, 5) != 0};
}

std::vector<UserRecord> UserService::listUsers(bool pending) const {
  std::vector<UserRecord> result;
  auto guard = db_.getStatement("SELECT id FROM users WHERE (status = 'pending') = ? ORDER BY created_at, id");
  sqlite3_bind_int(guard.get(), 1, pending);
  while (sqlite3_step(guard.get()) == SQLITE_ROW) {
    auto user = getUserById(sqlite3_column_int64(guard.get(), 0));
    if (user) result.push_back(*user);
  }
  return result;
}

bool UserService::isLastActiveAdmin(std::int64_t userId) const {
  auto guard = db_.getStatement(
      "SELECT 1 FROM users WHERE id = ? AND role IN ('admin', 'superuser') AND status = 'active' "
      "AND password_reset_required = 0 AND NOT EXISTS(SELECT 1 FROM users WHERE id != ? "
      "AND role IN ('admin', 'superuser') AND status = 'active' AND password_reset_required = 0)");
  sqlite3_bind_int64(guard.get(), 1, userId);
  sqlite3_bind_int64(guard.get(), 2, userId);
  return sqlite3_step(guard.get()) == SQLITE_ROW;
}

void UserService::audit(std::int64_t actorId, const std::string &action, std::int64_t targetId) {
  auto guard = db_.getStatement("INSERT INTO admin_audit(actor_user_id, action, target_user_id, created_at) VALUES(?, ?, ?, ?)");
  sqlite3_bind_int64(guard.get(), 1, actorId);
  sqlite3_bind_text(guard.get(), 2, action.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(guard.get(), 3, targetId);
  sqlite3_bind_int64(guard.get(), 4, utils::nowSeconds());
  if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot write audit event");
}

void UserService::revokeSessions(std::int64_t userId) {
  db::Database::TransactionGuard transaction(db_);
  {
    auto guard = db_.getStatement("UPDATE users SET auth_version = auth_version + 1 WHERE id = ?");
    sqlite3_bind_int64(guard.get(), 1, userId);
    if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot revoke sessions");
  }
  revokeAllRefreshTokens(userId);
  transaction.commit();
}

bool UserService::updateUser(std::int64_t actorId, std::int64_t userId, const Json::Value &patch, std::string &error) {
  db::Database::TransactionGuard transaction(db_);
  const auto actor = getUserById(actorId);
  if (!actor || (actor->role != "admin" && actor->role != "superuser") || actor->status != "active" || actor->passwordResetRequired) {
    error = "forbidden"; return false;
  }
  auto user = getUserById(userId);
  if (!user || user->status == "pending" || user->status == "deleting") { error = "user_not_found"; return false; }
  if (!patch.isObject() || patch.empty()) { error = "invalid_user_patch"; return false; }
  for (const auto &key : patch.getMemberNames()) {
    if (key != "role" && key != "status" && key != "quota_bytes") { error = "invalid_user_patch"; return false; }
  }

  // Superuser protections:
  // Superuser cannot be modified by anyone else.
  if (user->role == "superuser" && actorId != userId) {
    error = "cannot_modify_superuser"; return false;
  }

  if (patch.isMember("role")) {
    // Superuser cannot transfer or change their own role.
    if (user->role == "superuser") {
      if (patch["role"] != "superuser") {
        error = "cannot_modify_superuser"; return false;
      }
    } else {
      // Superuser role cannot be granted through API.
      if (!patch["role"].isString() || (patch["role"] != "admin" && patch["role"] != "user")) {
        error = "invalid_role"; return false;
      }
      // Only superuser can demote an admin to a regular user.
      if (user->role == "admin" && patch["role"].asString() == "user" && actor->role != "superuser") {
        error = "cannot_demote_admin"; return false;
      }
      user->role = patch["role"].asString();
    }
  }

  if (patch.isMember("status")) {
    if (!patch["status"].isString() || (patch["status"] != "active" && patch["status"] != "blocked")) {
      error = "invalid_status"; return false;
    }
    if (actorId == userId && patch["status"] == "blocked") {
      error = "cannot_block_self"; return false;
    }
    if (user->role == "superuser" && patch["status"] == "blocked") {
      error = "cannot_block_superuser"; return false;
    }
    user->status = patch["status"].asString();
  }

  if (patch.isMember("quota_bytes")) {
    if (!patch["quota_bytes"].isNull() && (!patch["quota_bytes"].isInt64() || patch["quota_bytes"].asInt64() < 0)) {
      error = "invalid_quota"; return false;
    }
    // Storage quota ceiling: regular admins cannot set quota higher than default_quota_bytes or set unlimited (0).
    if (actor->role != "superuser" && config_.defaultQuotaBytes > 0) {
      if (!patch["quota_bytes"].isNull()) {
        const auto val = patch["quota_bytes"].asInt64();
        if (val == 0 || val > config_.defaultQuotaBytes) {
          error = "quota_exceeded_default"; return false;
        }
      }
    }
    user->quotaBytes = patch["quota_bytes"].isNull() ? std::nullopt : std::optional<std::int64_t>(patch["quota_bytes"].asInt64());
  }

  if ((user->role != "admin" && user->role != "superuser" || user->status != "active") && isLastActiveAdmin(userId)) {
    error = "last_admin"; return false;
  }
  {
    auto guard = db_.getStatement("UPDATE users SET role = ?, status = ?, quota_bytes = ? WHERE id = ?");
    sqlite3_bind_text(guard.get(), 1, user->role.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(guard.get(), 2, user->status.c_str(), -1, SQLITE_TRANSIENT);
    if (user->quotaBytes) sqlite3_bind_int64(guard.get(), 3, *user->quotaBytes); else sqlite3_bind_null(guard.get(), 3);
    sqlite3_bind_int64(guard.get(), 4, userId);
    if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot update user");
  }
  if (user->status == "blocked") {
    // Already inside the transaction: invalidate every token without a nested BEGIN.
    auto guard = db_.getStatement("UPDATE users SET auth_version = auth_version + 1 WHERE id = ?");
    sqlite3_bind_int64(guard.get(), 1, userId);
    if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot revoke sessions");
    revokeAllRefreshTokens(userId);
  }
  audit(actorId, "user.update", userId);
  transaction.commit();
  return true;
}

bool UserService::decideApplication(std::int64_t actorId, std::int64_t userId, bool approve, std::string &error) {
  db::Database::TransactionGuard transaction(db_);
  const auto actor = getUserById(actorId);
  if (!actor || (actor->role != "admin" && actor->role != "superuser") || actor->status != "active" || actor->passwordResetRequired) {
    error = "forbidden"; return false;
  }
  {
    auto guard = db_.getStatement(approve ? "UPDATE users SET status = 'active' WHERE id = ? AND status = 'pending'" :
                                         "DELETE FROM users WHERE id = ? AND status = 'pending'");
    sqlite3_bind_int64(guard.get(), 1, userId);
    if (sqlite3_step(guard.get()) != SQLITE_DONE || sqlite3_changes(db_.raw()) != 1) { error = "application_not_found"; return false; }
  }
  audit(actorId, approve ? "registration.approve" : "registration.reject", userId);
  transaction.commit();
  return true;
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
  // Self-service deletion transfers shared data to another active administrator.
  std::int64_t recipient = 0;
  {
    auto guard = db_.getStatement("SELECT id FROM users WHERE id != ? AND role IN ('admin', 'superuser') AND status = 'active' AND password_reset_required = 0 ORDER BY id LIMIT 1");
    sqlite3_bind_int64(guard.get(), 1, userId);
    if (sqlite3_step(guard.get()) == SQLITE_ROW) recipient = sqlite3_column_int64(guard.get(), 0);
  }
  if (recipient == 0) return false;
  std::string error;
  return deleteUser(recipient, userId, error);
}

bool UserService::deleteUser(std::int64_t actorId, std::int64_t userId, std::string &error) {
  std::lock_guard<std::recursive_mutex> storageLock(ctx().storageMutex);
  try {
    {
      db::Database::TransactionGuard transaction(db_);
      const auto actor = getUserById(actorId);
      const auto user = getUserById(userId);
      if (!actor || (actor->role != "admin" && actor->role != "superuser") || actor->status != "active" || actor->passwordResetRequired) {
        error = "forbidden"; return false;
      }
      if (!user || user->status == "pending") { error = "user_not_found"; return false; }
      if (user->role == "superuser") { error = "cannot_delete_superuser"; return false; }
      if (user->role == "admin" && actor->role != "superuser") { error = "forbidden"; return false; }
      if (actorId == userId || isLastActiveAdmin(userId)) { error = "last_admin"; return false; }
      {
        auto guard = db_.getStatement("SELECT 1 FROM account_deletions WHERE recipient_user_id = ? LIMIT 1");
        sqlite3_bind_int64(guard.get(), 1, userId);
        if (sqlite3_step(guard.get()) == SQLITE_ROW) { error = "transfer_in_progress"; return false; }
      }
      if (user->status != "deleting") {
        Json::Value manifest;
        manifest["prefix"] = "Transferred-" + std::to_string(userId) + "-" + utils::randomTokenHex(8);
        manifest["files"] = Json::arrayValue;
        manifest["hashes"] = Json::arrayValue;
        std::int64_t transferBytes = 0;
        {
          auto guard = db_.getStatement("SELECT id, rel_path, type, size_bytes, scope FROM file_index WHERE is_deleted = 0 AND "
              "((owner_user_id = ? AND is_shared = 1) OR (scope = 'shared' AND uploader_user_id = ?)) ORDER BY rel_path");
          sqlite3_bind_int64(guard.get(), 1, userId);
          sqlite3_bind_int64(guard.get(), 2, userId);
          while (sqlite3_step(guard.get()) == SQLITE_ROW) {
            Json::Value file;
            file["id"] = Json::Int64(sqlite3_column_int64(guard.get(), 0));
            file["path"] = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 1));
            file["directory"] = std::string(reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 2))) == "directory";
            file["scope"] = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 4));
            if (!file["directory"].asBool()) transferBytes += sqlite3_column_int64(guard.get(), 3);
            manifest["files"].append(file);
          }
        }
        {
          auto guard = db_.getStatement("SELECT sha256 FROM file_index WHERE owner_user_id = ? UNION SELECT sha256 FROM trash WHERE owner_user_id = ?");
          sqlite3_bind_int64(guard.get(), 1, userId);
          sqlite3_bind_int64(guard.get(), 2, userId);
          while (sqlite3_step(guard.get()) == SQLITE_ROW) {
            const auto hash = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 0));
            if (hash && std::string(hash).size() == 64) manifest["hashes"].append(hash);
          }
        }
        const auto usage = ctx().quotaService->usage(actorId);
        if (transferBytes > 0 && usage.limit > 0 &&
            (usage.used > usage.limit || usage.reserved > usage.limit - usage.used ||
             transferBytes > usage.limit - usage.used - usage.reserved)) { error = "quota_exceeded"; return false; }
        // Durable reservation has no expiry until the deletion completes.
        {
          auto guard = db_.getStatement("INSERT INTO upload_reservations(user_id, scope, rel_path, bytes, expires_at) VALUES(?, 'deletion', ?, ?, 9223372036854775807)");
          sqlite3_bind_int64(guard.get(), 1, actorId);
          const auto target = std::to_string(userId);
          sqlite3_bind_text(guard.get(), 2, target.c_str(), -1, SQLITE_TRANSIENT);
          sqlite3_bind_int64(guard.get(), 3, transferBytes);
          if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot reserve transferred files");
        }
        {
          auto guard = db_.getStatement("INSERT INTO account_deletions(user_id, recipient_user_id, manifest, created_at) VALUES(?, ?, ?, ?)");
          const auto serialized = Json::writeString(Json::StreamWriterBuilder(), manifest);
          sqlite3_bind_int64(guard.get(), 1, userId);
          sqlite3_bind_int64(guard.get(), 2, actorId);
          sqlite3_bind_text(guard.get(), 3, serialized.c_str(), -1, SQLITE_TRANSIENT);
          sqlite3_bind_int64(guard.get(), 4, utils::nowSeconds());
          if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot schedule deletion");
        }
        {
          auto guard = db_.getStatement("UPDATE users SET status = 'deleting', auth_version = auth_version + 1 WHERE id = ?");
          sqlite3_bind_int64(guard.get(), 1, userId);
          if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot disable deleted account");
        }
        revokeAllRefreshTokens(userId);
        audit(actorId, "user.delete_started", userId);
      }
      transaction.commit();
    }
    finishDeletion(userId);
    return true;
  } catch (const std::exception &e) {
    LOG_ERROR << "Account deletion requires retry for user " << userId;
    error = "deletion_incomplete";
    return false;
  }
}

void UserService::finishDeletion(std::int64_t userId) {
  std::lock_guard<std::recursive_mutex> storageLock(ctx().storageMutex);
  Json::Value manifest;
  std::int64_t recipient;
  std::string phase;
  {
    auto guard = db_.getStatement("SELECT recipient_user_id, manifest, phase FROM account_deletions WHERE user_id = ?");
    sqlite3_bind_int64(guard.get(), 1, userId);
    if (sqlite3_step(guard.get()) != SQLITE_ROW) return;
    recipient = sqlite3_column_int64(guard.get(), 0);
    std::istringstream input(reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 1)));
    input >> manifest;
    phase = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 2));
  }
  const auto prefix = manifest["prefix"].asString();
  if (phase == "copying") {
    if (!getUserById(recipient)) throw std::runtime_error("Transfer recipient missing");
    for (const auto &file : manifest["files"]) {
      if (config_.hashFiles || file["scope"].asString() == "shared") continue;
      const auto source = ctx().fileService->resolvePath(userId, "admin", StorageScope::Private, file["path"].asString(), false);
      const auto destination = ctx().fileService->resolvePath(recipient, "admin", StorageScope::Private, prefix + "/" + file["path"].asString(), true);
      if (file["directory"].asBool()) { std::filesystem::create_directories(destination); continue; }
      std::filesystem::create_directories(destination.parent_path());
      // A retry accepts a previously verified copy but never overwrites unrelated data.
      const auto expected = utils::sha256FileHex(source);
      if (!std::filesystem::exists(destination)) {
        const auto staged = destination.string() + ".deletion-copy";
        std::filesystem::copy_file(source, staged, std::filesystem::copy_options::overwrite_existing);
        if (utils::sha256FileHex(staged) != expected) throw std::runtime_error("Transfer verification failed");
        utils::durableReplace(staged, destination);
      }
      if (utils::sha256FileHex(destination) != expected) throw std::runtime_error("Transfer destination conflict");
      utils::syncFile(destination);
      const auto rootPath = std::filesystem::absolute(config_.storageRoot).lexically_normal();
      for (auto parent = std::filesystem::absolute(destination).parent_path(); parent != rootPath && parent.has_relative_path(); parent = parent.parent_path())
        utils::syncDirectory(parent);
      utils::syncDirectory(rootPath);
    }
    db::Database::TransactionGuard transaction(db_);
    for (const auto &file : manifest["files"]) {
      if (file["scope"].asString() == "shared") {
        auto guard = db_.getStatement("UPDATE file_index SET uploader_user_id = ? WHERE id = ?");
        sqlite3_bind_int64(guard.get(), 1, recipient);
        sqlite3_bind_int64(guard.get(), 2, file["id"].asInt64());
        if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot transfer shared owner");
      } else {
        auto guard = db_.getStatement("UPDATE file_index SET owner_user_id = ?, uploader_user_id = ?, rel_path = ?, parent_path = ?, thumbnail_path = '', thumbnail_updated_at = NULL WHERE id = ?");
        const auto path = prefix + "/" + file["path"].asString();
        const auto parent = std::filesystem::path(path).parent_path().generic_string();
        sqlite3_bind_int64(guard.get(), 1, recipient);
        sqlite3_bind_int64(guard.get(), 2, recipient);
        sqlite3_bind_text(guard.get(), 3, path.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(guard.get(), 4, parent.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int64(guard.get(), 5, file["id"].asInt64());
        if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot transfer shared file");
      }
    }
    {
      auto guard = db_.getStatement("UPDATE account_deletions SET phase = 'cleanup' WHERE user_id = ?");
      sqlite3_bind_int64(guard.get(), 1, userId);
      if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot advance deletion");
    }
    ctx().quotaService->release(recipient, "deletion", std::to_string(userId));
    transaction.commit();
  }
  const auto root = std::filesystem::path(config_.storageRoot);
  for (const auto &directory : {"users", "trash", ".thumbs"})
    std::filesystem::remove_all(root / directory / std::to_string(userId));
  const auto tmp = root / ".tmp_uploads";
  if (std::filesystem::exists(tmp)) {
    for (const auto &entry : std::filesystem::directory_iterator(tmp))
      if (entry.path().filename().string().starts_with(std::to_string(userId) + "_")) std::filesystem::remove(entry.path());
  }
  {
    db::Database::TransactionGuard transaction(db_);
    {
      auto guard = db_.getStatement("DELETE FROM file_index WHERE owner_user_id = ?");
      sqlite3_bind_int64(guard.get(), 1, userId);
      if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot remove personal index");
    }
    {
      auto guard = db_.getStatement("DELETE FROM trash WHERE owner_user_id = ?");
      sqlite3_bind_int64(guard.get(), 1, userId);
      if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot remove account trash");
    }
    transaction.commit();
  }
  if (config_.hashFiles) {
    for (const auto &hash : manifest["hashes"]) {
      const auto value = hash.asString();
      auto guard = db_.getStatement("SELECT 1 FROM file_index WHERE sha256 = ? UNION ALL SELECT 1 FROM trash WHERE sha256 = ? LIMIT 1");
      sqlite3_bind_text(guard.get(), 1, value.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(guard.get(), 2, value.c_str(), -1, SQLITE_TRANSIENT);
      if (sqlite3_step(guard.get()) != SQLITE_ROW) std::filesystem::remove(root / "data" / value);
    }
  }
  db::Database::TransactionGuard transaction(db_);
  {
    auto guard = db_.getStatement("DELETE FROM account_deletions WHERE user_id = ?");
    sqlite3_bind_int64(guard.get(), 1, userId);
    if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot finish deletion");
  }
  {
    // Keep the disabled account visible for retry until every storage cleanup
    // succeeds. Account removal and completion of its job commit together.
    auto guard = db_.getStatement("DELETE FROM users WHERE id = ?");
    sqlite3_bind_int64(guard.get(), 1, userId);
    if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot remove account");
  }
  audit(recipient, "user.delete_completed", userId);
  transaction.commit();
}

void UserService::resumeDeletions() {
  std::vector<std::int64_t> ids;
  {
    auto guard = db_.getStatement("SELECT user_id FROM account_deletions ORDER BY created_at");
    while (sqlite3_step(guard.get()) == SQLITE_ROW) ids.push_back(sqlite3_column_int64(guard.get(), 0));
  }
  for (auto id : ids) {
    try { finishDeletion(id); }
    catch (...) { LOG_ERROR << "Account deletion needs retry for user " << id; }
  }
}

void UserService::cleanupExpiredResetCodes() {
  try {
    auto guard = db_.getStatement("DELETE FROM password_resets WHERE expires_at <= ? OR used_at IS NOT NULL");
    sqlite3_bind_int64(guard.get(), 1, utils::nowSeconds());
    sqlite3_step(guard.get());
  } catch (...) {}
}

bool UserService::requestPasswordReset(const std::string &username, std::string &codeOut, bool forceNew) {
  cleanupExpiredResetCodes();
  auto userGuard = db_.getStatement("SELECT id FROM users WHERE username = ? AND status IN ('active', 'blocked')");
  sqlite3_bind_text(userGuard.get(), 1, username.c_str(), -1, SQLITE_TRANSIENT);
  if (sqlite3_step(userGuard.get()) != SQLITE_ROW) return false;
  const auto userId = sqlite3_column_int64(userGuard.get(), 0);

  if (!forceNew) {
    auto activeGuard = db_.getStatement(
        "SELECT raw_code FROM password_resets "
        "WHERE user_id = ? AND used_at IS NULL AND expires_at > ? AND attempts < 5 AND raw_code != '' "
        "ORDER BY id DESC LIMIT 1");
    sqlite3_bind_int64(activeGuard.get(), 1, userId);
    sqlite3_bind_int64(activeGuard.get(), 2, utils::nowSeconds());
    if (sqlite3_step(activeGuard.get()) == SQLITE_ROW) {
      codeOut = reinterpret_cast<const char *>(sqlite3_column_text(activeGuard.get(), 0));
      return true;
    }
  }

  std::uint32_t randomValue;
  constexpr auto limit = std::numeric_limits<std::uint32_t>::max() -
                         (std::numeric_limits<std::uint32_t>::max() % 900000);
  do {
    if (RAND_bytes(reinterpret_cast<unsigned char *>(&randomValue), sizeof(randomValue)) != 1)
      throw std::runtime_error("Cannot generate recovery code");
  } while (randomValue >= limit);
  codeOut = std::to_string(100000 + randomValue % 900000);
  const auto digest = utils::hmacSha256Hex(config_.jwtSecret, std::to_string(userId) + "|" + codeOut);
  {
    auto guard = db_.getStatement("DELETE FROM password_resets WHERE user_id = ?");
    sqlite3_bind_int64(guard.get(), 1, userId);
    if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot replace recovery code");
  }
  auto guard = db_.getStatement("INSERT INTO password_resets(user_id, code, expires_at, created_at, attempts, raw_code) VALUES(?, ?, ?, ?, 0, ?)");
  sqlite3_bind_int64(guard.get(), 1, userId);
  sqlite3_bind_text(guard.get(), 2, digest.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(guard.get(), 3, utils::nowSeconds() + 600);
  sqlite3_bind_int64(guard.get(), 4, utils::nowSeconds());
  sqlite3_bind_text(guard.get(), 5, codeOut.c_str(), -1, SQLITE_TRANSIENT);
  if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot store recovery code");
  return true;
}

bool UserService::adminResetPassword(std::int64_t actorId, std::int64_t userId, std::string &code, std::string &error) {
  db::Database::TransactionGuard transaction(db_);
  const auto actor = getUserById(actorId);
  const auto user = getUserById(userId);
  if (!actor || (actor->role != "admin" && actor->role != "superuser") || actor->status != "active" || actor->passwordResetRequired) {
    error = "forbidden"; return false;
  }
  if (!user || (user->status != "active" && user->status != "blocked")) { error = "user_not_found"; return false; }
  if (user->role == "superuser" && actorId != userId) { error = "cannot_modify_superuser"; return false; }
  if (user->role == "admin" && actor->role != "superuser") { error = "forbidden"; return false; }
  if (isLastActiveAdmin(userId)) { error = "last_admin"; return false; }
  if (!requestPasswordReset(user->username, code, true)) { error = "user_not_found"; return false; }
  {
    auto guard = db_.getStatement("UPDATE users SET password_reset_required = 1, auth_version = auth_version + 1 WHERE id = ?");
    sqlite3_bind_int64(guard.get(), 1, userId);
    if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot require recovery");
  }
  revokeAllRefreshTokens(userId);
  audit(actorId, "user.password_reset", userId);
  LOG_INFO << "\n========================================\n"
           << "ADMIN GENERATED PASSWORD RESET FOR: " << user->username << "\n"
           << "TEMPORARY CODE: " << code << " (Valid for 10 minutes)\n"
           << "========================================\n";
  transaction.commit();
  return true;
}

std::vector<ResetCodeRecord> UserService::listResetCodes(std::int64_t actorId) {
  cleanupExpiredResetCodes();
  const auto actor = getUserById(actorId);
  if (!actor || (actor->role != "admin" && actor->role != "superuser") || actor->status != "active" || actor->passwordResetRequired) {
    return {};
  }
  std::vector<ResetCodeRecord> result;
  std::string sql;
  if (actor->role == "superuser") {
    sql = "SELECT r.id, r.user_id, u.username, u.role, r.raw_code, r.created_at, r.expires_at "
          "FROM password_resets r JOIN users u ON u.id = r.user_id "
          "WHERE r.used_at IS NULL AND r.expires_at > ? AND r.attempts < 5 AND r.raw_code != '' "
          "ORDER BY r.created_at DESC, r.id DESC";
  } else {
    sql = "SELECT r.id, r.user_id, u.username, u.role, r.raw_code, r.created_at, r.expires_at "
          "FROM password_resets r JOIN users u ON u.id = r.user_id "
          "WHERE u.role NOT IN ('admin', 'superuser') AND r.used_at IS NULL AND r.expires_at > ? AND r.attempts < 5 AND r.raw_code != '' "
          "ORDER BY r.created_at DESC, r.id DESC";
  }
  auto guard = db_.getStatement(sql);
  sqlite3_bind_int64(guard.get(), 1, utils::nowSeconds());
  while (sqlite3_step(guard.get()) == SQLITE_ROW) {
    ResetCodeRecord rec;
    rec.id = sqlite3_column_int64(guard.get(), 0);
    rec.userId = sqlite3_column_int64(guard.get(), 1);
    rec.username = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 2));
    rec.role = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 3));
    rec.code = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 4));
    rec.createdAt = sqlite3_column_int64(guard.get(), 5);
    rec.expiresAt = sqlite3_column_int64(guard.get(), 6);
    result.push_back(std::move(rec));
  }
  return result;
}

bool UserService::deleteResetCode(std::int64_t actorId, std::int64_t resetId, std::string &error) {
  const auto actor = getUserById(actorId);
  if (!actor || (actor->role != "admin" && actor->role != "superuser") || actor->status != "active" || actor->passwordResetRequired) {
    error = "forbidden"; return false;
  }
  std::int64_t targetUserId = 0;
  std::string targetRole;
  {
    auto guard = db_.getStatement("SELECT r.user_id, u.role FROM password_resets r JOIN users u ON u.id = r.user_id WHERE r.id = ?");
    sqlite3_bind_int64(guard.get(), 1, resetId);
    if (sqlite3_step(guard.get()) != SQLITE_ROW) {
      error = "code_not_found";
      return false;
    }
    targetUserId = sqlite3_column_int64(guard.get(), 0);
    targetRole = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 1));
  }
  if (actor->role != "superuser" && (targetRole == "admin" || targetRole == "superuser")) {
    error = "forbidden";
    return false;
  }
  {
    auto guard = db_.getStatement("DELETE FROM password_resets WHERE id = ?");
    sqlite3_bind_int64(guard.get(), 1, resetId);
    if (sqlite3_step(guard.get()) != SQLITE_DONE) {
      error = "delete_failed";
      return false;
    }
  }
  audit(actorId, "reset_code.delete", targetUserId);
  return true;
}

bool UserService::verifyPasswordReset(const std::string &username, const std::string &code, const std::string &newPassword) {
  if (newPassword.empty() || newPassword.size() > 4096) return false;
  cleanupExpiredResetCodes();
  db::Database::TransactionGuard transaction(db_);
  std::int64_t userId, resetId;
  std::string stored;
  {
    auto guard = db_.getStatement("SELECT u.id, r.id, r.code FROM users u JOIN password_resets r ON r.user_id = u.id "
        "WHERE u.username = ? AND u.status IN ('active', 'blocked') AND r.expires_at > ? "
        "AND r.used_at IS NULL AND r.attempts < 5 ORDER BY r.id DESC LIMIT 1");
    sqlite3_bind_text(guard.get(), 1, username.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(guard.get(), 2, utils::nowSeconds());
    if (sqlite3_step(guard.get()) != SQLITE_ROW) return false;
    userId = sqlite3_column_int64(guard.get(), 0);
    resetId = sqlite3_column_int64(guard.get(), 1);
    stored = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 2));
  }
  const auto digest = utils::hmacSha256Hex(config_.jwtSecret, std::to_string(userId) + "|" + code);
  const bool valid = digest.size() == stored.size() && CRYPTO_memcmp(digest.data(), stored.data(), digest.size()) == 0;
  {
    auto guard = db_.getStatement(valid ? "UPDATE password_resets SET used_at = ? WHERE id = ?" :
                                        "UPDATE password_resets SET attempts = attempts + 1 WHERE id = ? AND ? > 0");
    sqlite3_bind_int64(guard.get(), 1, valid ? utils::nowSeconds() : resetId);
    sqlite3_bind_int64(guard.get(), 2, valid ? resetId : 1);
    if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot update recovery attempt");
  }
  if (valid) {
    const auto hash = passwordHash(newPassword);
    auto guard = db_.getStatement("UPDATE users SET password_hash = ?, password_reset_required = 0, auth_version = auth_version + 1 WHERE id = ?");
    sqlite3_bind_text(guard.get(), 1, hash.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(guard.get(), 2, userId);
    if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("Cannot reset password");
    revokeAllRefreshTokens(userId);
  }
  transaction.commit();
  return valid;
}

}  // namespace server::services
