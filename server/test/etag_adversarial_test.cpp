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

#include <iostream>
#include <cassert>
#include <chrono>
#include <vector>
#include <string>
#include <thread>
#include <atomic>
#include <sstream>

#include "server/utils/HttpHelpers.hpp"

using namespace server::utils;

// Test helper macro
#define TEST_ASSERT(cond, msg) \
  do { \
    if (!(cond)) { \
      std::cerr << "[FAIL] Line " << __LINE__ << ": " << (msg) << std::endl; \
      std::exit(1); \
    } \
  } while (0)

void testFormatETag() {
  std::cout << "[TEST] Running testFormatETag..." << std::endl;
  TEST_ASSERT(formatETag("abc") == "\"abc\"", "Plain string quoted");
  TEST_ASSERT(formatETag("\"abc\"") == "\"abc\"", "Already quoted string remains quoted");
  TEST_ASSERT(formatETag("") == "\"\"", "Empty string becomes empty quoted");
  TEST_ASSERT(formatETag("a") == "\"a\"", "Single char string quoted");
  TEST_ASSERT(formatETag("\"") == "\"\"\"", "Single quote gets quoted");
  TEST_ASSERT(formatETag("\"\"") == "\"\"", "Double quote pair preserved");
  TEST_ASSERT(formatETag("sha256_256") == "\"sha256_256\"", "Standard thumbnail ETag");
  TEST_ASSERT(formatETag("1725134000_2048576_512") == "\"1725134000_2048576_512\"", "Mtime size ETag");
  std::cout << "[PASS] testFormatETag passed." << std::endl;
}

void testMatchesIfNoneMatch_StandardAndMixedQuotes() {
  std::cout << "[TEST] Running testMatchesIfNoneMatch_StandardAndMixedQuotes..." << std::endl;
  // Mixed quotes: Header quoted vs Target unquoted
  TEST_ASSERT(matchesIfNoneMatch("\"tag1\"", "tag1"), "Header quoted, Target unquoted");
  // Mixed quotes: Header unquoted vs Target quoted
  TEST_ASSERT(matchesIfNoneMatch("tag1", "\"tag1\""), "Header unquoted, Target quoted");
  // Both quoted
  TEST_ASSERT(matchesIfNoneMatch("\"tag1\"", "\"tag1\""), "Both quoted");
  // Both unquoted
  TEST_ASSERT(matchesIfNoneMatch("tag1", "tag1"), "Both unquoted");

  // Non-matches
  TEST_ASSERT(!matchesIfNoneMatch("\"tag1\"", "tag2"), "Mismatch tag");
  TEST_ASSERT(!matchesIfNoneMatch("tag1", "tag2"), "Mismatch unquoted");
  TEST_ASSERT(!matchesIfNoneMatch("", "tag1"), "Empty header");
  TEST_ASSERT(!matchesIfNoneMatch("   ", "tag1"), "Whitespace-only header");
  TEST_ASSERT(!matchesIfNoneMatch("\"tag1\"", ""), "Empty target tag");
  TEST_ASSERT(!matchesIfNoneMatch("\"tag1\"", "", ""), "Empty both target tags");

  std::cout << "[PASS] testMatchesIfNoneMatch_StandardAndMixedQuotes passed." << std::endl;
}

void testMatchesIfNoneMatch_WeakTags() {
  std::cout << "[TEST] Running testMatchesIfNoneMatch_WeakTags..." << std::endl;
  // Weak prefix W/ and w/
  TEST_ASSERT(matchesIfNoneMatch("W/\"tag1\"", "tag1"), "W/ quoted match against unquoted");
  TEST_ASSERT(matchesIfNoneMatch("W/\"tag1\"", "\"tag1\""), "W/ quoted match against quoted");
  TEST_ASSERT(matchesIfNoneMatch("w/\"tag1\"", "tag1"), "lowercase w/ quoted match");
  TEST_ASSERT(matchesIfNoneMatch("W/\"tag1\"", "W/\"tag1\""), "W/ header against W/ target");
  TEST_ASSERT(matchesIfNoneMatch("W/ \"tag1\"", "tag1"), "W/ with space before quote");
  TEST_ASSERT(matchesIfNoneMatch("w/ \t \"tag1\"", "tag1"), "w/ with tab before quote");
  TEST_ASSERT(matchesIfNoneMatch("W/tag1", "tag1"), "W/ unquoted");
  TEST_ASSERT(matchesIfNoneMatch("w/tag1", "tag1"), "w/ unquoted");
  TEST_ASSERT(!matchesIfNoneMatch("W/\"tag1\"", "tag2"), "W/ mismatch");
  TEST_ASSERT(!matchesIfNoneMatch("W/", "tag1"), "W/ prefix only without tag");
  TEST_ASSERT(!matchesIfNoneMatch("W/\"\"", "tag1"), "W/ empty quoted tag");

  std::cout << "[PASS] testMatchesIfNoneMatch_WeakTags passed." << std::endl;
}

