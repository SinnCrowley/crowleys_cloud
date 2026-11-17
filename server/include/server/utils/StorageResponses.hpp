// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later
#pragma once
#include "server/services/StorageActivity.hpp"
#include <drogon/drogon.h>
#include <filesystem>
#include <fstream>

namespace server::utils {
inline drogon::HttpResponsePtr storageFileResponse(
    const std::filesystem::path &path,
    const std::shared_ptr<services::StorageActivity::Lease> &activity,
    const std::string &contentType = "application/octet-stream",
    bool removeAfter = false,
    std::size_t startOffset = 0,
    std::size_t length = std::numeric_limits<std::size_t>::max()) {
  struct Reader {
    std::filesystem::path path;
    std::ifstream input;
    std::shared_ptr<services::StorageActivity::Lease> lease;
    bool remove;
    std::size_t bytesRemaining;
    Reader(const std::filesystem::path &file, std::shared_ptr<services::StorageActivity::Lease> activity, bool cleanup, std::size_t start, std::size_t len)
        : path(file), input(file, std::ios::binary), lease(std::move(activity)), remove(cleanup), bytesRemaining(len) {
      if (input && start > 0) {
        input.seekg(static_cast<std::streamoff>(start), std::ios::beg);
      }
    }
    ~Reader() {
      input.close();
      if (remove) { std::error_code error; std::filesystem::remove(path, error); }
    }
  };
  auto reader = std::make_shared<Reader>(path, activity, removeAfter, startOffset, length);
  if (!reader->input) throw std::runtime_error("Cannot open download");
  auto response = drogon::HttpResponse::newStreamResponse([reader](char *data, size_t size) -> size_t {
    if (!data || size == 0 || reader->bytesRemaining == 0) return 0;
    const auto toRead = std::min(size, reader->bytesRemaining);
    reader->input.read(data, static_cast<std::streamsize>(toRead));
    const auto count = static_cast<size_t>(reader->input.gcount());
    reader->bytesRemaining -= count;
    return count;
  });
  const auto totalLen = std::min(length, std::filesystem::file_size(path));
  response->addHeader("Content-Length", std::to_string(totalLen));
  response->setContentTypeString(contentType);
  return response;
}
}
