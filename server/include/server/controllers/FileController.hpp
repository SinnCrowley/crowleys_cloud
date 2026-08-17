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

class FileController : public drogon::HttpController<FileController> {
 public:
  METHOD_LIST_BEGIN
  ADD_METHOD_TO(FileController::listDir, "/api/dir", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::thumbnail, "/api/thumb", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::downloadFile, "/api/files", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::downloadFile, "/api/files", drogon::Head, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::downloadZip, "/api/files/zip", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::uploadFile, "/api/files", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::shareFile, "/api/files/share", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::checkHashes, "/api/files/check-hashes", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::createFolder, "/api/folders", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::moveFile, "/api/files/move", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::moveFile, "/api/files/rename", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::deleteFile, "/api/files", drogon::Delete, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::rebuildIndex, "/api/index/rebuild", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::getTrash, "/api/trash", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::checkRestoreConflicts, "/api/trash/restore-check", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::restoreTrash, "/api/trash/restore", drogon::Post, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::deleteTrash, "/api/trash", drogon::Delete, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::getTrashSettings, "/api/trash/settings", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::getAccountStats, "/api/account/stats", drogon::Get, "server::middleware::JwtMiddleware");
  ADD_METHOD_TO(FileController::uploadStatus, "/api/files/upload-status", drogon::Get, "server::middleware::JwtMiddleware");
  METHOD_LIST_END

  void listDir(const drogon::HttpRequestPtr &req,
               std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void thumbnail(const drogon::HttpRequestPtr &req,
                 std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void downloadFile(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void downloadZip(const drogon::HttpRequestPtr &req,
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
  void checkRestoreConflicts(const drogon::HttpRequestPtr &req,
                             std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void restoreTrash(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void deleteTrash(const drogon::HttpRequestPtr &req,
                   std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void getTrashSettings(const drogon::HttpRequestPtr &req,
                        std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void getAccountStats(const drogon::HttpRequestPtr &req,
                       std::function<void(const drogon::HttpResponsePtr &)> &&callback);
  void uploadStatus(const drogon::HttpRequestPtr &req,
                    std::function<void(const drogon::HttpResponsePtr &)> &&callback);
};

}  // namespace server::controllers