void testMatchesIfNoneMatch_Wildcard() {
  std::cout << "[TEST] Running testMatchesIfNoneMatch_Wildcard..." << std::endl;
  TEST_ASSERT(matchesIfNoneMatch("*", "anytag"), "Wildcard * matches any target");
  TEST_ASSERT(matchesIfNoneMatch(" * ", "anytag"), "Wildcard with spaces");
  TEST_ASSERT(matchesIfNoneMatch("\"*\"", "anytag"), "Quoted wildcard");
  TEST_ASSERT(matchesIfNoneMatch("W/\"*\"", "anytag"), "Weak quoted wildcard");
  TEST_ASSERT(matchesIfNoneMatch("W/*", "anytag"), "Weak unquoted wildcard");
  TEST_ASSERT(matchesIfNoneMatch("tag1, *", "tag2"), "Wildcard in comma list");
  TEST_ASSERT(matchesIfNoneMatch("*, tag1", "tag2"), "Wildcard first in comma list");

  // Wildcard when target tags are completely empty
  TEST_ASSERT(!matchesIfNoneMatch("*", "", ""), "Wildcard on empty targets returns false");

  std::cout << "[PASS] testMatchesIfNoneMatch_Wildcard passed." << std::endl;
}

void testMatchesIfNoneMatch_CommaListsAndTrailingSpaces() {
  std::cout << "[TEST] Running testMatchesIfNoneMatch_CommaListsAndTrailingSpaces..." << std::endl;
  // Mixed quoted/unquoted/weak tokens in list
  const std::string mixedList = "W/\"tag1\", tag2, \"tag3\", W/  \"tag4\"";
  TEST_ASSERT(matchesIfNoneMatch(mixedList, "tag1"), "Match weak tag1 in mixed list");
  TEST_ASSERT(matchesIfNoneMatch(mixedList, "tag2"), "Match unquoted tag2 in mixed list");
  TEST_ASSERT(matchesIfNoneMatch(mixedList, "tag3"), "Match quoted tag3 in mixed list");
  TEST_ASSERT(matchesIfNoneMatch(mixedList, "tag4"), "Match weak spaced tag4 in mixed list");
  TEST_ASSERT(!matchesIfNoneMatch(mixedList, "tag5"), "Absent item in mixed list");

  // Malformed comma lists with extra commas
  TEST_ASSERT(matchesIfNoneMatch(",,, \"target\" ,,,", "target"), "Multiple consecutive commas");
  TEST_ASSERT(matchesIfNoneMatch(",,,,", "target") == false, "Only commas");
  TEST_ASSERT(matchesIfNoneMatch(" , , \t , \r\n ", "target") == false, "Commas and whitespace only");
  TEST_ASSERT(matchesIfNoneMatch("tag1, , tag2 ,,, tag3", "tag2"), "Empty tokens between valid tokens");
  TEST_ASSERT(matchesIfNoneMatch("tag1,", "tag1"), "Trailing comma");
  TEST_ASSERT(matchesIfNoneMatch(",tag1", "tag1"), "Leading comma");
  TEST_ASSERT(matchesIfNoneMatch("tag1,   ", "tag1"), "Trailing comma with trailing spaces");
  TEST_ASSERT(matchesIfNoneMatch("   ,tag1", "tag1"), "Leading comma with leading spaces");

  // Whitespace variations (CRLF, Tabs, Trailing/Leading Spaces)
  TEST_ASSERT(matchesIfNoneMatch("  \"tag1\"  ", "tag1"), "Leading and trailing spaces");
  TEST_ASSERT(matchesIfNoneMatch(" \t \r\n \"tag1\" \t \r\n ", "tag1"), "CRLF and tabs surrounding tag");
  TEST_ASSERT(matchesIfNoneMatch(" \r\n W/\"tag1\" \r\n, \r\n \"tag2\" ", "tag1"), "Multiline weak list");
  TEST_ASSERT(matchesIfNoneMatch(" \r\n W/\"tag1\" \r\n, \r\n \"tag2\" ", "tag2"), "Multiline strong list");

  std::cout << "[PASS] testMatchesIfNoneMatch_CommaListsAndTrailingSpaces passed." << std::endl;
}

