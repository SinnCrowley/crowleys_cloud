#include "server/utils/Config.hpp"

#include <fstream>

#include <drogon/drogon.h>

namespace server::utils {

Config loadConfig(const std::string &path) {
  Config cfg;
  std::ifstream input(path);
  if (!input.is_open()) {
    LOG_WARN << "Config file not found at " << path << ", using defaults";
    return cfg;
  }

  Json::Value json;
  input >> json;

  cfg.host = json.get("host", cfg.host).asString();
  cfg.port = static_cast<uint16_t>(json.get("port", cfg.port).asUInt());
  cfg.storageRoot = json.get("storage_root", cfg.storageRoot).asString();
  cfg.dbPath = json.get("db_path", cfg.dbPath).asString();
  cfg.jwtSecret = json.get("jwt_secret", cfg.jwtSecret).asString();
  cfg.uploadLimitBytes = json.get("upload_limit_bytes", Json::Int64(cfg.uploadLimitBytes)).asInt64();
  cfg.rateLimitPerMinute = json.get("rate_limit_per_minute", cfg.rateLimitPerMinute).asInt();
  cfg.accessTokenTtlSeconds = json.get("access_token_ttl_seconds", Json::Int64(cfg.accessTokenTtlSeconds)).asInt64();
  cfg.refreshTokenTtlSeconds = json.get("refresh_token_ttl_seconds", Json::Int64(cfg.refreshTokenTtlSeconds)).asInt64();
  cfg.logDir = json.get("log_dir", cfg.logDir).asString();
  cfg.logLevel = json.get("log_level", cfg.logLevel).asString();
  cfg.accessLogEnabled = json.get("access_log_enabled", cfg.accessLogEnabled).asBool();
  cfg.videoThumbsEnabled = json.get("video_thumbs_enabled", cfg.videoThumbsEnabled).asBool();
  cfg.ffmpegBinary = json.get("ffmpeg_binary", cfg.ffmpegBinary).asString();
  cfg.logRetentionDays = json.get("log_retention_days", cfg.logRetentionDays).asInt();
  cfg.hashFiles = json.get("hash_files", cfg.hashFiles).asBool();
  cfg.encryptionKey = json.get("encryption_key", cfg.encryptionKey).asString();

  try {
    cfg.storageRoot = std::filesystem::weakly_canonical(cfg.storageRoot).generic_string();
  } catch (...) {}
  try {
    cfg.dbPath = std::filesystem::weakly_canonical(cfg.dbPath).generic_string();
  } catch (...) {}

  return cfg;
}

}  // namespace server::utils
