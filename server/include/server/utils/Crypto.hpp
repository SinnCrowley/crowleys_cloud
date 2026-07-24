#pragma once

#include <string>
#include <filesystem>
#include <functional>

namespace server::utils {

std::string sha256Hex(const std::string &input);
std::string sha256FileHex(const std::filesystem::path &path);
std::string hmacSha256Hex(const std::string &key, const std::string &input);
std::string randomTokenHex(std::size_t bytes = 32);
std::string encryptAes256(const std::string &plainText, const std::string &keySource);
std::string decryptAes256(const std::string &cipherText, const std::string &keySource);
bool encryptFileAes256(const std::filesystem::path &srcPath, const std::filesystem::path &dstPath, const std::string &keySource, std::string &outPlainSha256);
bool decryptFileAes256(const std::filesystem::path &srcPath, const std::filesystem::path &dstPath, const std::string &keySource);
bool decryptFileToStream(const std::filesystem::path &srcPath, const std::string &keySource, const std::function<void(const char* data, size_t size)> &chunkCallback);

}  // namespace server::utils
