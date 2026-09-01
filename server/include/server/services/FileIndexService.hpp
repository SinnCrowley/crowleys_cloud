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
  bool isShared{false};
  std::int64_t uploaderUserId{0};
  std::string blurhash;
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

struct UserStats {
  std::uintmax_t totalSize{0};
  std::int64_t totalCount{0};
  std::int64_t photoCount{0};
  std::uintmax_t photoSize{0};
  std::int64_t videoCount{0};
  std::uintmax_t videoSize{0};
  std::int64_t audioCount{0};
  std::uintmax_t audioSize{0};
  std::int64_t documentCount{0};
  std::uintmax_t documentSize{0};
  std::int64_t otherCount{0};
  std::uintmax_t otherSize{0};
  std::int64_t sharedCount{0};
  std::uintmax_t sharedSize{0};
};

/**
 * Service managing SQLite-backed index operations for files and directories.
 * Implements prepared statement reuse via Database statement caching, transaction-batched
 * index rebuilds, and directory search indexing.
 */
class FileIndexService {
 public:
  FileIndexService(db::Database &db, const FileService &fileService);

  UserStats getUserStats(std::int64_t userId) const;

  /**
   * Upserts file index entry from physical disk properties.
   */
  void upsertFile(std::int64_t ownerUserId,
                  StorageScope scope,
                  const std::string &relPath,
                  const std::filesystem::path &absolutePath,
                  std::int64_t uploaderUserId,
                  const std::string &thumbnailPath = "",
                  const std::string &blurhash = "");

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
                          const std::string &thumbnailPath = "",
                          const std::string &blurhash = "");

  void updateBlurHash(std::int64_t ownerUserId,
                      StorageScope scope,
                      const std::string &relPath,
                      const std::string &blurhash);

  void updateBlurHashBySha256(const std::string &sha256,
                              const std::string &blurhash);

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
