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

// FileIndexService implementation for database-backed file metadata indexing.
// Scope Isolation: Separates StorageScope::Private and StorageScope::Shared relative virtual paths.
// Hierarchical Directory Engine: Normalizes relative paths, handles parent path indexing, implicit directory synthesis,
// and ancestor sharing state propagation.
// Transaction Safety: Uses RAII TransactionGuard for bulk index resynchronization (rebuildIndex).
// Statement Caching: Uses Database::getStatement RAII StatementGuards for thread-safe query execution.

#include "server/services/FileIndexService.hpp"
#include "server/utils/Crypto.hpp"
#include "server/utils/TimeUtils.hpp"
#include <server/utils/PlatformUtils.hpp>

#include <sqlite3.h>

#include <algorithm>
#include <chrono>
#include <cctype>
#include <filesystem>
#include <stdexcept>
#include <unordered_map>
#include <unordered_set>

namespace server::services {
namespace {
std::string toLower(std::string value) {
  std::transform(
      value.begin(),
      value.end(),
      value.begin(),
      [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  return value;
}

std::string normalizeDirPrefix(const std::string &currentPath) {
  const auto clean = FileIndexService::normalizeRelPath(currentPath);
  if (clean.empty()) return "";
  return clean + "/";
}

std::string joinRelPath(const std::string &prefix, const std::string &segment) {
  if (prefix.empty()) return segment;
  return prefix + "/" + segment;
}
}  // namespace

FileIndexService::FileIndexService(db::Database &db, const FileService &fileService)
    : db_(db), fileService_(fileService) {}

void FileIndexService::upsertFile(std::int64_t ownerUserId,
                                  StorageScope scope,
                                  const std::string &relPath,
                                  const std::filesystem::path &absolutePath,
                                  std::int64_t uploaderUserId,
                                  const std::string &thumbnailPath,
                                  const std::string &blurhash) {
  const auto normalizedRel = normalizeRelPath(relPath);
  if (normalizedRel.empty()) return;

  const auto fileName = absolutePath.filename().string();
  const auto size = static_cast<std::int64_t>(std::filesystem::file_size(absolutePath));
  const auto mtime = utils::fileTimeToMillis(std::filesystem::last_write_time(absolutePath));
  const auto type = fileService_.classifyType(absolutePath);
  const auto mimeType = fileService_.mimeTypeFor(absolutePath);

  std::string sha256Val;
  try {
    sha256Val = utils::sha256FileHex(absolutePath);
  } catch (...) {
    sha256Val = "";
  }

  upsertFileExplicit(ownerUserId, scope, relPath, fileName, size, mtime, type, mimeType, uploaderUserId, sha256Val, thumbnailPath, blurhash);
}

void FileIndexService::upsertFileExplicit(std::int64_t ownerUserId,
                                          StorageScope scope,
                                          const std::string &relPath,
                                          const std::string &fileName,
                                          std::int64_t size,
                                          std::int64_t modifiedAt,
                                          const std::string &type,
                                          const std::string &mimeType,
                                          std::int64_t uploaderUserId,
                                          const std::string &sha256Val,
                                          const std::string &thumbnailPath,
                                          const std::string &blurhash) {
  const auto normalizedRel = normalizeRelPath(relPath);
  if (normalizedRel.empty()) return;
  const auto normalizedParent = normalizeRelPath(std::filesystem::path(normalizedRel).parent_path().generic_string());
  const auto now = utils::nowMillis();

  bool isShared = (scope == StorageScope::Private && isAncestorShared(ownerUserId, normalizedRel));

  const char *sql =
      "INSERT INTO file_index(owner_user_id, scope, rel_path, parent_path, name, type, mime_type, size_bytes, "
      "modified_at, uploaded_at, thumbnail_path, thumbnail_updated_at, is_deleted, uploader_user_id, sha256, is_shared, blurhash) "
      "VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?) "
      "ON CONFLICT(owner_user_id, scope, rel_path) DO UPDATE SET "
      "parent_path=excluded.parent_path, name=excluded.name, type=excluded.type, mime_type=excluded.mime_type, "
      "size_bytes=excluded.size_bytes, modified_at=excluded.modified_at, thumbnail_path=excluded.thumbnail_path, "
      "thumbnail_updated_at=excluded.thumbnail_updated_at, is_deleted=0, uploader_user_id=excluded.uploader_user_id, "
      "sha256=excluded.sha256, "
      "blurhash=CASE WHEN excluded.blurhash != '' THEN excluded.blurhash ELSE file_index.blurhash END";

  auto stmtGuard = db_.getStatement(sql);
  auto *stmt = stmtGuard.get();

  sqlite3_bind_int64(stmt, 1, ownerUserId);
  const auto scopeRaw = scopeToString(scope);
  sqlite3_bind_text(stmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, normalizedRel.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 4, normalizedParent.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 5, fileName.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 6, type.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 7, mimeType.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 8, size);
  sqlite3_bind_int64(stmt, 9, modifiedAt);
  sqlite3_bind_int64(stmt, 10, now);
  sqlite3_bind_text(stmt, 11, thumbnailPath.c_str(), -1, SQLITE_TRANSIENT);
  if (thumbnailPath.empty()) {
    sqlite3_bind_null(stmt, 12);
  } else {
    sqlite3_bind_int64(stmt, 12, now);
  }
  sqlite3_bind_int64(stmt, 13, uploaderUserId);
  sqlite3_bind_text(stmt, 14, sha256Val.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int(stmt, 15, isShared ? 1 : 0);
  sqlite3_bind_text(stmt, 16, blurhash.c_str(), -1, SQLITE_TRANSIENT);

  if (sqlite3_step(stmt) != SQLITE_DONE) {
    const auto *err = sqlite3_errmsg(db_.raw());
    throw std::runtime_error(err == nullptr ? "failed to upsert file index" : err);
  }
}

void FileIndexService::updateBlurHash(std::int64_t ownerUserId,
                                      StorageScope scope,
                                      const std::string &relPath,
                                      const std::string &blurhash) {
  const auto normalizedRel = normalizeRelPath(relPath);
  if (normalizedRel.empty() || blurhash.empty()) return;

  const char *sql =
      "UPDATE file_index SET blurhash = ? "
      "WHERE owner_user_id = ? AND scope = ? AND rel_path = ? AND is_deleted = 0";
  auto stmtGuard = db_.getStatement(sql);
  auto *stmt = stmtGuard.get();
  sqlite3_bind_text(stmt, 1, blurhash.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 2, ownerUserId);
  const auto scopeRaw = scopeToString(scope);
  sqlite3_bind_text(stmt, 3, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 4, normalizedRel.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_step(stmt);
}

void FileIndexService::updateBlurHashBySha256(const std::string &sha256,
                                              const std::string &blurhash) {
  if (sha256.empty() || blurhash.empty()) return;

  const char *sql =
      "UPDATE file_index SET blurhash = ? "
      "WHERE sha256 = ? AND is_deleted = 0";
  auto stmtGuard = db_.getStatement(sql);
  auto *stmt = stmtGuard.get();
  sqlite3_bind_text(stmt, 1, blurhash.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 2, sha256.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_step(stmt);
}

void FileIndexService::markDeleted(std::int64_t ownerUserId,
                                   StorageScope scope,
                                   const std::string &relPath) {
  const auto normalizedRel = normalizeRelPath(relPath);
  if (normalizedRel.empty()) return;

  auto stmtGuard = db_.getStatement(
      "UPDATE file_index SET is_deleted = 1 WHERE owner_user_id = ? AND scope = ? AND rel_path = ?");
  auto *stmt = stmtGuard.get();
  sqlite3_bind_int64(stmt, 1, ownerUserId);
  const auto scopeRaw = scopeToString(scope);
  sqlite3_bind_text(stmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, normalizedRel.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_step(stmt);
}

void FileIndexService::markDeletedPrefix(std::int64_t ownerUserId,
                                         StorageScope scope,
                                         const std::string &relPrefix) {
  const auto normalizedPrefix = normalizeRelPath(relPrefix);
  const auto pattern = normalizedPrefix.empty() ? "%" : normalizedPrefix + "/%";

  auto stmtGuard = db_.getStatement(
      "UPDATE file_index SET is_deleted = 1 WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR rel_path LIKE ?)");
  auto *stmt = stmtGuard.get();
  sqlite3_bind_int64(stmt, 1, ownerUserId);
  const auto scopeRaw = scopeToString(scope);
  sqlite3_bind_text(stmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, normalizedPrefix.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 4, pattern.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_step(stmt);
}

std::vector<IndexedDirEntry> FileIndexService::listDirectory(const ListIndexQuery &query) const {
  const auto currentPath = normalizeRelPath(query.currentPath);
  const auto dirPrefix = normalizeDirPrefix(currentPath);
  const auto pattern = dirPrefix.empty() ? "%" : dirPrefix + "%";
  const bool recursiveFiles = query.recursiveFiles;

  std::unordered_set<std::string> explicitlySharedDirs;
  if (query.scope == StorageScope::Shared) {
    auto sharedDirsGuard = db_.getStatement(
        "SELECT rel_path FROM file_index WHERE type = 'directory' AND is_shared = 1 AND is_deleted = 0");
    auto *sharedDirsStmt = sharedDirsGuard.get();
    while (sqlite3_step(sharedDirsStmt) == SQLITE_ROW) {
      const auto *pRaw = reinterpret_cast<const char *>(sqlite3_column_text(sharedDirsStmt, 0));
      if (pRaw != nullptr) {
        explicitlySharedDirs.insert(std::string(pRaw));
      }
    }
  }

  db::Database::StatementGuard stmtGuard;
  if (query.scope == StorageScope::Shared) {
    stmtGuard = db_.getStatement(
        "SELECT rel_path, name, type, mime_type, size_bytes, modified_at, thumbnail_path, is_shared, uploader_user_id, blurhash "
        "FROM file_index "
        "WHERE is_shared = 1 AND is_deleted = 0 AND rel_path LIKE ?");
    sqlite3_bind_text(stmtGuard.get(), 1, pattern.c_str(), -1, SQLITE_TRANSIENT);
  } else {
    stmtGuard = db_.getStatement(
        "SELECT rel_path, name, type, mime_type, size_bytes, modified_at, thumbnail_path, is_shared, uploader_user_id, blurhash "
        "FROM file_index "
        "WHERE owner_user_id = ? AND scope = ? AND is_deleted = 0 AND rel_path LIKE ?");
    sqlite3_bind_int64(stmtGuard.get(), 1, query.ownerUserId);
    const auto scopeRaw = scopeToString(query.scope);
    sqlite3_bind_text(stmtGuard.get(), 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmtGuard.get(), 3, pattern.c_str(), -1, SQLITE_TRANSIENT);
  }

  auto *stmt = stmtGuard.get();
  std::vector<IndexedDirEntry> files;
  std::unordered_map<std::string, IndexedDirEntry> dirs;

  while (sqlite3_step(stmt) == SQLITE_ROW) {
    const auto *relPathRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
    if (relPathRaw == nullptr) continue;

    const auto relPath = std::string(relPathRaw);

    std::string remaining;
    if (query.scope == StorageScope::Shared && currentPath.empty()) {
      std::string virtualParent = "";
      std::string temp = relPath;
      while (true) {
        auto slash = temp.find_last_of('/');
        if (slash == std::string::npos) {
          break;
        }
        temp = temp.substr(0, slash);
        if (explicitlySharedDirs.count(temp)) {
          virtualParent = temp;
          break;
        }
      }
      if (!virtualParent.empty()) continue; // Skip files inside explicitly shared directories at the root level

      remaining = std::filesystem::path(relPath).filename().string();
    } else {
      if (!dirPrefix.empty() && relPath.rfind(dirPrefix, 0) != 0) continue;
      remaining = dirPrefix.empty() ? relPath : relPath.substr(dirPrefix.size());
    }

    if (remaining.empty()) continue;

    const auto *nameRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
    const auto *typeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
    const auto *mimeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 3));
    const auto *thumbRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 6));
    const auto *blurRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 9));

    if (!recursiveFiles) {
      const auto slashPos = remaining.find('/');
      if (slashPos != std::string::npos) {
        const auto dirName = remaining.substr(0, slashPos);
        auto it = dirs.find(dirName);
        const auto fileMtime = sqlite3_column_int64(stmt, 5);
        if (it == dirs.end()) {
          dirs.emplace(
              dirName,
              IndexedDirEntry{
                  .name = dirName,
                  .path = joinRelPath(currentPath, dirName),
                  .isDir = true,
                  .size = 0,
                  .modifiedAt = fileMtime,
                  .type = "directory",
                  .mimeType = "inode/directory",
                  .thumbnailUrl = "",
                  .isShared = false,
                  .uploaderUserId = 0,
                  .blurhash = "",
              });
        } else if (fileMtime > it->second.modifiedAt) {
          it->second.modifiedAt = fileMtime;
        }
        continue;
      }
    }

    bool isEntryDir = (typeRaw != nullptr && std::string(typeRaw) == "directory");
    if (isEntryDir) {
      if (query.includeDirs) {
        auto it = dirs.find(remaining);
        std::string dirName = (nameRaw != nullptr && nameRaw[0] != '\0')
                                  ? std::string(nameRaw)
                                  : std::filesystem::path(relPath).filename().string();
        if (dirName.empty()) dirName = remaining;
        if (it == dirs.end()) {
          dirs.emplace(
              remaining,
              IndexedDirEntry{
                  .name = dirName,
                  .path = relPath,
                  .isDir = true,
                  .size = 0,
                  .modifiedAt = sqlite3_column_int64(stmt, 5),
                  .type = "directory",
                  .mimeType = "inode/directory",
                  .thumbnailUrl = "",
                  .isShared = sqlite3_column_int(stmt, 7) == 1,
                  .uploaderUserId = sqlite3_column_int64(stmt, 8),
                  .blurhash = "",
              });
        }
      }
      continue;
    }

    if (query.includeDirs && recursiveFiles) {
      auto slashPos = remaining.find_last_of('/');
      if (slashPos != std::string::npos) {
        std::string parentDirsPath = remaining.substr(0, slashPos);
        std::size_t startPos = 0;
        while (startPos < parentDirsPath.size()) {
          auto nextSlash = parentDirsPath.find('/', startPos);
          std::string sub = (nextSlash == std::string::npos)
                                ? parentDirsPath
                                : parentDirsPath.substr(0, nextSlash);
          if (!sub.empty()) {
            if (dirs.find(sub) == dirs.end()) {
              std::string subName = std::filesystem::path(sub).filename().string();
              dirs.emplace(
                  sub,
                  IndexedDirEntry{
                      .name = subName,
                      .path = joinRelPath(currentPath, sub),
                      .isDir = true,
                      .size = 0,
                      .modifiedAt = sqlite3_column_int64(stmt, 5),
                      .type = "directory",
                      .mimeType = "inode/directory",
                      .thumbnailUrl = "",
                      .isShared = sqlite3_column_int(stmt, 7) == 1,
                      .uploaderUserId = sqlite3_column_int64(stmt, 8),
                      .blurhash = "",
                  });
            }
          }
          if (nextSlash == std::string::npos) break;
          startPos = nextSlash + 1;
        }
      }
    }

    files.push_back(IndexedDirEntry{
        .name = std::string(nameRaw == nullptr ? "" : nameRaw),
        .path = relPath,
        .isDir = false,
        .size = static_cast<std::uintmax_t>(sqlite3_column_int64(stmt, 4)),
        .modifiedAt = sqlite3_column_int64(stmt, 5),
        .type = std::string(typeRaw == nullptr ? "other" : typeRaw),
        .mimeType = std::string(mimeRaw == nullptr ? "application/octet-stream" : mimeRaw),
        .thumbnailUrl = std::string(thumbRaw == nullptr ? "" : thumbRaw),
        .isShared = sqlite3_column_int(stmt, 7) == 1,
        .uploaderUserId = sqlite3_column_int64(stmt, 8),
        .blurhash = std::string(blurRaw == nullptr ? "" : blurRaw),
    });
  }

  std::vector<IndexedDirEntry> entries;
  entries.reserve(dirs.size() + files.size());
  if (query.includeDirs) {
    for (auto &pair : dirs) entries.push_back(std::move(pair.second));
  }

  const auto queryLower = toLower(query.query);
  for (const auto &entry : files) {
    if (!query.filterType.empty() && query.filterType != "all" && entry.type != query.filterType) {
      continue;
    }
    if (!queryLower.empty()) {
      if (toLower(entry.name).find(queryLower) == std::string::npos) continue;
    }
    entries.push_back(entry);
  }

  if (query.includeDirs && !queryLower.empty()) {
    entries.erase(
        std::remove_if(
            entries.begin(),
            entries.end(),
            [&](const auto &e) {
              if (!e.isDir) return false;
              return toLower(e.name).find(queryLower) == std::string::npos;
            }),
        entries.end());
  }

  std::sort(entries.begin(), entries.end(), [&](const auto &a, const auto &b) {
    if (a.isDir != b.isDir) return a.isDir > b.isDir;

    auto lessByName = [&]() { return query.sortAscending ? a.name < b.name : a.name > b.name; };
    if (query.sortBy == "size") {
      if (a.size == b.size) return lessByName();
      return query.sortAscending ? a.size < b.size : a.size > b.size;
    }
    if (query.sortBy == "date") {
      if (a.modifiedAt == b.modifiedAt) return lessByName();
      return query.sortAscending ? a.modifiedAt < b.modifiedAt : a.modifiedAt > b.modifiedAt;
    }
    if (query.sortBy == "type") {
      if (a.type == b.type) return lessByName();
      return query.sortAscending ? a.type < b.type : a.type > b.type;
    }
    return lessByName();
  });

  return entries;
}

bool FileIndexService::canDeletePath(std::int64_t ownerUserId,
                                     StorageScope scope,
                                     const std::string &relPath,
                                     std::int64_t requesterUserId,
                                     bool isDirectory) const {
  const auto normalizedRel = normalizeRelPath(relPath);
  if (normalizedRel.empty()) return false;
  const auto scopeRaw = scopeToString(scope);
  const auto pattern = normalizedRel + "/%";

  const char *sql = isDirectory
      ? "SELECT uploader_user_id FROM file_index "
        "WHERE owner_user_id = ? AND scope = ? AND is_deleted = 0 "
        "AND (rel_path = ? OR rel_path LIKE ?)"
      : "SELECT uploader_user_id FROM file_index "
        "WHERE owner_user_id = ? AND scope = ? AND is_deleted = 0 AND rel_path = ?";
  auto stmtGuard = db_.getStatement(sql);
  auto *stmt = stmtGuard.get();
  sqlite3_bind_int64(stmt, 1, ownerUserId);
  sqlite3_bind_text(stmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, normalizedRel.c_str(), -1, SQLITE_TRANSIENT);
  if (isDirectory) {
    sqlite3_bind_text(stmt, 4, pattern.c_str(), -1, SQLITE_TRANSIENT);
  }

  bool hasRows = false;
  bool allowed = true;
  while (sqlite3_step(stmt) == SQLITE_ROW) {
    hasRows = true;
    const auto uploaderUserId = sqlite3_column_int64(stmt, 0);
    if (uploaderUserId != requesterUserId) {
      allowed = false;
      break;
    }
  }
  return hasRows && allowed;
}

struct DbFileMeta {
  std::int64_t modifiedAt;
  std::int64_t size;
  std::string sha256;
};

std::int64_t FileIndexService::rebuildIndex(std::int64_t ownerUserId,
                                            StorageScope scope,
                                            const std::filesystem::path &rootPath) {
  const auto scopeRaw = scopeToString(scope);

  // RAII Transaction Management
  db::Database::TransactionGuard transaction(db_);

  std::unordered_map<std::string, DbFileMeta> dbFiles;
  {
    auto selectGuard = db_.getStatement(
        "SELECT rel_path, modified_at, size_bytes, sha256 FROM file_index WHERE owner_user_id = ? AND scope = ? AND is_deleted = 0 AND type != 'directory'");
    auto *selectStmt = selectGuard.get();
    sqlite3_bind_int64(selectStmt, 1, ownerUserId);
    sqlite3_bind_text(selectStmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
    while (sqlite3_step(selectStmt) == SQLITE_ROW) {
      const auto *relPathRaw = reinterpret_cast<const char *>(sqlite3_column_text(selectStmt, 0));
      if (relPathRaw) {
        dbFiles[std::string(relPathRaw)] = DbFileMeta{
          .modifiedAt = sqlite3_column_int64(selectStmt, 1),
          .size = sqlite3_column_int64(selectStmt, 2),
          .sha256 = reinterpret_cast<const char *>(sqlite3_column_text(selectStmt, 3)) ? reinterpret_cast<const char *>(sqlite3_column_text(selectStmt, 3)) : ""
        };
      }
    }
  }

  std::unordered_set<std::string> diskFiles;
  std::int64_t count = 0;
  std::error_code ecRoot;
  if (std::filesystem::exists(rootPath, ecRoot)) {
    std::error_code ec;
    for (const auto &entry : std::filesystem::recursive_directory_iterator(rootPath, ec)) {
      if (!entry.is_regular_file(ec)) continue;
      const auto rel = std::filesystem::relative(entry.path(), rootPath, ec).generic_string();
      diskFiles.insert(rel);

      auto it = dbFiles.find(rel);
      const auto mtime = utils::fileTimeToMillis(entry.last_write_time(ec));
      const auto size = static_cast<std::int64_t>(entry.file_size(ec));

      if (it != dbFiles.end() && it->second.modifiedAt == mtime && it->second.size == size && !it->second.sha256.empty()) {
        count++;
        continue;
      }

      const auto fileName = entry.path().filename().string();
      const auto type = fileService_.classifyType(entry.path());
      const auto mimeType = fileService_.mimeTypeFor(entry.path());
      std::string sha256Val;
      try {
        sha256Val = utils::sha256FileHex(entry.path());
      } catch (...) {
        sha256Val = "";
      }

      upsertFileExplicit(ownerUserId, scope, rel, fileName, size, mtime, type, mimeType, ownerUserId, sha256Val);
      count++;
    }
  }

  for (const auto &pair : dbFiles) {
    const auto &rel = pair.first;
    if (diskFiles.find(rel) == diskFiles.end()) {
      auto delGuard = db_.getStatement(
          "DELETE FROM file_index WHERE owner_user_id = ? AND scope = ? AND rel_path = ?");
      auto *delStmt = delGuard.get();
      sqlite3_bind_int64(delStmt, 1, ownerUserId);
      sqlite3_bind_text(delStmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(delStmt, 3, rel.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_step(delStmt);
    }
  }

  transaction.commit();
  return count;
}

std::string FileIndexService::scopeToString(StorageScope scope) {
  return scope == StorageScope::Private ? "private" : "shared";
}

std::string FileIndexService::normalizeRelPath(const std::string &rawPath) {
  if (rawPath.empty()) return "";
  auto path = std::filesystem::path(rawPath).lexically_normal().relative_path().generic_string();
  while (!path.empty() && path.front() == '/') path.erase(path.begin());
  if (path == ".") return "";
  return path;
}

std::optional<IndexedDirEntry> FileIndexService::findFileByHash(std::int64_t ownerUserId,
                                                                StorageScope scope,
                                                                const std::string &sha256) const {
  const char *sql =
      "SELECT rel_path, name, type, mime_type, size_bytes, modified_at, thumbnail_path, blurhash "
      "FROM file_index "
      "WHERE owner_user_id = ? AND scope = ? AND sha256 = ? AND is_deleted = 0 "
      "LIMIT 1";

  auto stmtGuard = db_.getStatement(sql);
  auto *stmt = stmtGuard.get();
  sqlite3_bind_int64(stmt, 1, ownerUserId);
  const auto scopeRaw = scopeToString(scope);
  sqlite3_bind_text(stmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, sha256.c_str(), -1, SQLITE_TRANSIENT);

  std::optional<IndexedDirEntry> entry;
  if (sqlite3_step(stmt) == SQLITE_ROW) {
    const auto *relPathRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
    const auto *nameRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
    const auto *typeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
    const auto *mimeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 3));
    const auto *thumbRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 6));
    const auto *blurRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 7));

