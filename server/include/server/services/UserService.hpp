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

#include "server/db/Database.hpp"
#include "server/utils/Config.hpp"

#include <optional>
#include <string>
#include <vector>
#include <json/json.h>

namespace server::services {

struct UserRecord {
  std::int64_t id;
  std::string username;
  std::string role;
  std::string status{"active"};
  std::optional<std::int64_t> quotaBytes;
  std::int64_t createdAt{0};
  bool passwordResetRequired{false};
};

struct AuthTokens {
  std::string accessToken;
  std::string refreshToken;
};

struct AccessClaims {
  std::int64_t userId;
  std::string role;
};

struct ResetCodeRecord {
  std::int64_t id{0};
  std::int64_t userId{0};
  std::string username;
  std::string role;
  std::string code;
  std::int64_t createdAt{0};
  std::int64_t expiresAt{0};
};

class UserService {
 public:
  UserService(db::Database &db, const utils::Config &config);

  std::optional<UserRecord> registerUser(const std::string &username,
                                         const std::string &password,
                                         std::string &error);
  std::optional<UserRecord> authenticate(const std::string &username,
                                         const std::string &password);

  bool verifyPasswordReset(const std::string &username, const std::string &code, const std::string &newPassword);
  bool requestPasswordReset(const std::string &username, std::string &codeOut, bool forceNew = false);
  std::vector<ResetCodeRecord> listResetCodes(std::int64_t actorId);
  bool deleteResetCode(std::int64_t actorId, std::int64_t resetId, std::string &error);
  void cleanupExpiredResetCodes();

  AuthTokens issueTokens(const UserRecord &user);
  std::optional<AuthTokens> refreshAccessToken(const std::string &refreshToken);
  bool logout(const std::string &refreshToken);
  std::optional<AccessClaims> verifyAccessToken(const std::string &accessToken) const;
  std::string makeSyncToken(std::int64_t userId) const;

  void revokeAllRefreshTokens(std::int64_t userId);
  std::optional<UserRecord> getUserById(std::int64_t userId) const;
  std::vector<UserRecord> listUsers(bool pending) const;
  bool updateUser(std::int64_t actorId, std::int64_t userId, const Json::Value &patch, std::string &error);
  bool decideApplication(std::int64_t actorId, std::int64_t userId, bool approve, std::string &error);
  bool adminResetPassword(std::int64_t actorId, std::int64_t userId, std::string &code, std::string &error);
  void revokeSessions(std::int64_t userId);
  void audit(std::int64_t actorId, const std::string &action, std::int64_t targetId);
  bool isLastActiveAdmin(std::int64_t userId) const;
  bool changePassword(std::int64_t userId, const std::string &newPassword);
  bool deleteAccount(std::int64_t userId);
  bool deleteUser(std::int64_t actorId, std::int64_t userId, std::string &error);
  void resumeDeletions();
  void finishDeletion(std::int64_t userId);

 private:
  db::Database &db_;
  const utils::Config &config_;

  std::string passwordHash(const std::string &password) const;
  bool verifyPassword(const std::string &password, const std::string &storedHash) const;
  std::string makeAccessToken(const UserRecord &user) const;
  std::string makeRefreshToken() const;
  std::string tokenSigningKey(std::int64_t userId) const;
};

}  // namespace server::services
