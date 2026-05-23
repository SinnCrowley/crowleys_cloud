#include "server/controllers/FileController.hpp"

#include "server/AppContext.hpp"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <fstream>
#include <mutex>
#include <thread>
#include <unordered_set>

namespace server::controllers {
namespace {
drogon::HttpResponsePtr jsonError(drogon::HttpStatusCode code, const std::string &msg) {
  Json::Value body;
  body["error"] = msg;
  auto resp = drogon::HttpResponse::newHttpJsonResponse(body);
  resp->setStatusCode(code);
  return resp;
}

bool getAuth(const drogon::HttpRequestPtr &req, std::int64_t &userId, std::string &role) {
  if (!req->attributes()->find("user_id") || !req->attributes()->find("role")) return false;
  userId = req->attributes()->get<std::int64_t>("user_id");
  role = req->attributes()->get<std::string>("role");
  return true;
}

std::string shellQuote(const std::string &value) {
  std::string out = "'";
  for (const auto ch : value) {
    if (ch == '\'') {
      out += "'\\''";
    } else {
      out += ch;
    }
  }
  out += "'";
  return out;
}
}  // namespace

namespace {
std::mutex thumbMutex;
std::unordered_set<std::string> thumbInFlight;
}

void FileController::listDir(const drogon::HttpRequestPtr &req,
                             std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  const auto scopeRaw = req->getParameter("scope");
  const auto pathRaw = req->getParameter("path");
  const auto scope = services::parseScope(scopeRaw);
  if (!scope.has_value()) {
    callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
    return;
  }

  try {
    const auto fullPath = server::ctx().fileService->resolvePath(userId, role, *scope, pathRaw, false);
    if (!std::filesystem::exists(fullPath) || !std::filesystem::is_directory(fullPath)) {
      callback(jsonError(drogon::k404NotFound, "Directory not found"));
      return;
    }

    const auto relPrefix = std::filesystem::path(pathRaw).lexically_normal().relative_path().generic_string();
    const auto filterType = req->getParameter("type");
    const auto query = req->getParameter("q");
    const auto sortBy = req->getParameter("sort");
    const auto order = req->getParameter("order");
    const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
    auto entries = server::ctx().fileIndexService->listDirectory({
        .ownerUserId = ownerUserId,
        .scope = *scope,
        .currentPath = relPrefix,
        .filterType = filterType,
        .query = query,
        .sortBy = sortBy,
        .sortAscending = order != "desc",
    });
    if (entries.empty()) {
      const auto fsEntries = server::ctx().fileService->listDirectory(fullPath);
      for (const auto &entry : fsEntries) {
        if (entry.isDir) continue;
        const auto fullRelPath = relPrefix.empty() ? entry.path : (relPrefix + "/" + entry.path);
        const auto absolutePath = fullPath / entry.path;
        server::ctx().fileIndexService->upsertFile(ownerUserId, *scope, fullRelPath, absolutePath);
      }
      entries = server::ctx().fileIndexService->listDirectory({
          .ownerUserId = ownerUserId,
          .scope = *scope,
          .currentPath = relPrefix,
          .filterType = filterType,
          .query = query,
          .sortBy = sortBy,
          .sortAscending = order != "desc",
      });
    }

    Json::Value body;
    body["entries"] = Json::arrayValue;
    for (const auto &entry : entries) {
      Json::Value v;
      v["name"] = entry.name;
      v["size"] = static_cast<Json::UInt64>(entry.size);
      v["is_dir"] = entry.isDir;
      v["modified_at"] = static_cast<Json::Int64>(entry.modifiedAt);
      v["type"] = entry.type;
      v["mime_type"] = entry.mimeType;
      const auto fullRelPath = entry.path;
      v["path"] = fullRelPath;
      if (!entry.isDir) {
        v["thumbnail_url"] = "/api/thumb?scope=" + scopeRaw + "&path=" + drogon::utils::urlEncode(fullRelPath) + "&s=256";
      }
      body["entries"].append(v);
    }
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::thumbnail(const drogon::HttpRequestPtr &req,
                               std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }
  const auto scope = services::parseScope(req->getParameter("scope"));
  if (!scope.has_value()) {
    callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
    return;
  }

  try {
    const auto rawPath = req->getParameter("path");
    const auto source = server::ctx().fileService->resolvePath(userId, role, *scope, rawPath, false);
    if (!std::filesystem::exists(source) || std::filesystem::is_directory(source)) {
      callback(jsonError(drogon::k404NotFound, "File not found"));
      return;
    }

    const auto fileType = server::ctx().fileService->classifyType(source);
    const auto sizeRaw = req->getParameter("s").empty() ? "256" : req->getParameter("s");
    const auto thumbSize = std::max(64, std::min(1024, std::stoi(sizeRaw)));
    const auto key = std::to_string(userId) + ":" + source.generic_string() + ":" + std::to_string(thumbSize);
    const auto thumbRoot = std::filesystem::path(server::ctx().config.storageRoot) / ".thumbs" / std::to_string(userId);
    std::filesystem::create_directories(thumbRoot);
    const auto thumbPathBase = thumbRoot / std::to_string(std::hash<std::string>{}(key));
    const auto thumbPath = fileType == "video"
        ? std::filesystem::path(thumbPathBase.string() + ".jpg")
        : thumbPathBase;

    if (std::filesystem::exists(thumbPath) &&
        std::filesystem::last_write_time(thumbPath) >= std::filesystem::last_write_time(source)) {
      auto resp = drogon::HttpResponse::newFileResponse(thumbPath.string());
      callback(resp);
      return;
    }

    {
      std::lock_guard<std::mutex> lock(thumbMutex);
      if (thumbInFlight.insert(key).second) {
        std::thread([source, thumbPath, key, thumbSize, fileType]() {
          try {
            if (fileType == "video" && server::ctx().config.videoThumbsEnabled) {
              const auto cmd =
                  shellQuote(server::ctx().config.ffmpegBinary) +
                  " -hide_banner -loglevel error -y -ss 00:00:01 -i " +
                  shellQuote(source.string()) +
                  " -frames:v 1 -vf " +
                  shellQuote("scale=" + std::to_string(thumbSize) + ":-1:force_original_aspect_ratio=decrease") +
                  " " + shellQuote(thumbPath.string());
              std::system(cmd.c_str());
            } else {
              std::filesystem::copy_file(
                  source, thumbPath, std::filesystem::copy_options::overwrite_existing);
            }
          } catch (...) {
          }
          std::lock_guard<std::mutex> lock(thumbMutex);
          thumbInFlight.erase(key);
        }).detach();
      }
    }

    auto resp = drogon::HttpResponse::newHttpResponse();
    resp->setStatusCode(drogon::k202Accepted);
    callback(resp);
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::downloadFile(const drogon::HttpRequestPtr &req,
                                  std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  const auto scope = services::parseScope(req->getParameter("scope"));
  if (!scope.has_value()) {
    callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
    return;
  }

  try {
    const auto fullPath = server::ctx().fileService->resolvePath(userId, role, *scope, req->getParameter("path"), false);
    if (!std::filesystem::exists(fullPath) || std::filesystem::is_directory(fullPath)) {
      callback(jsonError(drogon::k404NotFound, "File not found"));
      return;
    }

    auto resp = drogon::HttpResponse::newFileResponse(fullPath.string());
    callback(resp);
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::uploadFile(const drogon::HttpRequestPtr &req,
                                std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  const auto scope = services::parseScope(req->getParameter("scope"));
  if (!scope.has_value()) {
    callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
    return;
  }

  if (req->bodyLength() > static_cast<size_t>(server::ctx().config.uploadLimitBytes)) {
    callback(jsonError(drogon::k413RequestEntityTooLarge, "Upload exceeds limit"));
    return;
  }

  try {
    const auto target = server::ctx().fileService->resolvePath(userId, role, *scope, req->getParameter("path"), true);
    std::filesystem::create_directories(target.parent_path());
    const auto tmp = target.string() + ".tmp";

    std::ofstream out(tmp, std::ios::binary | std::ios::trunc);
    out.write(req->bodyData(), static_cast<std::streamsize>(req->bodyLength()));
    out.close();

    std::filesystem::rename(tmp, target);
    const auto relPath = std::filesystem::path(req->getParameter("path"))
                             .lexically_normal()
                             .relative_path()
                             .generic_string();
    const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
    server::ctx().fileIndexService->upsertFile(ownerUserId, *scope, relPath, target);

    Json::Value body;
    body["ok"] = true;
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::deleteFile(const drogon::HttpRequestPtr &req,
                                std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  const auto scope = services::parseScope(req->getParameter("scope"));
  if (!scope.has_value()) {
    callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
    return;
  }

  try {
    const auto target = server::ctx().fileService->resolvePath(userId, role, *scope, req->getParameter("path"), true);
    if (!std::filesystem::exists(target)) {
      callback(jsonError(drogon::k404NotFound, "File not found"));
      return;
    }
    const auto isDirectory = std::filesystem::is_directory(target);
    const auto relPath = std::filesystem::path(req->getParameter("path"))
                             .lexically_normal()
                             .relative_path()
                             .generic_string();
    const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
    std::filesystem::remove_all(target);
    if (isDirectory) {
      server::ctx().fileIndexService->markDeletedPrefix(ownerUserId, *scope, relPath);
    } else {
      server::ctx().fileIndexService->markDeleted(ownerUserId, *scope, relPath);
    }

    Json::Value body;
    body["ok"] = true;
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::rebuildIndex(const drogon::HttpRequestPtr &req,
                                  std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  const auto scopeRaw = req->getParameter("scope");
  const auto scope = services::parseScope(scopeRaw.empty() ? "private" : scopeRaw);
  if (!scope.has_value()) {
    callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
    return;
  }

  try {
    const auto rootPath = server::ctx().fileService->resolvePath(
        userId, role, *scope, "", false);
    const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
    const auto indexed = server::ctx().fileIndexService->rebuildIndex(ownerUserId, *scope, rootPath);

    Json::Value body;
    body["ok"] = true;
    body["indexed"] = static_cast<Json::Int64>(indexed);
    body["scope"] = *scope == services::StorageScope::Private ? "private" : "shared";
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

}  // namespace server::controllers
