#include "server/services/TrashService.hpp"
#include "server/services/FileIndexService.hpp"
#include "server/AppContext.hpp"
#include "server/utils/TimeUtils.hpp"

#include <iostream>
#include <sqlite3.h>
#include <chrono>
#include <filesystem>
#include <stdexcept>
#include <unordered_map>
#include <algorithm>

namespace server::services {

TrashService::TrashService(db::Database &db, const FileService &fileService)
    : db_(db), fileService_(fileService) {}

std::filesystem::path TrashService::getTrashPath(std::int64_t userId, std::int64_t trashId) const {
  return std::filesystem::path(server::ctx().config.storageRoot) / "trash" / std::to_string(userId) / std::to_string(trashId);
}

std::int64_t TrashService::getTrashRetentionDays(std::int64_t userId) const {
  std::int64_t days = 7; // Default 1 week
  auto stmtGuard = db_.getStatement("SELECT trash_retention_days FROM users WHERE id = ?");
  auto *stmt = stmtGuard.get();
  sqlite3_bind_int64(stmt, 1, userId);
  if (sqlite3_step(stmt) == SQLITE_ROW) {
    days = sqlite3_column_int64(stmt, 0);
  }
  return days;
}

void TrashService::setTrashRetentionDays(std::int64_t userId, std::int64_t days) {
  {
    auto stmtGuard = db_.getStatement("UPDATE users SET trash_retention_days = ? WHERE id = ?");
    auto *stmt = stmtGuard.get();
    sqlite3_bind_int64(stmt, 1, days);
    sqlite3_bind_int64(stmt, 2, userId);
    sqlite3_step(stmt);
  }

  if (days == 0) {
    purgeTrash(userId);
  }
}

std::vector<TrashEntry> TrashService::listTrash(std::int64_t userId, StorageScope scope, const std::string &searchQuery) const {
  std::vector<TrashEntry> entries;
  std::string sql =
      "SELECT id, owner_user_id, scope, original_path, name, is_dir, size_bytes, type, mime_type, deleted_at "
      "FROM trash WHERE owner_user_id = ? AND scope = ?";
  if (!searchQuery.empty()) {
    sql += " AND name LIKE ?";
  }
  sql += " ORDER BY deleted_at DESC";

  auto stmtGuard = db_.getStatement(sql);
  auto *stmt = stmtGuard.get();
  sqlite3_bind_int64(stmt, 1, userId);
  const auto scopeStr = FileIndexService::scopeToString(scope);
  sqlite3_bind_text(stmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
  if (!searchQuery.empty()) {
    std::string pattern = "%" + searchQuery + "%";
    sqlite3_bind_text(stmt, 3, pattern.c_str(), -1, SQLITE_TRANSIENT);
  }

  while (sqlite3_step(stmt) == SQLITE_ROW) {
    entries.push_back(TrashEntry{
        .id = sqlite3_column_int64(stmt, 0),
        .ownerUserId = sqlite3_column_int64(stmt, 1),
        .scope = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2)),
        .originalPath = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 3)),
        .name = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 4)),
        .isDir = sqlite3_column_int(stmt, 5) != 0,
        .size = static_cast<std::uintmax_t>(sqlite3_column_int64(stmt, 6)),
        .type = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 7)),
        .mimeType = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 8)),
        .deletedAt = sqlite3_column_int64(stmt, 9),
    });
  }
  return entries;
}

