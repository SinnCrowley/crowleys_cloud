// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later
#pragma once
#include "server/db/Database.hpp"
#include "server/utils/Config.hpp"
#include <cstdint>
#include <string>

namespace server::services {
struct QuotaUsage {
  std::int64_t used;
  std::int64_t reserved;
  std::int64_t limit;
};
class QuotaService {
 public:
  QuotaService(db::Database &db, const utils::Config &config) : db_(db), config_(config) {}
  QuotaUsage usage(std::int64_t userId) const;
  // Caller holds the storage mutation mutex through writing and index publication.
  void reserve(std::int64_t userId, const std::string &scope, const std::string &path, std::int64_t size);
  void release(std::int64_t userId, const std::string &scope, const std::string &path);
 private:
  db::Database &db_;
  const utils::Config &config_;
};
}
