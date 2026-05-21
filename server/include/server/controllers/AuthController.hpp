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
};

}  // namespace server::controllers
