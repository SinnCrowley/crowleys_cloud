// FileController implementation for Drogon HTTP endpoints.
// Path Resolution & Security: Delegates canonical path verification and traversal checks
// to FileService::resolvePath and FileIndexService::normalizeRelPath, guaranteeing scope isolation.
// Statement Caching: Uses Database::getStatement RAII StatementGuards for thread-safe query execution.
// Serialization: Uses centralized formatters (formatDirEntryJson, formatTrashEntryJson, jsonOk) for DTO creation.

#include "server/controllers/FileController.hpp"

#include "server/AppContext.hpp"
#include "server/utils/Crypto.hpp"
#include "server/utils/HttpHelpers.hpp"

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

#include <spawn.h>
#include <sys/wait.h>
#include <trantor/utils/Logger.h>
#include <unistd.h>

extern "C" char **environ;

namespace server::controllers {
using server::utils::jsonError;
using server::utils::jsonOk;
using server::utils::getAuth;

namespace {

Json::Value formatDirEntryJson(const services::IndexedDirEntry &entry, const std::string &scopeRaw) {
  Json::Value v;
  v["name"] = entry.name;
  v["size"] = static_cast<Json::UInt64>(entry.size);
  v["is_dir"] = entry.isDir;
  v["modified_at"] = static_cast<Json::Int64>(entry.modifiedAt);
  v["type"] = entry.type;
  v["mime_type"] = entry.mimeType;
  v["path"] = entry.path;
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

bool runProcess(const std::vector<std::string> &args) {
  if (args.empty()) return false;
  std::vector<char *> argv;
  argv.reserve(args.size() + 1);
  for (const auto &arg : args) {
    argv.push_back(const_cast<char *>(arg.c_str()));
  }
  argv.push_back(nullptr);

  pid_t pid;
  int status = posix_spawnp(&pid, argv[0], nullptr, nullptr, argv.data(), environ);
  if (status != 0) {
    return false;
  }
  while (waitpid(pid, &status, 0) == -1) {
    if (errno != EINTR) {
      return false;
    }
  }
  return WIFEXITED(status) && (WEXITSTATUS(status) == 0);
}
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
        .includeDirs = !typedView && !recursiveSearch,
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
      body["entries"].append(formatDirEntryJson(entry, scopeRaw));
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
        const char *idxSql = "SELECT sha256 FROM file_index WHERE owner_user_id = ? AND rel_path = ? AND is_deleted = 1 LIMIT 1";
        auto idxGuard = server::ctx().database->getStatement(idxSql);
        auto *idxStmt = idxGuard.get();
        sqlite3_bind_int64(idxStmt, 1, userId);
        sqlite3_bind_text(idxStmt, 2, origPath.c_str(), -1, SQLITE_TRANSIENT);
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
      virtualPath = rawPath;

      std::int64_t fileOwnerId = userId;
      if (*scope == services::StorageScope::Shared) {
        auto ownerId = server::ctx().fileIndexService->getSharedFileOwner(rawPath);
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
        sqlite3_bind_text(idxStmt, 3, rawPath.c_str(), -1, SQLITE_TRANSIENT);
        if (sqlite3_step(idxStmt) == SQLITE_ROW) {
          const auto shaValRaw = reinterpret_cast<const char *>(sqlite3_column_text(idxStmt, 0));
          if (shaValRaw) sha256Val = shaValRaw;
        }
        source = std::filesystem::path(server::ctx().config.storageRoot) / "data" / sha256Val;
      } else {
        if (*scope == services::StorageScope::Shared) {
          source = server::ctx().fileService->resolvePath(fileOwnerId, role, services::StorageScope::Private, rawPath, false);
        } else {
          source = server::ctx().fileService->resolvePath(userId, role, *scope, rawPath, false);
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
    const auto thumbPath = fileType == "video"
        ? std::filesystem::path(thumbPathBase.string() + ".jpg")
        : thumbPathBase;

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

        std::int64_t fileOwnerId = userId;
        if (*scope == services::StorageScope::Shared) {
          auto ownerId = server::ctx().fileIndexService->getSharedFileOwner(pathParam);
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
        sqlite3_bind_text(stmt, 3, pathParam.c_str(), -1, SQLITE_TRANSIENT);

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
      resp->setContentTypeCode(drogon::CT_APPLICATION_OCTET_STREAM);
      resp->addHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
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
          std::filesystem::rename(tempEncPath, physicalPath);

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
          std::filesystem::rename(tmpPath, target);

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
      const auto tmp = target.string() + ".tmp";

      std::ofstream out(tmp, std::ios::binary | std::ios::trunc);
      out.write(req->bodyData(), static_cast<std::streamsize>(req->bodyLength()));
      out.close();

      std::filesystem::rename(tmp, target);
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
    Json::Value body;
    body["entries"] = Json::arrayValue;
    for (const auto &entry : entries) {
      body["entries"].append(formatTrashEntryJson(entry));
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
