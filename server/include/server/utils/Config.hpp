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
  int trashRetentionDays{30};
};

Config loadConfig(const std::string &path);

}  // namespace server::utils
