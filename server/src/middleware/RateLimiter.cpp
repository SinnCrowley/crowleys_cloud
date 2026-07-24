// RateLimiter implementation for endpoint throttling and anti-abuse protection.
// Throttling Model: Fixed 1-minute window algorithm per IP/key.
// Memory Management: Periodic pruning removes inactive client buckets older than 2 minutes, preventing memory leaks under heavy traffic or IP spoofing.

#include "server/middleware/RateLimiter.hpp"
