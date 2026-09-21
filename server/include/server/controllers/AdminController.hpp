// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later
#pragma once

#include <drogon/HttpController.h>

namespace server::controllers {
class AdminController : public drogon::HttpController<AdminController> {
 public:
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(AdminController::users, "/api/admin/users", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::applications, "/api/admin/applications", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::updateUser, "/api/admin/users/{1}", drogon::Patch, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::userAction, "/api/admin/users/{1}/{2}", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::deleteUser, "/api/admin/users/{1}", drogon::Delete, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::configuration, "/api/admin/config", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::saveConfiguration, "/api/admin/config", drogon::Patch, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::rotateSigningSecret, "/api/admin/signing-secret", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::maintenance, "/api/admin/maintenance", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::rotateEncryption, "/api/admin/encryption-key", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::resumeEncryption, "/api/admin/encryption-key/resume", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::resetCodes, "/api/admin/reset-codes", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AdminController::deleteResetCode, "/api/admin/reset-codes/{1}", drogon::Delete, "server::middleware::JwtMiddleware");
  METHOD_LIST_END

  void resetCodes(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&);
  void deleteResetCode(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&, std::int64_t id);
  void maintenance(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&);
  void rotateEncryption(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&);
  void resumeEncryption(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&);
  void configuration(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&);
  void saveConfiguration(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&);
  void rotateSigningSecret(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&);
  void users(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&);
  void applications(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&);
  void deleteUser(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&, std::int64_t id);
  void updateUser(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&, std::int64_t id);
  void userAction(const drogon::HttpRequestPtr &, std::function<void(const drogon::HttpResponsePtr &)> &&, std::int64_t id, const std::string &action);
};
}
