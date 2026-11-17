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
 * Safely formats Content-Disposition header conforming to RFC 6266 / RFC 5987.
 * - Strips CRLF (\r, \n) and control characters to prevent HTTP Response Splitting.
 * - Escapes double quotes and backslashes in quoted ASCII fallback filename.
 * - Adds UTF-8 url-encoded filename* parameter for full unicode support.
 */
inline std::string formatContentDisposition(std::string_view dispositionType, std::string_view rawFileName) {
  std::string sanitizedFallback;
  sanitizedFallback.reserve(rawFileName.size());
  for (unsigned char c : rawFileName) {
    if (c == '\r' || c == '\n' || c == '\0' || c < 0x20 || c == 0x7F) {
      continue;
    }
    if (c == '"' || c == '\\') {
      sanitizedFallback.push_back('\\');
      sanitizedFallback.push_back(static_cast<char>(c));
    } else if (c < 0x80) {
      sanitizedFallback.push_back(static_cast<char>(c));
    } else {
      sanitizedFallback.push_back('_');
    }
  }
  if (sanitizedFallback.empty()) {
    sanitizedFallback = "file";
  }

  std::string cleanUtf8;
  cleanUtf8.reserve(rawFileName.size());
  for (unsigned char c : rawFileName) {
    if (c == '\r' || c == '\n' || c == '\0' || (c < 0x20 && c != '\t')) {
      continue;
    }
    cleanUtf8.push_back(static_cast<char>(c));
  }
  if (cleanUtf8.empty()) {
    cleanUtf8 = "file";
  }

  const std::string encodedUtf8 = drogon::utils::urlEncode(cleanUtf8);
  std::string result(dispositionType);
  result += "; filename=\"";
  result += sanitizedFallback;
  result += "\"; filename*=UTF-8''";
  result += encodedUtf8;
  return result;
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
inline drogon::HttpResponsePtr jsonError(drogon::HttpStatusCode code, const std::string &msg, const std::string &errorCode = "") {
  Json::Value body;
  body["error"] = msg;
  if (!errorCode.empty()) body["code"] = errorCode;
  auto resp = drogon::HttpResponse::newHttpJsonResponse(std::move(body));
  resp->setStatusCode(code);
  return resp;
}

inline drogon::HttpResponsePtr maintenanceResponse() {
  auto response = jsonError(drogon::k503ServiceUnavailable, "Server maintenance in progress", "maintenance");
  response->addHeader("Retry-After", "5");
  response->addHeader("X-Crowley-Maintenance", "true");
  response->addHeader("Cache-Control", "no-store");
  return response;
}

/**
 * Creates an HTTP JSON response formatted with {"ok": true} and 200 OK status.
 */
inline drogon::HttpResponsePtr jsonOk() {
  Json::Value body;
  body["ok"] = true;
  return drogon::HttpResponse::newHttpJsonResponse(std::move(body));
}

struct HttpByteRange {
  std::size_t start{0};
  std::size_t end{0};
  std::size_t length{0};
  bool satisfiable{true};
};

/**
 * Parses standard HTTP Range header (RFC 7233).
 * Supports "bytes=START-END", "bytes=START-", and "bytes=-SUFFIX".
 */
inline std::optional<HttpByteRange> parseRangeHeader(const std::string &rangeHeader, std::size_t totalSize) {
  if (rangeHeader.empty() || totalSize == 0) return std::nullopt;
  const std::string prefix = "bytes=";
  if (rangeHeader.rfind(prefix, 0) != 0) return std::nullopt;

  std::string spec = rangeHeader.substr(prefix.size());
  const auto commaPos = spec.find(',');
  if (commaPos != std::string::npos) {
    spec = spec.substr(0, commaPos);
  }
  while (!spec.empty() && (spec.front() == ' ' || spec.front() == '\t')) spec.erase(0, 1);
  while (!spec.empty() && (spec.back() == ' ' || spec.back() == '\t')) spec.pop_back();

  const auto dashPos = spec.find('-');
  if (dashPos == std::string::npos) return std::nullopt;

  const std::string startStr = spec.substr(0, dashPos);
  const std::string endStr = spec.substr(dashPos + 1);

  HttpByteRange r;
  if (startStr.empty()) {
    if (endStr.empty()) return std::nullopt;
    try {
      const auto suffixLen = std::stoull(endStr);
      if (suffixLen == 0) {
        r.satisfiable = false;
        return r;
      }
      if (suffixLen >= totalSize) {
        r.start = 0;
      } else {
        r.start = totalSize - static_cast<std::size_t>(suffixLen);
      }
      r.end = totalSize - 1;
      r.length = r.end - r.start + 1;
      r.satisfiable = true;
      return r;
    } catch (...) {
      return std::nullopt;
    }
  }

  try {
    const auto startVal = std::stoull(startStr);
    if (startVal >= totalSize) {
      r.satisfiable = false;
      return r;
    }
    r.start = static_cast<std::size_t>(startVal);
    if (endStr.empty()) {
      r.end = totalSize - 1;
    } else {
      const auto endVal = std::stoull(endStr);
      r.end = std::min(static_cast<std::size_t>(endVal), totalSize - 1);
      if (r.end < r.start) {
        r.satisfiable = false;
        return r;
      }
    }
    r.length = r.end - r.start + 1;
    r.satisfiable = true;
    return r;
  } catch (...) {
    return std::nullopt;
  }
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
