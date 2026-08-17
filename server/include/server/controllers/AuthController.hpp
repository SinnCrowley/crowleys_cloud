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

#include <drogon/HttpController.h>

namespace server::controllers {

class AuthController : public drogon::HttpController<AuthController> {
 public:
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(AuthController::registerUser, "/api/register", drogon::Post);
  ADD_METHOD_TO(AuthController::login, "/api/login", drogon::Post);
  ADD_METHOD_TO(AuthController::refresh, "/api/refresh", drogon::Post);
  ADD_METHOD_TO(AuthController::logout, "/api/logout", drogon::Post);
  ADD_METHOD_TO(AuthController::changePassword, "/api/account/password", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AuthController::deleteAccount, "/api/account", drogon::Delete, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AuthController::getSyncToken, "/api/account/sync-token", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(AuthController::requestReset, "/api/auth/reset-password/request", drogon::Post);
  ADD_METHOD_TO(AuthController::verifyReset, "/api/auth/reset-password/verify", drogon::Post);
  METHOD_LIST_END

  void registerUser(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void login(const drogon::HttpRequestPtr &req,
             std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void refresh(const drogon::HttpRequestPtr &req,
               std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void logout(const drogon::HttpRequestPtr &req,
              std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void changePassword(const drogon::HttpRequestPtr &req,
                      std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void deleteAccount(const drogon::HttpRequestPtr &req,
                     std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void getSyncToken(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void requestReset(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void verifyReset(const drogon::HttpRequestPtr &req,
                   std::function<void(const drogon::HttpResponsePtr &)> &&callback);
};

}  // namespace server::controllers
