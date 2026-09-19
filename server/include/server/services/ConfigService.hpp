// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later
#pragma once
#include "server/utils/Config.hpp"
#include <json/json.h>
#include <filesystem>
#include <string>

namespace server::services {
class ConfigService {
 public:
  explicit ConfigService(utils::Config &config) : config_(config) {}
  Json::Value snapshot() const;
  // Caller must hold configMutex.
  std::string revision() const;
  Json::Value save(std::int64_t actor, const std::string &revision, const Json::Value &changes);
  void rotateSigningSecret(std::int64_t actor, const std::string &revision, const std::string &secret);
  // Called by the durable encryption migration after every object has been verified.
  void finishEncryptionRotation(const std::string &oldKey, const std::string &newKey);
 private:
  utils::Config &config_;
  std::filesystem::path localPath() const;
  Json::Value overrides() const;
  Json::Value snapshotLocked() const;
  void persist(const Json::Value &values);
};
Json::Value configJson(const utils::Config &config);
}
