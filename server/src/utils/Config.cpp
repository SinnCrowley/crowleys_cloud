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

#include <fstream>
#include <filesystem>

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

Config loadConfig(const std::string &path) {
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
        }
      }
    }
  }

  if (actualPath.empty() || !std::filesystem::is_regular_file(actualPath, ec)) {
    LOG_WARN << "Config file not found or not a regular file at " << path << ", using defaults";
  } else {
    std::ifstream input(actualPath);
    if (!input.is_open()) {
      LOG_WARN << "Config file could not be opened at " << actualPath << ", using defaults";
    } else {
      try {
        Json::Value json;
        input >> json;

        cfg.host = json.get("host", cfg.host).asString();
        cfg.port = static_cast<uint16_t>(json.get("port", cfg.port).asUInt());
        cfg.storageRoot = json.get("storage_root", cfg.storageRoot).asString();
        cfg.dbPath = json.get("db_path", cfg.dbPath).asString();
        cfg.tempUploadDir = json.get("temp_upload_dir", cfg.tempUploadDir).asString();
        cfg.publicDir = json.get("public_dir", cfg.publicDir).asString();
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
        cfg.trashRetentionDays = json.get("trash_retention_days", cfg.trashRetentionDays).asInt();
      } catch (const std::exception &e) {
        LOG_ERROR << "Failed to parse config file at " << actualPath << ": " << e.what() << ", using defaults";
      } catch (...) {
        LOG_ERROR << "Failed to parse config file at " << actualPath << " (unknown error), using defaults";
      }
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

  return cfg;
}

}  // namespace server::utils
