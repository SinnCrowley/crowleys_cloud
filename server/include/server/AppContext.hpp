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
#include "server/middleware/RateLimiter.hpp"
#include "server/services/FileService.hpp"
#include "server/services/FileIndexService.hpp"
#include "server/services/ShareService.hpp"
#include "server/services/UserService.hpp"
#include "server/services/TrashService.hpp"
#include "server/utils/Config.hpp"

#include <memory>

namespace server {

struct AppContext {
  utils::Config config;
  std::unique_ptr<db::Database> database;
  std::unique_ptr<services::UserService> userService;
  std::unique_ptr<services::FileService> fileService;
  std::unique_ptr<services::FileIndexService> fileIndexService;
  std::unique_ptr<services::ShareService> shareService;
  std::unique_ptr<services::TrashService> trashService;
  std::unique_ptr<middleware::RateLimiter> authRateLimiter;
};

AppContext &ctx();

}  // namespace server
