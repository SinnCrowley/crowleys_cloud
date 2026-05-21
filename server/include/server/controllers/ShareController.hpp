#pragma once

#include <drogon/HttpController.h>

namespace server::controllers {

class ShareController : public drogon::HttpController<ShareController> {
 public:
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(ShareController::createShare, "/api/share", drogon::Post, "server::middleware::JwtMiddleware");
  METHOD_ADD(ShareController::publicDownload, "/s/{1}", drogon::Get);
  METHOD_LIST_END

  void createShare(const drogon::HttpRequestPtr &req,
                   std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void publicDownload(const drogon::HttpRequestPtr &req,
                      std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                      const std::string &token);
};

}  // namespace server::controllers
