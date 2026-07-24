#pragma once

#include "server/db/Database.hpp"
#include "server/services/FileService.hpp"

#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <vector>

namespace server::services {

struct IndexedDirEntry {
  std::string name;
  std::string path;
  bool isDir;
  std::uintmax_t size;
  std::int64_t modifiedAt;
  std::string type;
  std::string mimeType;
  std::string thumbnailUrl;
};

struct ListIndexQuery {
  std::int64_t ownerUserId;
  StorageScope scope;
  std::string currentPath;
  std::string filterType;
  std::string query;
  std::string sortBy;
  bool sortAscending;
  bool includeDirs{true};
  bool recursiveFiles{false};
};

/**
 * Service managing SQLite-backed index operations for files and directories.
 * Implements prepared statement reuse via Database statement caching, transaction-batched
 * index rebuilds, and directory search indexing.
 */
class FileIndexService {
 public:
  FileIndexService(db::Database &db, const FileService &fileService);

  /**
   * Upserts file index entry from physical disk properties.
   */
  void upsertFile(std::int64_t ownerUserId,
                  StorageScope scope,
                  const std::string &relPath,
                  const std::filesystem::path &absolutePath,
                  std::int64_t uploaderUserId,
                  const std::string &thumbnailPath = "");

  /**
   * Explicitly upserts file index entry with given metadata attributes.
   * Reuses cached prepared statements for high performance.
   */
  void upsertFileExplicit(std::int64_t ownerUserId,
                          StorageScope scope,
                          const std::string &relPath,
                          const std::string &fileName,
                          std::int64_t size,
                          std::int64_t modifiedAt,
                          const std::string &type,
                          const std::string &mimeType,
                          std::int64_t uploaderUserId,
                          const std::string &sha256Val,
                          const std::string &thumbnailPath = "");

  void markDeleted(std::int64_t ownerUserId, StorageScope scope, const std::string &relPath);
  void markDeletedPrefix(std::int64_t ownerUserId, StorageScope scope, const std::string &relPrefix);

  /**
   * Queries directory entries from file_index using cached prepared statements.
   */
  std::vector<IndexedDirEntry> listDirectory(const ListIndexQuery &query) const;

  /**
   * Finds an indexed file matching sha256 hash using cached prepared statements.
   */
  std::optional<IndexedDirEntry> findFileByHash(std::int64_t ownerUserId,
                                                StorageScope scope,
                                                const std::string &sha256) const;

  void setSharedFlag(std::int64_t ownerUserId, const std::string &relPath, bool isShared);
  std::optional<std::int64_t> getSharedFileOwner(const std::string &relPath) const;
  bool canDeletePath(std::int64_t ownerUserId,
                     StorageScope scope,
                     const std::string &relPath,
                     std::int64_t requesterUserId,
                     bool isDirectory) const;

  /**
   * Rebuilds file index for a root directory by scanning filesystem entries.
   * Executed within an explicit SQLite transaction (`BEGIN IMMEDIATE TRANSACTION` ... `COMMIT`)
   * and reuses cached prepared statements for batch upserts and deletions.
   */
  std::int64_t rebuildIndex(std::int64_t ownerUserId,
                            StorageScope scope,
                            const std::filesystem::path &rootPath);

  static std::string scopeToString(StorageScope scope);
  static std::string normalizeRelPath(const std::string &rawPath);

 private:
  bool isAncestorShared(std::int64_t ownerUserId, const std::string &relPath) const;

  db::Database &db_;
  const FileService &fileService_;
};

}  // namespace server::services
