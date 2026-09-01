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

// Crypto.cpp implementation for OpenSSL cryptographic operations.
// AES Encryption Format: [16-byte IV Prefix][AES-256-CBC Ciphertext]
// Key Derivation: SHA-256 digest mapping of arbitrary secret strings to 32-byte symmetric keys.
// Resource Lifecycle: Strict EVP_CIPHER_CTX_free cleanup across all early-exit and exception branches.
// Streaming Operations: 64KB buffered chunking for constant-memory file encryption and decryption streams.

#include "server/utils/Crypto.hpp"

#include <openssl/rand.h>
#include <openssl/hmac.h>
#include <openssl/sha.h>
#include <openssl/evp.h>
#include <openssl/kdf.h>
#include <openssl/core_names.h>
#include <openssl/params.h>
#include <openssl/crypto.h>

#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <vector>
#include <fstream>

namespace server::utils {

/**
 * Computes hexadecimal SHA-256 hash string of an input string.
 */
std::string sha256Hex(const std::string &input) {
  unsigned char hash[SHA256_DIGEST_LENGTH];
  SHA256(reinterpret_cast<const unsigned char *>(input.data()), input.size(), hash);

  std::ostringstream out;
  for (unsigned char i : hash) {
    out << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(i);
  }
  return out.str();
}

std::string sha256FileHex(const std::filesystem::path &path) {
  std::ifstream file(path, std::ios::binary);
  if (!file) {
    throw std::runtime_error("Cannot open file for hashing: " + path.string());
  }

  SHA256_CTX sha256;
  SHA256_Init(&sha256);

  constexpr std::size_t bufferSize = 32768; // 32KB
  std::vector<char> buffer(bufferSize);
  while (file.read(buffer.data(), bufferSize) || file.gcount() > 0) {
    SHA256_Update(&sha256, buffer.data(), file.gcount());
  }

  unsigned char hash[SHA256_DIGEST_LENGTH];
  SHA256_Final(hash, &sha256);

  std::ostringstream out;
  for (unsigned char i : hash) {
    out << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(i);
  }
  return out.str();
}

std::string hmacSha256Hex(const std::string &key, const std::string &input) {
  unsigned int len = 0;
  unsigned char hash[EVP_MAX_MD_SIZE];
  HMAC(EVP_sha256(),
       key.data(),
       static_cast<int>(key.size()),
       reinterpret_cast<const unsigned char *>(input.data()),
       input.size(),
       hash,
       &len);
  std::ostringstream out;
  for (unsigned int i = 0; i < len; ++i) {
    out << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(hash[i]);
  }
  return out.str();
}

std::string randomTokenHex(std::size_t bytes) {
  std::vector<unsigned char> raw(bytes);
  if (RAND_bytes(raw.data(), static_cast<int>(raw.size())) != 1) {
    throw std::runtime_error("Unable to generate secure random token");
  }

  std::ostringstream out;
  for (unsigned char b : raw) {
    out << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(b);
  }
  return out.str();
}

namespace {
static bool deriveArgon2idRaw(const std::string &password,
                             const std::vector<unsigned char> &salt,
                             uint32_t memCostKb,
                             uint32_t timeCost,
                             uint32_t lanes,
                             std::vector<unsigned char> &outHash) {
  EVP_KDF *kdf = EVP_KDF_fetch(nullptr, "ARGON2ID", nullptr);
  if (!kdf) return false;

  EVP_KDF_CTX *kctx = EVP_KDF_CTX_new(kdf);
  EVP_KDF_free(kdf);
  if (!kctx) return false;

  uint32_t threads = lanes;
  OSSL_PARAM params[7];
  params[0] = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_PASSWORD,
                                                const_cast<char *>(password.data()),
                                                password.size());
  params[1] = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_SALT,
                                                const_cast<unsigned char *>(salt.data()),
                                                salt.size());
  params[2] = OSSL_PARAM_construct_uint32(OSSL_KDF_PARAM_ARGON2_LANES, &lanes);
  params[3] = OSSL_PARAM_construct_uint32(OSSL_KDF_PARAM_ARGON2_MEMCOST, &memCostKb);
  params[4] = OSSL_PARAM_construct_uint32(OSSL_KDF_PARAM_ITER, &timeCost);
  params[5] = OSSL_PARAM_construct_uint32(OSSL_KDF_PARAM_THREADS, &threads);
  params[6] = OSSL_PARAM_construct_end();

