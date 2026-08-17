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

#include <cstdint>
#include <optional>
#include <string>

namespace server::services {

struct ShareRecord {
  std::string token;
  std::int64_t ownerUserId;
  std::string scope;
  std::string relPath;
};

class ShareService {
 public:
  explicit ShareService(db::Database &db);

  std::string createShare(std::int64_t ownerUserId,
                          const std::string &scope,
                          const std::string &relPath,
                          std::optional<std::int64_t> expiresAt);
  std::optional<ShareRecord> resolveShare(const std::string &token);

 private:
  db::Database &db_;
};

}  // namespace server::services
