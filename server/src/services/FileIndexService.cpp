#include "server/services/FileIndexService.hpp"

#include <sqlite3.h>

#include <algorithm>
#include <chrono>
#include <cctype>
#include <filesystem>
#include <stdexcept>
#include <unordered_map>

namespace server::services {
namespace {
std::int64_t nowMillis() {
  return std::chrono::duration_cast<std::chrono::milliseconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}

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
                                  const std::string &thumbnailPath) {
  const auto normalizedRel = normalizeRelPath(relPath);
  if (normalizedRel.empty()) return;
  const auto normalizedParent = normalizeRelPath(std::filesystem::path(normalizedRel).parent_path().generic_string());

  const auto fileName = absolutePath.filename().string();
  const auto size = static_cast<std::int64_t>(std::filesystem::file_size(absolutePath));
  const auto mtime = std::chrono::duration_cast<std::chrono::milliseconds>(
                         std::filesystem::last_write_time(absolutePath).time_since_epoch())
                         .count();
  const auto type = fileService_.classifyType(absolutePath);
  const auto mimeType = fileService_.mimeTypeFor(absolutePath);
  const auto now = nowMillis();

  sqlite3_stmt *stmt = nullptr;
  const char *sql =
      "INSERT INTO file_index(owner_user_id, scope, rel_path, parent_path, name, type, mime_type, size_bytes, "
      "modified_at, uploaded_at, thumbnail_path, thumbnail_updated_at, is_deleted, uploader_user_id) "
      "VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?) "
      "ON CONFLICT(owner_user_id, scope, rel_path) DO UPDATE SET "
      "parent_path=excluded.parent_path, name=excluded.name, type=excluded.type, mime_type=excluded.mime_type, "
      "size_bytes=excluded.size_bytes, modified_at=excluded.modified_at, thumbnail_path=excluded.thumbnail_path, "
      "thumbnail_updated_at=excluded.thumbnail_updated_at, is_deleted=0, uploader_user_id=excluded.uploader_user_id";

  sqlite3_prepare_v2(db_.raw(), sql, -1, &stmt, nullptr);
  sqlite3_bind_int64(stmt, 1, ownerUserId);
  const auto scopeRaw = scopeToString(scope);
  sqlite3_bind_text(stmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, normalizedRel.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 4, normalizedParent.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 5, fileName.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 6, type.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 7, mimeType.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 8, size);
  sqlite3_bind_int64(stmt, 9, mtime);
  sqlite3_bind_int64(stmt, 10, now);
  sqlite3_bind_text(stmt, 11, thumbnailPath.c_str(), -1, SQLITE_TRANSIENT);
  if (thumbnailPath.empty()) {
    sqlite3_bind_null(stmt, 12);
  } else {
    sqlite3_bind_int64(stmt, 12, now);
  }
  sqlite3_bind_int64(stmt, 13, uploaderUserId);

  if (sqlite3_step(stmt) != SQLITE_DONE) {
    const auto *err = sqlite3_errmsg(db_.raw());
    sqlite3_finalize(stmt);
    throw std::runtime_error(err == nullptr ? "failed to upsert file index" : err);
  }
  sqlite3_finalize(stmt);
}

void FileIndexService::markDeleted(std::int64_t ownerUserId,
                                   StorageScope scope,
                                   const std::string &relPath) {
  const auto normalizedRel = normalizeRelPath(relPath);
  if (normalizedRel.empty()) return;

  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(
      db_.raw(),
      "UPDATE file_index SET is_deleted = 1 WHERE owner_user_id = ? AND scope = ? AND rel_path = ?",
      -1,
      &stmt,
      nullptr);
  sqlite3_bind_int64(stmt, 1, ownerUserId);
  const auto scopeRaw = scopeToString(scope);
  sqlite3_bind_text(stmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, normalizedRel.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_step(stmt);
  sqlite3_finalize(stmt);
}

void FileIndexService::markDeletedPrefix(std::int64_t ownerUserId,
                                         StorageScope scope,
                                         const std::string &relPrefix) {
  const auto normalizedPrefix = normalizeRelPath(relPrefix);
  const auto pattern = normalizedPrefix.empty() ? "%" : normalizedPrefix + "/%";

  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(
      db_.raw(),
      "UPDATE file_index SET is_deleted = 1 WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR rel_path LIKE ?)",
      -1,
      &stmt,
      nullptr);
  sqlite3_bind_int64(stmt, 1, ownerUserId);
  const auto scopeRaw = scopeToString(scope);
  sqlite3_bind_text(stmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, normalizedPrefix.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 4, pattern.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_step(stmt);
  sqlite3_finalize(stmt);
}

std::vector<IndexedDirEntry> FileIndexService::listDirectory(const ListIndexQuery &query) const {
  const auto currentPath = normalizeRelPath(query.currentPath);
  const auto dirPrefix = normalizeDirPrefix(currentPath);
  const auto pattern = dirPrefix.empty() ? "%" : dirPrefix + "%";
  const bool recursiveFiles = query.recursiveFiles;

  sqlite3_stmt *stmt = nullptr;
  sqlite3_prepare_v2(
      db_.raw(),
      "SELECT rel_path, name, type, mime_type, size_bytes, modified_at, thumbnail_path "
      "FROM file_index "
      "WHERE owner_user_id = ? AND scope = ? AND is_deleted = 0 AND rel_path LIKE ?",
      -1,
      &stmt,
      nullptr);
  sqlite3_bind_int64(stmt, 1, query.ownerUserId);
  const auto scopeRaw = scopeToString(query.scope);
  sqlite3_bind_text(stmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, pattern.c_str(), -1, SQLITE_TRANSIENT);

  std::vector<IndexedDirEntry> files;
  std::unordered_map<std::string, IndexedDirEntry> dirs;

  while (sqlite3_step(stmt) == SQLITE_ROW) {
    const auto *relPathRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
    if (relPathRaw == nullptr) continue;

    const auto relPath = std::string(relPathRaw);
    if (!dirPrefix.empty() && relPath.rfind(dirPrefix, 0) != 0) continue;

    const auto remaining = dirPrefix.empty() ? relPath : relPath.substr(dirPrefix.size());
    if (remaining.empty()) continue;

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
              });
        } else if (fileMtime > it->second.modifiedAt) {
          it->second.modifiedAt = fileMtime;
        }
        continue;
      }
    }

    const auto *nameRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
    const auto *typeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
    const auto *mimeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 3));
    const auto *thumbRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 6));

    files.push_back(IndexedDirEntry{
        .name = std::string(nameRaw == nullptr ? "" : nameRaw),
        .path = relPath,
        .isDir = false,
        .size = static_cast<std::uintmax_t>(sqlite3_column_int64(stmt, 4)),
        .modifiedAt = sqlite3_column_int64(stmt, 5),
        .type = std::string(typeRaw == nullptr ? "other" : typeRaw),
        .mimeType = std::string(mimeRaw == nullptr ? "application/octet-stream" : mimeRaw),
        .thumbnailUrl = std::string(thumbRaw == nullptr ? "" : thumbRaw),
    });
  }
  sqlite3_finalize(stmt);

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

  sqlite3_stmt *stmt = nullptr;
  const char *sql = isDirectory
      ? "SELECT uploader_user_id FROM file_index "
        "WHERE owner_user_id = ? AND scope = ? AND is_deleted = 0 "
        "AND (rel_path = ? OR rel_path LIKE ?)"
      : "SELECT uploader_user_id FROM file_index "
        "WHERE owner_user_id = ? AND scope = ? AND is_deleted = 0 AND rel_path = ?";
  sqlite3_prepare_v2(db_.raw(), sql, -1, &stmt, nullptr);
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
  sqlite3_finalize(stmt);
  return hasRows && allowed;
}

