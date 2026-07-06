#include "server/utils/Crypto.hpp"

#include <openssl/rand.h>
#include <openssl/hmac.h>
#include <openssl/sha.h>
#include <openssl/evp.h>

#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <vector>
#include <fstream>

namespace server::utils {

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
std::string derive32ByteKey(const std::string &keySource) {
  unsigned char hash[SHA256_DIGEST_LENGTH];
  SHA256(reinterpret_cast<const unsigned char *>(keySource.data()), keySource.size(), hash);
  return std::string(reinterpret_cast<char *>(hash), SHA256_DIGEST_LENGTH);
}
} // namespace

std::string encryptAes256(const std::string &plainText, const std::string &keySource) {
  std::string key = derive32ByteKey(keySource);
  
  unsigned char iv[16];
  if (RAND_bytes(iv, sizeof(iv)) != 1) {
    throw std::runtime_error("Failed to generate random IV for AES encryption");
  }

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

}  // namespace server::utils
