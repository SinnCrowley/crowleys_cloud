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

#include "server/utils/Config.hpp"
#include "server/utils/PlatformUtils.hpp"

#include <cassert>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>

#define TEST_ASSERT(cond, msg) \
  do { \
    if (!(cond)) { \
      std::cerr << "\n[ASSERTION FAILED] " << (msg) << " at " << __FILE__ << ":" << __LINE__ << std::endl; \
      std::abort(); \
    } \
  } while (0)

using namespace server::utils;

static void testExecutablePathResolution() {
  std::cout << "[TEST] Executable path and directory resolution..." << std::endl;

  auto exePath = getExecutablePath();
  TEST_ASSERT(!exePath.empty(), "getExecutablePath() must not be empty");
  TEST_ASSERT(std::filesystem::exists(exePath), "getExecutablePath() must exist on disk");
  TEST_ASSERT(exePath.is_absolute(), "getExecutablePath() must be an absolute path");

  auto exeDir = getExecutableDir();
  TEST_ASSERT(!exeDir.empty(), "getExecutableDir() must not be empty");
  TEST_ASSERT(std::filesystem::exists(exeDir), "getExecutableDir() must exist on disk");
  TEST_ASSERT(exePath.parent_path() == exeDir, "getExecutableDir() must match exePath.parent_path()");

  std::cout << "  -> exePath: " << exePath.generic_string() << std::endl;
  std::cout << "  -> exeDir:  " << exeDir.generic_string() << std::endl;
}

static void testSubpathLogic() {
  std::cout << "[TEST] Portable isSubpath boundary verification..." << std::endl;

  TEST_ASSERT(isSubpath("/foo/bar/baz.txt", "/foo/bar"), "Direct child file must be subpath");
  TEST_ASSERT(isSubpath("/foo/bar/sub/dir", "/foo/bar"), "Nested subdirectory must be subpath");
  TEST_ASSERT(isSubpath("/foo/bar", "/foo/bar"), "Exact match must be considered subpath");
  TEST_ASSERT(!isSubpath("/foo/bar_suffix", "/foo/bar"), "Prefix overlap without separator must not be subpath");
  TEST_ASSERT(!isSubpath("/foo/baz", "/foo/bar"), "Different folder must not be subpath");
  TEST_ASSERT(!isSubpath("/foo", "/foo/bar"), "Parent directory must not be subpath of child");
}

static void testConfigPathDiscovery() {
  std::cout << "[TEST] Config path discovery (argv vs executable-relative)..." << std::endl;

  // Explicit argv[1]
  char arg0[] = "crowleys_cloud_server";
  char arg1[] = "/custom/path/to/my_config.json";
  char *argv_custom[] = {arg0, arg1, nullptr};
  auto resolvedCustom = resolveConfigPath(2, argv_custom);
  TEST_ASSERT(resolvedCustom == "/custom/path/to/my_config.json", "Explicit argv[1] must be preserved");

  // No arguments: should discover config relative to executable or parent
  char *argv_none[] = {arg0, nullptr};
  auto resolvedDefault = resolveConfigPath(1, argv_none);
  TEST_ASSERT(!resolvedDefault.empty(), "Default config path must not be empty");
  std::cout << "  -> Default discovered config: " << resolvedDefault << std::endl;
  TEST_ASSERT(std::filesystem::exists(resolvedDefault), "Discovered default config must exist on disk");
}

static void testLoadConfigAndPathResolution() {
  std::cout << "[TEST] Config loading and relative path resolution..." << std::endl;

  char arg0[] = "crowleys_cloud_server";
  char *argv_none[] = {arg0, nullptr};
  auto resolvedPath = resolveConfigPath(1, argv_none);

  Config cfg = loadConfig(resolvedPath);
  TEST_ASSERT(cfg.port > 0, "Loaded port must be positive");
  TEST_ASSERT(!cfg.storageRoot.empty(), "storageRoot must not be empty");
  TEST_ASSERT(!cfg.dbPath.empty(), "dbPath must not be empty");
  TEST_ASSERT(!cfg.publicDir.empty(), "publicDir must not be empty");

  // Verify paths are made absolute
  TEST_ASSERT(std::filesystem::path(cfg.storageRoot).is_absolute(), "storageRoot must be absolute");
  TEST_ASSERT(std::filesystem::path(cfg.dbPath).is_absolute(), "dbPath must be absolute");
  TEST_ASSERT(std::filesystem::path(cfg.publicDir).is_absolute(), "publicDir must be absolute");
  TEST_ASSERT(std::filesystem::path(cfg.logDir).is_absolute(), "logDir must be absolute");

  std::cout << "  -> storageRoot: " << cfg.storageRoot << std::endl;
  std::cout << "  -> dbPath:      " << cfg.dbPath << std::endl;
  std::cout << "  -> publicDir:   " << cfg.publicDir << std::endl;
}

