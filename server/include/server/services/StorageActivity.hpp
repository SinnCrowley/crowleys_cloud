// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later
#pragma once
#include <condition_variable>
#include <memory>
#include <mutex>
#include <stop_token>

namespace server::services {
// Counts operations, including streamed responses. Leases may finish on another thread.
class StorageActivity {
 public:
  class Lease {
   public:
    explicit Lease(StorageActivity &owner) : owner_(owner) {}
    ~Lease() {
      std::lock_guard<std::mutex> lock(owner_.mutex_);
      --owner_.active_;
      owner_.changed_.notify_all();
    }
   private:
    StorageActivity &owner_;
  };
  std::shared_ptr<Lease> enter() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (blocked_) return {};
    auto lease = std::make_shared<Lease>(*this);
    ++active_;
    return lease;
  }
  bool block() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (blocked_) return false;
    blocked_ = true;
    return true;
  }
  void unblock() { std::lock_guard<std::mutex> lock(mutex_); blocked_ = false; }
  bool blocked() const { std::lock_guard<std::mutex> lock(mutex_); return blocked_; }
  bool drain(std::stop_token stop) {
    std::unique_lock<std::mutex> lock(mutex_);
    return changed_.wait(lock, stop, [&] { return active_ == 0; });
  }
 private:
  mutable std::mutex mutex_;
  std::condition_variable_any changed_;
  bool blocked_{false};
  std::size_t active_{0};
};
}
