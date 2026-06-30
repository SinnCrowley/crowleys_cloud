#include "server/controllers/FileController.hpp"

#include "server/AppContext.hpp"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <fstream>
#include <mutex>
#include <thread>
#include <unordered_map>
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
    const auto relPrefix = std::filesystem::path(pathRaw).lexically_normal().relative_path().generic_string();
    const auto filterType = req->getParameter("type");
    const auto query = req->getParameter("q");
    const bool typedView = !filterType.empty() && filterType != "all";
    const bool recursiveSearch = !typedView && !query.empty();
    const auto sortBy = req->getParameter("sort");
    const auto order = req->getParameter("order");
    const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;

    if (*scope != services::StorageScope::Shared) {
      const auto fullPath = server::ctx().fileService->resolvePath(userId, role, *scope, pathRaw, false);
      if (!std::filesystem::exists(fullPath) || !std::filesystem::is_directory(fullPath)) {
        callback(jsonError(drogon::k404NotFound, "Directory not found"));
        return;
      }
    }

    auto entries = server::ctx().fileIndexService->listDirectory({
        .ownerUserId = ownerUserId,
        .scope = *scope,
        .currentPath = relPrefix,
        .filterType = filterType,
        .query = query,
        .sortBy = sortBy,
        .sortAscending = order != "desc",
        .includeDirs = !typedView && !recursiveSearch,
        .recursiveFiles = typedView || recursiveSearch,
    });

    if (entries.empty() && *scope != services::StorageScope::Shared) {
      const auto fullPath = server::ctx().fileService->resolvePath(userId, role, *scope, pathRaw, false);
      if (typedView || recursiveSearch) {
        const auto scopeRoot = server::ctx().fileService->resolvePath(userId, role, *scope, "", false);
        server::ctx().fileIndexService->rebuildIndex(ownerUserId, *scope, scopeRoot);
      } else {
        const auto fsEntries = server::ctx().fileService->listDirectory(fullPath);
        for (const auto &entry : fsEntries) {
          if (entry.isDir) continue;
          const auto fullRelPath = relPrefix.empty() ? entry.path : (relPrefix + "/" + entry.path);
          const auto absolutePath = fullPath / entry.path;
          const auto uploaderUserId = *scope == services::StorageScope::Shared ? 0 : userId;
          server::ctx().fileIndexService->upsertFile(
              ownerUserId, *scope, fullRelPath, absolutePath, uploaderUserId);
        }
      }
      entries = server::ctx().fileIndexService->listDirectory({
          .ownerUserId = ownerUserId,
          .scope = *scope,
          .currentPath = relPrefix,
          .filterType = filterType,
          .query = query,
          .sortBy = sortBy,
          .sortAscending = order != "desc",
          .includeDirs = !typedView && !recursiveSearch,
          .recursiveFiles = typedView || recursiveSearch,
      });
    }

    std::unordered_map<std::string, services::IndexedDirEntry> dirEntries;
    if (!typedView && !recursiveSearch) {
      for (const auto &entry : entries) {
        if (entry.isDir) {
          dirEntries[entry.path] = entry;
        }
      }
      if (*scope != services::StorageScope::Shared) {
        const auto fullPath = server::ctx().fileService->resolvePath(userId, role, *scope, pathRaw, false);
        const auto fsEntries = server::ctx().fileService->listDirectory(fullPath);
        for (const auto &fsEntry : fsEntries) {
          if (!fsEntry.isDir) continue;
          const auto fullRelPath = relPrefix.empty() ? fsEntry.path : (relPrefix + "/" + fsEntry.path);
          if (dirEntries.find(fullRelPath) != dirEntries.end()) continue;
          dirEntries.emplace(
              fullRelPath,
              services::IndexedDirEntry{
                  .name = fsEntry.name,
                  .path = fullRelPath,
                  .isDir = true,
                  .size = 0,
                  .modifiedAt = fsEntry.modifiedAt,
                  .type = "directory",
                  .mimeType = "inode/directory",
                  .thumbnailUrl = "",
              });
        }
      }
    }

    std::vector<services::IndexedDirEntry> mergedEntries;
    mergedEntries.reserve(dirEntries.size() + entries.size());
    for (const auto &[_, dirEntry] : dirEntries) {
      mergedEntries.push_back(dirEntry);
    }
    for (const auto &entry : entries) {
      if (!entry.isDir) mergedEntries.push_back(entry);
    }

    std::sort(mergedEntries.begin(), mergedEntries.end(), [&](const auto &a, const auto &b) {
      if (a.isDir != b.isDir) return a.isDir > b.isDir;

      auto lessByName = [&]() { return order != "desc" ? a.name < b.name : a.name > b.name; };
      if (sortBy == "size") {
        if (a.size == b.size) return lessByName();
        return order != "desc" ? a.size < b.size : a.size > b.size;
      }
      if (sortBy == "date") {
        if (a.modifiedAt == b.modifiedAt) return lessByName();
        return order != "desc" ? a.modifiedAt < b.modifiedAt : a.modifiedAt > b.modifiedAt;
      }
      if (sortBy == "type") {
        if (a.type == b.type) return lessByName();
        return order != "desc" ? a.type < b.type : a.type > b.type;
      }
      return lessByName();
    });

    Json::Value body;
    body["entries"] = Json::arrayValue;
    for (const auto &entry : mergedEntries) {
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

  try {
    std::filesystem::path source;
    std::int64_t cacheUserId = userId;

    const auto trashIdStr = req->getParameter("trash_id");
    if (!trashIdStr.empty()) {
      std::int64_t trashId = std::stoll(trashIdStr);
      sqlite3_stmt *stmt = nullptr;
      sqlite3_prepare_v2(server::ctx().database->raw(), "SELECT owner_user_id FROM trash WHERE id = ?", -1, &stmt, nullptr);
      sqlite3_bind_int64(stmt, 1, trashId);
      if (sqlite3_step(stmt) != SQLITE_ROW) {
        sqlite3_finalize(stmt);
        callback(jsonError(drogon::k404NotFound, "Trash item not found"));
        return;
      }
      std::int64_t ownerId = sqlite3_column_int64(stmt, 0);
      sqlite3_finalize(stmt);
      if (ownerId != userId) {
        callback(jsonError(drogon::k403Forbidden, "Forbidden"));
        return;
      }
      source = std::filesystem::path(server::ctx().config.storageRoot) / "trash" / std::to_string(userId) / std::to_string(trashId);
      cacheUserId = userId;
    } else {
      const auto scope = services::parseScope(req->getParameter("scope"));
      if (!scope.has_value()) {
        callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
        return;
      }
      const auto rawPath = req->getParameter("path");
      if (*scope == services::StorageScope::Shared) {
        auto ownerId = server::ctx().fileIndexService->getSharedFileOwner(rawPath);
        if (!ownerId.has_value()) {
          callback(jsonError(drogon::k404NotFound, "File not found"));
          return;
        }
        source = server::ctx().fileService->resolvePath(*ownerId, role, services::StorageScope::Private, rawPath, false);
        cacheUserId = *ownerId;
      } else {
        source = server::ctx().fileService->resolvePath(userId, role, *scope, rawPath, false);
      }
    }

    if (!std::filesystem::exists(source) || std::filesystem::is_directory(source)) {
      callback(jsonError(drogon::k404NotFound, "File not found"));
      return;
    }

    const auto fileType = server::ctx().fileService->classifyType(source);
    const auto sizeRaw = req->getParameter("s").empty() ? "256" : req->getParameter("s");
    const auto thumbSize = std::max(64, std::min(1024, std::stoi(sizeRaw)));
    const auto key = std::to_string(cacheUserId) + ":" + source.generic_string() + ":" + std::to_string(thumbSize);
    const auto thumbRoot = std::filesystem::path(server::ctx().config.storageRoot) / ".thumbs" / std::to_string(cacheUserId);
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

  try {
    std::filesystem::path fullPath;
    const auto trashIdStr = req->getParameter("trash_id");
    if (!trashIdStr.empty()) {
      std::int64_t trashId = std::stoll(trashIdStr);
      sqlite3_stmt *stmt = nullptr;
      sqlite3_prepare_v2(server::ctx().database->raw(), "SELECT owner_user_id FROM trash WHERE id = ?", -1, &stmt, nullptr);
      sqlite3_bind_int64(stmt, 1, trashId);
      if (sqlite3_step(stmt) != SQLITE_ROW) {
        sqlite3_finalize(stmt);
        callback(jsonError(drogon::k404NotFound, "Trash item not found"));
        return;
      }
      std::int64_t ownerId = sqlite3_column_int64(stmt, 0);
      sqlite3_finalize(stmt);
      if (ownerId != userId) {
        callback(jsonError(drogon::k403Forbidden, "Forbidden"));
        return;
      }
      fullPath = std::filesystem::path(server::ctx().config.storageRoot) / "trash" / std::to_string(userId) / std::to_string(trashId);
    } else {
      const auto scope = services::parseScope(req->getParameter("scope"));
      if (!scope.has_value()) {
        callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
        return;
      }
      if (*scope == services::StorageScope::Shared) {
        auto ownerId = server::ctx().fileIndexService->getSharedFileOwner(req->getParameter("path"));
        if (!ownerId.has_value()) {
          callback(jsonError(drogon::k404NotFound, "File not found"));
          return;
        }
        fullPath = server::ctx().fileService->resolvePath(*ownerId, role, services::StorageScope::Private, req->getParameter("path"), false);
      } else {
        fullPath = server::ctx().fileService->resolvePath(userId, role, *scope, req->getParameter("path"), false);
      }
    }

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
    const auto uploaderUserId = *scope == services::StorageScope::Shared ? userId : ownerUserId;
    server::ctx().fileIndexService->upsertFile(
        ownerUserId, *scope, relPath, target, uploaderUserId);

    Json::Value body;
    body["ok"] = true;
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::shareFile(const drogon::HttpRequestPtr &req,
                               std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  const auto pathRaw = req->getParameter("path");
  const auto sharedRaw = req->getParameter("shared");
  if (pathRaw.empty()) {
    callback(jsonError(drogon::k400BadRequest, "path is required"));
    return;
  }
  const bool isShared = sharedRaw == "1" || sharedRaw == "true";

  try {
    server::ctx().fileIndexService->setSharedFlag(userId, pathRaw, isShared);
    Json::Value body;
    body["ok"] = true;
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::checkHashes(const drogon::HttpRequestPtr &req,
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

  auto jsonPtr = req->getJsonObject();
  if (!jsonPtr || !jsonPtr->isMember("hashes") || !(*jsonPtr)["hashes"].isArray()) {
    callback(jsonError(drogon::k400BadRequest, "JSON with 'hashes' array is required"));
    return;
  }

  const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
  const auto &hashesVal = (*jsonPtr)["hashes"];

  Json::Value body;
  body["existing"] = Json::objectValue;

  for (Json::ArrayIndex i = 0; i < hashesVal.size(); ++i) {
    if (!hashesVal[i].isString()) continue;
    const std::string sha256 = hashesVal[i].asString();
    if (sha256.empty()) continue;

    auto entry = server::ctx().fileIndexService->findFileByHash(ownerUserId, *scope, sha256);
    if (entry.has_value()) {
      Json::Value item;
      item["path"] = entry->path;
      item["size"] = static_cast<Json::UInt64>(entry->size);
      body["existing"][sha256] = item;
    }
  }

  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void FileController::createFolder(const drogon::HttpRequestPtr &req,
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

  const auto pathRaw = req->getParameter("path");
  if (pathRaw.empty()) {
    callback(jsonError(drogon::k400BadRequest, "path is required"));
    return;
  }

  try {
    const auto target = server::ctx().fileService->resolvePath(userId, role, *scope, pathRaw, true);
    std::filesystem::create_directories(target);

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
    const auto relPath = std::filesystem::path(req->getParameter("path"))
                             .lexically_normal()
                             .relative_path()
                             .generic_string();
    if (*scope == services::StorageScope::Shared) {
      auto ownerId = server::ctx().fileIndexService->getSharedFileOwner(relPath);
      if (!ownerId.has_value()) {
        callback(jsonError(drogon::k404NotFound, "File not found in shared scope"));
        return;
      }
      if (*ownerId != userId) {
        callback(jsonError(drogon::k403Forbidden, "Only the owner can unshare files"));
        return;
      }
      server::ctx().fileIndexService->setSharedFlag(*ownerId, relPath, false);
    } else {
      server::ctx().trashService->moveToTrash(userId, *scope, relPath);
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

void FileController::getTrash(const drogon::HttpRequestPtr &req,
                              std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  const auto scopeRaw = req->getParameter("scope");
  const auto scope = services::parseScope(scopeRaw.empty() ? "private" : scopeRaw).value_or(services::StorageScope::Private);
  const auto query = req->getParameter("q");

  try {
    auto entries = server::ctx().trashService->listTrash(userId, scope, query);
    Json::Value body;
    body["entries"] = Json::arrayValue;
    for (const auto &entry : entries) {
      Json::Value v;
      v["id"] = static_cast<Json::Int64>(entry.id);
      v["name"] = entry.name;
      v["path"] = entry.originalPath;
      v["is_dir"] = entry.isDir;
      v["size"] = static_cast<Json::UInt64>(entry.size);
      v["modified_at"] = static_cast<Json::Int64>(entry.deletedAt);
      v["deleted_at"] = static_cast<Json::Int64>(entry.deletedAt);
      v["type"] = entry.type;
      v["mime_type"] = entry.mimeType;
      if (!entry.isDir) {
        v["thumbnail_url"] = "/api/thumb?trash_id=" + std::to_string(entry.id) + "&s=256";
      }
      body["entries"].append(v);
    }
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::restoreTrash(const drogon::HttpRequestPtr &req,
                                 std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  auto json = req->getJsonObject();
  if (!json || !json->isMember("ids") || !(*json)["ids"].isArray()) {
    callback(jsonError(drogon::k400BadRequest, "ids array is required"));
    return;
  }

  std::vector<std::int64_t> ids;
  for (const auto &idVal : (*json)["ids"]) {
    ids.push_back(idVal.asInt64());
  }

  try {
    server::ctx().trashService->restoreFromTrash(userId, ids);
    Json::Value body;
    body["ok"] = true;
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::deleteTrash(const drogon::HttpRequestPtr &req,
                                 std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  auto json = req->getJsonObject();
  if (!json || !json->isMember("ids") || !(*json)["ids"].isArray()) {
    callback(jsonError(drogon::k400BadRequest, "ids array is required"));
    return;
  }

  std::vector<std::int64_t> ids;
  for (const auto &idVal : (*json)["ids"]) {
    ids.push_back(idVal.asInt64());
  }

  try {
    server::ctx().trashService->deletePermanently(userId, ids);
    Json::Value body;
    body["ok"] = true;
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::getTrashSettings(const drogon::HttpRequestPtr &req,
                                      std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  try {
    std::int64_t days = server::ctx().trashService->getTrashRetentionDays(userId);
    Json::Value body;
    body["trash_retention_days"] = static_cast<Json::Int64>(days);
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::setTrashSettings(const drogon::HttpRequestPtr &req,
                                      std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  auto json = req->getJsonObject();
  if (!json || !json->isMember("trash_retention_days")) {
    callback(jsonError(drogon::k400BadRequest, "trash_retention_days is required"));
    return;
  }

  std::int64_t days = (*json)["trash_retention_days"].asInt64();

  try {
    server::ctx().trashService->setTrashRetentionDays(userId, days);
    Json::Value body;
    body["ok"] = true;
    body["trash_retention_days"] = static_cast<Json::Int64>(days);
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

}  // namespace server::controllers
