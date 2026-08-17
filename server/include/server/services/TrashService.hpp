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
#include <string>
#include <vector>
#include <optional>
#include <filesystem>

namespace server::services {

struct TrashEntry {
  std::int64_t id;
  std::int64_t ownerUserId;
  std::string scope;
  std::string originalPath;
  std::string name;
  bool isDir;
  std::uintmax_t size;
  std::string type;
  std::string mimeType;
  std::int64_t deletedAt;
};

struct TrashConflict {
  std::int64_t id;
  std::string name;
  std::string originalPath;
  std::uintmax_t existingSize{0};
  std::int64_t existingModified{0};
  std::uintmax_t trashSize{0};
  std::int64_t trashDeletedAt{0};
};

class TrashService {
 public:
  TrashService(db::Database &db, const FileService &fileService);

  std::int64_t getTrashRetentionDays(std::int64_t userId) const;
  void setTrashRetentionDays(std::int64_t userId, std::int64_t days);
  
  std::vector<TrashEntry> listTrash(std::int64_t userId, StorageScope scope, const std::string &searchQuery = "") const;
  
  void moveToTrash(std::int64_t userId, StorageScope scope, const std::string &relPath);
  std::vector<TrashConflict> checkRestoreConflicts(std::int64_t userId, const std::vector<std::int64_t> &ids) const;
  void restoreFromTrash(std::int64_t userId, const std::vector<std::int64_t> &ids, bool overwrite = false);
  void deletePermanently(std::int64_t userId, const std::vector<std::int64_t> &ids);
  
  void purgeTrash(std::int64_t userId);
  void cleanupExpiredTrash();

 private:
  db::Database &db_;
  const FileService &fileService_;

  std::filesystem::path getTrashPath(std::int64_t userId, std::int64_t trashId) const;
};

} // namespace server::services