void testMatchesIfNoneMatch_SecondaryFallback() {
  std::cout << "[TEST] Running testMatchesIfNoneMatch_SecondaryFallback..." << std::endl;
  const std::string thumbEtag = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855_256";
  const std::string baseSha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";

  // Match against primary thumb ETag
  TEST_ASSERT(matchesIfNoneMatch("\"" + thumbEtag + "\"", thumbEtag, baseSha256), "Primary tag match");
  TEST_ASSERT(matchesIfNoneMatch("W/\"" + thumbEtag + "\"", thumbEtag, baseSha256), "Primary weak tag match");

  // Match against fallback base SHA-256
  TEST_ASSERT(matchesIfNoneMatch("\"" + baseSha256 + "\"", thumbEtag, baseSha256), "Secondary base sha256 match");
  TEST_ASSERT(matchesIfNoneMatch("W/\"" + baseSha256 + "\"", thumbEtag, baseSha256), "Secondary weak base sha256 match");

  // List with both or fallback
  TEST_ASSERT(matchesIfNoneMatch("\"unrelated\", \"" + baseSha256 + "\"", thumbEtag, baseSha256), "Fallback in list");
  TEST_ASSERT(!matchesIfNoneMatch("\"unrelated\", \"wrong_hash\"", thumbEtag, baseSha256), "No match in list");

  // matchETag alias function test
  TEST_ASSERT(matchETag("\"" + thumbEtag + "\"", thumbEtag, baseSha256), "matchETag alias matches primary");
  TEST_ASSERT(matchETag("W/\"" + baseSha256 + "\"", thumbEtag, baseSha256), "matchETag alias matches secondary");

  std::cout << "[PASS] testMatchesIfNoneMatch_SecondaryFallback passed." << std::endl;
}

void testMatchesIfNoneMatch_AdversarialInputs() {
  std::cout << "[TEST] Running testMatchesIfNoneMatch_AdversarialInputs..." << std::endl;
  // Very long list of 2,000 tags
  std::string hugeList;
  for (int i = 0; i < 2000; ++i) {
    hugeList += "W/\"dummy_tag_" + std::to_string(i) + "\", ";
  }
  hugeList += "W/\"target_tag\"";

  TEST_ASSERT(matchesIfNoneMatch(hugeList, "target_tag"), "Match at end of 2,000 tag list");
  TEST_ASSERT(!matchesIfNoneMatch(hugeList, "nonexistent_tag"), "Non-match in 2,000 tag list");

  // Non-W slashes preserved
  TEST_ASSERT(matchesIfNoneMatch("///tag1", "///tag1"), "Non-W slashes preserved");
  TEST_ASSERT(matchesIfNoneMatch("W", "W"), "Single W");
  TEST_ASSERT(matchesIfNoneMatch("W/", "W/") == false, "W/ empty cleaned to empty");

  // UTF-8 strings
  TEST_ASSERT(matchesIfNoneMatch("\"тег_123\"", "тег_123"), "UTF-8 Cyrillic ETag");
  TEST_ASSERT(matchesIfNoneMatch("W/\"🏷️_tag\"", "🏷️_tag"), "Emoji ETag");

  std::cout << "[PASS] testMatchesIfNoneMatch_AdversarialInputs passed." << std::endl;
}

