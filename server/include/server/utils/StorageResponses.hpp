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
    const std::string &contentType = "application/octet-stream", bool removeAfter = false) {
  struct Reader {
    std::filesystem::path path;
    std::ifstream input;
    std::shared_ptr<services::StorageActivity::Lease> lease;
    bool remove;
    Reader(const std::filesystem::path &file, std::shared_ptr<services::StorageActivity::Lease> activity, bool cleanup)
        : path(file), input(file, std::ios::binary), lease(std::move(activity)), remove(cleanup) {}
    ~Reader() {
      input.close();
      if (remove) { std::error_code error; std::filesystem::remove(path, error); }
    }
  };
  auto reader = std::make_shared<Reader>(path, activity, removeAfter);
  if (!reader->input) throw std::runtime_error("Cannot open download");
  auto response = drogon::HttpResponse::newStreamResponse([reader](char *data, size_t size) -> size_t {
    if (!data || size == 0) return 0;
    reader->input.read(data, static_cast<std::streamsize>(size));
    return static_cast<size_t>(reader->input.gcount());
  });
  response->addHeader("Content-Length", std::to_string(std::filesystem::file_size(path)));
  response->setContentTypeString(contentType);
  return response;
}
}
