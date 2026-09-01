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

#include <cctype>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace server::utils {

/**
 * Formats a raw ETag identifier into a standard HTTP quoted ETag string.
 * Example: "a1b2c3_256" -> "\"a1b2c3_256\""
 */
inline std::string formatETag(std::string_view raw) {
  if (raw.size() >= 2 && raw.front() == '"' && raw.back() == '"') {
    return std::string(raw);
  }
  return "\"" + std::string(raw) + "\"";
}

/**
 * Validates whether the incoming If-None-Match header matches the target ETag(s)
 * according to RFC 7232 / RFC 9110 weak comparison rules.
 * Supports:
 * - Direct quoted and unquoted matching
 * - Weak validator prefix 'W/' or 'w/'
 * - Wildcard '*' matching
 * - Comma-separated multi-tag lists
 * - Secondary fallback tag matching (e.g. comparing against plain sha256 or mtime base)
 */
inline bool matchesIfNoneMatch(std::string_view ifNoneMatchHeader,
                               std::string_view etag1,
                               std::string_view etag2 = "") {
  if (ifNoneMatchHeader.empty()) {
    return false;
  }

  auto cleanTag = [](std::string_view s) -> std::string_view {
    while (!s.empty() && (s.front() == ' ' || s.front() == '\t' || s.front() == '\r' || s.front() == '\n')) {
      s.remove_prefix(1);
    }
    while (!s.empty() && (s.back() == ' ' || s.back() == '\t' || s.back() == '\r' || s.back() == '\n')) {
      s.remove_suffix(1);
    }
    if (s.size() >= 2 && (s[0] == 'W' || s[0] == 'w') && s[1] == '/') {
      s.remove_prefix(2);
    }
    while (!s.empty() && (s.front() == ' ' || s.front() == '\t' || s.front() == '\r' || s.front() == '\n')) {
      s.remove_prefix(1);
    }
    if (s.size() >= 2 && s.front() == '"' && s.back() == '"') {
      s.remove_prefix(1);
      s.remove_suffix(1);
    }
    return s;
  };

  const std::string_view clean1 = cleanTag(etag1);
  const std::string_view clean2 = etag2.empty() ? std::string_view{} : cleanTag(etag2);

  if (clean1.empty() && clean2.empty()) {
    return false;
  }

  size_t start = 0;
  while (start < ifNoneMatchHeader.size()) {
    size_t comma = ifNoneMatchHeader.find(',', start);
    std::string_view token = (comma == std::string_view::npos)
                                 ? ifNoneMatchHeader.substr(start)
                                 : ifNoneMatchHeader.substr(start, comma - start);
    std::string_view cleanToken = cleanTag(token);
    if (!cleanToken.empty()) {
      if (cleanToken == "*") {
        return true;
      }
      if (!clean1.empty() && cleanToken == clean1) {
        return true;
      }
      if (!clean2.empty() && cleanToken == clean2) {
        return true;
      }
    }
    if (comma == std::string_view::npos) break;
    start = comma + 1;
  }
  return false;
}

/**
 * Alias for matchesIfNoneMatch to support alternate naming conventions.
 */
inline bool matchETag(std::string_view ifNoneMatchHeader,
                      std::string_view etag1,
                      std::string_view etag2 = "") {
  return matchesIfNoneMatch(ifNoneMatchHeader, etag1, etag2);
}

/**
 * Creates an HTTP 304 Not Modified response with appropriate caching headers and empty body.
 */
inline drogon::HttpResponsePtr makeNotModifiedResponse(
    const std::string &etag,
    const std::string &cacheControl = "private, max-age=31536000, immutable") {
  auto resp = drogon::HttpResponse::newHttpResponse();
  resp->setStatusCode(drogon::k304NotModified);
  if (!etag.empty()) {
    resp->addHeader("ETag", formatETag(etag));
  }
  if (!cacheControl.empty()) {
    resp->addHeader("Cache-Control", cacheControl);
  }
  return resp;
}

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
