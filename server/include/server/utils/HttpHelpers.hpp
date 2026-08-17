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

#include <drogon/drogon.h>
#include <json/json.h>

#include <cstdint>
#include <optional>
#include <string>

namespace server::utils {

/**
 * Creates an HTTP JSON response formatted with an "error" message field and status code.
 */
inline drogon::HttpResponsePtr jsonError(drogon::HttpStatusCode code, const std::string &msg) {
  Json::Value body;
  body["error"] = msg;
  auto resp = drogon::HttpResponse::newHttpJsonResponse(std::move(body));
  resp->setStatusCode(code);
  return resp;
}

/**
 * Creates an HTTP JSON response formatted with {"ok": true} and 200 OK status.
 */
inline drogon::HttpResponsePtr jsonOk() {
  Json::Value body;
  body["ok"] = true;
  return drogon::HttpResponse::newHttpJsonResponse(std::move(body));
}

/**
 * Extracts authenticated user ID and role from Drogon request attributes.
 * Returns true if both attributes are present, false otherwise.
 */
inline bool getAuth(const drogon::HttpRequestPtr &req, std::int64_t &userId, std::string &role) {
  if (!req->attributes()->find("user_id") || !req->attributes()->find("role")) {
    return false;
  }
  userId = req->attributes()->get<std::int64_t>("user_id");
  role = req->attributes()->get<std::string>("role");
  return true;
}

/**
 * Extracts authenticated user ID from Drogon request attributes if present.
 */
inline std::optional<std::int64_t> getAuthUserId(const drogon::HttpRequestPtr &req) {
  if (!req->attributes()->find("user_id")) {
    return std::nullopt;
  }
  return req->attributes()->get<std::int64_t>("user_id");
}

/**
 * Extracts authenticated user role from Drogon request attributes if present.
 */
inline std::optional<std::string> getAuthRole(const drogon::HttpRequestPtr &req) {
  if (!req->attributes()->find("role")) {
    return std::nullopt;
  }
  return req->attributes()->get<std::string>("role");
}

}  // namespace server::utils