static void testAdversarialCwdHijackResistance() {
  std::cout << "[TEST] Adversarial CWD hijack resistance..." << std::endl;

  auto origCwd = std::filesystem::current_path();

  // Create an adversarial directory containing fake public and storage folders
  auto tmpDir = std::filesystem::temp_directory_path() / "adversarial_cwd_test";
  std::filesystem::create_directories(tmpDir / "public");
  std::filesystem::create_directories(tmpDir / "storage");
  std::filesystem::create_directories(tmpDir / "data");

  // Touch a fake canary file in the adversarial public folder
  {
    std::ofstream canary(tmpDir / "public" / "fake_canary.txt");
    canary << "I AM AN ADVERSARIAL CANARY";
  }

  // Switch CWD into the adversarial directory
  std::error_code ec;
  std::filesystem::current_path(tmpDir, ec);
  TEST_ASSERT(!ec, "current_path change must succeed");

  try {
    // Resolve and load default configuration while CWD is the adversarial directory
    char arg0[] = "crowleys_cloud_server";
    char *argv_none[] = {arg0, nullptr};
    auto resolvedPath = resolveConfigPath(1, argv_none);
    TEST_ASSERT(!resolvedPath.empty(), "resolveConfigPath must find config even from hostile CWD");

    Config cfg = loadConfig(resolvedPath);

    // CRITICAL ADVERSARIAL CHECKS:
    // cfg.publicDir MUST NOT be hijacked into tmpDir / "public"!
    TEST_ASSERT(cfg.publicDir != (tmpDir / "public").generic_string(),
                "publicDir MUST NOT be hijacked by CWD 'public' folder!");
    TEST_ASSERT(!std::filesystem::exists(std::filesystem::path(cfg.publicDir) / "fake_canary.txt"),
                "Server publicDir must NOT point to the hostile canary directory!");

    // cfg.storageRoot MUST NOT be hijacked into tmpDir / "storage"!
    TEST_ASSERT(cfg.storageRoot != (tmpDir / "storage").generic_string(),
                "storageRoot MUST NOT be hijacked by CWD 'storage' folder!");

    // cfg.dbPath MUST NOT be hijacked into tmpDir / "data"!
    TEST_ASSERT(cfg.dbPath.find((tmpDir / "data").generic_string()) == std::string::npos,
                "dbPath MUST NOT be hijacked by CWD 'data' folder!");

    std::cout << "  -> Verified publicDir (" << cfg.publicDir
              << ") was not hijacked by hostile CWD (" << tmpDir.generic_string() << ")" << std::endl;
    std::cout << "  -> Verified storageRoot (" << cfg.storageRoot
              << ") was not hijacked by hostile CWD (" << tmpDir.generic_string() << ")" << std::endl;

  } catch (...) {
    std::filesystem::current_path(origCwd, ec);
    std::filesystem::remove_all(tmpDir, ec);
    throw;
  }

  // Restore CWD and clean up
  std::filesystem::current_path(origCwd, ec);
  std::filesystem::remove_all(tmpDir, ec);
}

