#include "server/utils/Crypto.hpp"

#include <openssl/rand.h>
#include <openssl/hmac.h>
#include <openssl/sha.h>

#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <vector>

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
