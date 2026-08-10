#pragma once

#include <drogon/HttpController.h>

namespace server::controllers {

class FileController : public drogon::HttpController<FileController> {
 public:
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(FileController::listDir, "/api/dir", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::thumbnail, "/api/thumb", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::downloadFile, "/api/files", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::downloadFile, "/api/files", drogon::Head, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::uploadFile, "/api/files", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::shareFile, "/api/files/share", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::checkHashes, "/api/files/check-hashes", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::createFolder, "/api/folders", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::moveFile, "/api/files/move", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::deleteFile, "/api/files", drogon::Delete, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::rebuildIndex, "/api/index/rebuild", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::getTrash, "/api/trash", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::restoreTrash, "/api/trash/restore", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::deleteTrash, "/api/trash", drogon::Delete, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::getTrashSettings, "/api/account/settings/trash", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::setTrashSettings, "/api/account/settings/trash", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::uploadStatus, "/api/files/upload-status", drogon::Get, "server::middleware::JwtMiddleware");
  METHOD_LIST_END

  void listDir(const drogon::HttpRequestPtr &req,
               std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void thumbnail(const drogon::HttpRequestPtr &req,
                 std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void downloadFile(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void uploadFile(const drogon::HttpRequestPtr &req,
                  std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void shareFile(const drogon::HttpRequestPtr &req,
                 std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void checkHashes(const drogon::HttpRequestPtr &req,
                   std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void createFolder(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void moveFile(const drogon::HttpRequestPtr &req,
                std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void deleteFile(const drogon::HttpRequestPtr &req,
                  std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void rebuildIndex(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void getTrash(const drogon::HttpRequestPtr &req,
                std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void restoreTrash(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void deleteTrash(const drogon::HttpRequestPtr &req,
                   std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void getTrashSettings(const drogon::HttpRequestPtr &req,
                        std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void setTrashSettings(const drogon::HttpRequestPtr &req,
                        std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void uploadStatus(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
};

}  // namespace server::controllers