  bool ok = (EVP_KDF_derive(kctx, outHash.data(), outHash.size(), params) > 0);
  EVP_KDF_CTX_free(kctx);
  return ok;
}

static std::vector<unsigned char> hexToBytes(const std::string &hex) {
  std::vector<unsigned char> bytes;
  if (hex.size() % 2 != 0) return bytes;
  bytes.reserve(hex.size() / 2);
  for (std::size_t i = 0; i < hex.size(); i += 2) {
    unsigned int byteVal = 0;
    std::stringstream ss;
    ss << std::hex << hex.substr(i, 2);
    if (!(ss >> byteVal)) return {};
    bytes.push_back(static_cast<unsigned char>(byteVal));
  }
  return bytes;
}
} // namespace

bool isLegacyPasswordHash(const std::string &storedHash) {
  return storedHash.rfind("$argon2id$", 0) != 0;
}

std::string hashPassword(const std::string &password) {
  constexpr uint32_t memCostKb = 64 * 1024; // 64 MB
  constexpr uint32_t timeCost = 3;
  constexpr uint32_t lanes = 1;
  constexpr std::size_t saltBytes = 16;
  constexpr std::size_t hashBytes = 32;

  std::vector<unsigned char> salt(saltBytes);
  if (RAND_bytes(salt.data(), static_cast<int>(salt.size())) != 1) {
    throw std::runtime_error("Failed to generate salt for password hashing");
  }

  std::vector<unsigned char> hash(hashBytes);
  if (!deriveArgon2idRaw(password, salt, memCostKb, timeCost, lanes, hash)) {
    throw std::runtime_error("Failed to derive Argon2id hash");
  }

  std::ostringstream saltHexStream;
  for (unsigned char b : salt) {
    saltHexStream << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(b);
  }

  std::ostringstream hashHexStream;
  for (unsigned char b : hash) {
    hashHexStream << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(b);
  }

  std::ostringstream formatted;
  formatted << "$argon2id$v=19$m=" << memCostKb << ",t=" << timeCost << ",p=" << lanes
            << "$" << saltHexStream.str() << "$" << hashHexStream.str();
  return formatted.str();
}

bool verifyPasswordHash(const std::string &password, const std::string &storedHash) {
  if (isLegacyPasswordHash(storedHash)) {
    const auto legacyHash = sha256Hex("pw|" + password);
    if (legacyHash.size() != storedHash.size()) return false;
    return CRYPTO_memcmp(legacyHash.data(), storedHash.data(), legacyHash.size()) == 0;
  }

  // Parse $argon2id$v=19$m=65536,t=3,p=1$<salt_hex>$<hash_hex>
  std::vector<std::string> parts;
  std::stringstream ss(storedHash);
  std::string item;
  while (std::getline(ss, item, '$')) {
    parts.push_back(item);
  }

  if (parts.size() < 6 || parts[1] != "argon2id") {
    return false;
  }

  uint32_t memCostKb = 64 * 1024;
  uint32_t timeCost = 3;
  uint32_t lanes = 1;

  const std::string &paramsStr = parts[3];
  std::stringstream paramSs(paramsStr);
  std::string paramKV;
  while (std::getline(paramSs, paramKV, ',')) {
    auto eqPos = paramKV.find('=');
    if (eqPos != std::string::npos) {
      std::string key = paramKV.substr(0, eqPos);
      std::string val = paramKV.substr(eqPos + 1);
      try {
        if (key == "m") memCostKb = static_cast<uint32_t>(std::stoul(val));
        else if (key == "t") timeCost = static_cast<uint32_t>(std::stoul(val));
        else if (key == "p") lanes = static_cast<uint32_t>(std::stoul(val));
      } catch (...) {
        return false;
      }
    }
  }

  const std::string &saltHex = parts[4];
  const std::string &expectedHashHex = parts[5];

  auto saltBytes = hexToBytes(saltHex);
  auto expectedHashBytes = hexToBytes(expectedHashHex);

  if (saltBytes.empty() || expectedHashBytes.empty()) {
    return false;
  }

  std::vector<unsigned char> derivedHash(expectedHashBytes.size());
  if (!deriveArgon2idRaw(password, saltBytes, memCostKb, timeCost, lanes, derivedHash)) {
    return false;
  }

  return CRYPTO_memcmp(derivedHash.data(), expectedHashBytes.data(), derivedHash.size()) == 0;
}

