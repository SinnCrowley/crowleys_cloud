#pragma once

#include <string>

namespace server::utils {

std::string sha256Hex(const std::string &input);
std::string hmacSha256Hex(const std::string &key, const std::string &input);
std::string randomTokenHex(std::size_t bytes = 32);

}  // namespace server::utils
