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

#include "server/utils/Config.hpp"
#include "server/utils/PlatformUtils.hpp"
#include "server/utils/Crypto.hpp"

#include <fstream>
#include <filesystem>
#include <stdexcept>
#include <cstdlib>


#include <drogon/drogon.h>

namespace server::utils {

std::string resolveConfigPath(int argc, char *argv[]) {
  if (argc > 1 && argv[1] != nullptr && argv[1][0] != '\0') {
    return argv[1];
  }

  std::error_code ec;

  // 1. Executable-relative candidates (packaged layout and dev build)
  auto exeDir = getExecutableDir();
  if (!exeDir.empty()) {
    // <exeDir>/config/config.json
    auto p1 = exeDir / "config" / "config.json";
    if (std::filesystem::exists(p1, ec)) {
      auto cp = std::filesystem::weakly_canonical(p1, ec);
      return (!ec && !cp.empty()) ? cp.generic_string() : p1.generic_string();
    }

    // <exeDir>/config.json
    auto p2 = exeDir / "config.json";
    if (std::filesystem::exists(p2, ec)) {
      auto cp = std::filesystem::weakly_canonical(p2, ec);
      return (!ec && !cp.empty()) ? cp.generic_string() : p2.generic_string();
    }

    // <exeDir>/../config/config.json (e.g. build/ or bin/ directory during development)
    auto p3 = exeDir / ".." / "config" / "config.json";
    if (std::filesystem::exists(p3, ec)) {
      auto cp = std::filesystem::weakly_canonical(p3, ec);
      return (!ec && !cp.empty()) ? cp.generic_string() : p3.generic_string();
    }

    // <exeDir>/../../config/config.json (e.g. build/Release/ or build/Debug/ in multi-config generators)
    auto p4 = exeDir / ".." / ".." / "config" / "config.json";
    if (std::filesystem::exists(p4, ec)) {
      auto cp = std::filesystem::weakly_canonical(p4, ec);
      return (!ec && !cp.empty()) ? cp.generic_string() : p4.generic_string();
    }
  }

  // 2. Current working directory: ./config/config.json
  if (std::filesystem::exists("./config/config.json", ec)) {
    return "./config/config.json";
  }

  // 3. Fallback to <exeDir>/config/config.json if available
  if (!exeDir.empty()) {
    auto p1 = exeDir / "config" / "config.json";
    auto cp = std::filesystem::weakly_canonical(p1, ec);
    return (!ec && !cp.empty()) ? cp.generic_string() : p1.generic_string();
  }

  return "./config/config.json";
}

Config loadConfig(const std::string &path, bool initializeSecrets) {
  Config cfg;
  std::string actualPath = path;
  std::error_code ec;

  // If path does not exist as given, attempt discovery relative to executable directory
  if (!actualPath.empty() && !std::filesystem::exists(actualPath, ec)) {
    auto exeDir = getExecutableDir();
    if (!exeDir.empty()) {
      auto candidate = exeDir / path;
      if (std::filesystem::exists(candidate, ec)) {
        auto cp = std::filesystem::weakly_canonical(candidate, ec);
        actualPath = (!ec && !cp.empty()) ? cp.generic_string() : candidate.generic_string();
      } else {
        auto parentCandidate = exeDir / ".." / path;
        if (std::filesystem::exists(parentCandidate, ec)) {
          auto cp = std::filesystem::weakly_canonical(parentCandidate, ec);
          actualPath = (!ec && !cp.empty()) ? cp.generic_string() : parentCandidate.generic_string();
        } else {
          auto grandParentCandidate = exeDir / ".." / ".." / path;
          if (std::filesystem::exists(grandParentCandidate, ec)) {
            auto cp = std::filesystem::weakly_canonical(grandParentCandidate, ec);
            actualPath = (!ec && !cp.empty()) ? cp.generic_string() : grandParentCandidate.generic_string();
          }
        }
      }
    }
  }

  // Passing config.local.json explicitly still includes its sibling base config.
  if (std::filesystem::path(actualPath).filename() == "config.local.json") {
    actualPath = (std::filesystem::path(actualPath).parent_path() / "config.json").string();
  }

  auto applyFile = [&](const std::filesystem::path &file, bool local) {
    try {
      std::ifstream input(file);
      if (!input.is_open()) throw std::runtime_error("Cannot open configuration");
      Json::Value json;
      input >> json;
      if (!json.isObject()) throw std::runtime_error("Configuration must be an object");
      if (local) {
        for (const auto &name : json.getMemberNames()) {
          if (json[name].isNull()) throw std::runtime_error("Null override is not supported");
        }
      }
      // Apply atomically: a bad field must not leave a partially loaded config.
      Config updated = cfg;
      updated.registrationMode = json.get("registration_mode", updated.registrationMode).asString();
      if (updated.registrationMode != "approval" && updated.registrationMode != "open" && updated.registrationMode != "closed")
        throw std::runtime_error("Invalid registration mode");
      updated.defaultQuotaBytes = json.get("default_quota_bytes", Json::Int64(updated.defaultQuotaBytes)).asInt64();
      if (updated.defaultQuotaBytes < 0) throw std::runtime_error("Invalid default quota");
      updated.host = json.get("host", updated.host).asString();
      updated.port = static_cast<uint16_t>(json.get("port", updated.port).asUInt());
      updated.storageRoot = json.get("storage_root", updated.storageRoot).asString();
      updated.dbPath = json.get("db_path", updated.dbPath).asString();
      updated.tempUploadDir = json.get("temp_upload_dir", updated.tempUploadDir).asString();
      updated.publicDir = json.get("public_dir", updated.publicDir).asString();
      updated.jwtSecret = json.get("jwt_secret", updated.jwtSecret).asString();
      updated.uploadLimitBytes = json.get("upload_limit_bytes", Json::Int64(updated.uploadLimitBytes)).asInt64();
      updated.rateLimitPerMinute = json.get("rate_limit_per_minute", updated.rateLimitPerMinute).asInt();
      updated.accessTokenTtlSeconds = json.get("access_token_ttl_seconds", Json::Int64(updated.accessTokenTtlSeconds)).asInt64();
      updated.refreshTokenTtlSeconds = json.get("refresh_token_ttl_seconds", Json::Int64(updated.refreshTokenTtlSeconds)).asInt64();
      updated.logDir = json.get("log_dir", updated.logDir).asString();
      updated.logLevel = json.get("log_level", updated.logLevel).asString();
      updated.accessLogEnabled = json.get("access_log_enabled", updated.accessLogEnabled).asBool();
      updated.videoThumbsEnabled = json.get("video_thumbs_enabled", updated.videoThumbsEnabled).asBool();
      updated.ffmpegBinary = json.get("ffmpeg_binary", updated.ffmpegBinary).asString();
      updated.logRetentionDays = json.get("log_retention_days", updated.logRetentionDays).asInt();
      updated.hashFiles = json.get("hash_files", updated.hashFiles).asBool();
      updated.encryptionKey = json.get("encryption_key", updated.encryptionKey).asString();
      updated.trashRetentionDays = json.get("trash_retention_days", updated.trashRetentionDays).asInt();
      cfg = std::move(updated);
    } catch (...) {
      // Parser errors can include secret values; report only the file path.
      if (local || initializeSecrets) throw std::runtime_error("Invalid or unreadable config: " + file.string());
      LOG_ERROR << "Invalid or unreadable config at " << file.string() << ", using defaults";
    }
  };

  if (actualPath.empty() || !std::filesystem::is_regular_file(actualPath, ec)) {
    LOG_WARN << "Config file not found or not a regular file at " << path << ", using defaults";
  } else {
    applyFile(actualPath, false);
  }

  // Never discover overrides from CWD: they belong to the selected base file.
  if (!actualPath.empty() && !std::filesystem::is_directory(actualPath)) {
    const auto localPath = std::filesystem::path(actualPath).parent_path() / "config.local.json";
    if (std::filesystem::exists(localPath)) {
      applyFile(localPath, true);
    }
  }

  // Determine base directory for resolving relative application paths
  auto exeDir = getExecutableDir();
  std::filesystem::path baseDir;

  if (!actualPath.empty() && std::filesystem::exists(actualPath, ec)) {
    auto cfgAbs = std::filesystem::absolute(actualPath, ec);
    auto cfgDir = (!ec && !cfgAbs.empty()) ? cfgAbs.parent_path() : std::filesystem::path(actualPath).parent_path();
    if (cfgDir.filename() == "config") {
      baseDir = cfgDir.parent_path();
    } else {
      baseDir = cfgDir;
    }
  } else if (!exeDir.empty()) {
    if (std::filesystem::exists(exeDir / "public", ec) || std::filesystem::exists(exeDir / "config", ec)) {
      baseDir = exeDir;
    } else if (std::filesystem::exists(exeDir.parent_path() / "public", ec) ||
               std::filesystem::exists(exeDir.parent_path() / "config", ec)) {
      baseDir = exeDir.parent_path();
    } else if (std::filesystem::exists(exeDir.parent_path().parent_path() / "public", ec) ||
               std::filesystem::exists(exeDir.parent_path().parent_path() / "config", ec)) {
      baseDir = exeDir.parent_path().parent_path();
    } else {
      baseDir = exeDir;
    }
  } else {
    baseDir = std::filesystem::current_path(ec);
  }

  auto resolveRelative = [&](const std::string &raw, bool isPublicAsset = false) -> std::string {
    if (raw.empty()) return raw;
    std::filesystem::path p(raw);
    if (p.is_absolute()) {
      auto cp = std::filesystem::weakly_canonical(p, ec);
      return (!ec && !cp.empty()) ? cp.generic_string() : p.generic_string();
    }

    // 1. When baseDir is known, resolve relative to application baseDir
    if (!baseDir.empty()) {
      auto resolved = baseDir / p;
      if (isPublicAsset && !std::filesystem::exists(resolved, ec) && !exeDir.empty()) {
        auto exeCandidate = exeDir / p;
        if (std::filesystem::exists(exeCandidate, ec)) {
          resolved = exeCandidate;
        } else {
          auto exeParentCandidate = exeDir.parent_path() / p;
          if (std::filesystem::exists(exeParentCandidate, ec)) {
            resolved = exeParentCandidate;
          } else {
            auto exeGrandParentCandidate = exeDir.parent_path().parent_path() / p;
            if (std::filesystem::exists(exeGrandParentCandidate, ec)) {
              resolved = exeGrandParentCandidate;
            }
          }
        }
      }
      auto cp = std::filesystem::weakly_canonical(resolved, ec);
      return (!ec && !cp.empty()) ? cp.generic_string() : resolved.generic_string();
    }

    // 2. Only if baseDir is completely unavailable, fall back to CWD
    auto cwdCandidate = std::filesystem::current_path(ec) / p;
    auto cp = std::filesystem::weakly_canonical(cwdCandidate, ec);
    return (!ec && !cp.empty()) ? cp.generic_string() : cwdCandidate.generic_string();
  };

  cfg.storageRoot = resolveRelative(cfg.storageRoot);
  cfg.dbPath = resolveRelative(cfg.dbPath);
  cfg.tempUploadDir = resolveRelative(cfg.tempUploadDir);
  cfg.publicDir = resolveRelative(cfg.publicDir, true);
  cfg.logDir = resolveRelative(cfg.logDir);

  if (initializeSecrets) {
    auto environment = [&] {
      if (const auto value = std::getenv("CROWLEYS_JWT_SECRET"); value && *value != '\0') cfg.jwtSecret = value;
      if (const auto value = std::getenv("CROWLEYS_ENCRYPTION_KEY"); value && *value != '\0') cfg.encryptionKey = value;
    };
    auto missingJwt = [&] { return cfg.jwtSecret.empty() || cfg.jwtSecret == "change-this-secret"; };
    auto missingKey = [&] { return cfg.encryptionKey.empty() || cfg.encryptionKey == "default-local-encryption-key-for-testing"; };
    environment();
    if (missingJwt() || (cfg.hashFiles && missingKey())) {
      if (actualPath.empty() || !std::filesystem::is_regular_file(actualPath)) {
        throw std::runtime_error("Secret initialization requires an existing base config file");
      }
      const auto local = std::filesystem::path(actualPath).parent_path() / "config.local.json";
      const auto lock = std::filesystem::path(local.string() + ".init-lock");
      if (!std::filesystem::create_directory(lock)) {
        throw std::runtime_error("Secret initialization is locked; stop other server processes before removing " + lock.string());
      }
      struct Cleanup {
        std::filesystem::path path;
        ~Cleanup() { std::error_code ignored; std::filesystem::remove_all(path, ignored); }
      } cleanup{lock};
#ifndef _WIN32
      std::filesystem::permissions(lock, std::filesystem::perms::owner_all);
#endif
      // Re-read after taking the lock: another first launch may have just finished.
      cfg = loadConfig(actualPath);
      environment();
      if (missingJwt() || (cfg.hashFiles && missingKey())) {
        if (std::filesystem::exists(cfg.dbPath) ||
            (std::filesystem::exists(cfg.storageRoot) && !std::filesystem::is_empty(cfg.storageRoot))) {
          std::string missing;
          if (missingJwt()) missing = "jwt_secret";
          if (cfg.hashFiles && missingKey()) missing += (missing.empty() ? "" : ", ") + std::string("encryption_key");
          throw std::runtime_error("Secrets are missing (" + missing + ") but server data already exists. Expected local overrides at " + local.string() + "; restore the original secrets or configure non-empty CROWLEYS_JWT_SECRET/CROWLEYS_ENCRYPTION_KEY values. Automatic regeneration is disabled.");
        }
        // Explicit environment settings must be fixed by the operator, not persisted or replaced.
        if ((missingJwt() && std::getenv("CROWLEYS_JWT_SECRET") && *std::getenv("CROWLEYS_JWT_SECRET") != '\0') ||
            (missingKey() && std::getenv("CROWLEYS_ENCRYPTION_KEY") && *std::getenv("CROWLEYS_ENCRYPTION_KEY") != '\0')) {
          throw std::runtime_error("Secret environment variables must contain non-placeholder values");
        }
        Json::Value overrides(Json::objectValue);
        if (std::filesystem::exists(local)) {
          std::ifstream input(local);
          input >> overrides;
          if (!input || !overrides.isObject()) throw std::runtime_error("Cannot read local overrides");
        }
        if (missingJwt()) overrides["jwt_secret"] = cfg.jwtSecret = randomTokenHex();
        if (missingKey()) overrides["encryption_key"] = cfg.encryptionKey = randomTokenHex();
        const auto temporary = lock / "config.json";
        {
          std::ofstream output(temporary, std::ios::binary);
#ifndef _WIN32
          std::filesystem::permissions(temporary, std::filesystem::perms::owner_read | std::filesystem::perms::owner_write);
#endif
          output << overrides << "\n";
          output.close();
          if (!output) throw std::runtime_error("Cannot save generated secrets");
        }
#ifdef _WIN32
        if (!MoveFileExW(temporary.c_str(), local.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
          throw std::runtime_error("Cannot replace local config with generated secrets");
        }
#else
        std::filesystem::rename(temporary, local);
#endif
        LOG_INFO << "Initialized secrets in " << local.string() << "; back up this file with your data";
      }
    }
  }

  cfg.sourcePath = actualPath.empty() ? "" : std::filesystem::absolute(actualPath).lexically_normal().string();
  return cfg;
}

}  // namespace server::utils