namespace {
// Derives a 32-byte binary key from keySource using SHA-256 digest for AES-256-CBC cipher.
std::string derive32ByteKey(const std::string &keySource) {
  unsigned char hash[SHA256_DIGEST_LENGTH];
  SHA256(reinterpret_cast<const unsigned char *>(keySource.data()), keySource.size(), hash);
  return std::string(reinterpret_cast<char *>(hash), SHA256_DIGEST_LENGTH);
}
} // namespace

/**
 * Encrypts plainText using AES-256-CBC with a randomly generated 16-byte IV.
 * Returns binary payload format: [16-byte random IV][AES-256-CBC Ciphertext]
 */
std::string encryptAes256(const std::string &plainText, const std::string &keySource) {
  std::string key = derive32ByteKey(keySource);
  
  // Step 1: Generate random 16-byte initialization vector (IV)
  unsigned char iv[16];
  if (RAND_bytes(iv, sizeof(iv)) != 1) {
    throw std::runtime_error("Failed to generate random IV for AES encryption");
  }

  // Step 2: Initialize OpenSSL cipher context
  EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
  if (!ctx) {
    throw std::runtime_error("Failed to create EVP_CIPHER_CTX");
  }

  if (EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr, 
                         reinterpret_cast<const unsigned char *>(key.data()), iv) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    throw std::runtime_error("Failed to initialize AES encryption");
  }

  std::vector<unsigned char> cipherText(plainText.size() + 16);
  int len = 0;
  int ciphertextLen = 0;

  // Step 3: Encrypt plaintext bytes
  if (EVP_EncryptUpdate(ctx, cipherText.data(), &len, 
                        reinterpret_cast<const unsigned char *>(plainText.data()), 
                        static_cast<int>(plainText.size())) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    throw std::runtime_error("Failed to update AES encryption");
  }
  ciphertextLen = len;

  if (EVP_EncryptFinal_ex(ctx, cipherText.data() + len, &len) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    throw std::runtime_error("Failed to finalize AES encryption");
  }
  ciphertextLen += len;

  EVP_CIPHER_CTX_free(ctx);

  // Step 4: Prepend 16-byte IV to ciphertext payload
  std::string result(reinterpret_cast<char *>(iv), sizeof(iv));
  result.append(reinterpret_cast<char *>(cipherText.data()), ciphertextLen);
  return result;
}

std::string decryptAes256(const std::string &cipherTextWithIv, const std::string &keySource) {
  if (cipherTextWithIv.size() < 16) {
    throw std::runtime_error("Ciphertext too short (missing IV)");
  }

  std::string key = derive32ByteKey(keySource);

  unsigned char iv[16];
  std::copy(cipherTextWithIv.begin(), cipherTextWithIv.begin() + 16, iv);

  std::string encryptedPayload = cipherTextWithIv.substr(16);

  EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
  if (!ctx) {
    throw std::runtime_error("Failed to create EVP_CIPHER_CTX for decryption");
  }

  if (EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr, 
                         reinterpret_cast<const unsigned char *>(key.data()), iv) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    throw std::runtime_error("Failed to initialize AES decryption");
  }

  std::vector<unsigned char> plainText(encryptedPayload.size() + 16);
  int len = 0;
  int plaintextLen = 0;

  if (EVP_DecryptUpdate(ctx, plainText.data(), &len, 
                        reinterpret_cast<const unsigned char *>(encryptedPayload.data()), 
                        static_cast<int>(encryptedPayload.size())) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    throw std::runtime_error("Failed to update AES decryption");
  }
  plaintextLen = len;

  if (EVP_DecryptFinal_ex(ctx, plainText.data() + len, &len) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    throw std::runtime_error("Failed to finalize AES decryption");
  }
  plaintextLen += len;

  EVP_CIPHER_CTX_free(ctx);

  return std::string(reinterpret_cast<char *>(plainText.data()), plaintextLen);
}