    entry = IndexedDirEntry{
        .name = std::string(nameRaw == nullptr ? "" : nameRaw),
        .path = std::string(relPathRaw == nullptr ? "" : relPathRaw),
        .isDir = false,
        .size = static_cast<std::uintmax_t>(sqlite3_column_int64(stmt, 4)),
        .modifiedAt = sqlite3_column_int64(stmt, 5),
        .type = std::string(typeRaw == nullptr ? "other" : typeRaw),
        .mimeType = std::string(mimeRaw == nullptr ? "application/octet-stream" : mimeRaw),
        .thumbnailUrl = std::string(thumbRaw == nullptr ? "" : thumbRaw),
        .isShared = false,
        .uploaderUserId = 0,
        .blurhash = std::string(blurRaw == nullptr ? "" : blurRaw),
    };
  }
  return entry;
}

void FileIndexService::setSharedFlag(std::int64_t ownerUserId,
                                     const std::string &relPath,
                                     bool isShared) {
  const auto normalized = normalizeRelPath(relPath);
  bool isDir = false;
  // 1. Check database first to see if it is indexed as a directory
  {
    const char *dbSql = "SELECT type FROM file_index WHERE owner_user_id = ? AND scope = 'private' AND rel_path = ? LIMIT 1";
    auto dbGuard = db_.getStatement(dbSql);
    auto *dbStmt = dbGuard.get();
    sqlite3_bind_int64(dbStmt, 1, ownerUserId);
    sqlite3_bind_text(dbStmt, 2, normalized.c_str(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(dbStmt) == SQLITE_ROW) {
      const auto *typeRaw = reinterpret_cast<const char *>(sqlite3_column_text(dbStmt, 0));
      if (typeRaw != nullptr && std::string(typeRaw) == "directory") {
        isDir = true;
      }
    }
  }
  // 2. If not found/not directory in DB, check physical disk safely
  if (!isDir) {
    std::error_code ec;
    const auto absolutePath = fileService_.resolvePath(ownerUserId, "user", StorageScope::Private, normalized, false);
    isDir = std::filesystem::is_directory(absolutePath, ec);
  }

  if (isShared) {
    if (isDir) {
      // 1. Upsert a directory entry for the folder itself in file_index to mark it explicitly shared.
      const auto parent = normalizeRelPath(std::filesystem::path(normalized).parent_path().generic_string());
      const auto name = std::filesystem::path(normalized).filename().string();
      const auto now = utils::nowMillis();

      const char *sql =
          "INSERT INTO file_index(owner_user_id, scope, rel_path, parent_path, name, type, mime_type, size_bytes, "
          "modified_at, uploaded_at, is_deleted, uploader_user_id, is_shared, is_explicit_shared) "
          "VALUES(?, 'private', ?, ?, ?, 'directory', 'inode/directory', 0, ?, ?, 0, ?, 1, 1) "
          "ON CONFLICT(owner_user_id, scope, rel_path) DO UPDATE SET "
          "is_shared=1, is_explicit_shared=1, is_deleted=0";

      auto stmtGuard = db_.getStatement(sql);
      auto *stmt = stmtGuard.get();
      sqlite3_bind_int64(stmt, 1, ownerUserId);
      sqlite3_bind_text(stmt, 2, normalized.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(stmt, 3, parent.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(stmt, 4, name.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_int64(stmt, 5, now);
      sqlite3_bind_int64(stmt, 6, now);
      sqlite3_bind_int64(stmt, 7, ownerUserId);

      sqlite3_step(stmt);

      // 2. Mark all files inside this directory as is_shared = 1
      const auto pattern = normalized + "/%";
      const char *updSql =
          "UPDATE file_index SET is_shared = 1 "
          "WHERE owner_user_id = ? AND scope = 'private' AND rel_path LIKE ?";
      auto updGuard = db_.getStatement(updSql);
      auto *updStmt = updGuard.get();
      sqlite3_bind_int64(updStmt, 1, ownerUserId);
      sqlite3_bind_text(updStmt, 2, pattern.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_step(updStmt);
    } else {
      // It's a file
      const char *sql =
          "UPDATE file_index SET is_shared = 1, is_explicit_shared = 1 "
          "WHERE owner_user_id = ? AND scope = 'private' AND rel_path = ?";
      auto stmtGuard = db_.getStatement(sql);
      auto *stmt = stmtGuard.get();
      sqlite3_bind_int64(stmt, 1, ownerUserId);
      sqlite3_bind_text(stmt, 2, normalized.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_step(stmt);
    }
  } else {
    // Unshare
    if (isDir) {
      // Unsharing a directory unshares the directory itself AND everything inside it.
      const auto pattern = normalized + "/%";
      const char *sql =
          "UPDATE file_index SET is_shared = 0, is_explicit_shared = 0 "
          "WHERE owner_user_id = ? AND scope = 'private' AND (rel_path = ? OR rel_path LIKE ?)";
      auto stmtGuard = db_.getStatement(sql);
      auto *stmt = stmtGuard.get();
      sqlite3_bind_int64(stmt, 1, ownerUserId);
      sqlite3_bind_text(stmt, 2, normalized.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(stmt, 3, pattern.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_step(stmt);
    } else {
      // Unsharing a file only affects the file itself
      const char *sql =
          "UPDATE file_index SET is_shared = 0, is_explicit_shared = 0 "
          "WHERE owner_user_id = ? AND scope = 'private' AND rel_path = ?";
      auto stmtGuard = db_.getStatement(sql);
      auto *stmt = stmtGuard.get();
      sqlite3_bind_int64(stmt, 1, ownerUserId);
      sqlite3_bind_text(stmt, 2, normalized.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_step(stmt);
    }
  }
}

std::optional<std::int64_t> FileIndexService::getSharedFileOwner(const std::string &relPath) const {
  std::string temp = relPath;
  while (true) {
    const char *sql =
        "SELECT is_shared, owner_user_id FROM file_index "
        "WHERE rel_path = ? AND is_deleted = 0 "
        "LIMIT 1";

    auto stmtGuard = db_.getStatement(sql);
    auto *stmt = stmtGuard.get();
    sqlite3_bind_text(stmt, 1, temp.c_str(), -1, SQLITE_TRANSIENT);

    std::optional<std::int64_t> ownerId;
    bool found = false;
    bool isShared = false;

    if (sqlite3_step(stmt) == SQLITE_ROW) {
      found = true;
      isShared = sqlite3_column_int(stmt, 0) == 1;
      ownerId = sqlite3_column_int64(stmt, 1);
    }

    if (found) {
      if (isShared) {
        return ownerId;
      } else {
        return std::nullopt;
      }
    }

    auto slash = temp.find_last_of('/');
    if (slash == std::string::npos) {
      break;
    }
    temp = temp.substr(0, slash);
  }
  return std::nullopt;
}

bool FileIndexService::isAncestorShared(std::int64_t ownerUserId, const std::string &relPath) const {
  std::string temp = relPath;
  while (true) {
    auto slash = temp.find_last_of('/');
    if (slash == std::string::npos) {
      break;
    }
    temp = temp.substr(0, slash);

    const char *sql =
        "SELECT 1 FROM file_index "
        "WHERE owner_user_id = ? AND scope = 'private' AND rel_path = ? AND type = 'directory' AND is_shared = 1 AND is_deleted = 0 "
        "LIMIT 1";
    auto stmtGuard = db_.getStatement(sql);
    auto *stmt = stmtGuard.get();
    sqlite3_bind_int64(stmt, 1, ownerUserId);
    sqlite3_bind_text(stmt, 2, temp.c_str(), -1, SQLITE_TRANSIENT);
    bool shared = (sqlite3_step(stmt) == SQLITE_ROW);
    if (shared) {
      return true;
    }
  }
  return false;
}

UserStats FileIndexService::getUserStats(std::int64_t userId) const {
  UserStats stats;

  // 1. Private files aggregated by type
  {
    auto stmtGuard = db_.getStatement(
        "SELECT type, COUNT(*), COALESCE(SUM(size_bytes), 0) "
        "FROM file_index "
        "WHERE owner_user_id = ? AND scope = 'private' AND is_deleted = 0 "
        "GROUP BY type");
    auto *stmt = stmtGuard.get();
    sqlite3_bind_int64(stmt, 1, userId);

    while (sqlite3_step(stmt) == SQLITE_ROW) {
      const auto *typeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
      const auto count = sqlite3_column_int64(stmt, 1);
      const auto size = static_cast<std::uintmax_t>(sqlite3_column_int64(stmt, 2));
      const std::string typeStr = typeRaw ? typeRaw : "other";

      stats.totalCount += count;
      if (typeStr == "photo" || typeStr == "image") {
        stats.photoCount += count;
        stats.photoSize += size;
        stats.totalSize += size;
      } else if (typeStr == "video") {
        stats.videoCount += count;
        stats.videoSize += size;
        stats.totalSize += size;
      } else if (typeStr == "audio") {
        stats.audioCount += count;
        stats.audioSize += size;
        stats.totalSize += size;
      } else if (typeStr == "document") {
        stats.documentCount += count;
        stats.documentSize += size;
        stats.totalSize += size;
      } else if (typeStr == "directory") {
        // Directories increment file/folder count, size is 0
      } else {
        stats.otherCount += count;
        stats.otherSize += size;
        stats.totalSize += size;
      }
    }
  }

  // 2. Shared files
  {
    auto stmtGuard = db_.getStatement(
        "SELECT COUNT(*), COALESCE(SUM(size_bytes), 0) "
        "FROM file_index "
        "WHERE is_shared = 1 AND is_deleted = 0 AND type != 'directory'");
    auto *stmt = stmtGuard.get();
    if (sqlite3_step(stmt) == SQLITE_ROW) {
      stats.sharedCount = sqlite3_column_int64(stmt, 0);
      stats.sharedSize = static_cast<std::uintmax_t>(sqlite3_column_int64(stmt, 1));
    }
  }

  return stats;
}

}  // namespace server::services