void TrashService::moveToTrash(std::int64_t userId, StorageScope scope, const std::string &relPath) {
  const auto role = "user"; // Default role
  const auto configHashFiles = server::ctx().config.hashFiles;

  bool isDir = false;
  std::uintmax_t size = 0;
  std::string name;
  std::string type = "directory";
  std::string mimeType = "inode/directory";

  if (configHashFiles) {
    auto stmtGuard = db_.getStatement(
        "SELECT name, type, mime_type, size_bytes FROM file_index WHERE owner_user_id = ? AND scope = ? AND rel_path = ? LIMIT 1");
    auto *stmt = stmtGuard.get();
    sqlite3_bind_int64(stmt, 1, userId);
    const auto scopeStr = FileIndexService::scopeToString(scope);
    sqlite3_bind_text(stmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 3, relPath.c_str(), -1, SQLITE_TRANSIENT);

    if (sqlite3_step(stmt) == SQLITE_ROW) {
      name = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
      type = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1));
      mimeType = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2));
      size = sqlite3_column_int64(stmt, 3);
      isDir = (type == "directory");
    } else {
      throw std::runtime_error("File or directory not found");
    }
  } else {
    const auto target = fileService_.resolvePath(userId, role, scope, relPath, true);
    if (!std::filesystem::exists(target)) {
      throw std::runtime_error("File or directory not found");
    }
    isDir = std::filesystem::is_directory(target);
    name = target.filename().string();
    if (!isDir) {
      size = std::filesystem::file_size(target);
      type = fileService_.classifyType(target);
      mimeType = fileService_.mimeTypeFor(target);
    }
  }

  std::int64_t days = getTrashRetentionDays(userId);
  if (days == 0) {
    // Trash is disabled, delete physically immediately
    if (configHashFiles) {
      if (!isDir) {
        auto sGuard = db_.getStatement("SELECT sha256 FROM file_index WHERE owner_user_id = ? AND scope = ? AND rel_path = ?");
        auto *sStmt = sGuard.get();
        sqlite3_bind_int64(sStmt, 1, userId);
        const auto scopeStr = FileIndexService::scopeToString(scope);
        sqlite3_bind_text(sStmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sStmt, 3, relPath.c_str(), -1, SQLITE_TRANSIENT);
        if (sqlite3_step(sStmt) == SQLITE_ROW) {
          const auto shaVal = reinterpret_cast<const char *>(sqlite3_column_text(sStmt, 0));
          if (shaVal && std::string(shaVal).size() > 0) {
            auto refGuard = db_.getStatement("SELECT COUNT(*) FROM file_index WHERE sha256 = ?");
            auto *refStmt = refGuard.get();
            sqlite3_bind_text(refStmt, 1, shaVal, -1, SQLITE_TRANSIENT);
            if (sqlite3_step(refStmt) == SQLITE_ROW) {
              if (sqlite3_column_int(refStmt, 0) <= 1) {
                const auto path = std::filesystem::path(server::ctx().config.storageRoot) / "data" / shaVal;
                std::error_code ec;
                std::filesystem::remove(path, ec);
              }
            }
          }
        }
      } else {
        auto sGuard = db_.getStatement(
            "SELECT sha256 FROM file_index WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR rel_path LIKE ?) AND type != 'directory'");
        auto *sStmt = sGuard.get();
        sqlite3_bind_int64(sStmt, 1, userId);
        const auto scopeStr = FileIndexService::scopeToString(scope);
        sqlite3_bind_text(sStmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sStmt, 3, relPath.c_str(), -1, SQLITE_TRANSIENT);
        const auto pattern = relPath + "/%";
        sqlite3_bind_text(sStmt, 4, pattern.c_str(), -1, SQLITE_TRANSIENT);
        while (sqlite3_step(sStmt) == SQLITE_ROW) {
          const auto shaVal = reinterpret_cast<const char *>(sqlite3_column_text(sStmt, 0));
          if (shaVal && std::string(shaVal).size() > 0) {
            auto refGuard = db_.getStatement("SELECT COUNT(*) FROM file_index WHERE sha256 = ?");
            auto *refStmt = refGuard.get();
            sqlite3_bind_text(refStmt, 1, shaVal, -1, SQLITE_TRANSIENT);
            if (sqlite3_step(refStmt) == SQLITE_ROW) {
              if (sqlite3_column_int(refStmt, 0) <= 1) {
                const auto path = std::filesystem::path(server::ctx().config.storageRoot) / "data" / shaVal;
                std::error_code ec;
                std::filesystem::remove(path, ec);
              }
            }
          }
        }
      }
    } else {
      const auto target = fileService_.resolvePath(userId, role, scope, relPath, true);
      std::filesystem::remove_all(target);
    }

    if (isDir) {
      server::ctx().fileIndexService->markDeletedPrefix(userId, scope, relPath);
    } else {
      server::ctx().fileIndexService->markDeleted(userId, scope, relPath);
    }

    auto delIndexGuard = db_.getStatement(
        "DELETE FROM file_index WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR rel_path LIKE ?)");
    auto *delIndexStmt = delIndexGuard.get();
    sqlite3_bind_int64(delIndexStmt, 1, userId);
    const auto scopeStr = FileIndexService::scopeToString(scope);
    sqlite3_bind_text(delIndexStmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(delIndexStmt, 3, relPath.c_str(), -1, SQLITE_TRANSIENT);
    const auto pattern = relPath + "/%";
    sqlite3_bind_text(delIndexStmt, 4, pattern.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_step(delIndexStmt);
    return;
  }

  std::int64_t now = utils::nowMillis();

  auto insertGuard = db_.getStatement(
      "INSERT INTO trash(owner_user_id, scope, original_path, name, is_dir, size_bytes, type, mime_type, deleted_at) "
      "VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)");
  auto *stmt = insertGuard.get();
  sqlite3_bind_int64(stmt, 1, userId);
  const auto scopeStr = FileIndexService::scopeToString(scope);
  sqlite3_bind_text(stmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, relPath.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 4, name.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int(stmt, 5, isDir ? 1 : 0);
  sqlite3_bind_int64(stmt, 6, size);
  sqlite3_bind_text(stmt, 7, type.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 8, mimeType.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(stmt, 9, now);

  if (sqlite3_step(stmt) != SQLITE_DONE) {
    throw std::runtime_error("Failed to insert trash entry");
  }

  std::int64_t trashId = sqlite3_last_insert_rowid(db_.raw());

  if (!configHashFiles) {
    const auto target = fileService_.resolvePath(userId, role, scope, relPath, true);
    const auto trashPath = getTrashPath(userId, trashId);
    std::filesystem::create_directories(trashPath.parent_path());
    std::filesystem::rename(target, trashPath);
  }

  if (isDir) {
    server::ctx().fileIndexService->markDeletedPrefix(userId, scope, relPath);
  } else {
    server::ctx().fileIndexService->markDeleted(userId, scope, relPath);
  }
}

void TrashService::restoreFromTrash(std::int64_t userId, const std::vector<std::int64_t> &ids) {
  const auto configHashFiles = server::ctx().config.hashFiles;
  for (const auto id : ids) {
    std::string scopeStr = "private";
    std::string originalPath;
    std::string name;
    bool isDir = false;

    {
      auto queryGuard = db_.getStatement("SELECT scope, original_path, name, is_dir FROM trash WHERE id = ? AND owner_user_id = ?");
      auto *stmt = queryGuard.get();
      sqlite3_bind_int64(stmt, 1, id);
      sqlite3_bind_int64(stmt, 2, userId);

      if (sqlite3_step(stmt) != SQLITE_ROW) {
        continue;
      }

      const auto scopeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
      scopeStr = std::string(scopeRaw ? scopeRaw : "private");
      originalPath = std::string(reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1)));
      name = std::string(reinterpret_cast<const char *>(sqlite3_column_text(stmt, 2)));
      isDir = sqlite3_column_int(stmt, 3) != 0;
    }

    const auto scope = parseScope(scopeStr).value_or(StorageScope::Private);
    const auto role = "user";
    std::string finalRelPath = originalPath;
    std::string finalName = name;

    if (!configHashFiles) {
      auto target = fileService_.resolvePath(userId, role, scope, originalPath, true);
      if (std::filesystem::exists(target)) {
        const auto parent = target.parent_path();
        const auto stem = target.stem().string();
        const auto ext = target.extension().string();
        int counter = 1;
        while (true) {
          const auto candidate = parent / (stem + " (" + std::to_string(counter) + ")" + ext);
          if (!std::filesystem::exists(candidate)) {
            target = candidate;
            finalName = stem + " (" + std::to_string(counter) + ")" + ext;
            const auto origParentRel = std::filesystem::path(originalPath).parent_path().generic_string();
            finalRelPath = origParentRel.empty() ? finalName : (origParentRel + "/" + finalName);
            break;
          }
          counter++;
        }
      }

      const auto trashPath = getTrashPath(userId, id);
      std::filesystem::create_directories(target.parent_path());
      std::filesystem::rename(trashPath, target);
    } else {
      // In hashFiles, check virtual name conflict in DB
      bool conflict = false;
      {
        auto confGuard = db_.getStatement("SELECT 1 FROM file_index WHERE owner_user_id = ? AND scope = ? AND rel_path = ? AND is_deleted = 0 LIMIT 1");
        auto *confStmt = confGuard.get();
        sqlite3_bind_int64(confStmt, 1, userId);
        sqlite3_bind_text(confStmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(confStmt, 3, originalPath.c_str(), -1, SQLITE_TRANSIENT);
        conflict = (sqlite3_step(confStmt) == SQLITE_ROW);
      }

      if (conflict) {
        const auto stem = std::filesystem::path(originalPath).stem().string();
        const auto ext = std::filesystem::path(originalPath).extension().string();
        const auto parentRel = std::filesystem::path(originalPath).parent_path().generic_string();
        int counter = 1;
        while (true) {
          finalName = stem + " (" + std::to_string(counter) + ")" + ext;
          finalRelPath = parentRel.empty() ? finalName : (parentRel + "/" + finalName);

          bool subConflict = false;
          {
            auto confGuard = db_.getStatement("SELECT 1 FROM file_index WHERE owner_user_id = ? AND scope = ? AND rel_path = ? AND is_deleted = 0 LIMIT 1");
            auto *confStmt = confGuard.get();
            sqlite3_bind_int64(confStmt, 1, userId);
            sqlite3_bind_text(confStmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(confStmt, 3, finalRelPath.c_str(), -1, SQLITE_TRANSIENT);
            subConflict = (sqlite3_step(confStmt) == SQLITE_ROW);
          }

          if (!subConflict) break;
          counter++;
        }
      }
    }

    // 4. Update file_index table
    {
      auto nameGuard = db_.getStatement("UPDATE file_index SET name = ?, rel_path = ?, is_deleted = 0, deleted_at = NULL WHERE owner_user_id = ? AND scope = ? AND rel_path = ? AND is_deleted = 1");
      auto *nameStmt = nameGuard.get();
      sqlite3_bind_text(nameStmt, 1, finalName.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(nameStmt, 2, finalRelPath.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_int64(nameStmt, 3, userId);
      sqlite3_bind_text(nameStmt, 4, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(nameStmt, 5, originalPath.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_step(nameStmt);
    }

    // For children of directory (if isDir)
    if (isDir) {
      auto updGuard = db_.getStatement(
          "UPDATE file_index SET rel_path = ? || SUBSTR(rel_path, ?), "
          "parent_path = CASE WHEN parent_path = ? THEN ? ELSE ? || SUBSTR(parent_path, ?) END, "
          "is_deleted = 0, deleted_at = NULL "
          "WHERE owner_user_id = ? AND scope = ? AND rel_path LIKE ? AND is_deleted = 1");
      auto *updStmt = updGuard.get();
      sqlite3_bind_text(updStmt, 1, finalRelPath.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_int(updStmt, 2, static_cast<int>(originalPath.length() + 1));
      sqlite3_bind_text(updStmt, 3, originalPath.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(updStmt, 4, finalRelPath.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(updStmt, 5, finalRelPath.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_int(updStmt, 6, static_cast<int>(originalPath.length() + 1));
      sqlite3_bind_int64(updStmt, 7, userId);
      sqlite3_bind_text(updStmt, 8, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
      const auto pattern = originalPath + "/%";
      sqlite3_bind_text(updStmt, 9, pattern.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_step(updStmt);
    }

    // 5. Delete row from trash table
    {
      auto delGuard = db_.getStatement("DELETE FROM trash WHERE id = ?");
      auto *delStmt = delGuard.get();
      sqlite3_bind_int64(delStmt, 1, id);
      sqlite3_step(delStmt);
    }
  }
}

void TrashService::deletePermanently(std::int64_t userId, const std::vector<std::int64_t> &ids) {
  const auto configHashFiles = server::ctx().config.hashFiles;
  for (const auto id : ids) {
    std::string scopeStr = "private";
    std::string originalPath;
    bool isDir = false;

    {
      auto queryGuard = db_.getStatement("SELECT scope, original_path, is_dir FROM trash WHERE id = ? AND owner_user_id = ?");
      auto *stmt = queryGuard.get();
      sqlite3_bind_int64(stmt, 1, id);
      sqlite3_bind_int64(stmt, 2, userId);

      if (sqlite3_step(stmt) != SQLITE_ROW) {
        continue;
      }

      const auto scopeRaw = reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0));
      scopeStr = std::string(scopeRaw ? scopeRaw : "private");
      originalPath = std::string(reinterpret_cast<const char *>(sqlite3_column_text(stmt, 1)));
      isDir = sqlite3_column_int(stmt, 2) != 0;
    }

    // 2. Remove physical file / clean up hashes
    if (configHashFiles) {
      auto sGuard = db_.getStatement(
          "SELECT sha256 FROM file_index WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR rel_path LIKE ?) AND type != 'directory' AND is_deleted = 1");
      auto *sStmt = sGuard.get();
      sqlite3_bind_int64(sStmt, 1, userId);
      sqlite3_bind_text(sStmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(sStmt, 3, originalPath.c_str(), -1, SQLITE_TRANSIENT);
      const auto pattern = originalPath + "/%";
      sqlite3_bind_text(sStmt, 4, pattern.c_str(), -1, SQLITE_TRANSIENT);

      while (sqlite3_step(sStmt) == SQLITE_ROW) {
        const auto shaVal = reinterpret_cast<const char *>(sqlite3_column_text(sStmt, 0));
        if (shaVal && std::string(shaVal).size() > 0) {
          auto refGuard = db_.getStatement("SELECT COUNT(*) FROM file_index WHERE sha256 = ?");
          auto *refStmt = refGuard.get();
          sqlite3_bind_text(refStmt, 1, shaVal, -1, SQLITE_TRANSIENT);
          if (sqlite3_step(refStmt) == SQLITE_ROW) {
            if (sqlite3_column_int(refStmt, 0) <= 1) {
              const auto path = std::filesystem::path(server::ctx().config.storageRoot) / "data" / shaVal;
              std::error_code ec;
              std::filesystem::remove(path, ec);
            }
          }
        }
      }
    } else {
      const auto trashPath = getTrashPath(userId, id);
      std::filesystem::remove_all(trashPath);
    }

    // 3. Delete from file_index where is_deleted = 1
    {
      auto delIndexGuard = db_.getStatement(
          "DELETE FROM file_index WHERE owner_user_id = ? AND scope = ? AND (rel_path = ? OR rel_path LIKE ?) AND is_deleted = 1");
      auto *delIndexStmt = delIndexGuard.get();
      sqlite3_bind_int64(delIndexStmt, 1, userId);
      sqlite3_bind_text(delIndexStmt, 2, scopeStr.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(delIndexStmt, 3, originalPath.c_str(), -1, SQLITE_TRANSIENT);
      const auto pattern = originalPath + "/%";
      sqlite3_bind_text(delIndexStmt, 4, pattern.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_step(delIndexStmt);
    }

    // 4. Delete from trash
    {
      auto delTrashGuard = db_.getStatement("DELETE FROM trash WHERE id = ?");
      auto *delTrashStmt = delTrashGuard.get();
      sqlite3_bind_int64(delTrashStmt, 1, id);
      sqlite3_step(delTrashStmt);
    }
  }
}

void TrashService::purgeTrash(std::int64_t userId) {
  std::vector<std::int64_t> ids;
  {
    auto stmtGuard = db_.getStatement("SELECT id FROM trash WHERE owner_user_id = ?");
    auto *stmt = stmtGuard.get();
    sqlite3_bind_int64(stmt, 1, userId);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
      ids.push_back(sqlite3_column_int64(stmt, 0));
    }
  }

  deletePermanently(userId, ids);
}

void TrashService::cleanupExpiredTrash() {
  std::int64_t now = utils::nowMillis();

  std::vector<std::pair<std::int64_t, std::int64_t>> expired;
  {
    auto stmtGuard = db_.getStatement(
        "SELECT t.id, t.owner_user_id FROM trash t "
        "JOIN users u ON t.owner_user_id = u.id "
        "WHERE u.trash_retention_days > 0 AND t.deleted_at < (? - u.trash_retention_days * 86400000)");
    auto *stmt = stmtGuard.get();
    sqlite3_bind_int64(stmt, 1, now);

    while (sqlite3_step(stmt) == SQLITE_ROW) {
      expired.push_back({sqlite3_column_int64(stmt, 0), sqlite3_column_int64(stmt, 1)});
    }
  }

  std::unordered_map<std::int64_t, std::vector<std::int64_t>> grouped;
  for (const auto &p : expired) {
    grouped[p.second].push_back(p.first);
  }

  for (const auto &[userId, ids] : grouped) {
    deletePermanently(userId, ids);
  }
}

} // namespace server::services
