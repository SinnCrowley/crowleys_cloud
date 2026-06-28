#include "server/utils/Crypto.hpp"

#include <openssl/rand.h>
#include <openssl/hmac.h>
#include <openssl/sha.h>

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

}  // namespace server::utils
