#include "server/controllers/AuthController.hpp"

#include "server/AppContext.hpp"

#include <drogon/drogon.h>

namespace server::controllers {
namespace {
drogon::HttpResponsePtr jsonError(drogon::HttpStatusCode code, const std::string &msg) {
  Json::Value body;
  body["error"] = msg;
  auto resp = drogon::HttpResponse::newHttpJsonResponse(body);
  resp->setStatusCode(code);
  return resp;
}

std::string requestIp(const drogon::HttpRequestPtr &req) {
  return req->peerAddr().toIp();
}
}  // namespace

void AuthController::registerUser(const drogon::HttpRequestPtr &req,
                                  std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  auto &app = server::ctx();
  if (!app.authRateLimiter->allow(requestIp(req))) {
    callback(jsonError(drogon::k429TooManyRequests, "Rate limit exceeded"));
    return;
  }

  const auto json = req->getJsonObject();
  if (!json || !json->isMember("username") || !json->isMember("password")) {
    callback(jsonError(drogon::k400BadRequest, "username and password are required"));
    return;
  }

  std::string error;
  auto user = app.userService->registerUser(
      (*json)["username"].asString(),
      (*json)["password"].asString(),
      error);
  if (!user.has_value()) {
    callback(jsonError(drogon::k409Conflict, error));
    return;
  }

  const auto tokens = app.userService->issueTokens(*user);
  Json::Value body;
  body["access_token"] = tokens.accessToken;
  body["refresh_token"] = tokens.refreshToken;
  body["token_type"] = "Bearer";
  body["expires_in"] = static_cast<Json::Int64>(app.config.accessTokenTtlSeconds);
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::login(const drogon::HttpRequestPtr &req,
                           std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  auto &app = server::ctx();
  if (!app.authRateLimiter->allow(requestIp(req))) {
    callback(jsonError(drogon::k429TooManyRequests, "Rate limit exceeded"));
    return;
  }

  const auto json = req->getJsonObject();
  if (!json || !json->isMember("username") || !json->isMember("password")) {
    callback(jsonError(drogon::k400BadRequest, "username and password are required"));
    return;
  }

  auto user = app.userService->authenticate((*json)["username"].asString(), (*json)["password"].asString());
  if (!user.has_value()) {
    callback(jsonError(drogon::k401Unauthorized, "Invalid credentials"));
    return;
  }

  const auto tokens = app.userService->issueTokens(*user);
  Json::Value body;
  body["access_token"] = tokens.accessToken;
  body["refresh_token"] = tokens.refreshToken;
  body["token_type"] = "Bearer";
  body["expires_in"] = static_cast<Json::Int64>(app.config.accessTokenTtlSeconds);
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::refresh(const drogon::HttpRequestPtr &req,
                             std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
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
  if (!req->attributes()->find("user_id")) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }
  const auto json = req->getJsonObject();
  if (!json || !json->isMember("new_password")) {
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
  if (!req->attributes()->find("user_id")) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }
  const auto userId = req->attributes()->get<std::int64_t>("user_id");
  const auto ok = server::ctx().userService->deleteAccount(userId);
  if (!ok) {
    callback(jsonError(drogon::k404NotFound, "User not found"));
    return;
  }

  Json::Value body;
  body["ok"] = true;
  body["message"] = "Account deleted; all sessions revoked.";
  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void AuthController::requestReset(const drogon::HttpRequestPtr &req,
                                  std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  const auto json = req->getJsonObject();
  if (!json || !json->isMember("username")) {
    callback(jsonError(drogon::k400BadRequest, "username is required"));
    return;
  }

  const auto username = (*json)["username"].asString();
  std::string code;
  const auto ok = server::ctx().userService->requestPasswordReset(username, code);

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
  const auto json = req->getJsonObject();
  if (!json || !json->isMember("username") || !json->isMember("code") || !json->isMember("new_password")) {
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

}  // namespace server::controllers
