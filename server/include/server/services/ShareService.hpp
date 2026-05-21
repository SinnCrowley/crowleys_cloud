#pragma once

#include "server/db/Database.hpp"

#include <cstdint>
#include <optional>
#include <string>

namespace server::services {

struct ShareRecord {
  std::string token;
  std::int64_t ownerUserId;
  std::string scope;
  std::string relPath;
};

class ShareService {
 public:
  explicit ShareService(db::Database &db);

  std::string createShare(std::int64_t ownerUserId,
                          const std::string &scope,
                          const std::string &relPath,
                          std::optional<std::int64_t> expiresAt);
  std::optional<ShareRecord> resolveShare(const std::string &token);

 private:
  db::Database &db_;
};

}  // namespace server::services