bool encryptFileAes256(const std::filesystem::path &srcPath, const std::filesystem::path &dstPath, const std::string &keySource, std::string &outPlainSha256) {
  std::ifstream in(srcPath, std::ios::binary);
  if (!in) return false;

  std::ofstream out(dstPath, std::ios::binary | std::ios::trunc);
  if (!out) return false;

  std::string key = derive32ByteKey(keySource);
  unsigned char iv[16];
  if (RAND_bytes(iv, sizeof(iv)) != 1) return false;

  out.write(reinterpret_cast<const char*>(iv), sizeof(iv));

  EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
  if (!ctx) return false;

  if (EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr, 
                         reinterpret_cast<const unsigned char *>(key.data()), iv) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    return false;
  }

  SHA256_CTX sha256;
  SHA256_Init(&sha256);

  constexpr size_t bufferSize = 65536; // 64KB
  std::vector<char> buffer(bufferSize);
  std::vector<unsigned char> cipherBuffer(bufferSize + 16);

  while (in.read(buffer.data(), bufferSize) || in.gcount() > 0) {
    auto count = in.gcount();
    SHA256_Update(&sha256, buffer.data(), count);

    int outLen = 0;
    if (EVP_EncryptUpdate(ctx, cipherBuffer.data(), &outLen,
                           reinterpret_cast<const unsigned char*>(buffer.data()), static_cast<int>(count)) != 1) {
      EVP_CIPHER_CTX_free(ctx);
      return false;
    }
    if (outLen > 0) {
      out.write(reinterpret_cast<const char*>(cipherBuffer.data()), outLen);
    }
  }

  int outLen = 0;
  if (EVP_EncryptFinal_ex(ctx, cipherBuffer.data(), &outLen) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    return false;
  }
  if (outLen > 0) {
    out.write(reinterpret_cast<const char*>(cipherBuffer.data()), outLen);
  }

  EVP_CIPHER_CTX_free(ctx);
  in.close();
  out.close();

  unsigned char hash[SHA256_DIGEST_LENGTH];
  SHA256_Final(hash, &sha256);

  std::ostringstream hexOut;
  for (unsigned char i : hash) {
    hexOut << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(i);
  }
  outPlainSha256 = hexOut.str();

  return true;
}

bool decryptFileAes256(const std::filesystem::path &srcPath, const std::filesystem::path &dstPath, const std::string &keySource) {
  std::ifstream in(srcPath, std::ios::binary);
  if (!in) return false;

  unsigned char iv[16];
  if (!in.read(reinterpret_cast<char*>(iv), sizeof(iv))) return false;

  std::ofstream out(dstPath, std::ios::binary | std::ios::trunc);
  if (!out) return false;

  std::string key = derive32ByteKey(keySource);

  EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
  if (!ctx) return false;

  if (EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr, 
                         reinterpret_cast<const unsigned char *>(key.data()), iv) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    return false;
  }

  constexpr size_t bufferSize = 65536; // 64KB
  std::vector<char> buffer(bufferSize);
  std::vector<unsigned char> plainBuffer(bufferSize + 16);

  while (in.read(buffer.data(), bufferSize) || in.gcount() > 0) {
    auto count = in.gcount();
    int outLen = 0;
    if (EVP_DecryptUpdate(ctx, plainBuffer.data(), &outLen,
                           reinterpret_cast<const unsigned char*>(buffer.data()), static_cast<int>(count)) != 1) {
      EVP_CIPHER_CTX_free(ctx);
      return false;
    }
    if (outLen > 0) {
      out.write(reinterpret_cast<const char*>(plainBuffer.data()), outLen);
    }
  }

  int outLen = 0;
  if (EVP_DecryptFinal_ex(ctx, plainBuffer.data(), &outLen) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    return false;
  }
  if (outLen > 0) {
    out.write(reinterpret_cast<const char*>(plainBuffer.data()), outLen);
  }

  EVP_CIPHER_CTX_free(ctx);
  return true;
}

