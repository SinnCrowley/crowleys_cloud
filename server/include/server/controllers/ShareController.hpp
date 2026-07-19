#pragma once

#include <drogon/HttpController.h>

namespace server::controllers {

class ShareController : public drogon::HttpController<ShareController> {
 public:
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(ShareController::createShare, "/api/share", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(ShareController::getShareInfo, "/api/public/share/{1}/info", drogon::Get);
  ADD_METHOD_TO(ShareController::sharePage, "/s/{1}", drogon::Get);
  ADD_METHOD_TO(ShareController::rawFile, "/s/{1}/raw", drogon::Get);
  ADD_METHOD_TO(ShareController::downloadZip, "/s/{1}/zip", drogon::Get);
  ADD_METHOD_TO(ShareController::publicAsset, "/public/{1}", drogon::Get);
  METHOD_LIST_END

  void createShare(const drogon::HttpRequestPtr &req,
                   std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void getShareInfo(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                    const std::string &token);
  void sharePage(const drogon::HttpRequestPtr &req,
                 std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                 const std::string &token);
  void rawFile(const drogon::HttpRequestPtr &req,
               std::function<void(const drogon::HttpResponsePtr &)> &&callback,
               const std::string &token);
  void downloadZip(const drogon::HttpRequestPtr &req,
               std::function<void(const drogon::HttpResponsePtr &)> &&callback,
               const std::string &token);
  void publicAsset(const drogon::HttpRequestPtr &req,
                   std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                   const std::string &filename);
};

}  // namespace server::controllers
