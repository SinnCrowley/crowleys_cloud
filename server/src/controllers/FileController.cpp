// FileController implementation for Drogon HTTP endpoints.
// Path Resolution & Security: Delegates canonical path verification and traversal checks
// to FileService::resolvePath and FileIndexService::normalizeRelPath, guaranteeing scope isolation.
// Statement Caching: Uses Database::getStatement RAII StatementGuards for thread-safe query execution.
// Serialization: Uses centralized formatters (formatDirEntryJson, formatTrashEntryJson, jsonOk) for DTO creation.

#include "server/controllers/FileController.hpp"

#include <drogon/MultiPart.h>

#include "server/AppContext.hpp"
#include "server/utils/Crypto.hpp"
#include "server/utils/HttpHelpers.hpp"
#include "server/utils/ZipWriter.hpp"
#include "dir_entry.pb.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <fstream>
#include <mutex>
#include <thread>
#include <unordered_map>
#include <unordered_set>
#include <queue>
#include <condition_variable>
#include <fstream>

#include <server/utils/PlatformUtils.hpp>
#include <trantor/utils/Logger.h>

namespace server::controllers {
using server::utils::jsonError;
using server::utils::jsonOk;
using server::utils::getAuth;

namespace {

struct FileZipCleanupHelper {
  std::filesystem::path tmpZipPath;
  drogon::HttpResponsePtr response;

  FileZipCleanupHelper(std::filesystem::path p, drogon::HttpResponsePtr resp)
      : tmpZipPath(std::move(p)), response(std::move(resp)) {}

  ~FileZipCleanupHelper() {
    std::error_code ec;
    if (!tmpZipPath.empty() && std::filesystem::exists(tmpZipPath, ec)) {
      std::filesystem::remove(tmpZipPath, ec);
    }
  }
};

Json::Value formatDirEntryJson(const services::IndexedDirEntry &entry,
                               const std::string &scopeRaw,
                               std::int64_t currentUserId = 0,
                               std::unordered_map<std::int64_t, std::string> *userCache = nullptr) {
  Json::Value v;
  v["name"] = entry.name;
  v["size"] = static_cast<Json::UInt64>(entry.size);
  v["is_dir"] = entry.isDir;
  v["modified_at"] = static_cast<Json::Int64>(entry.modifiedAt);
  v["type"] = entry.type;
  v["mime_type"] = entry.mimeType;
  v["path"] = entry.path;
  v["is_shared"] = entry.isShared;
  v["uploader_user_id"] = static_cast<Json::Int64>(entry.uploaderUserId);
  v["is_owner"] = (currentUserId == 0 || entry.uploaderUserId == 0 || entry.uploaderUserId == currentUserId);

  std::string ownerName = "Shared";
  if (entry.uploaderUserId > 0) {
    if (userCache && userCache->count(entry.uploaderUserId)) {
      ownerName = (*userCache)[entry.uploaderUserId];
    } else {
      const auto userRec = server::ctx().userService->getUserById(entry.uploaderUserId);
      if (userRec.has_value() && !userRec->username.empty()) {
        ownerName = userRec->username;
      } else {
        ownerName = "User #" + std::to_string(entry.uploaderUserId);
      }
      if (userCache) {
        (*userCache)[entry.uploaderUserId] = ownerName;
      }
    }
  }
  v["owner_name"] = ownerName;

  if (!entry.isDir) {
    v["thumbnail_url"] = "/api/thumb?scope=" + scopeRaw + "&path=" + drogon::utils::urlEncode(entry.path) + "&s=256";
  }
  return v;
}

Json::Value formatTrashEntryJson(const services::TrashEntry &entry) {
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
  return v;
}

using server::utils::runProcess;
}  // namespace

namespace {
std::mutex thumbMutex;
std::unordered_set<std::string> thumbInFlight;

class ThumbnailThreadPool {
 public:
  ThumbnailThreadPool(size_t threads) : stop_(false) {
    for (size_t i = 0; i < threads; ++i) {
      workers_.emplace_back([this] {
        for (;;) {
          std::function<void()> task;
          {
            std::unique_lock<std::mutex> lock(this->queueMutex_);
            this->condition_.wait(lock, [this] { return this->stop_ || !this->tasks_.empty(); });
            if (this->stop_ && this->tasks_.empty()) return;
            task = std::move(this->tasks_.front());
            this->tasks_.pop();
          }
          task();
        }
      });
    }
  }

  template <class F>
  void enqueue(F &&f) {
    {
      std::unique_lock<std::mutex> lock(queueMutex_);
      tasks_.emplace(std::forward<F>(f));
    }
    condition_.notify_one();
  }

  ~ThumbnailThreadPool() {
    {
      std::unique_lock<std::mutex> lock(queueMutex_);
      stop_ = true;
    }
    condition_.notify_all();
    for (std::thread &worker : workers_) {
      if (worker.joinable()) worker.join();
    }
  }

 private:
  std::vector<std::thread> workers_;
  std::queue<std::function<void()>> tasks_;
  std::mutex queueMutex_;
  std::condition_variable condition_;
  bool stop_;
};

ThumbnailThreadPool thumbPool(2);
}  // namespace

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
    const auto relPrefix = services::FileIndexService::normalizeRelPath(pathRaw);
    const auto filterType = req->getParameter("type");
    const auto query = req->getParameter("q");
    const bool typedView = !filterType.empty() && filterType != "all";
    const bool recursiveSearch = !typedView && !query.empty();
    const auto sortBy = req->getParameter("sort");
    const auto order = req->getParameter("order");
    const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;