std::int64_t FileIndexService::rebuildIndex(std::int64_t ownerUserId,
                                            StorageScope scope,
                                            const std::filesystem::path &rootPath) {
  const auto scopeRaw = scopeToString(scope);

  sqlite3_exec(db_.raw(), "BEGIN IMMEDIATE TRANSACTION", nullptr, nullptr, nullptr);
  try {
    sqlite3_stmt *clearStmt = nullptr;
    sqlite3_prepare_v2(
        db_.raw(),
        "DELETE FROM file_index WHERE owner_user_id = ? AND scope = ?",
        -1,
        &clearStmt,
        nullptr);
    sqlite3_bind_int64(clearStmt, 1, ownerUserId);
    sqlite3_bind_text(clearStmt, 2, scopeRaw.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_step(clearStmt);
    sqlite3_finalize(clearStmt);

    std::int64_t count = 0;
    if (std::filesystem::exists(rootPath)) {
      for (const auto &entry : std::filesystem::recursive_directory_iterator(rootPath)) {
        if (!entry.is_regular_file()) continue;
        const auto rel = std::filesystem::relative(entry.path(), rootPath).generic_string();
        upsertFile(ownerUserId, scope, rel, entry.path(), ownerUserId);
        count++;
      }
    }
    sqlite3_exec(db_.raw(), "COMMIT", nullptr, nullptr, nullptr);
    return count;
  } catch (...) {
    sqlite3_exec(db_.raw(), "ROLLBACK", nullptr, nullptr, nullptr);
    throw;
  }
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

}  // namespace server::services