static void testNonExistentDirectoryResolution() {
  std::cout << "[TEST] Non-existent target directory resolution under baseDir..." << std::endl;

  auto origCwd = std::filesystem::current_path();
  auto tmpDir = std::filesystem::temp_directory_path() / "adversarial_nonexistent_test";
  std::filesystem::create_directories(tmpDir / "hostile_cwd" / "fresh_storage");

  // Create isolated config directory with custom config.json
  auto appDir = tmpDir / "app";
  std::filesystem::create_directories(appDir / "config");
  auto customCfgPath = appDir / "config" / "config.json";
  {
    std::ofstream out(customCfgPath);
    out << "{\n"
        << "  \"port\": 9999,\n"
        << "  \"storage_root\": \"./fresh_storage\",\n"
        << "  \"db_path\": \"./fresh_data/db.sqlite3\"\n"
        << "}\n";
  }

  // CWD contains 'fresh_storage'
  std::error_code ec;
  std::filesystem::current_path(tmpDir / "hostile_cwd", ec);
  TEST_ASSERT(!ec, "current_path change to hostile_cwd must succeed");

  try {
    Config cfg = loadConfig(customCfgPath.generic_string());

    // fresh_storage does not exist yet under appDir, but does exist in CWD.
    // The resolution MUST resolve to appDir / fresh_storage, NOT hostile_cwd / fresh_storage!
    auto expectedStorage = std::filesystem::weakly_canonical(appDir / "fresh_storage", ec).generic_string();
    auto hostileStorage = std::filesystem::weakly_canonical(tmpDir / "hostile_cwd" / "fresh_storage", ec).generic_string();

    TEST_ASSERT(cfg.storageRoot == expectedStorage, "storageRoot must resolve to baseDir / fresh_storage");
    TEST_ASSERT(cfg.storageRoot != hostileStorage, "storageRoot must NEVER be hijacked by CWD fresh_storage");

    std::cout << "  -> Verified non-existent storageRoot (" << cfg.storageRoot
              << ") resolved to baseDir and resisted CWD hijack" << std::endl;

  } catch (...) {
    std::filesystem::current_path(origCwd, ec);
    std::filesystem::remove_all(tmpDir, ec);
    throw;
  }

  std::filesystem::current_path(origCwd, ec);
  std::filesystem::remove_all(tmpDir, ec);
}

static void testMalformedAndEdgeCaseConfigs() {
  std::cout << "[TEST] Malformed JSON, directories, empty paths, and edge cases..." << std::endl;

  // 1. Empty path string
  Config cfgEmpty = loadConfig("");
  TEST_ASSERT(cfgEmpty.port == 8080, "Default port must be 8080 on empty path");
  TEST_ASSERT(!cfgEmpty.storageRoot.empty(), "storageRoot must have valid default on empty path");

  // 2. Directory passed as config path (should not crash or read directory stream)
  auto tmpDir = std::filesystem::temp_directory_path() / "config_dir_test";
  std::filesystem::create_directories(tmpDir);
  Config cfgDir = loadConfig(tmpDir.generic_string());
  TEST_ASSERT(cfgDir.port == 8080, "Default port must be 8080 when directory passed as config");

  // 3. Completely non-existent path
  Config cfgNonExistent = loadConfig("/non_existent_path_nowhere_12345/config.json");
  TEST_ASSERT(cfgNonExistent.port == 8080, "Default port must be 8080 on non-existent config path");

  // 4. Malformed JSON file (syntax error, truncated, binary garbage)
  auto malformedFile = tmpDir / "malformed_config.json";
  {
    std::ofstream out(malformedFile);
    out << "{ \"port\": 9090, \"broken_json_syntax: ";
  }
  Config cfgMalformed = loadConfig(malformedFile.generic_string());
  TEST_ASSERT(cfgMalformed.port == 8080, "Default port must be preserved when JSON parsing throws syntax error");

  // Clean up
  std::error_code ec;
  std::filesystem::remove_all(tmpDir, ec);

  std::cout << "  -> Verified empty path, directory path, non-existent path, and malformed JSON resilience" << std::endl;
}

int main(int argc, char *argv[]) {
  std::cout << "========================================" << std::endl;
  std::cout << "Running Config & Runtime Path Resolution Tests" << std::endl;
  std::cout << "========================================" << std::endl;

  testExecutablePathResolution();
  testSubpathLogic();
  testConfigPathDiscovery();
  testLoadConfigAndPathResolution();
  testAdversarialCwdHijackResistance();
  testNonExistentDirectoryResolution();
  testMalformedAndEdgeCaseConfigs();

  std::cout << "\n[ALL TESTS PASSED CLEANLY]\n" << std::endl;
  return 0;
}
