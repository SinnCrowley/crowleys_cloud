#include "server/AppContext.hpp"
#include "server/middleware/JwtMiddleware.hpp"
#include "server/utils/Config.hpp"

#include <drogon/drogon.h>
#include <trantor/utils/Logger.h>

#include <filesystem>

namespace server {
AppContext &ctx() {
  static AppContext singleton;
  return singleton;
}
}  // namespace server

int main() {
  auto &appCtx = server::ctx();
  appCtx.config = server::utils::loadConfig("./config/config.json");

  std::filesystem::create_directories(std::filesystem::path(appCtx.config.storageRoot) / "users");
  std::filesystem::create_directories(std::filesystem::path(appCtx.config.storageRoot) / "shared");
  std::filesystem::create_directories("./data");
  std::filesystem::create_directories(appCtx.config.logDir);

  appCtx.database = std::make_unique<server::db::Database>("./data/server.sqlite3");
  appCtx.database->migrate();

  appCtx.userService = std::make_unique<server::services::UserService>(*appCtx.database, appCtx.config);
  appCtx.fileService = std::make_unique<server::services::FileService>(appCtx.config);
  appCtx.fileIndexService =
      std::make_unique<server::services::FileIndexService>(*appCtx.database, *appCtx.fileService);
  appCtx.shareService = std::make_unique<server::services::ShareService>(*appCtx.database);
  appCtx.authRateLimiter = std::make_unique<server::middleware::RateLimiter>(appCtx.config.rateLimitPerMinute);

  const auto level = appCtx.config.logLevel;
  if (level == "TRACE") {
    drogon::app().setLogLevel(trantor::Logger::kTrace);
  } else if (level == "DEBUG") {
    drogon::app().setLogLevel(trantor::Logger::kDebug);
  } else if (level == "WARN") {
    drogon::app().setLogLevel(trantor::Logger::kWarn);
  } else if (level == "ERROR") {
    drogon::app().setLogLevel(trantor::Logger::kError);
  } else {
    drogon::app().setLogLevel(trantor::Logger::kInfo);
  }
  drogon::app().setLogPath(appCtx.config.logDir);

  if (appCtx.config.accessLogEnabled) {
    drogon::app().registerPostHandlingAdvice([](const drogon::HttpRequestPtr &req,
                                                const drogon::HttpResponsePtr &resp) {
      LOG_INFO << "access method=" << req->methodString()
               << " path=" << req->path()
               << " status=" << static_cast<int>(resp->statusCode())
               << " ip=" << req->peerAddr().toIp();
    });
  }

  drogon::app().addListener(appCtx.config.host, appCtx.config.port);
  if (appCtx.config.uploadLimitBytes > 0) {
    const auto limit = static_cast<size_t>(appCtx.config.uploadLimitBytes);
    drogon::app().setClientMaxBodySize(limit);
    drogon::app().setClientMaxMemoryBodySize(limit);
  }
  LOG_INFO << "Starting server on " << appCtx.config.host << ":" << appCtx.config.port
           << " with logs in " << appCtx.config.logDir;
  drogon::app().run();
  return 0;
}
