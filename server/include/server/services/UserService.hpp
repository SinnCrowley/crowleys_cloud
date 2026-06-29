#pragma once

#include "server/db/Database.hpp"
#include "server/utils/Config.hpp"

#include <optional>
#include <string>

namespace server::services {

struct UserRecord {
  std::int64_t id;
  std::string username;
  std::string role;
};

struct AuthTokens {
  std::string accessToken;
  std::string refreshToken;
};

struct AccessClaims {
  std::int64_t userId;
  std::string role;
};

class UserService {
 public:
  UserService(db::Database &db, const utils::Config &config);

  std::optional<UserRecord> registerUser(const std::string &username,
                                         const std::string &password,
                                         std::string &error);
  std::optional<UserRecord> authenticate(const std::string &username,
                                         const std::string &password);

  bool requestPasswordReset(const std::string &username, std::string &codeOut);
  bool verifyPasswordReset(const std::string &username, const std::string &code, const std::string &newPassword);

  AuthTokens issueTokens(const UserRecord &user);
  std::optional<AuthTokens> refreshAccessToken(const std::string &refreshToken);
  bool logout(const std::string &refreshToken);
  std::optional<AccessClaims> verifyAccessToken(const std::string &accessToken) const;

  void revokeAllRefreshTokens(std::int64_t userId);
  std::optional<UserRecord> getUserById(std::int64_t userId);
  bool changePassword(std::int64_t userId, const std::string &newPassword);
  bool deleteAccount(std::int64_t userId);

 private:
  db::Database &db_;
  const utils::Config &config_;

  std::string passwordHash(const std::string &password) const;
  bool verifyPassword(const std::string &password, const std::string &storedHash) const;
  std::string makeAccessToken(const UserRecord &user) const;
  std::string makeRefreshToken() const;
};

}  // namespace server::services
