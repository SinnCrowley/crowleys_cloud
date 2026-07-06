#pragma once

#include <string>
#include <filesystem>

namespace server::utils {

std::string sha256Hex(const std::string &input);
std::string sha256FileHex(const std::filesystem::path &path);
std::string hmacSha256Hex(const std::string &key, const std::string &input);
std::string randomTokenHex(std::size_t bytes = 32);
std::string encryptAes256(const std::string &plainText, const std::string &keySource);
std::string decryptAes256(const std::string &cipherText, const std::string &keySource);

}  // namespace server::utils
