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
  const auto root = scope == StorageScope::Private ? rootForUser(userId) : sharedRoot();

  std::error_code ec;
  if (!fs::exists(root, ec)) {
    fs::create_directories(root, ec);
  }

  // 1. Cleanly normalize the relative path lexically
  auto cleanRel = fs::path(rawPath).lexically_normal().relative_path().generic_string();
  while (!cleanRel.empty() && cleanRel.front() == '/') cleanRel.erase(cleanRel.begin());
  if (cleanRel == ".") cleanRel.clear();

  // 2. Canonicalize root and candidate target path safely (weakly_canonical works for existing & non-existing files)
  const auto normalizedRoot = fs::weakly_canonical(root, ec);
  const auto candidate = fs::weakly_canonical(normalizedRoot / cleanRel, ec);

  // 3. Strict Boundary Verification:
  // Prevent prefix-spoofing vulnerabilities where a root path (e.g. `/users/1`)
  // falsely matches a target path (e.g. `/users/10/file.txt`).
  // Enforce exact match or requiring a trailing directory separator on the root prefix.
  const auto candidateStr = candidate.generic_string();
  auto rootStr = normalizedRoot.generic_string();

  if (candidateStr != rootStr) {
    if (rootStr.empty() || rootStr.back() != '/') {
      rootStr.push_back('/');
    }
    if (candidateStr.size() < rootStr.size() || candidateStr.compare(0, rootStr.size(), rootStr) != 0) {
      throw std::runtime_error("Path escapes allowed root");
    }
  }

  return candidate;
}

std::vector<DirEntry> FileService::listDirectory(const std::filesystem::path &path) const {
  std::vector<DirEntry> entries;
  std::error_code ec;
  for (const auto &entry : fs::directory_iterator(path, ec)) {
    const auto isDir = entry.is_directory(ec);
    const auto size = isDir ? 0 : entry.file_size(ec);
    const auto mtime = std::chrono::duration_cast<std::chrono::milliseconds>(
                           entry.last_write_time(ec).time_since_epoch())
                           .count();
    const auto fileName = entry.path().filename().string();
    const auto type = isDir ? "directory" : classifyType(entry.path());
    const auto mimeType = isDir ? "inode/directory" : mimeTypeFor(entry.path());
    entries.push_back(DirEntry{
        .name = fileName,
        .path = fileName,
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
