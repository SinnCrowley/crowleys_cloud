// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later
#pragma once
#include <atomic>
#include <filesystem>
#include <json/json.h>
#include <mutex>
#include <thread>

namespace server::services {
class EncryptionRotationService {
 public:
  EncryptionRotationService() = default;
  ~EncryptionRotationService() {
    if (worker_.joinable()) { worker_.request_stop(); worker_.join(); }
  }
  void recover();
  void start(std::int64_t actor, const std::string &revision, const std::string &newKey);
  void resume(std::int64_t actor);
  Json::Value status() const;
 private:
  std::mutex workerMutex_;
  std::jthread worker_;
  std::atomic<bool> running_{false};
  std::filesystem::path keyPath() const;
  Json::Value keys() const;
  void launch();
  void run(std::stop_token stop);
  void initializeJournal(const Json::Value &keys);
  void enumerate(const Json::Value &keys);
  void processObject(const Json::Value &keys, const std::string &name);
};
}
