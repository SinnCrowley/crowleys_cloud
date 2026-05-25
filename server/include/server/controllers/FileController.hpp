#pragma once

#include <drogon/HttpController.h>

namespace server::controllers {

class FileController : public drogon::HttpController<FileController> {
 public:
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(FileController::listDir, "/api/dir", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::thumbnail, "/api/thumb", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::downloadFile, "/api/files", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::uploadFile, "/api/files", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::createFolder, "/api/folders", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::deleteFile, "/api/files", drogon::Delete, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::rebuildIndex, "/api/index/rebuild", drogon::Post, "server::middleware::JwtMiddleware");
  METHOD_LIST_END

  void listDir(const drogon::HttpRequestPtr &req,
               std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void thumbnail(const drogon::HttpRequestPtr &req,
                 std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void downloadFile(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void uploadFile(const drogon::HttpRequestPtr &req,
                  std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void createFolder(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void deleteFile(const drogon::HttpRequestPtr &req,
                  std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void rebuildIndex(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
};

}  // namespace server::controllers
