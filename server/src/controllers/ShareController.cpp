#include "server/controllers/ShareController.hpp"

#include "server/AppContext.hpp"

#include <chrono>
#include <filesystem>
#include <sstream>
#include <trantor/utils/Logger.h>

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

std::string htmlEscape(const std::string &value) {
  std::string out;
  out.reserve(value.size());
  for (const auto ch : value) {
    switch (ch) {
      case '&':
        out += "&amp;";
        break;
      case '<':
        out += "&lt;";
        break;
      case '>':
        out += "&gt;";
        break;
      case '"':
        out += "&quot;";
        break;
      case '\'':
        out += "&#39;";
        break;
      default:
        out.push_back(ch);
        break;
    }
  }
  return out;
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
    if (!std::filesystem::exists(resolved)) {
      callback(jsonError(drogon::k404NotFound, "Only existing files or folders can be shared"));
      return;
    }

    std::optional<std::int64_t> expiresAt;
    if (json->isMember("expires_in_seconds") && (*json)["expires_in_seconds"].isInt64()) {
      expiresAt = nowSeconds() + (*json)["expires_in_seconds"].asInt64();
    }

    const auto normalizedScope = *scope == services::StorageScope::Private ? "private" : "shared";
    const auto token = server::ctx().shareService->createShare(
        userId, normalizedScope, (*json)["path"].asString(), expiresAt);

    Json::Value body;
    body["token"] = token;
    body["url"] = "/s/" + token;
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k500InternalServerError, e.what()));
  }
}

void ShareController::publicDownload(const drogon::HttpRequestPtr &req,
                                     std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                                     const std::string &token) {
  auto share = server::ctx().shareService->resolveShare(token);
  if (!share.has_value()) {
    LOG_WARN << "share_public_download token_not_found_or_expired token=" << token;
    callback(jsonError(drogon::k404NotFound, "Invalid or expired share token"));
    return;
  }

  try {
    const auto scope = services::parseScope(share->scope);
    if (!scope.has_value()) {
      std::ostringstream hex;
      hex << std::hex;
      for (unsigned char c : share->scope) {
        hex << static_cast<int>(c) << ' ';
      }
      LOG_WARN << "share_public_download invalid_scope token=" << token
               << " raw_scope=" << share->scope
               << " raw_scope_hex=" << hex.str();
      callback(jsonError(drogon::k400BadRequest, "Invalid share scope"));
      return;
    }

    const auto root = server::ctx().fileService->resolvePath(
        share->ownerUserId, "user", *scope, share->relPath, false);
    if (!std::filesystem::exists(root)) {
      LOG_WARN << "share_public_download missing_root token=" << token
               << " owner_user_id=" << share->ownerUserId
               << " scope=" << share->scope
               << " rel_path=" << share->relPath
               << " resolved_root=" << root.string();
      callback(jsonError(drogon::k404NotFound, "Shared resource not found"));
      return;
    }

    if (!std::filesystem::is_directory(root)) {
      callback(drogon::HttpResponse::newFileResponse(root.string()));
      return;
    }

    const auto relRaw = req->getParameter("p");
    const auto relPath = std::filesystem::path(relRaw).lexically_normal().relative_path();
    const auto target = std::filesystem::weakly_canonical(root / relPath);
    const auto normalizedRoot = std::filesystem::weakly_canonical(root);
    const auto targetString = target.generic_string();
    const auto rootString = normalizedRoot.generic_string();
    if (targetString.size() < rootString.size() ||
        targetString.compare(0, rootString.size(), rootString) != 0) {
      callback(jsonError(drogon::k400BadRequest, "Invalid path"));
      return;
    }
    if (!std::filesystem::exists(target)) {
      LOG_WARN << "share_public_download missing_target token=" << token
               << " target=" << target.string();
      callback(jsonError(drogon::k404NotFound, "Path not found"));
      return;
    }

    const auto downloadMode = req->getParameter("download") == "1";
    if (downloadMode) {
      if (std::filesystem::is_directory(target)) {
        callback(jsonError(drogon::k400BadRequest, "Directory cannot be downloaded directly"));
        return;
      }
      callback(drogon::HttpResponse::newFileResponse(target.string()));
      return;
    }

    if (!std::filesystem::is_directory(target)) {
      callback(drogon::HttpResponse::newFileResponse(target.string()));
      return;
    }

    const auto currentRel = std::filesystem::relative(target, normalizedRoot).generic_string();
    std::ostringstream html;
    html << "<!doctype html><html><head><meta charset=\"utf-8\"><title>Shared Folder</title></head><body>";
    html << "<h2>Shared Folder</h2>";
    html << "<p>Path: /" << htmlEscape(currentRel) << "</p>";

    if (!currentRel.empty()) {
      const auto parentRel =
          std::filesystem::path(currentRel).parent_path().generic_string();
      html << "<p><a href=\"/s/" << token << "?p=" << drogon::utils::urlEncode(parentRel)
           << "\">.. (parent)</a></p>";
    }
    html << "<ul>";
    for (const auto &entry : std::filesystem::directory_iterator(target)) {
      const auto name = entry.path().filename().string();
      const auto entryRel = std::filesystem::relative(entry.path(), normalizedRoot).generic_string();
      if (entry.is_directory()) {
        html << "<li>[DIR] <a href=\"/s/" << token << "?p="
             << drogon::utils::urlEncode(entryRel) << "\">"
             << htmlEscape(name) << "</a></li>";
      } else {
        html << "<li>[FILE] " << htmlEscape(name) << " - "
             << "<a href=\"/s/" << token << "?download=1&p="
             << drogon::utils::urlEncode(entryRel)
             << "\">download</a></li>";
      }
    }
    html << "</ul></body></html>";

    auto resp = drogon::HttpResponse::newHttpResponse();
    resp->setStatusCode(drogon::k200OK);
    resp->setContentTypeCode(drogon::CT_TEXT_HTML);
    resp->setBody(html.str());
    callback(resp);
  } catch (const std::exception &e) {
    LOG_WARN << "share_public_download exception token=" << token << " error=" << e.what();
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

}  // namespace server::controllers
