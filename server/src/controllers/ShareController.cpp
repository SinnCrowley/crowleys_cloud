// ShareController implementation for public resource sharing endpoints.
// Token & Path Resolution: Resolves share link tokens and validates target subpaths.
// Statement Caching: Uses Database::getStatement RAII StatementGuards for thread-safe query execution.
// Serialization: Uses centralized Json DTO formatters for consistent API responses.

#include "server/controllers/ShareController.hpp"

#include "server/AppContext.hpp"
#include "server/utils/Crypto.hpp"
#include "server/utils/HttpHelpers.hpp"
#include "server/utils/TimeUtils.hpp"
#include "server/utils/ZipWriter.hpp"

#include <chrono>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <sqlite3.h>
#include <trantor/utils/Logger.h>

namespace server::controllers {
using server::utils::jsonError;
using server::utils::nowSeconds;

namespace {

struct ZipCleanupHelper {
  std::filesystem::path path;
  drogon::HttpResponsePtr resp;
  ~ZipCleanupHelper() {
    std::error_code ec;
    std::filesystem::remove(path, ec);
  }
};

struct SharedTargetInfo {
  bool exists{false};
  bool isDir{false};
  std::string name;
  std::string sha256;
  std::string mimeType;
  std::string type;
  std::uintmax_t size{0};
  std::int64_t modifiedAt{0};
  std::filesystem::path physicalPath;
  std::string scopeStr;
  std::int64_t ownerUserId{0};
  services::StorageScope scope;
  std::string shareRelPath;
  std::string targetRelPath;
};

std::optional<SharedTargetInfo> resolveSharedTargetInfo(
    const std::string &token,
    const std::string &subParam,
    std::string &outError) {
  auto share = server::ctx().shareService->resolveShare(token);
  if (!share.has_value()) {
    outError = "Invalid or expired share token";
    return std::nullopt;
  }

  const auto scopeOpt = services::parseScope(share->scope);
  if (!scopeOpt.has_value()) {
    outError = "Invalid share scope";
    return std::nullopt;
  }

  SharedTargetInfo info;
  info.ownerUserId = share->ownerUserId;
  info.scope = *scopeOpt;
  info.scopeStr = services::FileIndexService::scopeToString(info.scope);
  info.shareRelPath = services::FileIndexService::normalizeRelPath(share->relPath);

  const auto cleanSub = std::filesystem::path(subParam).lexically_normal().relative_path().generic_string();
  if (cleanSub.empty() || cleanSub == ".") {
    info.targetRelPath = info.shareRelPath;
  } else if (info.shareRelPath.empty()) {
    info.targetRelPath = cleanSub;
  } else {
    info.targetRelPath = info.shareRelPath + "/" + cleanSub;
  }

  if (!info.shareRelPath.empty()) {
    if (info.targetRelPath.size() < info.shareRelPath.size() ||
        info.targetRelPath.compare(0, info.shareRelPath.size(), info.shareRelPath) != 0) {
      outError = "Invalid path";
      return std::nullopt;
    }
  }

  const bool hashFiles = server::ctx().config.hashFiles;
  if (hashFiles) {
    if (info.targetRelPath.empty()) {
      info.exists = true;
      info.isDir = true;
      info.name = "Shared Folder";
      return info;
    }

    const auto queryOwnerUserId = (info.scope == services::StorageScope::Shared) ? 0 : info.ownerUserId;

    const char *sql = "SELECT type, sha256, mime_type, name, size_bytes, modified_at FROM file_index WHERE owner_user_id = ? AND scope = ? AND rel_path = ? AND is_deleted = 0 LIMIT 1";
    auto stmtGuard = server::ctx().database->getStatement(sql);
    auto *stmt = stmtGuard.get();
    sqlite3_bind_int64(stmt, 1, queryOwnerUserId);
    sqlite3_bind_text(stmt, 2, info.scopeStr.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 3, info.targetRelPath.c_str(), -1, SQLITE_TRANSIENT);

    if (sqlite3_step(stmt) == SQLITE_ROW) {
      const auto typeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
      if (typeRaw) info.type = typeRaw;
      info.isDir = (info.type == "directory");
      const auto shaRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
      if (shaRaw) info.sha256 = shaRaw;
      const auto mimeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
      if (mimeRaw) info.mimeType = mimeRaw;
      const auto nameRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 3));
      if (nameRaw) info.name = nameRaw;
      info.size = static_cast<std::uintmax_t>(sqlite3_column_int64(stmt, 4));
      info.modifiedAt = sqlite3_column_int64(stmt, 5);
      info.exists = true;
      return info;
    }

