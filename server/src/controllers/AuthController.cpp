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
#include "server/utils/HttpHelpers.hpp"

#include <drogon/drogon.h>

namespace server::controllers {
using server::utils::jsonError;
using server::utils::jsonOk;
using server::utils::getAuthUserId;

namespace {
std::string requestIp(const drogon::HttpRequestPtr &req) {
  return req->peerAddr().toIp();
}
}  // namespace

void AuthController::registerUser(const drogon::HttpRequestPtr &req,
                                  std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(server::ctx().configMutex);
  auto &app = server::ctx();
  if (!app.authRateLimiter->allow(requestIp(req))) {
    callback(jsonError(drogon::k429TooManyRequests, "Rate limit exceeded"));
    return;
  }

  const auto json = req->getJsonObject();
  if (!json || !(*json)["username"].isString() || !(*json)["password"].isString()) {
    callback(jsonError(drogon::k400BadRequest, "username and password are required"));
    return;
  }

  std::string error;
  auto user = app.userService->registerUser(
      (*json)["username"].asString(),
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
  if (!json || !(*json)["username"].isString() || !(*json)["password"].isString()) {
    callback(jsonError(drogon::k400BadRequest, "username and password are required"));
    return;
  }

  auto user = app.userService->authenticate((*json)["username"].asString(), (*json)["password"].asString());
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
  if (!json || !(*json)["new_password"].isString() || (*json)["new_password"].asString().empty() || (*json)["new_password"].asString().size() > 4096) {
    callback(jsonError(drogon::k400BadRequest, "new_password is required"));
    return;
  }

  const auto userId = req->attributes()->get<std::int64_t>("user_id");
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
  std::string code;
  const auto ok = server::ctx().userService->requestPasswordReset(username, code, false);

  if (ok) {
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
  if (!json || !(*json)["username"].isString() || !(*json)["code"].isString() || !(*json)["new_password"].isString() || (*json)["new_password"].asString().empty() || (*json)["new_password"].asString().size() > 4096) {
    callback(jsonError(drogon::k400BadRequest, "username, code and new_password are required"));
    return;
  }

  const auto username = (*json)["username"].asString();
  const auto code = (*json)["code"].asString();
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
