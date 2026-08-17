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