    const char *dirSql = "SELECT 1 FROM file_index WHERE owner_user_id = ? AND scope = ? AND (parent_path = ? OR parent_path LIKE ?) AND is_deleted = 0 LIMIT 1";
    auto dirGuard = server::ctx().database->getStatement(dirSql);
    auto *dirStmt = dirGuard.get();
    sqlite3_bind_int64(dirStmt, 1, queryOwnerUserId);
    sqlite3_bind_text(dirStmt, 2, info.scopeStr.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(dirStmt, 3, info.targetRelPath.c_str(), -1, SQLITE_TRANSIENT);
    const auto dirPattern = info.targetRelPath + "/%";
    sqlite3_bind_text(dirStmt, 4, dirPattern.c_str(), -1, SQLITE_TRANSIENT);

    if (sqlite3_step(dirStmt) == SQLITE_ROW) {
      info.exists = true;
      info.isDir = true;
      info.type = "directory";
      info.mimeType = "inode/directory";
      info.name = std::filesystem::path(info.targetRelPath).filename().string();
      return info;
    }

    outError = "Shared resource not found";
    return std::nullopt;
  } else {
    try {
      const auto root = server::ctx().fileService->resolvePath(
          info.ownerUserId, "user", info.scope, info.targetRelPath, false);
      if (!std::filesystem::exists(root)) {
        outError = "Shared resource not found";
        return std::nullopt;
      }
      info.exists = true;
      info.isDir = std::filesystem::is_directory(root);
      info.physicalPath = root;
      info.name = root.filename().string();
      info.size = info.isDir ? 0 : std::filesystem::file_size(root);
      info.modifiedAt = std::chrono::duration_cast<std::chrono::seconds>(
                            std::filesystem::last_write_time(root).time_since_epoch()).count();
      info.type = info.isDir ? "directory" : server::ctx().fileService->classifyType(root);
      info.mimeType = info.isDir ? "inode/directory" : server::ctx().fileService->mimeTypeFor(root);
      return info;
    } catch (const std::exception &e) {
      outError = e.what();
      return std::nullopt;
    }
  }
}
}  // namespace

