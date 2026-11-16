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

#include "server/controllers/AuthController.hpp"

#include "server/AppContext.hpp"
#include "server/utils/Crypto.hpp"
#include "server/utils/HttpHelpers.hpp"
#include "server/utils/TimeUtils.hpp"

#include <drogon/drogon.h>
#include <openssl/crypto.h>

namespace server::controllers {
using server::utils::jsonError;
using server::utils::jsonOk;
using server::utils::getAuthUserId;

namespace {
std::string requestIp(const drogon::HttpRequestPtr &req) {
  return req->peerAddr().toIp();
}

std::mutex consumedNoncesMutex;
std::unordered_map<std::string, std::int64_t> consumedNonces;

void cleanupExpiredNonces() {
  const auto now = server::utils::nowSeconds();
  for (auto it = consumedNonces.begin(); it != consumedNonces.end();) {
    if (now - it->second > 150) {
      it = consumedNonces.erase(it);
    } else {
      ++it;
    }
  }
}
}  // namespace

void AuthController::authChallenge(const drogon::HttpRequestPtr &req,
                                   std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  auto &app = server::ctx();
  if (!app.authRateLimiter->allow(requestIp(req))) {
    callback(jsonError(drogon::k429TooManyRequests, "Rate limit exceeded"));
    return;
  }

  std::string username = req->getParameter("username");
  std::string clientNonce = req->getParameter("nonce");
  if (clientNonce.empty()) clientNonce = req->getParameter("client_nonce");

  const auto json = req->getJsonObject();
  if (username.empty() && json && (*json)["username"].isString()) {
    username = (*json)["username"].asString();
  }
  if (clientNonce.empty() && json && (*json)["nonce"].isString()) {
    clientNonce = (*json)["nonce"].asString();
  }
  if (clientNonce.empty() && json && (*json)["client_nonce"].isString()) {
    clientNonce = (*json)["client_nonce"].asString();
  }

  if (username.empty()) {
    callback(jsonError(drogon::k400BadRequest, "username is required"));
    return;
  }

  if (clientNonce.empty()) {
    clientNonce = server::utils::randomTokenHex(16);
  }

  auto cred = app.userService->getScramCredentials(username);
  if (cred.has_value()) {
    if (cred->kdf == "argon2id") {
      const auto serverNonce = server::utils::randomTokenHex(16);
      const auto nonce = clientNonce + "_" + serverNonce;
      const auto expiresAt = server::utils::nowSeconds() + 120;
      const auto sigMaterial = username + "|" + nonce + "|" + cred->saltHex + "|argon2id|" + std::to_string(cred->memCostKb) + "|" + std::to_string(cred->timeCost) + "|" + std::to_string(cred->lanes) + "|" + std::to_string(expiresAt);
      const auto challengeToken = server::utils::hmacSha256Hex(app.config.jwtSecret, sigMaterial) + "." + std::to_string(expiresAt);

      Json::Value body;
      body["ok"] = true;
      body["auth_mode"] = "scram-argon2id";
      body["salt"] = cred->saltHex;
      body["m"] = cred->memCostKb;
      body["t"] = cred->timeCost;
      body["p"] = cred->lanes;
      body["nonce"] = nonce;
      body["challenge_token"] = challengeToken;
      callback(drogon::HttpResponse::newHttpJsonResponse(body));
      return;
    } else if (cred->iterations > 0) {
      const auto serverNonce = server::utils::randomTokenHex(16);
      const auto nonce = clientNonce + "_" + serverNonce;
      const auto expiresAt = server::utils::nowSeconds() + 120;
      const auto sigMaterial = username + "|" + nonce + "|" + cred->saltHex + "|" + std::to_string(cred->iterations) + "|" + std::to_string(expiresAt);
      const auto challengeToken = server::utils::hmacSha256Hex(app.config.jwtSecret, sigMaterial) + "." + std::to_string(expiresAt);

      Json::Value body;
      body["ok"] = true;
      body["auth_mode"] = "scram";
      body["salt"] = cred->saltHex;
      body["iterations"] = cred->iterations;
      body["nonce"] = nonce;
      body["challenge_token"] = challengeToken;
      callback(drogon::HttpResponse::newHttpJsonResponse(body));
      return;
    } else {
      Json::Value body;
      body["ok"] = true;
      body["auth_mode"] = "legacy";
      callback(drogon::HttpResponse::newHttpJsonResponse(body));
      return;
    }
  }

  // Non-existent user: Return deterministic dummy challenge to prevent user enumeration
  const auto dummySalt = server::utils::hmacSha256Hex(app.config.jwtSecret, "dummy_salt:" + username).substr(0, 32);
  const auto serverNonce = server::utils::randomTokenHex(16);
  const auto nonce = clientNonce + "_" + serverNonce;
  const auto expiresAt = server::utils::nowSeconds() + 120;
  const auto dummyToken = "dummy." + std::to_string(expiresAt);

  Json::Value body;
  body["ok"] = true;
  body["auth_mode"] = "scram-argon2id";
  body["salt"] = dummySalt;
  body["m"] = 19456;
  body["t"] = 2;
  body["p"] = 1;
  body["nonce"] = nonce;
  body["challenge_token"] = dummyToken;
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::registerUser(const drogon::HttpRequestPtr &req,
                                  std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  auto &app = server::ctx();
  if (!app.authRateLimiter->allow(requestIp(req))) {
    callback(jsonError(drogon::k429TooManyRequests, "Rate limit exceeded"));
    return;
  }

  const auto json = req->getJsonObject();
  if (!json || !(*json)["username"].isString()) {
    callback(jsonError(drogon::k400BadRequest, "username is required"));
    return;
  }

  const auto username = (*json)["username"].asString();

  // 1. SCRAM Registration mode:
  if (json->isMember("salt") && json->isMember("stored_key") && json->isMember("server_key") && (json->isMember("iterations") || json->isMember("m") || json->isMember("kdf"))) {
    if (!(*json)["salt"].isString() || !(*json)["stored_key"].isString() || !(*json)["server_key"].isString()) {
      callback(jsonError(drogon::k400BadRequest, "Invalid SCRAM registration parameters"));
      return;
    }
    const auto salt = (*json)["salt"].asString();
    const auto storedKey = (*json)["stored_key"].asString();
    const auto serverKey = (*json)["server_key"].asString();

    if (salt.empty() || storedKey.empty() || serverKey.empty()) {
      callback(jsonError(drogon::k400BadRequest, "Invalid SCRAM registration parameters"));
      return;
    }

    std::string scramHash;
    if (json->isMember("m") || (json->isMember("kdf") && (*json)["kdf"].asString() == "argon2id") || !json->isMember("iterations")) {
      uint32_t memCostKb = json->isMember("m") && (*json)["m"].isIntegral() ? (*json)["m"].asUInt() : 19456;
      uint32_t timeCost = json->isMember("t") && (*json)["t"].isIntegral() ? (*json)["t"].asUInt() : 2;
      uint32_t lanes = json->isMember("p") && (*json)["p"].isIntegral() ? (*json)["p"].asUInt() : 1;
      scramHash = "$scram-argon2id$m=" + std::to_string(memCostKb) + ",t=" + std::to_string(timeCost) + ",p=" + std::to_string(lanes) + "$" + salt + "$" + storedKey + "$" + serverKey;
    } else {
      const auto iterations = (*json)["iterations"].asUInt();
      if (iterations == 0) {
        callback(jsonError(drogon::k400BadRequest, "Invalid SCRAM registration parameters"));
        return;
      }
      scramHash = "$scram-sha-256$" + std::to_string(iterations) + "$" + salt + "$" + storedKey + "$" + serverKey;
    }

    std::string error;
    auto user = app.userService->registerUserWithScram(username, scramHash, error);
    if (!user.has_value()) {
      callback(jsonError(error == "registration_closed" ? drogon::k403Forbidden :
                         error == "invalid_credentials" ? drogon::k400BadRequest : drogon::k409Conflict, error, error));
      return;
    }

    if (user->status == "pending") {
      Json::Value body;
      body["status"] = "pending";
      body["code"] = "registration_pending";
      auto response = drogon::HttpResponse::newHttpJsonResponse(body);
      response->setStatusCode(drogon::k202Accepted);
      callback(response);
      return;
    }

    const auto tokens = app.userService->issueTokens(*user);
    Json::Value body;
    body["access_token"] = tokens.accessToken;
    body["refresh_token"] = tokens.refreshToken;
    body["user"]["id"] = Json::Int64(user->id);
    body["user"]["username"] = user->username;
    body["user"]["role"] = user->role;
    body["user"]["status"] = user->status;
    body["token_type"] = "Bearer";
    body["expires_in"] = static_cast<Json::Int64>(app.config.accessTokenTtlSeconds);
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
    return;
  }

  // 2. Legacy Registration mode:
  if (!(*json)["password"].isString()) {
    callback(jsonError(drogon::k400BadRequest, "username and password are required"));
    return;
  }

  std::string error;
  auto user = app.userService->registerUser(
      username,
      (*json)["password"].asString(),
      error);
  if (!user.has_value()) {
    callback(jsonError(error == "registration_closed" ? drogon::k403Forbidden :
                       error == "invalid_credentials" ? drogon::k400BadRequest : drogon::k409Conflict, error, error));
    return;
  }

  if (user->status == "pending") {
    Json::Value body;
    body["status"] = "pending";
    body["code"] = "registration_pending";
    auto response = drogon::HttpResponse::newHttpJsonResponse(body);
    response->setStatusCode(drogon::k202Accepted);
    callback(response);
    return;
  }

  const auto tokens = app.userService->issueTokens(*user);
  Json::Value body;
  body["access_token"] = tokens.accessToken;
  body["refresh_token"] = tokens.refreshToken;
  body["user"]["id"] = Json::Int64(user->id);
  body["user"]["username"] = user->username;
  body["user"]["role"] = user->role;
  body["user"]["status"] = user->status;
  body["token_type"] = "Bearer";
  body["expires_in"] = static_cast<Json::Int64>(app.config.accessTokenTtlSeconds);
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::login(const drogon::HttpRequestPtr &req,
                           std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  auto &app = server::ctx();
  if (!app.authRateLimiter->allow(requestIp(req))) {
    callback(jsonError(drogon::k429TooManyRequests, "Rate limit exceeded"));
    return;
  }

  const auto json = req->getJsonObject();
  if (!json || !(*json)["username"].isString()) {
    callback(jsonError(drogon::k400BadRequest, "username is required"));
    return;
  }

  const auto username = (*json)["username"].asString();

  // 1. SCRAM Challenge-Response Login mode:
  if (json->isMember("client_proof") && json->isMember("nonce") && json->isMember("challenge_token")) {
    const auto nonce = (*json)["nonce"].asString();
    const auto clientProof = (*json)["client_proof"].asString();
    const auto challengeToken = (*json)["challenge_token"].asString();

    if (nonce.empty() || clientProof.empty() || challengeToken.empty()) {
      callback(jsonError(drogon::k400BadRequest, "Invalid challenge parameters"));
      return;
    }

    // Replay attack prevention:
    {
      std::lock_guard<std::mutex> lock(consumedNoncesMutex);
      cleanupExpiredNonces();
      if (consumedNonces.count(nonce)) {
        callback(jsonError(drogon::k401Unauthorized, "Nonce already consumed"));
        return;
      }
      consumedNonces[nonce] = server::utils::nowSeconds();
    }

    auto dotPos = challengeToken.find('.');
    if (dotPos == std::string::npos) {
      callback(jsonError(drogon::k401Unauthorized, "Invalid challenge token"));
      return;
    }
    const auto sig = challengeToken.substr(0, dotPos);
    std::int64_t expiresAt = 0;
    try {
      expiresAt = std::stoll(challengeToken.substr(dotPos + 1));
    } catch (...) {
      callback(jsonError(drogon::k401Unauthorized, "Invalid challenge token"));
      return;
    }
    if (server::utils::nowSeconds() > expiresAt) {
      callback(jsonError(drogon::k401Unauthorized, "Challenge token expired"));
      return;
    }

    auto cred = app.userService->getScramCredentials(username);
    if (!cred.has_value() || (cred->kdf.empty() && cred->iterations == 0)) {
      callback(jsonError(drogon::k401Unauthorized, "Invalid credentials"));
      return;
    }

    if (cred->status != "active" || cred->passwordResetRequired) {
      const std::string code = cred->status == "pending" ? "registration_pending" :
                               cred->status == "blocked" ? "account_blocked" : "password_reset_required";
      callback(jsonError(drogon::k403Forbidden, code, code));
      return;
    }

    std::string sigMaterial;
    std::string authMessage;
    if (cred->kdf == "argon2id") {
      sigMaterial = username + "|" + nonce + "|" + cred->saltHex + "|argon2id|" + std::to_string(cred->memCostKb) + "|" + std::to_string(cred->timeCost) + "|" + std::to_string(cred->lanes) + "|" + std::to_string(expiresAt);
      authMessage = server::utils::scramArgon2idAuthMessage(username, nonce, cred->saltHex, cred->memCostKb, cred->timeCost, cred->lanes);
    } else {
      sigMaterial = username + "|" + nonce + "|" + cred->saltHex + "|" + std::to_string(cred->iterations) + "|" + std::to_string(expiresAt);
      authMessage = server::utils::scramAuthMessage(username, nonce, cred->saltHex, cred->iterations);
    }

    const auto expectedSig = server::utils::hmacSha256Hex(app.config.jwtSecret, sigMaterial);
    if (sig.size() != expectedSig.size() || CRYPTO_memcmp(sig.data(), expectedSig.data(), sig.size()) != 0) {
      callback(jsonError(drogon::k401Unauthorized, "Invalid challenge token"));
      return;
    }

    std::string serverSignature;
    if (!server::utils::scramVerifyClientProof(cred->storedKeyHex, authMessage, clientProof, cred->serverKeyHex, serverSignature)) {
      callback(jsonError(drogon::k401Unauthorized, "Invalid credentials"));
      return;
    }

    auto user = app.userService->getUserById(cred->userId);
    if (!user.has_value()) {
      callback(jsonError(drogon::k401Unauthorized, "Invalid credentials"));
      return;
    }

    const auto tokens = app.userService->issueTokens(*user);
    Json::Value body;
    body["access_token"] = tokens.accessToken;
    body["refresh_token"] = tokens.refreshToken;
    body["server_signature"] = serverSignature;
    body["user"]["id"] = Json::Int64(user->id);
    body["user"]["username"] = user->username;
    body["user"]["role"] = user->role;
    body["user"]["status"] = user->status;
    const auto usage = app.quotaService->usage(user->id);
    body["user"]["used_bytes"] = Json::Int64(usage.used);
    body["user"]["reserved_bytes"] = Json::Int64(usage.reserved);
    body["user"]["quota_bytes"] = Json::Int64(usage.limit);
    body["token_type"] = "Bearer";
    body["expires_in"] = static_cast<Json::Int64>(app.config.accessTokenTtlSeconds);
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
    return;
  }

  // 2. Legacy Login mode (plaintext password):
  if (!(*json)["password"].isString()) {
    callback(jsonError(drogon::k400BadRequest, "password or SCRAM proof required"));
    return;
  }

  auto user = app.userService->authenticate(username, (*json)["password"].asString());
  if (!user.has_value()) {
    callback(jsonError(drogon::k401Unauthorized, "Invalid credentials"));
    return;
  }

  if (user->status != "active" || user->passwordResetRequired) {
    const std::string code = user->status == "pending" ? "registration_pending" :
                             user->status == "blocked" ? "account_blocked" : "password_reset_required";
    callback(jsonError(drogon::k403Forbidden, code, code));
    return;
  }

  const auto tokens = app.userService->issueTokens(*user);
  Json::Value body;
  body["access_token"] = tokens.accessToken;
  body["refresh_token"] = tokens.refreshToken;
  body["user"]["id"] = Json::Int64(user->id);
  body["user"]["username"] = user->username;
  body["user"]["role"] = user->role;
  body["user"]["status"] = user->status;
  const auto usage = app.quotaService->usage(user->id);
  body["user"]["used_bytes"] = Json::Int64(usage.used);
  body["user"]["reserved_bytes"] = Json::Int64(usage.reserved);
  body["user"]["quota_bytes"] = Json::Int64(usage.limit);
  body["token_type"] = "Bearer";
  body["expires_in"] = static_cast<Json::Int64>(app.config.accessTokenTtlSeconds);
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::refresh(const drogon::HttpRequestPtr &req,
                             std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  const auto json = req->getJsonObject();
  if (!json || !json->isMember("refresh_token")) {
    callback(jsonError(drogon::k400BadRequest, "refresh_token is required"));
    return;
  }

  auto tokens = server::ctx().userService->refreshAccessToken((*json)["refresh_token"].asString());
  if (!tokens.has_value()) {
    callback(jsonError(drogon::k401Unauthorized, "Invalid refresh token"));
    return;
  }

  Json::Value body;
  body["access_token"] = tokens->accessToken;
  body["refresh_token"] = tokens->refreshToken;
  body["token_type"] = "Bearer";
  body["expires_in"] = static_cast<Json::Int64>(server::ctx().config.accessTokenTtlSeconds);
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::logout(const drogon::HttpRequestPtr &req,
                            std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  const auto json = req->getJsonObject();
  if (!json || !json->isMember("refresh_token")) {
    callback(jsonError(drogon::k400BadRequest, "refresh_token is required"));
    return;
  }

  server::ctx().userService->logout((*json)["refresh_token"].asString());
  Json::Value body;
  body["ok"] = true;
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::changePassword(const drogon::HttpRequestPtr &req,
                                    std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  if (!req->attributes()->find("user_id")) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }
  const auto json = req->getJsonObject();
  if (!json) {
    callback(jsonError(drogon::k400BadRequest, "Request body is required"));
    return;
  }

  const auto userId = req->attributes()->get<std::int64_t>("user_id");

  // SCRAM password update
  if (json->isMember("salt") && json->isMember("stored_key") && json->isMember("server_key") && (json->isMember("iterations") || json->isMember("m") || json->isMember("kdf"))) {
    if (!(*json)["salt"].isString() || !(*json)["stored_key"].isString() || !(*json)["server_key"].isString()) {
      callback(jsonError(drogon::k400BadRequest, "Invalid SCRAM parameters"));
      return;
    }
    const auto salt = (*json)["salt"].asString();
    const auto storedKey = (*json)["stored_key"].asString();
    const auto serverKey = (*json)["server_key"].asString();
    if (salt.empty() || storedKey.empty() || serverKey.empty()) {
      callback(jsonError(drogon::k400BadRequest, "Invalid SCRAM parameters"));
      return;
    }

    std::string scramHash;
    if (json->isMember("m") || (json->isMember("kdf") && (*json)["kdf"].asString() == "argon2id") || !json->isMember("iterations")) {
      uint32_t memCostKb = json->isMember("m") && (*json)["m"].isIntegral() ? (*json)["m"].asUInt() : 19456;
      uint32_t timeCost = json->isMember("t") && (*json)["t"].isIntegral() ? (*json)["t"].asUInt() : 2;
      uint32_t lanes = json->isMember("p") && (*json)["p"].isIntegral() ? (*json)["p"].asUInt() : 1;
      scramHash = "$scram-argon2id$m=" + std::to_string(memCostKb) + ",t=" + std::to_string(timeCost) + ",p=" + std::to_string(lanes) + "$" + salt + "$" + storedKey + "$" + serverKey;
    } else {
      const auto iterations = (*json)["iterations"].asUInt();
      if (iterations == 0) {
        callback(jsonError(drogon::k400BadRequest, "Invalid SCRAM parameters"));
        return;
      }
      scramHash = "$scram-sha-256$" + std::to_string(iterations) + "$" + salt + "$" + storedKey + "$" + serverKey;
    }

    const auto ok = server::ctx().userService->changePasswordWithScram(userId, scramHash);
    if (!ok) {
      callback(jsonError(drogon::k404NotFound, "User not found"));
      return;
    }
    Json::Value body;
    body["ok"] = true;
    body["message"] = "Password updated; all sessions revoked.";
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
    return;
  }

  if (!(*json)["new_password"].isString() || (*json)["new_password"].asString().empty() || (*json)["new_password"].asString().size() > 4096) {
    callback(jsonError(drogon::k400BadRequest, "new_password or SCRAM keys required"));
    return;
  }

  const auto ok = server::ctx().userService->changePassword(userId, (*json)["new_password"].asString());
  if (!ok) {
    callback(jsonError(drogon::k404NotFound, "User not found"));
    return;
  }

  Json::Value body;
  body["ok"] = true;
  body["message"] = "Password updated; all sessions revoked.";
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::deleteAccount(const drogon::HttpRequestPtr &req,
                                   std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  auto activity = server::ctx().storageActivity.enter();
  if (!activity) { callback(server::utils::maintenanceResponse()); return; }
  if (!req->attributes()->find("user_id")) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }
  const auto userId = req->attributes()->get<std::int64_t>("user_id");
  const auto ok = server::ctx().userService->deleteAccount(userId);
  if (!ok) {
    callback(jsonError(drogon::k409Conflict, "Cannot delete this account", "account_deletion_conflict"));
    return;
  }

  Json::Value body;
  body["ok"] = true;
  body["message"] = "Account deleted; all sessions revoked.";
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::requestReset(const drogon::HttpRequestPtr &req,
                                  std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  if (!server::ctx().authRateLimiter->allow("password-reset:" + requestIp(req))) {
    callback(jsonError(drogon::k429TooManyRequests, "Rate limit exceeded"));
    return;
  }
  const auto json = req->getJsonObject();
  if (!json || !json->isMember("username") || !(*json)["username"].isString()) {
    callback(jsonError(drogon::k400BadRequest, "username is required"));
    return;
  }

  const auto username = (*json)["username"].asString();
  if (!server::ctx().authRateLimiter->allow("password-reset-user:" + username)) {
    callback(jsonError(drogon::k429TooManyRequests, "Rate limit exceeded"));
    return;
  }
  std::string code;
  const auto ok = server::ctx().userService->requestPasswordReset(username, code, false);

  if (ok && server::ctx().config.devLogResetCodes) {
    LOG_INFO << "\n========================================\n"
             << "PASSWORD RESET REQUESTED FOR: " << username << "\n"
             << "TEMPORARY CODE: " << code << " (Valid for 10 minutes)\n"
             << "========================================\n";
  }

  Json::Value body;
  body["ok"] = true;
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::verifyReset(const drogon::HttpRequestPtr &req,
                                 std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  if (!server::ctx().authRateLimiter->allow("password-reset:" + requestIp(req))) {
    callback(jsonError(drogon::k429TooManyRequests, "Rate limit exceeded"));
    return;
  }
  const auto json = req->getJsonObject();
  if (!json || !(*json)["username"].isString() || !(*json)["code"].isString()) {
    callback(jsonError(drogon::k400BadRequest, "username and code are required"));
    return;
  }

  const auto username = (*json)["username"].asString();
  if (!server::ctx().authRateLimiter->allow("password-reset-user:" + username)) {
    callback(jsonError(drogon::k429TooManyRequests, "Rate limit exceeded"));
    return;
  }
  const auto code = (*json)["code"].asString();

  if (json->isMember("salt") && json->isMember("stored_key") && json->isMember("server_key") && (json->isMember("iterations") || json->isMember("m") || json->isMember("kdf"))) {
    if (!(*json)["salt"].isString() || !(*json)["stored_key"].isString() || !(*json)["server_key"].isString()) {
      callback(jsonError(drogon::k400BadRequest, "Invalid SCRAM parameters"));
      return;
    }
    const auto salt = (*json)["salt"].asString();
    const auto storedKey = (*json)["stored_key"].asString();
    const auto serverKey = (*json)["server_key"].asString();
    if (salt.empty() || storedKey.empty() || serverKey.empty()) {
      callback(jsonError(drogon::k400BadRequest, "Invalid SCRAM parameters"));
      return;
    }

    std::string scramHash;
    if (json->isMember("m") || (json->isMember("kdf") && (*json)["kdf"].asString() == "argon2id") || !json->isMember("iterations")) {
      uint32_t memCostKb = json->isMember("m") && (*json)["m"].isIntegral() ? (*json)["m"].asUInt() : 19456;
      uint32_t timeCost = json->isMember("t") && (*json)["t"].isIntegral() ? (*json)["t"].asUInt() : 2;
      uint32_t lanes = json->isMember("p") && (*json)["p"].isIntegral() ? (*json)["p"].asUInt() : 1;
      scramHash = "$scram-argon2id$m=" + std::to_string(memCostKb) + ",t=" + std::to_string(timeCost) + ",p=" + std::to_string(lanes) + "$" + salt + "$" + storedKey + "$" + serverKey;
    } else {
      const auto iterations = (*json)["iterations"].asUInt();
      if (iterations == 0) {
        callback(jsonError(drogon::k400BadRequest, "Invalid SCRAM parameters"));
        return;
      }
      scramHash = "$scram-sha-256$" + std::to_string(iterations) + "$" + salt + "$" + storedKey + "$" + serverKey;
    }

    const auto ok = server::ctx().userService->verifyPasswordResetWithScram(username, code, scramHash);
    if (!ok) {
      callback(jsonError(drogon::k400BadRequest, "Invalid or expired recovery code"));
      return;
    }

    Json::Value body;
    body["ok"] = true;
    body["message"] = "Password reset successfully; all active sessions revoked.";
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
    return;
  }

  if (!(*json)["new_password"].isString() || (*json)["new_password"].asString().empty() || (*json)["new_password"].asString().size() > 4096) {
    callback(jsonError(drogon::k400BadRequest, "username, code and new_password (or SCRAM keys) are required"));
    return;
  }

  const auto newPassword = (*json)["new_password"].asString();

  const auto ok = server::ctx().userService->verifyPasswordReset(username, code, newPassword);
  if (!ok) {
    callback(jsonError(drogon::k400BadRequest, "Invalid or expired recovery code"));
    return;
  }

  Json::Value body;
  body["ok"] = true;
  body["message"] = "Password reset successfully; all active sessions revoked.";
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::getSyncToken(const drogon::HttpRequestPtr &req,
                                  std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  if (!req->attributes()->find("user_id")) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }
  const auto role = req->attributes()->get<std::string>("role");
  if (role == "sync") {
    callback(jsonError(drogon::k403Forbidden, "Forbidden for sync role"));
    return;
  }
  const auto userId = req->attributes()->get<std::int64_t>("user_id");
  const auto token = server::ctx().userService->makeSyncToken(userId);

  Json::Value body;
  body["sync_token"] = token;
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::account(const drogon::HttpRequestPtr &req,
                             std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  const auto user = server::ctx().userService->getUserById(*getAuthUserId(req));
  if (!user) { callback(jsonError(drogon::k401Unauthorized, "Unauthorized")); return; }
  Json::Value body;
  const auto usage = server::ctx().quotaService->usage(user->id);
  body["used_bytes"] = Json::Int64(usage.used);
  body["reserved_bytes"] = Json::Int64(usage.reserved);
  body["quota_bytes"] = Json::Int64(usage.limit);
  body["id"] = Json::Int64(user->id);
  body["username"] = user->username;
  body["role"] = user->role;
  body["status"] = user->status;
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

}  // namespace server::controllers
