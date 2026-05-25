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

class FileIndexService {
 public:
  FileIndexService(db::Database &db, const FileService &fileService);

  void upsertFile(std::int64_t ownerUserId,
                  StorageScope scope,
                  const std::string &relPath,
                  const std::filesystem::path &absolutePath,
                  std::int64_t uploaderUserId,
                  const std::string &thumbnailPath = "");
  void markDeleted(std::int64_t ownerUserId, StorageScope scope, const std::string &relPath);
  void markDeletedPrefix(std::int64_t ownerUserId, StorageScope scope, const std::string &relPrefix);

  std::vector<IndexedDirEntry> listDirectory(const ListIndexQuery &query) const;
  bool canDeletePath(std::int64_t ownerUserId,
                     StorageScope scope,
                     const std::string &relPath,
                     std::int64_t requesterUserId,
                     bool isDirectory) const;

  std::int64_t rebuildIndex(std::int64_t ownerUserId,
                            StorageScope scope,
                            const std::filesystem::path &rootPath);

  static std::string scopeToString(StorageScope scope);
  static std::string normalizeRelPath(const std::string &rawPath);

 private:
  db::Database &db_;
  const FileService &fileService_;
};

}  // namespace server::services