    if (*scope != services::StorageScope::Shared) {
      if (server::ctx().config.hashFiles) {
        if (!relPrefix.empty()) {
          const char *sql = "SELECT 1 FROM file_index WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR parent_path = ? OR parent_path LIKE ?) AND is_deleted = 0 LIMIT 1";
          auto stmtGuard = server::ctx().database->getStatement(sql);
          auto *stmt = stmtGuard.get();
          sqlite3_bind_int64(stmt, 1, ownerUserId);
          const auto scopeStr = services::FileIndexService::scopeToString(*scope);
          sqlite3_bind_text(stmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(stmt, 3, relPrefix.c_str(), -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(stmt, 4, relPrefix.c_str(), -1, SQLITE_TRANSIENT);
          const auto pattern = relPrefix + "/%";
          sqlite3_bind_text(stmt, 5, pattern.c_str(), -1, SQLITE_TRANSIENT);
          bool exists = (sqlite3_step(stmt) == SQLITE_ROW);
          if (!exists) {
            callback(jsonError(drogon::k404NotFound, "Directory not found"));
            return;
          }
        }
      } else {
        const auto fullPath = server::ctx().fileService->resolvePath(userId, role, *scope, pathRaw, false);
        std::error_code ec;
        const auto st = std::filesystem::status(fullPath, ec);
        if (ec || !std::filesystem::exists(st) || !std::filesystem::is_directory(st)) {
          callback(jsonError(drogon::k404NotFound, "Directory not found"));
          return;
        }
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
        .includeDirs = !typedView,
        .recursiveFiles = typedView || recursiveSearch,
    });

    if (entries.empty() && *scope != services::StorageScope::Shared && !server::ctx().config.hashFiles) {
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
          .includeDirs = !typedView,
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
      if (*scope != services::StorageScope::Shared && !server::ctx().config.hashFiles) {
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
      if (!entry.isDir || recursiveSearch) mergedEntries.push_back(entry);
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

    const auto acceptHeader = req->getHeader("Accept");
    if (acceptHeader.find("application/x-protobuf") != std::string::npos) {
      server::proto::DirResponse protoResponse;
      for (const auto &entry : mergedEntries) {
        auto *protoEntry = protoResponse.add_entries();
        protoEntry->set_name(entry.name);
        protoEntry->set_path(entry.path);
        protoEntry->set_is_dir(entry.isDir);
        protoEntry->set_size(entry.size);
        protoEntry->set_modified_at(entry.modifiedAt);
        protoEntry->set_type(entry.type);
        protoEntry->set_mime_type(entry.mimeType);
        if (!entry.isDir) {
          protoEntry->set_thumbnail_url("/api/thumb?scope=" + scopeRaw + "&path=" + drogon::utils::urlEncode(entry.path) + "&s=256");
        }
      }
      auto resp = drogon::HttpResponse::newHttpResponse();
      resp->setBody(protoResponse.SerializeAsString());
      resp->setContentTypeCode(drogon::ContentType::CT_CUSTOM);
      resp->setContentTypeString("application/x-protobuf");
      callback(resp);
    } else {
      Json::Value body;
      body["entries"] = Json::arrayValue;
      std::unordered_map<std::int64_t, std::string> userCache;
      for (const auto &entry : mergedEntries) {
        body["entries"].append(formatDirEntryJson(entry, scopeRaw, userId, &userCache));
      }
      callback(drogon::HttpResponse::newHttpJsonResponse(body));
    }
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
    std::filesystem::path virtualPath;
    std::int64_t cacheUserId = userId;
    std::string sha256Val;
    const bool hashFiles = server::ctx().config.hashFiles;

    const auto trashIdStr = req->getParameter("trash_id");
    if (!trashIdStr.empty()) {
      std::int64_t trashId = std::stoll(trashIdStr);
      const char *sql = "SELECT owner_user_id, original_path FROM trash WHERE id = ?";
      auto stmtGuard = server::ctx().database->getStatement(sql);
      auto *stmt = stmtGuard.get();
      sqlite3_bind_int64(stmt, 1, trashId);
      if (sqlite3_step(stmt) != SQLITE_ROW) {
        callback(jsonError(drogon::k404NotFound, "Trash item not found"));
        return;
      }
      std::int64_t ownerId = sqlite3_column_int64(stmt, 0);
      std::string origPath = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
      if (ownerId != userId) {
        callback(jsonError(drogon::k403Forbidden, "Forbidden"));
        return;
      }

      virtualPath = origPath;

      if (hashFiles) {
        const auto normalizedOrig = services::FileIndexService::normalizeRelPath(origPath);
        const char *idxSql = "SELECT sha256 FROM file_index WHERE owner_user_id = ? AND rel_path = ? AND is_deleted = 1 LIMIT 1";
        auto idxGuard = server::ctx().database->getStatement(idxSql);
        auto *idxStmt = idxGuard.get();
        sqlite3_bind_int64(idxStmt, 1, userId);
        sqlite3_bind_text(idxStmt, 2, normalizedOrig.c_str(), -1, SQLITE_TRANSIENT);
        if (sqlite3_step(idxStmt) == SQLITE_ROW) {
          const auto shaValRaw = reinterpret_cast<const char *>(sqlite3_column_text(idxStmt, 0));
          if (shaValRaw) sha256Val = shaValRaw;
        }
        source = std::filesystem::path(server::ctx().config.storageRoot) / "data" / sha256Val;
      } else {
        source = std::filesystem::path(server::ctx().config.storageRoot) / "trash" / std::to_string(userId) / std::to_string(trashId);
      }
      cacheUserId = userId;
    } else {
      const auto scope = services::parseScope(req->getParameter("scope"));
      if (!scope.has_value()) {
        callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
        return;
      }
      const auto rawPath = req->getParameter("path");
      const auto normalizedPath = services::FileIndexService::normalizeRelPath(rawPath);
      virtualPath = normalizedPath;

      std::int64_t fileOwnerId = userId;
      if (*scope == services::StorageScope::Shared) {
        auto ownerId = server::ctx().fileIndexService->getSharedFileOwner(normalizedPath);
        if (!ownerId.has_value()) {
          callback(jsonError(drogon::k404NotFound, "File not found"));
          return;
        }
        fileOwnerId = *ownerId;
      }

      if (hashFiles) {
        const char *idxSql = "SELECT sha256 FROM file_index WHERE owner_user_id = ? AND scope = ? AND rel_path = ? AND is_deleted = 0 LIMIT 1";
        auto idxGuard = server::ctx().database->getStatement(idxSql);
        auto *idxStmt = idxGuard.get();
        sqlite3_bind_int64(idxStmt, 1, fileOwnerId);
        const auto scopeStr = services::FileIndexService::scopeToString(*scope);
        sqlite3_bind_text(idxStmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(idxStmt, 3, normalizedPath.c_str(), -1, SQLITE_TRANSIENT);
        if (sqlite3_step(idxStmt) == SQLITE_ROW) {
          const auto shaValRaw = reinterpret_cast<const char *>(sqlite3_column_text(idxStmt, 0));
          if (shaValRaw) sha256Val = shaValRaw;
        }
        source = std::filesystem::path(server::ctx().config.storageRoot) / "data" / sha256Val;
      } else {
        if (*scope == services::StorageScope::Shared) {
          source = server::ctx().fileService->resolvePath(fileOwnerId, role, services::StorageScope::Private, normalizedPath, false);
        } else {
          source = server::ctx().fileService->resolvePath(userId, role, *scope, normalizedPath, false);
        }
      }
      cacheUserId = fileOwnerId;
    }

    std::error_code ecSource;
    const auto srcStatus = std::filesystem::status(source, ecSource);
    if (ecSource || !std::filesystem::exists(srcStatus) || std::filesystem::is_directory(srcStatus)) {
      callback(jsonError(drogon::k404NotFound, "File not found"));
      return;
    }

    const auto fileType = server::ctx().fileService->classifyType(virtualPath);
    const auto sizeRaw = req->getParameter("s").empty() ? "256" : req->getParameter("s");
    const auto thumbSize = std::max(64, std::min(1024, std::stoi(sizeRaw)));
    const auto key = std::to_string(cacheUserId) + ":" + source.generic_string() + ":" + std::to_string(thumbSize);
    const auto thumbRoot = std::filesystem::path(server::ctx().config.storageRoot) / ".thumbs" / std::to_string(cacheUserId);
    std::filesystem::create_directories(thumbRoot);
    const auto thumbPathBase = thumbRoot / std::to_string(std::hash<std::string>{}(key));
    const auto thumbPath = std::filesystem::path(thumbPathBase.string() + ".jpg");

    std::error_code ecThumb, ecSrcTime;
    const auto thumbMtime = std::filesystem::last_write_time(thumbPath, ecThumb);
    const auto srcMtime = std::filesystem::last_write_time(source, ecSrcTime);
    if (!ecThumb && !ecSrcTime && thumbMtime >= srcMtime) {
      auto resp = drogon::HttpResponse::newFileResponse(thumbPath.string());
      callback(resp);
      return;
    }

    {
      std::lock_guard<std::mutex> lock(thumbMutex);
      if (thumbInFlight.insert(key).second) {
        thumbPool.enqueue([source, thumbPath, key, thumbSize, fileType, hashFiles]() {
          std::filesystem::path actualSource = source;
          std::filesystem::path decryptedTmp;

          if (hashFiles) {
            try {
              decryptedTmp = thumbPath.string() + ".dec.tmp";
              if (utils::decryptFileAes256(source, decryptedTmp, server::ctx().config.encryptionKey)) {
                actualSource = decryptedTmp;
              } else {
                std::filesystem::remove(decryptedTmp);
              }
            } catch (...) {
            }
          }

          try {
            if (fileType == "video" && server::ctx().config.videoThumbsEnabled) {
              std::vector<std::string> args = {
                  server::ctx().config.ffmpegBinary,
                  "-hide_banner",
                  "-loglevel",
                  "error",
                  "-y",
                  "-ss",
                  "00:00:01",
                  "-i",
                  actualSource.string(),
                  "-frames:v",
                  "1",
                  "-vf",
                  "scale=" + std::to_string(thumbSize) + ":-1:force_original_aspect_ratio=decrease",
                  thumbPath.string()};
              runProcess(args);
            } else if (fileType == "photo") {
              std::vector<std::string> args = {
                  server::ctx().config.ffmpegBinary,
                  "-hide_banner",
                  "-loglevel",
                  "error",
                  "-y",
                  "-i",
                  actualSource.string(),
                  "-vf",
                  "scale=" + std::to_string(thumbSize) + ":-1:force_original_aspect_ratio=decrease",
                  thumbPath.string()};
              runProcess(args);
            } else {
              std::filesystem::copy_file(
                  actualSource, thumbPath, std::filesystem::copy_options::overwrite_existing);
            }
          } catch (...) {
          }

          if (!decryptedTmp.empty()) {
            std::error_code ec;
            std::filesystem::remove(decryptedTmp, ec);
          }

          std::lock_guard<std::mutex> lock(thumbMutex);
          thumbInFlight.erase(key);
        });
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
    const auto trashIdStr = req->getParameter("trash_id");
    const bool hashFiles = server::ctx().config.hashFiles;

    if (hashFiles) {
      std::string sha256Val;
      std::string fileName;
      std::string mimeType = "application/octet-stream";

      if (!trashIdStr.empty()) {
        std::int64_t trashId = std::stoll(trashIdStr);
        const char *sql = "SELECT owner_user_id, original_path, name, mime_type FROM trash WHERE id = ?";
        auto stmtGuard = server::ctx().database->getStatement(sql);
        auto *stmt = stmtGuard.get();
        sqlite3_bind_int64(stmt, 1, trashId);
        if (sqlite3_step(stmt) != SQLITE_ROW) {
          callback(jsonError(drogon::k404NotFound, "Trash item not found"));
          return;
        }
        std::int64_t ownerId = sqlite3_column_int64(stmt, 0);
        std::string origPath = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
        fileName = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
        mimeType = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 3));

        if (ownerId != userId) {
          callback(jsonError(drogon::k403Forbidden, "Forbidden"));
          return;
        }

        const char *idxSql = "SELECT sha256 FROM file_index WHERE owner_user_id = ? AND rel_path = ? AND is_deleted = 1 LIMIT 1";
        auto idxGuard = server::ctx().database->getStatement(idxSql);
        auto *idxStmt = idxGuard.get();
        sqlite3_bind_int64(idxStmt, 1, userId);
        sqlite3_bind_text(idxStmt, 2, origPath.c_str(), -1, SQLITE_TRANSIENT);
        if (sqlite3_step(idxStmt) == SQLITE_ROW) {
          const auto shaValRaw = reinterpret_cast<const char *>(sqlite3_column_text(idxStmt, 0));
          if (shaValRaw) sha256Val = shaValRaw;
        }
      } else {
        const auto scope = services::parseScope(req->getParameter("scope"));
        if (!scope.has_value()) {
          callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
          return;
        }
        const auto pathParam = req->getParameter("path");
        const auto normalizedPath = services::FileIndexService::normalizeRelPath(pathParam);

        std::int64_t fileOwnerId = userId;
        if (*scope == services::StorageScope::Shared) {
          auto ownerId = server::ctx().fileIndexService->getSharedFileOwner(normalizedPath);
          if (!ownerId.has_value()) {
            callback(jsonError(drogon::k404NotFound, "File not found"));
            return;
          }
          fileOwnerId = *ownerId;
        }

        const char *sql = "SELECT sha256, mime_type, name FROM file_index WHERE owner_user_id = ? AND scope = ? AND rel_path = ? AND is_deleted = 0 LIMIT 1";
        auto stmtGuard = server::ctx().database->getStatement(sql);
        auto *stmt = stmtGuard.get();
        sqlite3_bind_int64(stmt, 1, fileOwnerId);
        const auto scopeStr = services::FileIndexService::scopeToString(*scope);
        sqlite3_bind_text(stmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 3, normalizedPath.c_str(), -1, SQLITE_TRANSIENT);

        if (sqlite3_step(stmt) == SQLITE_ROW) {
          const auto shaValRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
          if (shaValRaw) sha256Val = shaValRaw;
          const auto mimeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
          if (mimeRaw) mimeType = mimeRaw;
          const auto nameRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
          if (nameRaw) fileName = nameRaw;
        }
      }

      if (sha256Val.empty()) {
        callback(jsonError(drogon::k404NotFound, "File not found"));
        return;
      }

      const auto physicalPath = std::filesystem::path(server::ctx().config.storageRoot) / "data" / sha256Val;
      if (!std::filesystem::exists(physicalPath)) {
        callback(jsonError(drogon::k404NotFound, "Physical file not found"));
        return;
      }

      auto resp = drogon::HttpResponse::newAsyncStreamResponse([physicalPath, key = server::ctx().config.encryptionKey](drogon::ResponseStreamPtr stream) {
        std::thread([stream = std::move(stream), physicalPath, key]() mutable {
          try {
            utils::decryptFileToStream(physicalPath, key, [&stream](const char* data, size_t size) {
              stream->send(std::string(data, size));
            });
          } catch (const std::exception &e) {
            LOG_ERROR << "FileController::downloadFile async stream exception: " << e.what();
          } catch (...) {
            LOG_ERROR << "FileController::downloadFile async stream unknown exception";
          }
          stream->close();
        }).detach();
      });

      if (!mimeType.empty()) {
        resp->setContentTypeString(mimeType);
      } else {
        resp->setContentTypeCode(drogon::CT_APPLICATION_OCTET_STREAM);
      }
      const auto isDownloadQuery = req->getParameter("download") == "1" || req->getParameter("download") == "true";
      const auto dispositionType = isDownloadQuery ? "attachment" : "inline";
      resp->addHeader("Content-Disposition", std::string(dispositionType) + "; filename=\"" + fileName + "\"");
      callback(resp);
      return;
    }

    std::filesystem::path fullPath;
    if (!trashIdStr.empty()) {
      std::int64_t trashId = std::stoll(trashIdStr);
      const char *sql = "SELECT owner_user_id FROM trash WHERE id = ?";
      auto stmtGuard = server::ctx().database->getStatement(sql);
      auto *stmt = stmtGuard.get();
      sqlite3_bind_int64(stmt, 1, trashId);
      if (sqlite3_step(stmt) != SQLITE_ROW) {
        callback(jsonError(drogon::k404NotFound, "Trash item not found"));
        return;
      }
      std::int64_t ownerId = sqlite3_column_int64(stmt, 0);
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

    std::error_code ec;
    const auto st = std::filesystem::status(fullPath, ec);
    if (ec || !std::filesystem::exists(st) || std::filesystem::is_directory(st)) {
      callback(jsonError(drogon::k404NotFound, "File not found"));
      return;
    }

    auto resp = drogon::HttpResponse::newFileResponse(fullPath.string());
    callback(resp);
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::downloadZip(const drogon::HttpRequestPtr &req,
                                std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  try {
    const auto scopeOpt = services::parseScope(req->getParameter("scope"));
    if (!scopeOpt.has_value()) {
      callback(jsonError(drogon::k400BadRequest, "scope must be private or shared"));
      return;
    }

    const auto rawPath = req->getParameter("path");
    const auto targetRelPath = services::FileIndexService::normalizeRelPath(rawPath);
    const auto scopeStr = services::FileIndexService::scopeToString(*scopeOpt);
    const auto queryOwnerUserId = (*scopeOpt == services::StorageScope::Shared) ? 0 : userId;

    std::string zipFilename = "Files.zip";
    if (!targetRelPath.empty()) {
      const auto folderName = std::filesystem::path(targetRelPath).filename().string();
      zipFilename = (folderName.empty() ? "Folder" : folderName) + ".zip";
    } else if (*scopeOpt == services::StorageScope::Shared) {
      zipFilename = "SharedFiles.zip";
    }

    const auto tmpZipPath = std::filesystem::temp_directory_path() /
                            ("crowley_user_zip_" + std::to_string(userId) + "_" +
                             std::to_string(std::chrono::system_clock::now().time_since_epoch().count()) + ".zip");

    utils::ZipWriter zipWriter;
    bool hasEntries = false;

    const bool hashFiles = server::ctx().config.hashFiles;
    if (hashFiles) {
      db::Database::StatementGuard stmtGuard;
      if (targetRelPath.empty()) {
        const char *sql = "SELECT rel_path, sha256 FROM file_index WHERE owner_user_id = ? AND scope = ? AND type != 'directory' AND is_deleted = 0";
        stmtGuard = server::ctx().database->getStatement(sql);
        sqlite3_bind_int64(stmtGuard.get(), 1, queryOwnerUserId);
        sqlite3_bind_text(stmtGuard.get(), 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
      } else {
        const char *sql = "SELECT rel_path, sha256 FROM file_index WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR parent_path = ? OR parent_path LIKE ?) AND type != 'directory' AND is_deleted = 0";
        stmtGuard = server::ctx().database->getStatement(sql);
        sqlite3_bind_int64(stmtGuard.get(), 1, queryOwnerUserId);
        sqlite3_bind_text(stmtGuard.get(), 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmtGuard.get(), 3, targetRelPath.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmtGuard.get(), 4, targetRelPath.c_str(), -1, SQLITE_TRANSIENT);
        const auto pattern = targetRelPath + "/%";
        sqlite3_bind_text(stmtGuard.get(), 5, pattern.c_str(), -1, SQLITE_TRANSIENT);
      }

      auto *stmt = stmtGuard.get();
      if (stmt != nullptr) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
          const auto relPathRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
          const auto shaRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
          if (!relPathRaw || !shaRaw) continue;

          std::string relPath = relPathRaw;
          std::string sha256 = shaRaw;

          std::string fileSubRel = relPath;
          if (!targetRelPath.empty() && fileSubRel.size() >= targetRelPath.size()) {
            fileSubRel = fileSubRel.substr(targetRelPath.size());
            if (!fileSubRel.empty() && fileSubRel[0] == '/') fileSubRel.erase(0, 1);
          }

          const auto physicalPath = std::filesystem::path(server::ctx().config.storageRoot) / "data" / sha256;
          if (!std::filesystem::exists(physicalPath)) continue;

          std::ifstream in(physicalPath, std::ios::binary);
          if (!in) continue;
          std::string content((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
          in.close();

          if (!server::ctx().config.encryptionKey.empty()) {
            try {
              content = utils::decryptAes256(content, server::ctx().config.encryptionKey);
            } catch (...) {
              continue;
            }
          }

          if (zipWriter.addFile(fileSubRel, content)) {
            hasEntries = true;
          }
        }
      }
    } else {
      const auto physicalPath = server::ctx().fileService->resolvePath(userId, role, *scopeOpt, targetRelPath, false);
      if (std::filesystem::exists(physicalPath) && std::filesystem::is_directory(physicalPath)) {
        for (const auto &entry : std::filesystem::recursive_directory_iterator(physicalPath)) {
          if (!entry.is_regular_file()) continue;
          auto rel = std::filesystem::relative(entry.path(), physicalPath).generic_string();
          if (zipWriter.addFileFromDisk(rel, entry.path())) {
            hasEntries = true;
          }
        }
      }
    }

    if (!zipWriter.writeToFile(tmpZipPath) || !std::filesystem::exists(tmpZipPath)) {
      callback(jsonError(drogon::k500InternalServerError, "Failed to create ZIP archive"));
      return;
    }

    auto resp = drogon::HttpResponse::newFileResponse(tmpZipPath.string());
    resp->addHeader("Content-Disposition", "attachment; filename=\"" + zipFilename + "\"");

    auto helper = std::make_shared<FileZipCleanupHelper>(tmpZipPath, resp);
    drogon::HttpResponsePtr aliasedResp(helper, resp.get());
    callback(aliasedResp);
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::uploadStatus(const drogon::HttpRequestPtr &req,
                                  std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  try {
    const auto relPath = services::FileIndexService::normalizeRelPath(req->getParameter("path"));
    const auto tmpDir = std::filesystem::path(server::ctx().config.storageRoot) / ".tmp_uploads";
    const auto tmpPath = tmpDir / (std::to_string(userId) + "_" + utils::sha256Hex(relPath));

    std::error_code ec;
    const auto sz = std::filesystem::file_size(tmpPath, ec);
    std::size_t bytesReceived = ec ? 0 : static_cast<std::size_t>(sz);

    Json::Value body;
    body["ok"] = true;
    body["bytes_received"] = static_cast<Json::UInt64>(bytesReceived);
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
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

  if (req->contentType() == drogon::CT_MULTIPART_FORM_DATA) {
    drogon::MultiPartParser parser;
    if (parser.parse(req) != 0) {
      callback(jsonError(drogon::k400BadRequest, "Failed to parse multipart request"));
      return;
    }

    const auto &files = parser.getFiles();
    if (files.empty()) {
      callback(jsonError(drogon::k400BadRequest, "No files found in multipart payload"));
      return;
    }

    const auto targetPath = services::FileIndexService::normalizeRelPath(req->getParameter("path"));
    const bool hashFiles = server::ctx().config.hashFiles;
    Json::Value body;
    body["ok"] = true;
    body["uploaded"] = Json::arrayValue;

    for (const auto &file : files) {
      std::string fileName = file.getFileName();
      if (fileName.empty()) continue;

      std::string relPath = targetPath.empty() ? fileName : (targetPath + "/" + fileName);
      relPath = services::FileIndexService::normalizeRelPath(relPath);

      std::string_view fileData = file.fileData();
      std::size_t fileLength = file.fileLength();

      try {
        if (hashFiles) {
          std::string plainData(fileData.data(), fileLength);
          std::string plainSha256 = utils::sha256Hex(plainData);
          std::string cipherText = utils::encryptAes256(plainData, server::ctx().config.encryptionKey);

          const auto dataDir = std::filesystem::path(server::ctx().config.storageRoot) / "data";
          std::filesystem::create_directories(dataDir);
          const auto physicalPath = dataDir / plainSha256;

          std::ofstream out(physicalPath, std::ios::binary | std::ios::trunc);
          out.write(cipherText.data(), cipherText.size());
          out.close();

          const auto now = std::chrono::duration_cast<std::chrono::milliseconds>(
                               std::chrono::system_clock::now().time_since_epoch())
                               .count();
          const auto type = server::ctx().fileService->classifyType(fileName);
          const auto mimeType = server::ctx().fileService->mimeTypeFor(fileName);
          const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
          const auto uploaderUserId = *scope == services::StorageScope::Shared ? userId : ownerUserId;

          server::ctx().fileIndexService->upsertFileExplicit(
              ownerUserId, *scope, relPath, fileName, fileLength, now, type, mimeType, uploaderUserId, plainSha256);
        } else {
          const auto target = server::ctx().fileService->resolvePath(userId, role, *scope, relPath, true);
          std::filesystem::create_directories(target.parent_path());
          const auto tmp = target.parent_path() / (target.filename().string() + ".tmp");

          std::ofstream out(tmp, std::ios::binary | std::ios::trunc);
          out.write(fileData.data(), static_cast<std::streamsize>(fileLength));
          out.close();

          utils::portableRename(tmp, target);
          const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
          const auto uploaderUserId = *scope == services::StorageScope::Shared ? userId : ownerUserId;
          server::ctx().fileIndexService->upsertFile(
              ownerUserId, *scope, relPath, target, uploaderUserId);
        }

        Json::Value fileObj;
        fileObj["name"] = fileName;
        fileObj["path"] = relPath;
        fileObj["size"] = static_cast<Json::UInt64>(fileLength);
        fileObj["ok"] = true;
        body["uploaded"].append(fileObj);
      } catch (const std::exception &e) {
        Json::Value fileObj;
        fileObj["name"] = fileName;
        fileObj["path"] = relPath;
        fileObj["ok"] = false;
        fileObj["error"] = e.what();
        body["uploaded"].append(fileObj);
      }
    }

    callback(drogon::HttpResponse::newHttpJsonResponse(body));
    return;
  }

  const auto offsetStr = req->getParameter("offset");
  const auto totalStr = req->getParameter("total");
  const auto isLastStr = req->getParameter("is_last");

  if (!offsetStr.empty()) {
    try {
      std::size_t offset = std::stoull(offsetStr);
      std::size_t total = totalStr.empty() ? 0 : std::stoull(totalStr);
      bool isLast = isLastStr == "true";

      const auto relPath = services::FileIndexService::normalizeRelPath(req->getParameter("path"));
      const auto tmpDir = std::filesystem::path(server::ctx().config.storageRoot) / ".tmp_uploads";
      std::filesystem::create_directories(tmpDir);
      const auto tmpPath = tmpDir / (std::to_string(userId) + "_" + utils::sha256Hex(relPath));

      auto mode = (offset == 0) ? (std::ios::binary | std::ios::trunc) : (std::ios::binary | std::ios::app);
      std::ofstream out(tmpPath, mode);
      if (req->bodyLength() > 0) {
        out.write(req->bodyData(), static_cast<std::streamsize>(req->bodyLength()));
      }
      out.close();

      const auto currentSize = std::filesystem::file_size(tmpPath);
      const bool completed = (total > 0 && currentSize >= total) || isLast;

      if (completed) {
        const bool hashFiles = server::ctx().config.hashFiles;
        if (hashFiles) {
          const auto fileSize = currentSize;
          const auto dataDir = std::filesystem::path(server::ctx().config.storageRoot) / "data";
          std::filesystem::create_directories(dataDir);

          const auto tempEncPath = dataDir / ("tmp_" + std::to_string(userId) + "_" + utils::randomTokenHex(16));
          std::string plainSha256;
          if (!utils::encryptFileAes256(tmpPath, tempEncPath, server::ctx().config.encryptionKey, plainSha256)) {
            std::filesystem::remove(tempEncPath);
            callback(jsonError(drogon::k500InternalServerError, "Failed to encrypt file"));
            return;
          }

          const auto physicalPath = dataDir / plainSha256;
          utils::portableRename(tempEncPath, physicalPath);

          const auto fileName = std::filesystem::path(relPath).filename().string();
          const auto now = std::chrono::duration_cast<std::chrono::milliseconds>(
                               std::chrono::system_clock::now().time_since_epoch())
                               .count();
          const auto type = server::ctx().fileService->classifyType(fileName);
          const auto mimeType = server::ctx().fileService->mimeTypeFor(fileName);
          const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
          const auto uploaderUserId = *scope == services::StorageScope::Shared ? userId : ownerUserId;

          server::ctx().fileIndexService->upsertFileExplicit(
              ownerUserId, *scope, relPath, fileName, fileSize, now, type, mimeType, uploaderUserId, plainSha256);
        } else {
          const auto target = server::ctx().fileService->resolvePath(userId, role, *scope, req->getParameter("path"), true);
          std::filesystem::create_directories(target.parent_path());
          utils::portableRename(tmpPath, target);

          const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
          const auto uploaderUserId = *scope == services::StorageScope::Shared ? userId : ownerUserId;
          server::ctx().fileIndexService->upsertFile(
              ownerUserId, *scope, relPath, target, uploaderUserId);
        }

        std::error_code ec;
        std::filesystem::remove(tmpPath, ec);

        Json::Value body;
        body["ok"] = true;
        body["completed"] = true;
        body["bytes_received"] = static_cast<Json::UInt64>(currentSize);
        callback(drogon::HttpResponse::newHttpJsonResponse(body));
        return;
      } else {
        Json::Value body;
        body["ok"] = true;
        body["completed"] = false;
        body["bytes_received"] = static_cast<Json::UInt64>(currentSize);
        callback(drogon::HttpResponse::newHttpJsonResponse(body));
        return;
      }
    } catch (const std::exception &e) {
      callback(jsonError(drogon::k400BadRequest, e.what()));
      return;
    }
  }

  if (req->bodyLength() > static_cast<size_t>(server::ctx().config.uploadLimitBytes)) {
    callback(jsonError(drogon::k413RequestEntityTooLarge, "Upload exceeds limit"));
    return;
  }

  try {
    const bool hashFiles = server::ctx().config.hashFiles;
    if (hashFiles) {
      std::string plainData(req->bodyData(), req->bodyLength());
      std::string plainSha256 = utils::sha256Hex(plainData);
      std::string cipherText = utils::encryptAes256(plainData, server::ctx().config.encryptionKey);

      const auto dataDir = std::filesystem::path(server::ctx().config.storageRoot) / "data";
      std::filesystem::create_directories(dataDir);
      const auto physicalPath = dataDir / plainSha256;

      std::ofstream out(physicalPath, std::ios::binary | std::ios::trunc);
      out.write(cipherText.data(), cipherText.size());
      out.close();

      const auto relPath = services::FileIndexService::normalizeRelPath(req->getParameter("path"));
      const auto fileName = std::filesystem::path(relPath).filename().string();
      const auto now = std::chrono::duration_cast<std::chrono::milliseconds>(
                           std::chrono::system_clock::now().time_since_epoch())
                           .count();
      const auto type = server::ctx().fileService->classifyType(fileName);
      const auto mimeType = server::ctx().fileService->mimeTypeFor(fileName);
      const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
      const auto uploaderUserId = *scope == services::StorageScope::Shared ? userId : ownerUserId;

      server::ctx().fileIndexService->upsertFileExplicit(
          ownerUserId, *scope, relPath, fileName, req->bodyLength(), now, type, mimeType, uploaderUserId, plainSha256);
    } else {
      const auto target = server::ctx().fileService->resolvePath(userId, role, *scope, req->getParameter("path"), true);
      std::filesystem::create_directories(target.parent_path());
      const auto tmp = target.parent_path() / (target.filename().string() + ".tmp");

      std::ofstream out(tmp, std::ios::binary | std::ios::trunc);
      out.write(req->bodyData(), static_cast<std::streamsize>(req->bodyLength()));
      out.close();

      utils::portableRename(tmp, target);
      const auto relPath = services::FileIndexService::normalizeRelPath(req->getParameter("path"));
      const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
      const auto uploaderUserId = *scope == services::StorageScope::Shared ? userId : ownerUserId;
      server::ctx().fileIndexService->upsertFile(
          ownerUserId, *scope, relPath, target, uploaderUserId);
    }

    callback(jsonOk());
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
    callback(jsonOk());
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
    if (server::ctx().config.hashFiles) {
      const auto relPath = services::FileIndexService::normalizeRelPath(pathRaw);
      const auto fileName = std::filesystem::path(relPath).filename().string();
      const auto now = std::chrono::duration_cast<std::chrono::milliseconds>(
                           std::chrono::system_clock::now().time_since_epoch())
                           .count();
      const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
      const auto uploaderUserId = *scope == services::StorageScope::Shared ? userId : ownerUserId;
      server::ctx().fileIndexService->upsertFileExplicit(
          ownerUserId, *scope, relPath, fileName, 0, now, "directory", "inode/directory", uploaderUserId, "");
    } else {
      const auto target = server::ctx().fileService->resolvePath(userId, role, *scope, pathRaw, true);
      std::filesystem::create_directories(target);
    }

    callback(jsonOk());
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::moveFile(const drogon::HttpRequestPtr &req,
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

  const auto src = services::FileIndexService::normalizeRelPath(req->getParameter("src"));
  const auto dest = services::FileIndexService::normalizeRelPath(req->getParameter("dest"));

  if (src.empty() || dest.empty()) {
    callback(jsonError(drogon::k400BadRequest, "src and dest must be specified"));
    return;
  }

  if (src == dest) {
    Json::Value body;
    body["ok"] = true;
    body["message"] = "File/folder already has this name";
    callback(drogon::HttpResponse::newHttpJsonResponse(body));
    return;
  }

  const auto ownerUserId = *scope == services::StorageScope::Shared ? 0 : userId;
  const auto scopeStr = services::FileIndexService::scopeToString(*scope);

  try {
    const bool hashFiles = server::ctx().config.hashFiles;
    if (hashFiles) {
      // 1. Check if source exists in index
      bool exists = false;
      {
        const std::string prefixPattern = src + "/%";
        auto stmtGuard = server::ctx().database->getStatement(
            "SELECT 1 FROM file_index WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR rel_path LIKE ?) AND is_deleted = 0 LIMIT 1");
        sqlite3_bind_int64(stmtGuard.get(), 1, ownerUserId);
        sqlite3_bind_text(stmtGuard.get(), 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmtGuard.get(), 3, src.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmtGuard.get(), 4, prefixPattern.c_str(), -1, SQLITE_TRANSIENT);
        exists = (sqlite3_step(stmtGuard.get()) == SQLITE_ROW);
      }
      if (!exists) {
        callback(jsonError(drogon::k404NotFound, "Source file/folder not found"));
        return;
      }

      // Check if destination path already exists
      bool destExists = false;
      {
        const std::string prefixPattern = dest + "/%";
        auto stmtGuard = server::ctx().database->getStatement(
            "SELECT 1 FROM file_index WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR rel_path LIKE ?) AND is_deleted = 0 LIMIT 1");
        sqlite3_bind_int64(stmtGuard.get(), 1, ownerUserId);
        sqlite3_bind_text(stmtGuard.get(), 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmtGuard.get(), 3, dest.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmtGuard.get(), 4, prefixPattern.c_str(), -1, SQLITE_TRANSIENT);
        destExists = (sqlite3_step(stmtGuard.get()) == SQLITE_ROW);
      }
      if (destExists) {
        callback(jsonError(drogon::k409Conflict, "A file or folder with that name already exists"));
        return;
      }

      // 2. Perform database update for renaming/moving the index entry and its descendants
      const auto newName = std::filesystem::path(dest).filename().string();
      const auto destParent = services::FileIndexService::normalizeRelPath(std::filesystem::path(dest).parent_path().generic_string());
      const int srcLen = static_cast<int>(src.length());
      
      auto stmtGuard = server::ctx().database->getStatement(
          "UPDATE file_index SET "
          "  rel_path = ?1 || substr(rel_path, ?2), "
          "  parent_path = CASE WHEN rel_path = ?3 THEN ?4 ELSE ?1 || substr(parent_path, ?2) END, "
          "  name = CASE WHEN rel_path = ?3 THEN ?5 ELSE name END "
          "WHERE owner_user_id = ?6 AND scope = ?7 AND (rel_path = ?8 OR rel_path LIKE ?9) AND is_deleted = 0");
          
      sqlite3_bind_text(stmtGuard.get(), 1, dest.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_int(stmtGuard.get(), 2, srcLen + 1);
      sqlite3_bind_text(stmtGuard.get(), 3, src.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(stmtGuard.get(), 4, destParent.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(stmtGuard.get(), 5, newName.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_int64(stmtGuard.get(), 6, ownerUserId);
      sqlite3_bind_text(stmtGuard.get(), 7, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(stmtGuard.get(), 8, src.c_str(), -1, SQLITE_TRANSIENT);
      std::string prefixPattern = src + "/%";
      sqlite3_bind_text(stmtGuard.get(), 9, prefixPattern.c_str(), -1, SQLITE_TRANSIENT);
      
      if (sqlite3_step(stmtGuard.get()) != SQLITE_DONE) {
        callback(jsonError(drogon::k500InternalServerError, "Failed to update file index"));
        return;
      }
    } else {
      // Direct filesystem mode
      const auto srcPath = server::ctx().fileService->resolvePath(userId, role, *scope, src, false);
      const auto destPath = server::ctx().fileService->resolvePath(userId, role, *scope, dest, false);
      
      if (!std::filesystem::exists(srcPath)) {
        callback(jsonError(drogon::k404NotFound, "Source path does not exist"));
        return;
      }

      if (std::filesystem::exists(destPath)) {
        callback(jsonError(drogon::k409Conflict, "A file or folder with that name already exists"));
        return;
      }
      
      std::filesystem::create_directories(destPath.parent_path());
      std::error_code ec;
      utils::portableRename(srcPath, destPath, ec);
      if (ec) {
        callback(jsonError(drogon::k500InternalServerError, "Failed to rename file/folder on disk: " + ec.message()));
        return;
      }
      
      // Update DB indexes for filesystem rename
      // Rebuild index for dest path (and children)
      server::ctx().fileIndexService->rebuildIndex(ownerUserId, *scope, destPath);
      // Mark old src index paths as deleted
      server::ctx().fileIndexService->markDeleted(ownerUserId, *scope, src);
      server::ctx().fileIndexService->markDeletedPrefix(ownerUserId, *scope, src);
    }
    
    Json::Value body;
    body["ok"] = true;
    body["message"] = "File/folder moved successfully";
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
    const auto relPath = services::FileIndexService::normalizeRelPath(req->getParameter("path"));
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

    callback(jsonOk());
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
    const auto acceptHeader = req->getHeader("Accept");
    if (acceptHeader.find("application/x-protobuf") != std::string::npos) {
      server::proto::DirResponse protoResponse;
      for (const auto &entry : entries) {
        auto *protoEntry = protoResponse.add_entries();
        protoEntry->set_id(entry.id);
        protoEntry->set_name(entry.name);
        protoEntry->set_path(entry.originalPath);
        protoEntry->set_is_dir(entry.isDir);
        protoEntry->set_size(entry.size);
        protoEntry->set_modified_at(entry.deletedAt);
        protoEntry->set_type(entry.isDir ? "directory" : "file");
        protoEntry->set_mime_type(entry.isDir ? "inode/directory" : "application/octet-stream");
        if (!entry.isDir) {
          protoEntry->set_thumbnail_url("/api/thumb?trash_id=" + std::to_string(entry.id) + "&s=256");
        }
      }
      auto resp = drogon::HttpResponse::newHttpResponse();
      resp->setBody(protoResponse.SerializeAsString());
      resp->setContentTypeCode(drogon::ContentType::CT_CUSTOM);
      resp->setContentTypeString("application/x-protobuf");
      callback(resp);
    } else {
      Json::Value body;
      body["entries"] = Json::arrayValue;
      for (const auto &entry : entries) {
        body["entries"].append(formatTrashEntryJson(entry));
      }
      callback(drogon::HttpResponse::newHttpJsonResponse(body));
    }
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

void FileController::checkRestoreConflicts(const drogon::HttpRequestPtr &req,
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
    const auto conflicts = server::ctx().trashService->checkRestoreConflicts(userId, ids);
    Json::Value body;
    body["ok"] = true;
    body["has_conflicts"] = !conflicts.empty();
    body["conflicts"] = Json::arrayValue;
    for (const auto &c : conflicts) {
      Json::Value item;
      item["id"] = static_cast<Json::Int64>(c.id);
      item["name"] = c.name;
      item["original_path"] = c.originalPath;
      item["existing_size"] = static_cast<Json::UInt64>(c.existingSize);
      item["existing_modified"] = static_cast<Json::Int64>(c.existingModified);
      item["trash_size"] = static_cast<Json::UInt64>(c.trashSize);
      item["trash_deleted_at"] = static_cast<Json::Int64>(c.trashDeletedAt);
      body["conflicts"].append(item);
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

  bool overwrite = false;
  if (json->isMember("overwrite")) {
    overwrite = (*json)["overwrite"].asBool();
  }

  try {
    server::ctx().trashService->restoreFromTrash(userId, ids, overwrite);
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

void FileController::getAccountStats(const drogon::HttpRequestPtr &req,
                                     std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::int64_t userId;
  std::string role;
  if (!getAuth(req, userId, role)) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  try {
    const auto stats = server::ctx().fileIndexService->getUserStats(userId);
    Json::Value body;
    body["total_size"] = static_cast<Json::UInt64>(stats.totalSize);
    body["total_count"] = static_cast<Json::Int64>(stats.totalCount);
    body["used_bytes"] = static_cast<Json::UInt64>(stats.totalSize);
    body["limit_bytes"] = Json::nullValue;
    body["photo_count"] = static_cast<Json::Int64>(stats.photoCount);
    body["photo_size"] = static_cast<Json::UInt64>(stats.photoSize);
    body["video_count"] = static_cast<Json::Int64>(stats.videoCount);
    body["video_size"] = static_cast<Json::UInt64>(stats.videoSize);
    body["audio_count"] = static_cast<Json::Int64>(stats.audioCount);
    body["audio_size"] = static_cast<Json::UInt64>(stats.audioSize);
    body["document_count"] = static_cast<Json::Int64>(stats.documentCount);
    body["document_size"] = static_cast<Json::UInt64>(stats.documentSize);
    body["other_count"] = static_cast<Json::Int64>(stats.otherCount);
    body["other_size"] = static_cast<Json::UInt64>(stats.otherSize);
    body["shared_count"] = static_cast<Json::Int64>(stats.sharedCount);
    body["shared_size"] = static_cast<Json::UInt64>(stats.sharedSize);

    callback(drogon::HttpResponse::newHttpJsonResponse(body));
  } catch (const std::exception &e) {
    callback(jsonError(drogon::k400BadRequest, e.what()));
  }
}

}  // namespace server::controllers
