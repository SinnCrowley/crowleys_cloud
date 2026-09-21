// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later
#include "server/services/ConfigService.hpp"
#include "server/AppContext.hpp"
#include "server/utils/DurableFiles.hpp"
#include <cstdlib>
#include <drogon/drogon.h>
#include <fstream>
#include <set>
#include <sstream>
#include <stdexcept>

namespace server::services {
namespace {
struct Field { const char *name; const char *type; const char *apply; };
const Field fields[] = {
  {"registration_mode", "string", "live"},
  {"default_quota_bytes", "integer", "live"},
  {"host", "string", "restart"},
  {"port", "integer", "restart"},
  {"storage_root", "string", "migration"},
  {"db_path", "string", "migration"},
  {"temp_upload_dir", "string", "restart"},
  {"public_dir", "string", "restart"},
  {"jwt_secret", "string", "rotation"},
  {"upload_limit_bytes", "integer", "live"},
  {"rate_limit_per_minute", "integer", "live"},
  {"access_token_ttl_seconds", "integer", "live"},
  {"refresh_token_ttl_seconds", "integer", "live"},
  {"log_dir", "string", "restart"},
  {"log_level", "string", "live"},
  {"access_log_enabled", "boolean", "live"},
  {"video_thumbs_enabled", "boolean", "live"},
  {"ffmpeg_binary", "string", "live"},
  {"log_retention_days", "integer", "live"},
  {"hash_files", "boolean", "migration"},
  {"encryption_key", "string", "rotation"},
  {"trash_retention_days", "integer", "live"},
};
bool secretField(const std::string &name) { return name == "jwt_secret" || name == "encryption_key"; }
const char *environment(const std::string &name) {
  if (name == "jwt_secret") {
    const auto value = std::getenv("CROWLEYS_JWT_SECRET");
    return value && *value != '\0' ? value : nullptr;
  }
  if (name == "encryption_key") {
    const auto value = std::getenv("CROWLEYS_ENCRYPTION_KEY");
    return value && *value != '\0' ? value : nullptr;
  }
  return nullptr;
}
std::string contents(const std::filesystem::path &path) {
  if (!std::filesystem::exists(path)) return "";
  std::ifstream input(path, std::ios::binary);
  if (!input) throw std::runtime_error("config_unreadable");
  std::ostringstream output;
  output << input.rdbuf();
  return output.str();
}
Json::Value readObject(const std::filesystem::path &path) {
  const auto text = contents(path);
  if (text.empty()) return Json::Value(Json::objectValue);
  Json::Value value;
  Json::CharReaderBuilder builder;
  std::string error;
  std::istringstream input(text);
  if (!Json::parseFromStream(builder, input, &value, &error) || !value.isObject()) throw std::runtime_error("config_unreadable");
  return value;
}
void requireSuperuser(std::int64_t actor) {
  const auto user = ctx().userService->getUserById(actor);
  if (!user || user->role != "superuser" || user->status != "active" || user->passwordResetRequired) throw std::runtime_error("forbidden");
}
void validate(const Json::Value &values) {
  for (const auto &field : fields) {
    const auto &value = values[field.name];
    const std::string type = field.type;
    if ((type == "string" && !value.isString()) || (type == "boolean" && !value.isBool()) ||
        (type == "integer" && (!value.isInt64() || value.asInt64() < 0))) throw std::runtime_error("invalid_config_value");
    if (type == "string" && value.asString().find('\0') != std::string::npos) throw std::runtime_error("invalid_config_value");
  }
  if (values["port"].asInt64() < 1 || values["port"].asInt64() > 65535 ||
      values["rate_limit_per_minute"].asInt64() < 1 || values["rate_limit_per_minute"].asInt64() > 1000000 ||
      values["access_token_ttl_seconds"].asInt64() < 1 || values["access_token_ttl_seconds"].asInt64() > 315360000 ||
      values["refresh_token_ttl_seconds"].asInt64() < 1 || values["refresh_token_ttl_seconds"].asInt64() > 315360000 ||
      values["log_retention_days"].asInt64() > 365000 || values["trash_retention_days"].asInt64() > 365000)
    throw std::runtime_error("invalid_config_value");
  const auto mode = values["registration_mode"].asString();
  if (mode != "open" && mode != "approval" && mode != "closed") throw std::runtime_error("invalid_config_value");
  const std::set<std::string> levels{"TRACE", "DEBUG", "INFO", "WARN", "ERROR"};
  if (!levels.count(values["log_level"].asString())) throw std::runtime_error("invalid_config_value");
  for (const auto *key : {"host", "storage_root", "db_path", "temp_upload_dir", "public_dir", "log_dir", "ffmpeg_binary"})
    if (values[key].asString().empty()) throw std::runtime_error("invalid_config_value");
  if (values["jwt_secret"].asString().size() < 32 ||
      (values["hash_files"].asBool() && values["encryption_key"].asString().size() < 32)) throw std::runtime_error("invalid_secret");
}
void applyLive(utils::Config &config, const Json::Value &values) {
  config.registrationMode = values["registration_mode"].asString();
  config.defaultQuotaBytes = values["default_quota_bytes"].asInt64();
  config.uploadLimitBytes = values["upload_limit_bytes"].asInt64();
  config.rateLimitPerMinute = values["rate_limit_per_minute"].asInt64();
  config.accessTokenTtlSeconds = values["access_token_ttl_seconds"].asInt64();
  config.refreshTokenTtlSeconds = values["refresh_token_ttl_seconds"].asInt64();
  config.logLevel = values["log_level"].asString();
  config.accessLogEnabled = values["access_log_enabled"].asBool();
  config.videoThumbsEnabled = values["video_thumbs_enabled"].asBool();
  config.ffmpegBinary = values["ffmpeg_binary"].asString();
  config.logRetentionDays = values["log_retention_days"].asInt64();
  config.trashRetentionDays = values["trash_retention_days"].asInt64();
  ctx().accessLogEnabled = config.accessLogEnabled;
  ctx().authRateLimiter->setLimit(config.rateLimitPerMinute);
  const auto level = config.logLevel;
  drogon::app().setLogLevel(level == "TRACE" ? trantor::Logger::kTrace : level == "DEBUG" ? trantor::Logger::kDebug :
                          level == "WARN" ? trantor::Logger::kWarn : level == "ERROR" ? trantor::Logger::kError : trantor::Logger::kInfo);
}
}
Json::Value configJson(const utils::Config &config) {
  Json::Value value;
  value["registration_mode"] = config.registrationMode;
  value["default_quota_bytes"] = Json::Int64(config.defaultQuotaBytes);
  value["host"] = config.host;
  value["port"] = Json::Int64(config.port);
  value["storage_root"] = config.storageRoot;
  value["db_path"] = config.dbPath;
  value["temp_upload_dir"] = config.tempUploadDir;
  value["public_dir"] = config.publicDir;
  value["jwt_secret"] = config.jwtSecret;
  value["upload_limit_bytes"] = Json::Int64(config.uploadLimitBytes);
  value["rate_limit_per_minute"] = Json::Int64(config.rateLimitPerMinute);
  value["access_token_ttl_seconds"] = Json::Int64(config.accessTokenTtlSeconds);
  value["refresh_token_ttl_seconds"] = Json::Int64(config.refreshTokenTtlSeconds);
  value["log_dir"] = config.logDir;
  value["log_level"] = config.logLevel;
  value["access_log_enabled"] = config.accessLogEnabled;
  value["video_thumbs_enabled"] = config.videoThumbsEnabled;
  value["ffmpeg_binary"] = config.ffmpegBinary;
  value["log_retention_days"] = Json::Int64(config.logRetentionDays);
  value["hash_files"] = config.hashFiles;
  value["encryption_key"] = config.encryptionKey;
  value["trash_retention_days"] = Json::Int64(config.trashRetentionDays);
  return value;
}
std::filesystem::path ConfigService::localPath() const {
  return std::filesystem::path(config_.sourcePath).parent_path() / "config.local.json";
}
std::string ConfigService::revision() const {
  return utils::sha256Hex(contents(config_.sourcePath) + "|" + contents(localPath()));
}
Json::Value ConfigService::overrides() const { return readObject(localPath()); }
void ConfigService::persist(const Json::Value &values) {
  utils::writePrivateAtomic(localPath(), Json::writeString(Json::StreamWriterBuilder(), values) + "\n");
}
Json::Value ConfigService::snapshot() const {
  std::shared_lock<std::shared_mutex> lock(ctx().configMutex);
  return snapshotLocked();
}
Json::Value ConfigService::snapshotLocked() const {
  auto savedConfig = utils::loadConfig(config_.sourcePath);
  if (const auto value = environment("jwt_secret")) savedConfig.jwtSecret = value;
  if (const auto value = environment("encryption_key")) savedConfig.encryptionKey = value;
  const auto saved = configJson(savedConfig);
  const auto effective = configJson(config_);
  const auto local = overrides();
  const auto base = readObject(config_.sourcePath);
  Json::Value result;
  result["revision"] = revision();
  result["fields"] = Json::arrayValue;
  for (const auto &field : fields) {
    Json::Value item;
    item["name"] = field.name;
    item["type"] = field.type;
    item["apply"] = field.apply;
    item["secret"] = secretField(field.name);
    item["source"] = environment(field.name) ? "environment" : local.isMember(field.name) ? "local" : base.isMember(field.name) ? "base" : "default";
    item["editable"] = !environment(field.name);
    item["pending"] = saved[field.name] != effective[field.name];
    item["value"] = secretField(field.name) ? Json::Value() : saved[field.name];
    item["effective"] = secretField(field.name) ? Json::Value() : effective[field.name];
    item["configured"] = secretField(field.name) && !effective[field.name].asString().empty();
    result["fields"].append(item);
  }
  return result;
}
Json::Value ConfigService::save(std::int64_t actor, const std::string &expectedRevision, const Json::Value &changes) {
  std::unique_lock<std::shared_mutex> lock(ctx().configMutex);
  std::lock_guard<std::recursive_mutex> storageLock(ctx().storageMutex);
  requireSuperuser(actor);
  if (ctx().storageActivity.blocked()) throw std::runtime_error("maintenance");
  if (expectedRevision != revision()) throw std::runtime_error("config_conflict");
  if (!changes.isObject() || changes.empty()) throw std::runtime_error("invalid_config_patch");
  auto local = overrides();
  auto savedConfig = utils::loadConfig(config_.sourcePath);
  if (const auto value = environment("jwt_secret")) savedConfig.jwtSecret = value;
  if (const auto value = environment("encryption_key")) savedConfig.encryptionKey = value;
  auto values = configJson(savedConfig);
  const auto effective = configJson(config_);
  for (const auto &key : changes.getMemberNames()) {
    if (!values.isMember(key)) throw std::runtime_error("unknown_config_field");
    if (environment(key)) throw std::runtime_error("config_from_environment");
    if (secretField(key)) throw std::runtime_error("rotation_required");
    if (key == "db_path" || key == "storage_root" || key == "hash_files") {
      bool nonempty;
      {
        auto guard = ctx().database->getStatement(key == "db_path" ? "SELECT 1 FROM users LIMIT 1" :
            "SELECT 1 FROM file_index UNION ALL SELECT 1 FROM trash UNION ALL SELECT 1 FROM upload_reservations LIMIT 1");
        nonempty = sqlite3_step(guard.get()) == SQLITE_ROW;
      }
      if (!nonempty && key != "db_path" && std::filesystem::exists(config_.storageRoot)) {
        for (const auto &entry : std::filesystem::recursive_directory_iterator(config_.storageRoot)) {
          if (entry.is_regular_file() || entry.is_symlink()) { nonempty = true; break; }
        }
      }
      if (nonempty && changes[key] != effective[key]) throw std::runtime_error("manual_migration_required");
    }
    values[key] = changes[key];
    local[key] = changes[key];
  }
  validate(values);
  for (const auto *key : {"storage_root", "db_path", "temp_upload_dir", "public_dir", "log_dir"}) {
    if (changes.isMember(key) && !std::filesystem::path(changes[key].asString()).is_absolute()) throw std::runtime_error("absolute_path_required");
  }
  persist(local);
  applyLive(config_, values);
  ctx().userService->audit(actor, "config.update", 0);
  return snapshotLocked();
}
void ConfigService::rotateSigningSecret(std::int64_t actor, const std::string &expectedRevision, const std::string &secret) {
  std::unique_lock<std::shared_mutex> lock(ctx().configMutex);
  requireSuperuser(actor);
  if (ctx().storageActivity.blocked()) throw std::runtime_error("maintenance");
  if (expectedRevision != revision()) throw std::runtime_error("config_conflict");
  if (environment("jwt_secret")) throw std::runtime_error("config_from_environment");
  if (secret.size() < 32 || secret.size() > 4096 || secret.find('\0') != std::string::npos || secret == config_.jwtSecret) throw std::runtime_error("invalid_secret");
  auto local = overrides();
  local["jwt_secret"] = secret;
  // Revoke durably before changing the signing secret. A crash between these
  // steps may require retrying rotation but cannot leave old refresh sessions valid.
  {
    db::Database::TransactionGuard transaction(*ctx().database);
    {
      auto guard = ctx().database->getStatement("UPDATE users SET auth_version = auth_version + 1");
      if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("session_revocation_failed");
    }
    {
      auto guard = ctx().database->getStatement("DELETE FROM refresh_tokens");
      if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("session_revocation_failed");
    }
    // Recovery-code hashes are keyed by the signing secret to prevent offline
    // brute force of the six-digit value after a database-only disclosure.
    {
      auto guard = ctx().database->getStatement("DELETE FROM password_resets");
      if (sqlite3_step(guard.get()) != SQLITE_DONE) throw std::runtime_error("session_revocation_failed");
    }
    ctx().userService->audit(actor, "config.signing_rotation_started", 0);
    transaction.commit();
  }
  persist(local);
  config_.jwtSecret = secret;
  ctx().userService->audit(actor, "config.signing_rotation_completed", 0);
}
void ConfigService::finishEncryptionRotation(const std::string &oldKey, const std::string &newKey) {
  std::unique_lock<std::shared_mutex> lock(ctx().configMutex);
  if (environment("encryption_key")) throw std::runtime_error("config_from_environment");
  if (config_.encryptionKey != oldKey && config_.encryptionKey != newKey) throw std::runtime_error("encryption_key_conflict");
  auto local = overrides();
  local["encryption_key"] = newKey;
  persist(local);
  config_.encryptionKey = newKey;
}
}
