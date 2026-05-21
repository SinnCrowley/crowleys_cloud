#pragma once

#include <chrono>
#include <mutex>
#include <string>
#include <unordered_map>

namespace server::middleware {

class RateLimiter {
 public:
  explicit RateLimiter(int maxPerMinute) : maxPerMinute_(maxPerMinute) {}

  bool allow(const std::string &key) {
    const auto now = std::chrono::steady_clock::now();
    std::lock_guard<std::mutex> lock(mu_);
    auto &entry = buckets_[key];
    if (now - entry.windowStart >= std::chrono::minutes(1)) {
      entry.windowStart = now;
      entry.count = 0;
    }
    entry.count++;
    return entry.count <= maxPerMinute_;
  }

 private:
  struct Bucket {
    std::chrono::steady_clock::time_point windowStart{std::chrono::steady_clock::now()};
    int count{0};
  };

  int maxPerMinute_;
  std::mutex mu_;
  std::unordered_map<std::string, Bucket> buckets_;
};

}  // namespace server::middleware
