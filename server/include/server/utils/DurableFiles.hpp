// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later
#pragma once
#include "server/utils/Crypto.hpp"
#include <algorithm>
#include <filesystem>
#include <fstream>
#include <stdexcept>
#include <string>
#ifdef _WIN32
#include <windows.h>
#include <aclapi.h>
#include <vector>
#else
#include <fcntl.h>
#include <unistd.h>
#endif

namespace server::utils {
inline void syncFile(const std::filesystem::path &path) {
#ifdef _WIN32
  HANDLE handle = CreateFileW(path.c_str(), GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
                              nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (handle == INVALID_HANDLE_VALUE) throw std::runtime_error("Cannot open file for durable write");
  const bool ok = FlushFileBuffers(handle);
  CloseHandle(handle);
#else
  const int handle = ::open(path.c_str(), O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
  if (handle < 0) throw std::runtime_error("Cannot open file for durable write");
  const bool ok = ::fsync(handle) == 0;
  ::close(handle);
#endif
  if (!ok) throw std::runtime_error("Cannot flush file");
}

inline void syncDirectory(const std::filesystem::path &path) {
#ifndef _WIN32
  const int handle = ::open(path.c_str(), O_RDONLY | O_DIRECTORY | O_CLOEXEC);
  if (handle < 0) throw std::runtime_error("Cannot open directory for durable write");
  const bool ok = ::fsync(handle) == 0;
  ::close(handle);
  if (!ok) throw std::runtime_error("Cannot flush directory");
#else
  (void)path; // MoveFileExW below requests write-through on Windows.
#endif
}

inline void durableReplace(const std::filesystem::path &from, const std::filesystem::path &to) {
  syncFile(from);
#ifdef _WIN32
  if (!MoveFileExW(from.c_str(), to.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH))
    throw std::runtime_error("Cannot replace file");
#else
  std::filesystem::rename(from, to);
  syncDirectory(to.parent_path());
#endif
}

inline void writePrivateAtomic(const std::filesystem::path &path, const std::string &contents) {
  const auto temporary = path.parent_path() / (path.filename().string() + "." + randomTokenHex(12) + ".tmp");
  try {
#ifdef _WIN32
    HANDLE token = nullptr;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token))
      throw std::runtime_error("Cannot determine private file owner");
    DWORD length = 0;
    GetTokenInformation(token, TokenUser, nullptr, 0, &length);
    std::vector<unsigned char> buffer(length);
    const bool tokenOk = GetTokenInformation(token, TokenUser, buffer.data(), length, &length);
    CloseHandle(token);
    if (!tokenOk) throw std::runtime_error("Cannot determine private file owner");
    EXPLICIT_ACCESSW access{};
    access.grfAccessPermissions = GENERIC_ALL;
    access.grfAccessMode = SET_ACCESS;
    access.grfInheritance = NO_INHERITANCE;
    access.Trustee.TrusteeForm = TRUSTEE_IS_SID;
    access.Trustee.TrusteeType = TRUSTEE_IS_USER;
    access.Trustee.ptstrName = static_cast<LPWSTR>(reinterpret_cast<TOKEN_USER *>(buffer.data())->User.Sid);
    PACL acl = nullptr;
    if (SetEntriesInAclW(1, &access, nullptr, &acl) != ERROR_SUCCESS)
      throw std::runtime_error("Cannot restrict private file access");
    SECURITY_DESCRIPTOR descriptor{};
    const bool secure = InitializeSecurityDescriptor(&descriptor, SECURITY_DESCRIPTOR_REVISION) &&
      SetSecurityDescriptorDacl(&descriptor, TRUE, acl, FALSE) &&
      SetSecurityDescriptorControl(&descriptor, SE_DACL_PROTECTED, SE_DACL_PROTECTED);
    SECURITY_ATTRIBUTES attributes{sizeof(SECURITY_ATTRIBUTES), &descriptor, FALSE};
    HANDLE handle = secure ? CreateFileW(temporary.c_str(), GENERIC_WRITE, 0, &attributes,
                                        CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr) : INVALID_HANDLE_VALUE;
    LocalFree(acl);
    if (handle == INVALID_HANDLE_VALUE) throw std::runtime_error("Cannot create private file");
    std::size_t written = 0;
    while (written < contents.size()) {
      DWORD count = 0;
      const DWORD chunk = static_cast<DWORD>(std::min<std::size_t>(contents.size() - written, MAXDWORD));
      if (!WriteFile(handle, contents.data() + written, chunk, &count, nullptr) || count == 0) {
        CloseHandle(handle); throw std::runtime_error("Cannot write private file");
      }
      written += count;
    }
    CloseHandle(handle);
#else
    const int handle = ::open(temporary.c_str(), O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW, 0600);
    if (handle < 0) throw std::runtime_error("Cannot create private file");
    std::size_t written = 0;
    while (written < contents.size()) {
      const auto count = ::write(handle, contents.data() + written, contents.size() - written);
      if (count <= 0) { ::close(handle); throw std::runtime_error("Cannot write private file"); }
      written += static_cast<std::size_t>(count);
    }
    ::close(handle);
#endif
    durableReplace(temporary, path);
  } catch (...) {
    std::error_code error;
    std::filesystem::remove(temporary, error);
    throw;
  }
}
}
