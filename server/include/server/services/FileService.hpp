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

/**
 * Service managing physical filesystem operations, mime-type classifications,
 * and canonical path boundary checks.
 */
class FileService {
 public:
  explicit FileService(const utils::Config &config);

  /**
   * Resolves a relative user or shared path into a absolute physical filesystem path.
   * Performs strict canonical path boundary checks to prevent directory traversal (`..`)
   * and root prefix spoofing (e.g., preventing `/users/1` from accessing `/users/10`).
   *
   * @param userId Authenticated owner or requester user ID.
   * @param role User authorization role.
   * @param scope Private user storage scope or Shared system scope.
   * @param rawPath Unsanitized input relative path string.
   * @param writeIntent True if caller intends to create or write to the target path.
   * @return Absolute canonical filesystem path within allowed root scope.
   * @throws std::runtime_error if target path escapes the scope root.
   */
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

/**
 * Parses user input scope string into StorageScope enum.
 */
std::optional<StorageScope> parseScope(const std::string &value);

}  // namespace server::services