bool decryptFileToStream(const std::filesystem::path &srcPath, const std::string &keySource, const std::function<void(const char* data, size_t size)> &chunkCallback) {
  std::ifstream in(srcPath, std::ios::binary);
  if (!in) return false;

  unsigned char iv[16];
  if (!in.read(reinterpret_cast<char*>(iv), sizeof(iv))) return false;

  std::string key = derive32ByteKey(keySource);

  EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
  if (!ctx) return false;

  if (EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr, 
                         reinterpret_cast<const unsigned char *>(key.data()), iv) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    return false;
  }

  constexpr size_t bufferSize = 65536; // 64KB
  std::vector<char> buffer(bufferSize);
  std::vector<unsigned char> plainBuffer(bufferSize + 16);

  while (in.read(buffer.data(), bufferSize) || in.gcount() > 0) {
    auto count = in.gcount();
    int outLen = 0;
    if (EVP_DecryptUpdate(ctx, plainBuffer.data(), &outLen,
                           reinterpret_cast<const unsigned char*>(buffer.data()), static_cast<int>(count)) != 1) {
      EVP_CIPHER_CTX_free(ctx);
      return false;
    }
    if (outLen > 0) {
      chunkCallback(reinterpret_cast<const char*>(plainBuffer.data()), outLen);
    }
  }

  int outLen = 0;
  if (EVP_DecryptFinal_ex(ctx, plainBuffer.data(), &outLen) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    return false;
  }
  if (outLen > 0) {
    chunkCallback(reinterpret_cast<const char*>(plainBuffer.data()), outLen);
  }

  EVP_CIPHER_CTX_free(ctx);
  return true;
}

bool decryptFileToMemory(const std::filesystem::path &srcPath,
                         const std::string &keySource,
                         std::vector<uint8_t> &outPlainBytes) {
  outPlainBytes.clear();

  std::error_code ec;
  const auto fileSize = std::filesystem::file_size(srcPath, ec);
  if (ec || fileSize < 32) {
    return false;
  }

  const auto cipherSize = fileSize - 16;
  if (cipherSize % 16 != 0) {
    return false;
  }

  std::ifstream in(srcPath, std::ios::binary);
  if (!in) {
    return false;
  }

  unsigned char iv[16];
  if (!in.read(reinterpret_cast<char*>(iv), sizeof(iv))) {
    return false;
  }

  std::string key = derive32ByteKey(keySource);

  EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
  if (!ctx) {
    return false;
  }

  if (EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr,
                         reinterpret_cast<const unsigned char *>(key.data()), iv) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    return false;
  }

  outPlainBytes.resize(cipherSize + 16);

  constexpr size_t bufferSize = 65536; // 64KB
  std::vector<char> buffer(bufferSize);

  int totalPlainLen = 0;
  bool ok = true;

  while (in.read(buffer.data(), bufferSize) || in.gcount() > 0) {
    auto count = in.gcount();
    int outLen = 0;
    if (EVP_DecryptUpdate(ctx,
                           outPlainBytes.data() + totalPlainLen,
                           &outLen,
                           reinterpret_cast<const unsigned char*>(buffer.data()),
                           static_cast<int>(count)) != 1) {
      ok = false;
      break;
    }
    totalPlainLen += outLen;
  }

  if (ok) {
    int finalLen = 0;
    if (EVP_DecryptFinal_ex(ctx, outPlainBytes.data() + totalPlainLen, &finalLen) != 1) {
      ok = false;
    } else {
      totalPlainLen += finalLen;
    }
  }

  EVP_CIPHER_CTX_free(ctx);

  if (!ok) {
    outPlainBytes.clear();
    return false;
  }

  outPlainBytes.resize(totalPlainLen);
  return true;
}

bool decryptBufferAes256(const uint8_t *cipherData,
                         size_t cipherLen,
                         const std::string &keySource,
                         std::vector<uint8_t> &outPlainBytes) {
  outPlainBytes.clear();

  if (!cipherData || cipherLen < 32) {
    return false;
  }

  const size_t cipherPayloadLen = cipherLen - 16;
  if (cipherPayloadLen % 16 != 0) {
    return false;
  }

  const unsigned char *iv = cipherData;
  const unsigned char *payload = cipherData + 16;

  std::string key = derive32ByteKey(keySource);

  EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
  if (!ctx) {
    return false;
  }

  if (EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr,
                         reinterpret_cast<const unsigned char *>(key.data()), iv) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    return false;
  }

  outPlainBytes.resize(cipherPayloadLen + 16);

  int outLen = 0;
  if (EVP_DecryptUpdate(ctx, outPlainBytes.data(), &outLen, payload, static_cast<int>(cipherPayloadLen)) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    outPlainBytes.clear();
    return false;
  }

  int finalLen = 0;
  if (EVP_DecryptFinal_ex(ctx, outPlainBytes.data() + outLen, &finalLen) != 1) {
    EVP_CIPHER_CTX_free(ctx);
    outPlainBytes.clear();
    return false;
  }

  EVP_CIPHER_CTX_free(ctx);
  outPlainBytes.resize(outLen + finalLen);
  return true;
}

}  // namespace server::utils
