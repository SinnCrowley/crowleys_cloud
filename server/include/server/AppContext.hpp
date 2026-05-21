#pragma once

#include "server/db/Database.hpp"
#include "server/middleware/RateLimiter.hpp"
#include "server/services/FileService.hpp"
#include "server/services/FileIndexService.hpp"
#include "server/services/ShareService.hpp"
#include "server/services/UserService.hpp"
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
  std::unique_ptr<middleware::RateLimiter> authRateLimiter;
};

AppContext &ctx();

}  // namespace server
