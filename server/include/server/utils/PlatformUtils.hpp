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

#pragma once

#include <chrono>
#include <filesystem>
#include <string>
#include <vector>
#include <system_error>
#include <algorithm>
#include <cctype>

#if defined(_WIN32)
#include <process.h>
#include <windows.h>
#else
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>
extern "C" char **environ;
#endif

namespace server::utils {

/**
 * Cross-platform process execution for thumbnail generation and external tools.
 */
inline bool runProcess(const std::vector<std::string> &args) {
  if (args.empty()) return false;

#if defined(_WIN32)
  std::vector<const char *> argv;
  argv.reserve(args.size() + 1);
  for (const auto &arg : args) {
    argv.push_back(arg.c_str());
  }
  argv.push_back(nullptr);

  intptr_t ret = _spawnvp(_P_WAIT, argv[0], const_cast<char *const *>(argv.data()));
  return ret == 0;
#else
  std::vector<char *> argv;
  argv.reserve(args.size() + 1);
  for (const auto &arg : args) {
    argv.push_back(const_cast<char *>(arg.c_str()));
  }
  argv.push_back(nullptr);

  pid_t pid;
  int status = posix_spawnp(&pid, argv[0], nullptr, nullptr, argv.data(), environ);
  if (status != 0) {
    return false;
  }
  while (waitpid(pid, &status, 0) == -1) {
    if (errno != EINTR) {
      return false;
    }
  }
  return WIFEXITED(status) && (WEXITSTATUS(status) == 0);
#endif
}

/**
 * Portable file/directory rename operation.
 * On Windows, std::filesystem::rename fails if the target destination already exists.
 */
inline void portableRename(const std::filesystem::path &from, const std::filesystem::path &to, std::error_code &ec) {
#if defined(_WIN32)
  if (std::filesystem::exists(to, ec)) {
    std::filesystem::remove_all(to, ec);
    if (ec) return;
  }
#endif
  std::filesystem::rename(from, to, ec);
}

inline void portableRename(const std::filesystem::path &from, const std::filesystem::path &to) {
  std::error_code ec;
  portableRename(from, to, ec);
  if (ec) {
    throw std::filesystem::filesystem_error("portableRename failed", from, to, ec);
  }
}

/**
 * Convert file_time_type to Unix Epoch milliseconds portably across MSVC, GCC, and Clang.
 */
inline int64_t fileTimeToMillis(const std::filesystem::file_time_type &ftime) {
  using namespace std::chrono;
  auto sys_now = system_clock::now();
  auto file_now = std::filesystem::file_time_type::clock::now();
  auto s_time = sys_now + duration_cast<milliseconds>(ftime - file_now);
  return duration_cast<milliseconds>(s_time.time_since_epoch()).count();
}

/**
 * Portable boundary verification: check if candidate path is under allowed root.
 * Handles case-sensitivity appropriately for the operating system (Windows/macOS vs Linux).
 */
inline bool isSubpath(const std::filesystem::path &candidate, const std::filesystem::path &root) {
  auto candidateStr = candidate.generic_string();
  auto rootStr = root.generic_string();

  if (rootStr.empty() || rootStr.back() != '/') {
    rootStr.push_back('/');
  }

#if defined(_WIN32) || defined(__APPLE__)
  // Case-insensitive comparison for Windows (NTFS) and macOS (APFS)
  auto toLower = [](std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return std::tolower(c); });
    return s;
  };
  candidateStr = toLower(candidateStr);
  rootStr = toLower(rootStr);
#endif

  if (candidateStr == rootStr.substr(0, rootStr.size() - 1)) {
    return true;
  }
  return candidateStr.size() >= rootStr.size() && candidateStr.compare(0, rootStr.size(), rootStr) == 0;
}

}  // namespace server::utils
