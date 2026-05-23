#include "server/services/FileService.hpp"

#include <chrono>
#include <algorithm>
#include <cctype>
#include <unordered_map>
#include <stdexcept>

namespace server::services {

namespace fs = std::filesystem;

FileService::FileService(const utils::Config &config) : config_(config) {}

std::filesystem::path FileService::rootForUser(std::int64_t userId) const {
  return fs::path(config_.storageRoot) / "users" / std::to_string(userId);
}

std::filesystem::path FileService::sharedRoot() const {
  return fs::path(config_.storageRoot) / "shared";
}

std::filesystem::path FileService::resolvePath(std::int64_t userId,
                                               const std::string &role,
                                               StorageScope scope,
                                               const std::string &rawPath,
                                               bool writeIntent) const {
  (void)role;
  (void)writeIntent;
  auto root = scope == StorageScope::Private ? rootForUser(userId) : sharedRoot();

  fs::create_directories(root);

  const auto cleanRel = fs::path(rawPath).lexically_normal().relative_path();
  const auto candidate = fs::weakly_canonical(root / cleanRel);
  const auto normalizedRoot = fs::weakly_canonical(root);

  const auto candidateString = candidate.generic_string();
  const auto rootString = normalizedRoot.generic_string();
  if (candidateString.size() < rootString.size() || candidateString.compare(0, rootString.size(), rootString) != 0) {
    throw std::runtime_error("Path escapes allowed root");
  }

  return candidate;
}

std::vector<DirEntry> FileService::listDirectory(const std::filesystem::path &path) const {
  std::vector<DirEntry> entries;
  for (const auto &entry : fs::directory_iterator(path)) {
    const auto rel = fs::relative(entry.path(), path);
    const auto status = entry.symlink_status();
    const auto isDir = fs::is_directory(status);
    const auto size = isDir ? 0 : fs::file_size(entry.path());
    const auto mtime = std::chrono::duration_cast<std::chrono::milliseconds>(
                           fs::last_write_time(entry.path()).time_since_epoch())
                           .count();
    const auto type = isDir ? "directory" : classifyType(entry.path());
    const auto mimeType = isDir ? "inode/directory" : mimeTypeFor(entry.path());
    entries.push_back(DirEntry{
        .name = entry.path().filename().string(),
        .path = rel.generic_string(),
        .isDir = isDir,
        .size = size,
        .modifiedAt = mtime,
        .type = type,
        .mimeType = mimeType,
        .thumbnailUrl = isDir ? "" : "/api/thumb"});
  }
  return entries;
}

std::string FileService::classifyType(const std::filesystem::path &path) const {
  static const std::unordered_map<std::string, std::string> map = {
      {".jpg", "photo"}, {".jpeg", "photo"}, {".png", "photo"}, {".webp", "photo"}, {".gif", "photo"},
      {".mp4", "video"}, {".mkv", "video"}, {".mov", "video"}, {".webm", "video"},
      {".mp3", "audio"}, {".wav", "audio"}, {".ogg", "audio"}, {".flac", "audio"},
      {".pdf", "document"}, {".doc", "document"}, {".docx", "document"}, {".xls", "document"},
      {".xlsx", "document"}, {".ppt", "document"}, {".pptx", "document"}, {".txt", "document"}};
  auto ext = path.extension().string();
  std::transform(ext.begin(), ext.end(), ext.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  auto it = map.find(ext);
  if (it != map.end()) return it->second;
  return "other";
}

std::string FileService::mimeTypeFor(const std::filesystem::path &path) const {
  static const std::unordered_map<std::string, std::string> map = {
      {".jpg", "image/jpeg"}, {".jpeg", "image/jpeg"}, {".png", "image/png"}, {".webp", "image/webp"}, {".gif", "image/gif"},
      {".mp4", "video/mp4"}, {".mkv", "video/x-matroska"}, {".mov", "video/quicktime"}, {".webm", "video/webm"},
      {".mp3", "audio/mpeg"}, {".wav", "audio/wav"}, {".ogg", "audio/ogg"}, {".flac", "audio/flac"},
      {".pdf", "application/pdf"}, {".docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"},
      {".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"},
      {".pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation"},
      {".txt", "text/plain"}};
  auto ext = path.extension().string();
  std::transform(ext.begin(), ext.end(), ext.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  auto it = map.find(ext);
  if (it != map.end()) return it->second;
  return "application/octet-stream";
}

std::optional<StorageScope> parseScope(const std::string &value) {
  auto normalized = value;
  normalized.erase(normalized.begin(), std::find_if(normalized.begin(), normalized.end(), [](unsigned char c) {
    return !std::isspace(c);
  }));
  normalized.erase(std::find_if(normalized.rbegin(), normalized.rend(), [](unsigned char c) {
    return !std::isspace(c);
  }).base(), normalized.end());
  std::transform(normalized.begin(), normalized.end(), normalized.begin(), [](unsigned char c) {
    return static_cast<char>(std::tolower(c));
  });

  // Legacy compatibility: ignore separators/punctuation around scope text.
  std::string alphaOnly;
  alphaOnly.reserve(normalized.size());
  for (unsigned char c : normalized) {
    if (std::isalpha(c)) alphaOnly.push_back(static_cast<char>(c));
  }

  if (normalized == "private") return StorageScope::Private;
  if (normalized == "shared") return StorageScope::Shared;
  if (alphaOnly == "private") return StorageScope::Private;
  if (alphaOnly == "shared") return StorageScope::Shared;
  return std::nullopt;
}

}  // namespace server::services
