#pragma once

#include <chrono>
#include <cstdint>

namespace server::utils {

/**
 * Returns current Unix epoch timestamp in seconds.
 */
inline std::int64_t nowSeconds() {
  return std::chrono::duration_cast<std::chrono::seconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}

/**
 * Returns current Unix epoch timestamp in milliseconds.
 */
inline std::int64_t nowMillis() {
  return std::chrono::duration_cast<std::chrono::milliseconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}

}  // namespace server::utils
