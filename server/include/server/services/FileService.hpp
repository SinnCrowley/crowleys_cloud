#pragma once

#include "server/utils/Config.hpp"

#include <filesystem>
#include <optional>
#include <string>
#include <vector>

namespace server::services {

enum class StorageScope { Private, Shared };

struct DirEntry {
  std::string name;
  std::string path;
  bool isDir;
  std::uintmax_t size;
  std::int64_t modifiedAt;
  std::string type;
  std::string mimeType;
  std::string thumbnailUrl;
};

class FileService {
 public:
  explicit FileService(const utils::Config &config);

  std::filesystem::path resolvePath(std::int64_t userId,
                                    const std::string &role,
                                    StorageScope scope,
                                    const std::string &rawPath,
                                    bool writeIntent) const;
  std::vector<DirEntry> listDirectory(const std::filesystem::path &path) const;
  std::string classifyType(const std::filesystem::path &path) const;
  std::string mimeTypeFor(const std::filesystem::path &path) const;

 private:
  const utils::Config &config_;
  std::filesystem::path rootForUser(std::int64_t userId) const;
  std::filesystem::path sharedRoot() const;
};

std::optional<StorageScope> parseScope(const std::string &value);

}  // namespace server::services
