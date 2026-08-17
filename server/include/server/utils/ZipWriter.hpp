// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

#pragma once

#include <cstdint>
#include <fstream>
#include <filesystem>
#include <string>
#include <vector>

namespace server::utils {

class ZipWriter {
 public:
  struct Entry {
    std::string filename;
    std::uint32_t crc32{0};
    std::uint32_t compressedSize{0};
    std::uint32_t uncompressedSize{0};
    std::uint32_t localHeaderOffset{0};
    std::uint16_t dosTime{0};
    std::uint16_t dosDate{0};
    std::uint16_t compressionMethod{8};
    std::vector<std::uint8_t> compressedData;
  };

  ZipWriter() = default;
  ~ZipWriter() = default;

  bool addFile(const std::string &archivePath, const std::string &content);
  bool addFileFromDisk(const std::string &archivePath, const std::filesystem::path &filePath);
  bool writeToFile(const std::filesystem::path &outputPath);

 private:
  std::vector<Entry> entries_;

  static void getDosTimeDate(std::uint16_t &dosTime, std::uint16_t &dosDate);
  static bool compressData(const std::string &raw, std::vector<std::uint8_t> &outCompressed, std::uint32_t &outCrc32);
};

}  // namespace server::utils
