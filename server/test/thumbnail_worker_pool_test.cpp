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

#include "server/services/ThumbnailQueue.hpp"
#include "server/utils/Crypto.hpp"

#include <atomic>
#include <chrono>
#include <cstdlib>
#include <iostream>
#include <thread>
#include <vector>

#define TEST_ASSERT(cond) \
  do { \
    if (!(cond)) { \
      std::cerr << "\n[ASSERTION FAILED] " #cond " at " << __FILE__ << ":" << __LINE__ << std::endl; \
      std::abort(); \
    } \
  } while (0)

using namespace server;
using namespace server::services;

// 1. Verify that concurrent worker execution never exceeds 2 threads
static void testStrictBoundedWorkerConcurrency() {
  std::cout << "[TEST] Running Strict Bounded Worker Concurrency test..." << std::endl;

  std::atomic<int> activeWorkers{0};
  std::atomic<int> maxConcurrentWorkers{0};
  std::atomic<int> completedTasks{0};

  // Create queue configured with 2 workers
  ThumbnailQueue queue(100, 2);
  queue.setTaskProcessor([&](const ThumbnailTask &) {
    int current = activeWorkers.fetch_add(1) + 1;
    int prevMax = maxConcurrentWorkers.load();
    while (current > prevMax && !maxConcurrentWorkers.compare_exchange_weak(prevMax, current)) {}

    // Simulate non-trivial work
    std::this_thread::sleep_for(std::chrono::milliseconds(20));

    activeWorkers.fetch_sub(1);
    completedTasks.fetch_add(1);
  });

  queue.start();

  // Enqueue 20 tasks
  for (int i = 0; i < 20; ++i) {
    ThumbnailTask task;
    task.key = "concurrency_task_" + std::to_string(i);
    TEST_ASSERT(queue.enqueue(task));
  }

  // Wait for completion
  for (int i = 0; i < 100; ++i) {
    if (completedTasks == 20) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }

  queue.stop();

  std::cout << "  [INFO] Completed tasks: " << completedTasks
            << ", Max concurrent workers observed: " << maxConcurrentWorkers << std::endl;

  TEST_ASSERT(completedTasks == 20);
  TEST_ASSERT(maxConcurrentWorkers <= 2);
  TEST_ASSERT(maxConcurrentWorkers >= 1);

  std::cout << "  [PASS] Strict Bounded Worker Concurrency passed." << std::endl;
}

// 2. High-throughput Non-blocking Producer Latency (< 100 microseconds per enqueue)
static void testNonBlockingProducerLatency() {
  std::cout << "[TEST] Running Non-Blocking Producer Latency test..." << std::endl;

  ThumbnailQueue queue(1000, 0); // Producer only, no worker pop

  const int taskCount = 500;
  auto start = std::chrono::high_resolution_clock::now();

  for (int i = 0; i < taskCount; ++i) {
    ThumbnailTask task;
    task.key = "perf_task_" + std::to_string(i);
    task.thumbSize = 256;
    task.sourcePath = "/dummy/path/" + std::to_string(i);
    bool ok = queue.enqueue(task);
    TEST_ASSERT(ok);
  }

  auto elapsed = std::chrono::high_resolution_clock::now() - start;
  auto totalMicroseconds = std::chrono::duration_cast<std::chrono::microseconds>(elapsed).count();
  double avgMicroseconds = static_cast<double>(totalMicroseconds) / taskCount;

  std::cout << "  [INFO] Total time for " << taskCount << " enqueues: "
            << totalMicroseconds << " µs (avg " << avgMicroseconds << " µs/enqueue)" << std::endl;

  TEST_ASSERT(avgMicroseconds < 50.0); // Extremely fast in-memory hash insert
  TEST_ASSERT(queue.size() == taskCount);

  std::cout << "  [PASS] Non-Blocking Producer Latency passed." << std::endl;
}

// 3. High Burst Deduplication & Drop Under Load
static void testBurstDeduplicationUnderLoad() {
  std::cout << "[TEST] Running Burst Deduplication Under Load test..." << std::endl;

  ThumbnailQueue queue(50, 0, OverflowPolicy::DropNewest);

  // Enqueue 10 unique tasks
  for (int i = 0; i < 10; ++i) {
    ThumbnailTask task;
    task.key = "unique_" + std::to_string(i);
    TEST_ASSERT(queue.enqueue(task));
  }

  // Rapidly hammer the queue with duplicates of those 10 tasks (1,000 requests)
  size_t rejectedDuplicates = 0;
  for (int i = 0; i < 1000; ++i) {
    ThumbnailTask task;
    task.key = "unique_" + std::to_string(i % 10);
    if (!queue.enqueue(task)) {
      rejectedDuplicates++;
    }
  }

  TEST_ASSERT(rejectedDuplicates == 1000);
  TEST_ASSERT(queue.size() == 10);
  TEST_ASSERT(queue.inFlightCount() == 10);

  std::cout << "  [INFO] Successfully rejected " << rejectedDuplicates << " duplicate tasks in O(1) time." << std::endl;
  std::cout << "  [PASS] Burst Deduplication Under Load passed." << std::endl;
}

int main() {
  std::cout << "==================================================" << std::endl;
  std::cout << "Starting ThumbnailWorkerPool Concurrency Tests" << std::endl;
  std::cout << "==================================================" << std::endl;

  testStrictBoundedWorkerConcurrency();
  testNonBlockingProducerLatency();
  testBurstDeduplicationUnderLoad();

  std::cout << "==================================================" << std::endl;
  std::cout << "ALL WORKER POOL TESTS PASSED SUCCESSFULLY!" << std::endl;
  std::cout << "==================================================" << std::endl;
  return 0;
}
