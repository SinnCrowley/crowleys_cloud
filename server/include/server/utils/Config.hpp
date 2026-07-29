#pragma once

#include <cstdint>
#include <string>

namespace server::utils {

struct Config {
  std::string host{"0.0.0.0"};
  uint16_t port{8080};
  std::string storageRoot{"./storage"};
  std::string dbPath{"./data/server.sqlite3"};
  std::string tempUploadDir{"./uploads"};
  std::string jwtSecret{"change-this-secret"};
  std::int64_t uploadLimitBytes{10LL * 1024 * 1024 * 1024};
  int rateLimitPerMinute{10};
  std::int64_t accessTokenTtlSeconds{24 * 60 * 60};
  std::int64_t refreshTokenTtlSeconds{90LL * 24 * 60 * 60};
  std::string logDir{"./logs"};
  std::string logLevel{"INFO"};
  bool accessLogEnabled{true};
  bool videoThumbsEnabled{true};
  std::string ffmpegBinary{"ffmpeg"};
  int logRetentionDays{0};
  bool hashFiles{false};
  std::string encryptionKey{""};
};

Config loadConfig(const std::string &path);

}  // namespace server::utils
