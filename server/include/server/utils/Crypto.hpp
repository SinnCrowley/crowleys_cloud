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
#include <vector>

namespace server::utils {

std::string sha256Hex(const std::string &input);
std::string sha256FileHex(const std::filesystem::path &path);
std::string hmacSha256Hex(const std::string &key, const std::string &input);
std::string randomTokenHex(std::size_t bytes = 32);
std::string hashPassword(const std::string &password);
bool verifyPasswordHash(const std::string &password, const std::string &storedHash);
bool isLegacyPasswordHash(const std::string &storedHash);
bool isScramPasswordHash(const std::string &storedHash);

struct ScramHashInfo {
  std::string kdf{"argon2id"};
  uint32_t iterations{4096};
  uint32_t memCostKb{19456};
  uint32_t timeCost{2};
  uint32_t lanes{1};
  std::string saltHex;
  std::string storedKeyHex;
  std::string serverKeyHex;
};

std::vector<unsigned char> pbkdf2Sha256(const std::string &password, const std::vector<unsigned char> &salt, uint32_t iterations, size_t keyLen = 32);
bool scramGenerateKeys(const std::string &password, const std::string &saltHex, uint32_t iterations, std::string &outStoredKeyHex, std::string &outServerKeyHex);
bool scramArgon2idGenerateKeys(const std::string &password, const std::string &saltHex, uint32_t memCostKb, uint32_t timeCost, uint32_t lanes, std::string &outStoredKeyHex, std::string &outServerKeyHex);
std::string scramAuthMessage(const std::string &username, const std::string &nonce, const std::string &saltHex, uint32_t iterations);
std::string scramArgon2idAuthMessage(const std::string &username, const std::string &nonce, const std::string &saltHex, uint32_t memCostKb, uint32_t timeCost, uint32_t lanes);
bool scramVerifyClientProof(const std::string &storedKeyHex, const std::string &authMessage, const std::string &clientProofHex, const std::string &serverKeyHex, std::string &outServerSignatureHex);
std::string scramComputeServerSignature(const std::string &serverKeyHex, const std::string &authMessage);
std::string scramHashPassword(const std::string &password, uint32_t iterations = 4096);
std::string scramArgon2idHashPassword(const std::string &password, uint32_t memCostKb = 19456, uint32_t timeCost = 2, uint32_t lanes = 1);
bool parseScramHash(const std::string &hash, ScramHashInfo &outInfo);
bool parseScramHash(const std::string &hash, uint32_t &outIterations, std::string &outSaltHex, std::string &outStoredKeyHex, std::string &outServerKeyHex);
std::string encryptAes256(const std::string &plainText, const std::string &keySource);
std::string decryptAes256(const std::string &cipherText, const std::string &keySource);
bool encryptFileAes256(const std::filesystem::path &srcPath, const std::filesystem::path &dstPath, const std::string &keySource, std::string &outPlainSha256);
bool verifyEncryptedFile(const std::filesystem::path &path, const std::string &key,
                         const std::string &expectedHash, std::uintmax_t &plainSize);
bool reencryptFile(const std::filesystem::path &source, const std::filesystem::path &destination,
                   const std::string &oldKey, const std::string &newKey,
                   const std::string &expectedHash, std::uintmax_t &plainSize);
bool decryptFileAes256(const std::filesystem::path &srcPath, const std::filesystem::path &dstPath, const std::string &keySource);
std::function<std::size_t(char *, std::size_t)> decryptedFileReader(const std::filesystem::path &path, const std::string &keySource);
bool decryptFileToStream(const std::filesystem::path &srcPath, const std::string &keySource, const std::function<void(const char* data, size_t size)> &chunkCallback);
bool decryptFileToMemory(const std::filesystem::path &srcPath, const std::string &keySource, std::vector<uint8_t> &outPlainBytes);
bool decryptBufferAes256(const uint8_t *cipherData, size_t cipherLen, const std::string &keySource, std::vector<uint8_t> &outPlainBytes);

}  // namespace server::utils