void testMakeNotModifiedResponse() {
  std::cout << "[TEST] Running testMakeNotModifiedResponse..." << std::endl;
  auto resp = makeNotModifiedResponse("abc_256", "private, max-age=31536000, immutable");
  TEST_ASSERT(resp->statusCode() == drogon::k304NotModified, "HTTP 304 status code");
  TEST_ASSERT(resp->getHeader("ETag") == "\"abc_256\"", "Quoted ETag header");
  TEST_ASSERT(resp->getHeader("Cache-Control") == "private, max-age=31536000, immutable", "Cache-Control header");
  TEST_ASSERT(resp->getBody().empty(), "Empty body on 304 response");
  TEST_ASSERT(resp->getBody().size() == 0, "0 bytes body payload");

  // Verify Download 304 response headers
  auto downloadResp = makeNotModifiedResponse("sha256_val", "private, no-cache");
  TEST_ASSERT(downloadResp->statusCode() == drogon::k304NotModified, "Download HTTP 304");
  TEST_ASSERT(downloadResp->getHeader("ETag") == "\"sha256_val\"", "Download ETag");
  TEST_ASSERT(downloadResp->getHeader("Cache-Control") == "private, no-cache", "Download Cache-Control");
  TEST_ASSERT(downloadResp->getBody().size() == 0, "Download 304 0-byte body");

  // Estimate serialized HTTP frame size:
  // "HTTP/1.1 304 Not Modified\r\nETag: \"abc_256\"\r\nCache-Control: private, max-age=31536000, immutable\r\n\r\n"
  std::ostringstream oss;
  oss << "HTTP/1.1 304 Not Modified\r\n";
  oss << "ETag: " << resp->getHeader("ETag") << "\r\n";
  oss << "Cache-Control: " << resp->getHeader("Cache-Control") << "\r\n\r\n";
  std::string frame = oss.str();
  std::cout << "Estimated HTTP 304 wire frame length: " << frame.size() << " bytes" << std::endl;
  std::cout << "HTTP 304 frame payload preview:\n" << frame;
  TEST_ASSERT(frame.size() < 150, "HTTP 304 wire frame is strictly under 150 bytes");

  std::cout << "[PASS] testMakeNotModifiedResponse passed." << std::endl;
}

void testPerformanceAndStress() {
  std::cout << "[TEST] Running testPerformanceAndStress (1,000,000 iterations)..." << std::endl;
  const std::string header = "W/\"tag0\", \"tag1\", W/\"tag2\", \"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855_256\", \"tag4\"";
  const std::string target1 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855_256";
  const std::string target2 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";

  auto start = std::chrono::high_resolution_clock::now();
  int matchCount = 0;
  constexpr int iterations = 1000000;
  for (int i = 0; i < iterations; ++i) {
    if (matchesIfNoneMatch(header, target1, target2)) {
      matchCount++;
    }
  }
  auto end = std::chrono::high_resolution_clock::now();
  auto elapsedNs = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
  double avgNs = static_cast<double>(elapsedNs) / iterations;
  double opsPerSec = (iterations * 1e9) / elapsedNs;

  TEST_ASSERT(matchCount == iterations, "All 1M iterations matched");
  std::cout << "1,000,000 matches in " << elapsedNs / 1e6 << " ms" << std::endl;
  std::cout << "Average latency: " << avgNs << " ns per check (" << opsPerSec << " ops/sec)" << std::endl;
  TEST_ASSERT(avgNs < 1000.0, "Sub-microsecond latency confirmed (< 1000 ns)");

  // Multithreaded stress test
  std::cout << "[TEST] Running multithreaded stress test across 8 threads (800,000 operations)..." << std::endl;
  std::atomic<int> totalMatches{0};
  std::vector<std::thread> threads;
  for (int t = 0; t < 8; ++t) {
    threads.emplace_back([&header, &target1, &target2, &totalMatches]() {
      for (int i = 0; i < 100000; ++i) {
        if (matchesIfNoneMatch(header, target1, target2)) {
          totalMatches.fetch_add(1, std::memory_order_relaxed);
        }
      }
    });
  }
  for (auto &th : threads) {
    th.join();
  }
  TEST_ASSERT(totalMatches.load() == 800000, "Multithreaded 800k operations all matched without race condition");
  std::cout << "[PASS] testPerformanceAndStress passed." << std::endl;
}

int main() {
  std::cout << "=========================================================" << std::endl;
  std::cout << "Starting Adversarial HTTP 304 & ETag Test Suite" << std::endl;
  std::cout << "=========================================================" << std::endl;

  testFormatETag();
  testMatchesIfNoneMatch_StandardAndMixedQuotes();
  testMatchesIfNoneMatch_WeakTags();
  testMatchesIfNoneMatch_Wildcard();
  testMatchesIfNoneMatch_CommaListsAndTrailingSpaces();
  testMatchesIfNoneMatch_SecondaryFallback();
  testMatchesIfNoneMatch_AdversarialInputs();
  testMakeNotModifiedResponse();
  testPerformanceAndStress();

  std::cout << "=========================================================" << std::endl;
  std::cout << "ALL ADVERSARIAL TESTS PASSED CLEANLY!" << std::endl;
  std::cout << "=========================================================" << std::endl;
  return 0;
}