void ShareController::createShare(const drogon::HttpRequestPtr &req,
                                  std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  if (!req->attributes()->find("user_id") || !req->attributes()->find("role")) {
    callback(jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  const auto userId = req->attributes()->get<std::int64_t>("user_id");

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
    const auto relPath = services::FileIndexService::normalizeRelPath((*json)["path"].asString());
    bool exists = false;

    if (server::ctx().config.hashFiles) {
      if (relPath.empty()) {
        exists = true;
      } else {
        const char *sql = "SELECT 1 FROM file_index WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR parent_path = ? OR parent_path LIKE ?) AND is_deleted = 0 LIMIT 1";
        auto stmtGuard = server::ctx().database->getStatement(sql);
        auto *stmt = stmtGuard.get();
        const auto ownerId = *scope == services::StorageScope::Shared ? 0 : userId;
        sqlite3_bind_int64(stmt, 1, ownerId);
        const auto scopeStr = services::FileIndexService::scopeToString(*scope);
        sqlite3_bind_text(stmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 3, relPath.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 4, relPath.c_str(), -1, SQLITE_TRANSIENT);
        const auto pattern = relPath + "/%";
        sqlite3_bind_text(stmt, 5, pattern.c_str(), -1, SQLITE_TRANSIENT);
        if (sqlite3_step(stmt) == SQLITE_ROW) {
          exists = true;
        }
      }
    } else {
      const auto resolved = server::ctx().fileService->resolvePath(userId, "user", *scope, (*json)["path"].asString(), false);
      exists = std::filesystem::exists(resolved);
    }

    if (!exists) {
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

void ShareController::getShareInfo(const drogon::HttpRequestPtr &req,
                                   std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                                   const std::string &token) {
  std::string error;
  const auto subParam = req->getParameter("p");
  const auto targetOpt = resolveSharedTargetInfo(token, subParam, error);

  if (!targetOpt.has_value()) {
    callback(jsonError(drogon::k404NotFound, error.empty() ? "Resource not found" : error));
    return;
  }

  const auto target = *targetOpt;
  const bool hashFiles = server::ctx().config.hashFiles;

  Json::Value body;
  body["token"] = token;
  body["rootName"] = target.name.empty() ? "Shared Folder" : target.name;
  body["isFolder"] = target.isDir;

  if (target.isDir) {
    std::string currentRel;
    if (target.targetRelPath.size() >= target.shareRelPath.size()) {
      currentRel = target.targetRelPath.substr(target.shareRelPath.size());
      if (!currentRel.empty() && currentRel[0] == '/') currentRel.erase(0, 1);
    }
    body["currentRelPath"] = currentRel;

    Json::Value filesJson(Json::arrayValue);

    if (hashFiles) {
      const auto queryOwnerUserId = (target.scope == services::StorageScope::Shared) ? 0 : target.ownerUserId;
      const auto entries = server::ctx().fileIndexService->listDirectory({
          .ownerUserId = queryOwnerUserId,
          .scope = target.scope,
          .currentPath = target.targetRelPath,
          .includeDirs = true,
          .recursiveFiles = false,
      });

      for (const auto &entry : entries) {
        Json::Value fileObj;
        fileObj["name"] = entry.name;

        std::string entryRel = entry.path;
        if (entryRel.size() >= target.shareRelPath.size() && !target.shareRelPath.empty()) {
          entryRel = entryRel.substr(target.shareRelPath.size());
          if (!entryRel.empty() && entryRel[0] == '/') entryRel.erase(0, 1);
        }
        fileObj["relPath"] = entryRel;
        fileObj["isDir"] = entry.isDir;
        fileObj["size"] = Json::Value::UInt64(entry.size);
        fileObj["modifiedAt"] = Json::Value::Int64(entry.modifiedAt);
        fileObj["type"] = entry.type;
        fileObj["mimeType"] = entry.mimeType;
        filesJson.append(fileObj);
      }
    } else {
      const auto entries = server::ctx().fileService->listDirectory(target.physicalPath);
      for (const auto &entry : entries) {
        Json::Value fileObj;
        fileObj["name"] = entry.name;
        std::string entryRel = currentRel.empty() ? entry.name : (currentRel + "/" + entry.name);
        fileObj["relPath"] = entryRel;
        fileObj["isDir"] = entry.isDir;
        fileObj["size"] = Json::Value::UInt64(entry.size);
        fileObj["modifiedAt"] = Json::Value::Int64(entry.modifiedAt);
        fileObj["type"] = entry.type;
        fileObj["mimeType"] = entry.mimeType;
        filesJson.append(fileObj);
      }
    }
    body["files"] = filesJson;
  } else {
    body["currentRelPath"] = "";
    Json::Value filesJson(Json::arrayValue);
    Json::Value fileObj;
    fileObj["name"] = target.name;
    fileObj["relPath"] = "";
    fileObj["isDir"] = false;
    fileObj["size"] = Json::Value::UInt64(target.size);
    fileObj["modifiedAt"] = Json::Value::Int64(target.modifiedAt);
    fileObj["type"] = target.type;
    fileObj["mimeType"] = target.mimeType;
    filesJson.append(fileObj);
    body["files"] = filesJson;
  }

  callback(drogon::HttpResponse::newHttpJsonResponse(body));
}

void ShareController::sharePage(const drogon::HttpRequestPtr &req,
                                std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                                const std::string &token) {
  auto share = server::ctx().shareService->resolveShare(token);
  if (!share.has_value()) {
    callback(jsonError(drogon::k404NotFound, "Invalid or expired share token"));
    return;
  }

  const std::string shareHtmlPath = "./public/share.html";
  if (std::filesystem::exists(shareHtmlPath)) {
    callback(drogon::HttpResponse::newFileResponse(shareHtmlPath));
  } else {
    callback(jsonError(drogon::k404NotFound, "Share UI template not found"));
  }
}

void ShareController::rawFile(const drogon::HttpRequestPtr &req,
                             std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                             const std::string &token) {
  std::string error;
  const auto subParam = req->getParameter("p");
  const auto targetOpt = resolveSharedTargetInfo(token, subParam, error);

  if (!targetOpt.has_value()) {
    callback(jsonError(drogon::k404NotFound, error.empty() ? "Resource not found" : error));
    return;
  }

  const auto target = *targetOpt;
  if (target.isDir) {
    callback(jsonError(drogon::k400BadRequest, "Target is a directory"));
    return;
  }

  const auto downloadMode = req->getParameter("download") == "1";
  const auto disposition = downloadMode ? "attachment" : "inline";

  if (server::ctx().config.hashFiles) {
    if (target.sha256.empty()) {
      callback(jsonError(drogon::k404NotFound, "File hash not found"));
      return;
    }

    const auto physicalPath = std::filesystem::path(server::ctx().config.storageRoot) / "data" / target.sha256;
    if (!std::filesystem::exists(physicalPath)) {
      callback(jsonError(drogon::k404NotFound, "Physical file not found"));
      return;
    }

    auto resp = drogon::HttpResponse::newAsyncStreamResponse([physicalPath, key = server::ctx().config.encryptionKey](drogon::ResponseStreamPtr stream) {
      std::thread([stream = std::move(stream), physicalPath, key]() mutable {
        try {
          if (!key.empty()) {
            utils::decryptFileToStream(physicalPath, key, [&stream](const char* data, size_t size) {
              stream->send(std::string(data, size));
            });
          } else {
            std::ifstream in(physicalPath, std::ios::binary);
            if (in) {
              constexpr size_t bufferSize = 65536;
              std::vector<char> buffer(bufferSize);
              while (in.read(buffer.data(), bufferSize) || in.gcount() > 0) {
                stream->send(std::string(buffer.data(), in.gcount()));
              }
            }
          }
        } catch (const std::exception &e) {
          LOG_ERROR << "ShareController::rawFile async stream exception: " << e.what();
        } catch (...) {
          LOG_ERROR << "ShareController::rawFile async stream unknown exception";
        }
        stream->close();
      }).detach();
    });
    resp->setContentTypeString(target.mimeType.empty() ? "application/octet-stream" : target.mimeType);
    resp->addHeader("Content-Disposition", std::string(disposition) + "; filename=\"" + target.name + "\"");
    callback(resp);
  } else {
    auto resp = drogon::HttpResponse::newFileResponse(target.physicalPath.string());
    resp->addHeader("Content-Disposition", std::string(disposition) + "; filename=\"" + target.name + "\"");
    callback(resp);
  }
}

void ShareController::downloadZip(const drogon::HttpRequestPtr &req,
                                std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                                const std::string &token) {
  std::string error;
  const auto subParam = req->getParameter("p");
  const auto targetOpt = resolveSharedTargetInfo(token, subParam, error);

  if (!targetOpt.has_value()) {
    callback(jsonError(drogon::k404NotFound, error.empty() ? "Resource not found" : error));
    return;
  }

  const auto target = *targetOpt;
  if (!target.isDir) {
    callback(jsonError(drogon::k400BadRequest, "Target is not a directory"));
    return;
  }

  const auto zipFilename = (target.name.empty() ? "SharedFolder" : target.name) + ".zip";
  const auto tmpZipPath = std::filesystem::temp_directory_path() /
                          ("crowley_zip_" + token + "_" + std::to_string(std::chrono::system_clock::now().time_since_epoch().count()) + ".zip");

  utils::ZipWriter zipWriter;
  bool hasEntries = false;

  const bool hashFiles = server::ctx().config.hashFiles;
  if (hashFiles) {
    const auto queryOwnerUserId = (target.scope == services::StorageScope::Shared) ? 0 : target.ownerUserId;
    db::Database::StatementGuard stmtGuard;

    if (target.targetRelPath.empty()) {
      const char *sql = "SELECT rel_path, sha256, name FROM file_index WHERE owner_user_id = ? AND scope = ? AND type != 'directory' AND is_deleted = 0";
      stmtGuard = server::ctx().database->getStatement(sql);
      sqlite3_bind_int64(stmtGuard.get(), 1, queryOwnerUserId);
      sqlite3_bind_text(stmtGuard.get(), 2, target.scopeStr.c_str(), -1, SQLITE_TRANSIENT);
    } else {
      const char *sql = "SELECT rel_path, sha256, name FROM file_index WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR parent_path = ? OR parent_path LIKE ?) AND type != 'directory' AND is_deleted = 0";
      stmtGuard = server::ctx().database->getStatement(sql);
      sqlite3_bind_int64(stmtGuard.get(), 1, queryOwnerUserId);
      sqlite3_bind_text(stmtGuard.get(), 2, target.scopeStr.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(stmtGuard.get(), 3, target.targetRelPath.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(stmtGuard.get(), 4, target.targetRelPath.c_str(), -1, SQLITE_TRANSIENT);
      const auto pattern = target.targetRelPath + "/%";
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
        if (!target.targetRelPath.empty() && fileSubRel.size() >= target.targetRelPath.size()) {
          fileSubRel = fileSubRel.substr(target.targetRelPath.size());
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
    if (std::filesystem::exists(target.physicalPath) && std::filesystem::is_directory(target.physicalPath)) {
      for (const auto &entry : std::filesystem::recursive_directory_iterator(target.physicalPath)) {
        if (!entry.is_regular_file()) continue;
        auto rel = std::filesystem::relative(entry.path(), target.physicalPath).generic_string();
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
  
  auto helper = std::make_shared<ZipCleanupHelper>(tmpZipPath, resp);
  drogon::HttpResponsePtr aliasedResp(helper, resp.get());
  callback(aliasedResp);
}

void ShareController::publicAsset(const drogon::HttpRequestPtr &req,
                                   std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                                   const std::string &filename) {
  const std::string cleanName = std::filesystem::path(filename).filename().string();
  const std::string assetPath = "./public/" + cleanName;
  if (std::filesystem::exists(assetPath)) {
    callback(drogon::HttpResponse::newFileResponse(assetPath));
  } else {
    callback(jsonError(drogon::k404NotFound, "Asset not found"));
  }
}

}  // namespace server::controllers
