#pragma once

#include <chrono>
#include <mutex>
#include <string>
#include <unordered_map>

namespace server::middleware {

/**
 * Thread-safe fixed-window rate limiter.
 * Tracks and limits incoming request frequency per client key (e.g., client IP address).
 * Features periodic automatic bucket pruning to prevent unbounded map memory growth under high traffic.
 */
class RateLimiter {
 public:
  explicit RateLimiter(int maxPerMinute) : maxPerMinute_(maxPerMinute) {}

  /**
   * Evaluates if a request for the given key is within allowed rate limits.
   * Resets window counts every minute and triggers periodic bucket eviction.
   */
  bool allow(const std::string &key) {
    const auto now = std::chrono::steady_clock::now();
    std::lock_guard<std::mutex> lock(mu_);

    // Execute periodic bucket cleanup every 60 seconds to prune stale client IP entries
    if (now - lastCleanup_ >= std::chrono::minutes(1)) {
      cleanupStaleBucketsLocked(now);
      lastCleanup_ = now;
    }

    auto &entry = buckets_[key];
    if (now - entry.windowStart >= std::chrono::minutes(1)) {
      entry.windowStart = now;
      entry.count = 0;
    }
    entry.count++;
    return entry.count <= maxPerMinute_;
  }

  /**
   * Manually cleans up rate limit buckets older than 2 minutes.
   */
  void cleanup() {
    const auto now = std::chrono::steady_clock::now();
    std::lock_guard<std::mutex> lock(mu_);
    cleanupStaleBucketsLocked(now);
  }

 private:
  struct Bucket {
    std::chrono::steady_clock::time_point windowStart{std::chrono::steady_clock::now()};
    int count{0};
  };

  void cleanupStaleBucketsLocked(std::chrono::steady_clock::time_point now) {
    for (auto it = buckets_.begin(); it != buckets_.end();) {
      if (now - it->second.windowStart >= std::chrono::minutes(2)) {
        it = buckets_.erase(it);
      } else {
        ++it;
      }
    }
  }

  int maxPerMinute_;
  std::mutex mu_;
  std::chrono::steady_clock::time_point lastCleanup_{std::chrono::steady_clock::now()};
  std::unordered_map<std::string, Bucket> buckets_;
};

}  // namespace server::middleware
