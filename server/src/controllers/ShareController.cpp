#include "server/controllers/ShareController.hpp"

#include "server/AppContext.hpp"

#include <chrono>

namespace server::controllers {
namespace {
drogon::HttpResponsePtr jsonError(drogon::HttpStatusCode code, const std::string &msg) {
  Json::Value body;
  body["error"] = msg;
  auto resp = drogon::HttpResponse::newHttpJsonResponse(body);
  resp->setStatusCode(code);
  return resp;
}

std::int64_t nowSeconds() {
  return std::chrono::duration_cast<std::chrono::seconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}
}  // namespace

void ShareController::createShare(const drogon::HttpRequestPtr &req,
                                  std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  if (!req->attributes()->find("user_id") || !req->attributes()->find("role")) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  const auto userId = req->attributes()->get<std::int64_t>("user_id");
  const auto role = req->attributes()->get<std::string>("role");

  const auto json = req->getJsonObject();
  if (!json || !json->isMember("scope") || !json->isMember("path")) {
    callback(jsonError(drogon::k400BadRequest, "scope and path are required"));
    return;
  }

  const auto scopeRaw = (*json)["scope"].asString();
  auto scope = services::parseScope(scopeRaw);
  if (!scope.has_value()) {
    callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
    return;
  }

  try {
    const auto resolved = server::ctx().fileService->resolvePath(userId, role, *scope, (*json)["path"].asString(), false);
    if (!std::filesystem::exists(resolved) || std::filesystem::is_directory(resolved)) {
      callback(jsonError(drogon::k404NotFound, "Only existing files can be shared"));
      return;
    }

    std::optional<std::int64_t> expiresAt;
    if (json->isMember("expires_in_seconds") && (*json)["expires_in_seconds"].isInt64()) {
      expiresAt = nowSeconds() + (*json)["expires_in_seconds"].asInt64();
    }

    const auto token = server::ctx().shareService->createShare(userId, scopeRaw, (*json)["path"].asString(), expiresAt);

    Json::Value body;
    body["token"] = token;
    body["url"] = "/s/" + token;
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void ShareController::publicDownload(const drogon::HttpRequestPtr &,
                                     std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                                     const std::string &token) {
  auto share = server::ctx().shareService->resolveShare(token);
  if (!share.has_value()) {
    callback(jsonError(drogon::k404NotFound, "Invalid or expired share token"));
    return;
  }

  try {
    const auto scope = services::parseScope(share->scope);
    if (!scope.has_value()) {
      callback(jsonError(drogon::k400BadRequest, "Invalid share scope"));
      return;
    }

    const auto path = server::ctx().fileService->resolvePath(share->ownerUserId, "owner", *scope, share->relPath, false);
    if (!std::filesystem::exists(path) || std::filesystem::is_directory(path)) {
      callback(jsonError(drogon::k404NotFound, "Shared file not found"));
      return;
    }

    callback(drogon::HttpResponse::newFileResponse(path.string()));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

}  // namespace server::controllers
