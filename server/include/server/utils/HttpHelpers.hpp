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
