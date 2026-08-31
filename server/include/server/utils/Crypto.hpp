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

#include <string>
#include <filesystem>
#include <functional>

namespace server::utils {

std::string sha256Hex(const std::string &input);
std::string sha256FileHex(const std::filesystem::path &path);
std::string hmacSha256Hex(const std::string &key, const std::string &input);
std::string randomTokenHex(std::size_t bytes = 32);
std::string hashPassword(const std::string &password);
bool verifyPasswordHash(const std::string &password, const std::string &storedHash);
bool isLegacyPasswordHash(const std::string &storedHash);
std::string encryptAes256(const std::string &plainText, const std::string &keySource);
std::string decryptAes256(const std::string &cipherText, const std::string &keySource);
bool encryptFileAes256(const std::filesystem::path &srcPath, const std::filesystem::path &dstPath, const std::string &keySource, std::string &outPlainSha256);
bool decryptFileAes256(const std::filesystem::path &srcPath, const std::filesystem::path &dstPath, const std::string &keySource);
bool decryptFileToStream(const std::filesystem::path &srcPath, const std::string &keySource, const std::function<void(const char* data, size_t size)> &chunkCallback);

}  // namespace server::utils
