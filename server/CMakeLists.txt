# ==============================================================================
# Crowley's Cloud Server — CMake Build Configuration
# Milestone 3 (R3): Build System & Dependency Audit
# Cross-Platform Support: Linux (GCC/Clang), macOS (Apple Clang), Windows (MSVC 2022)
# ==============================================================================

cmake_minimum_required(VERSION 3.15)
project(crowleys_cloud_server VERSION 0.6.0 LANGUAGES C CXX)

# Require C++20 standard for modern standard library features (std::filesystem, etc.)
set(CMAKE_CXX_STANDARD 20 CACHE STRING "C++ standard to use" FORCE)
set(CMAKE_CXX_STANDARD_REQUIRED ON CACHE BOOL "Require C++ standard" FORCE)
set(CMAKE_CXX_EXTENSIONS OFF CACHE BOOL "Disable compiler extensions" FORCE)

# ------------------------------------------------------------------------------
# Platform Hints & Compiler Settings
# ------------------------------------------------------------------------------

# Add Apple Homebrew search paths if on macOS
if(APPLE)
  if(EXISTS "/opt/homebrew")
    list(APPEND CMAKE_PREFIX_PATH "/opt/homebrew")
  endif()
  if(EXISTS "/opt/homebrew/opt/openssl@3")
    list(APPEND CMAKE_PREFIX_PATH "/opt/homebrew/opt/openssl@3")
  endif()
  if(EXISTS "/usr/local/opt/openssl@3")
    list(APPEND CMAKE_PREFIX_PATH "/usr/local/opt/openssl@3")
  endif()
endif()

# Windows & MSVC definitions and compiler options
if(WIN32)
  add_compile_definitions(NOMINMAX WIN32_LEAN_AND_MEAN _CRT_SECURE_NO_WARNINGS _WINSOCK_DEPRECATED_NO_WARNINGS)
endif()

if(MSVC)
  add_compile_options(/EHsc /bigobj /utf-8)
  if(VCPKG_TARGET_TRIPLET MATCHES "static")
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>" CACHE STRING "" FORCE)
  endif()
endif()

# Required system libraries per platform
set(PLATFORM_LIBS)
if(WIN32)
  list(APPEND PLATFORM_LIBS ws2_32 crypt32 rpcrt4)
endif()

# ------------------------------------------------------------------------------
# 1. External Frameworks & Dependencies
# ------------------------------------------------------------------------------
include(FetchContent)

# Disable Drogon/Trantor examples, tests, docs, ctl, and unused ORM backends for faster, cleaner builds
set(BUILD_CTL OFF CACHE BOOL "" FORCE)
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(BUILD_DOC OFF CACHE BOOL "" FORCE)
set(BUILD_ORM OFF CACHE BOOL "" FORCE)
set(BUILD_POSTGRESQL OFF CACHE BOOL "" FORCE)
set(BUILD_MYSQL OFF CACHE BOOL "" FORCE)
set(BUILD_SQLITE OFF CACHE BOOL "" FORCE)
set(BUILD_REDIS OFF CACHE BOOL "" FORCE)
set(USE_SPDLOG OFF CACHE BOOL "" FORCE)
set(BUILD_BROTLI OFF CACHE BOOL "" FORCE)
set(BUILD_YAML_CONFIG OFF CACHE BOOL "" FORCE)
set(BUILD_C-ARES OFF CACHE BOOL "" FORCE)

# Fetch and configure Drogon C++ Web Framework (v1.9.13)
FetchContent_Declare(
  drogon
  GIT_REPOSITORY https://github.com/drogonframework/drogon.git
  GIT_TAG v1.9.13
)
FetchContent_MakeAvailable(drogon)

# Trantor's OpenSSLProvider.cc uses Windows CryptoAPI (CertOpenSystemStoreW, HCRYPTPROV_LEGACY)
# on Windows without explicitly including <wincrypt.h>. Patch OpenSSLProvider.cc directly if fetched.
if(WIN32)
  set(TRANTOR_OPENSSL_PROVIDER "${drogon_SOURCE_DIR}/trantor/trantor/net/inner/tlsprovider/OpenSSLProvider.cc")
  if(EXISTS "${TRANTOR_OPENSSL_PROVIDER}")
    file(READ "${TRANTOR_OPENSSL_PROVIDER}" _provider_content)
    if(NOT _provider_content MATCHES "wincrypt\\.h")
      string(REGEX REPLACE "(#ifdef[ \t]+_WIN32)"
        "\\1\n#include <winsock2.h>\n#include <windows.h>\n#include <wincrypt.h>\n#undef X509_NAME\n#undef X509_CERT_PAIR\n#undef X509_EXTENSIONS\n#undef PKCS7_ISSUER_AND_SERIAL\n#undef OCSP_REQUEST\n#undef OCSP_RESPONSE"
        _provider_content "${_provider_content}")
      file(WRITE "${TRANTOR_OPENSSL_PROVIDER}" "${_provider_content}")
    endif()
  endif()
endif()

# Ensure Trantor and Drogon targets strictly adhere to C++20 standard
if(TARGET trantor)
  set_target_properties(trantor PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
  )
  if(WIN32)
    target_link_libraries(trantor PRIVATE crypt32 ws2_32)
  endif()
  get_target_property(TRANTOR_OPTS trantor COMPILE_OPTIONS)
  if(TRANTOR_OPTS)
    list(REMOVE_ITEM TRANTOR_OPTS "-Werror")
    set_target_properties(trantor PROPERTIES COMPILE_OPTIONS "${TRANTOR_OPTS}")
  endif()
endif()

if(TARGET drogon)
  set_target_properties(drogon PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
  )
  get_target_property(DROGON_OPTS drogon COMPILE_OPTIONS)
  if(DROGON_OPTS)
    list(REMOVE_ITEM DROGON_OPTS "-Werror")
    set_target_properties(drogon PROPERTIES COMPILE_OPTIONS "${DROGON_OPTS}")
  endif()
endif()

# Locate required system libraries:
# - OpenSSL: Cryptographic operations (SHA256, HMAC, AES-256-CBC, RAND_bytes)
# - SQLite3: Embedded database engine for user accounting, index, and shares
# - Threads: POSIX / Win32 thread support for async networking and concurrency
# - ZLIB: Zip archive compression & CRC32 calculation (ZipWriter)
# - Protobuf: Binary serialization protocol for directory entry responses
# - LibWebP: In-memory WebP image encoding and decoding (ImageUtils)
find_package(OpenSSL REQUIRED)
find_package(SQLite3 REQUIRED)
if(TARGET SQLite::SQLite3 AND NOT SQLite3_LIBRARIES)
  set(SQLite3_LIBRARIES SQLite::SQLite3)
endif()
find_package(Threads REQUIRED)
find_package(ZLIB REQUIRED)

# Protobuf Discovery: Try CONFIG mode first (vcpkg / CMake configs), then module mode, then PkgConfig
find_package(Protobuf CONFIG QUIET)
if(NOT Protobuf_FOUND AND NOT PROTOBUF_FOUND)
  find_package(Protobuf QUIET)
endif()
if(NOT TARGET protobuf::libprotobuf AND NOT Protobuf_FOUND AND NOT PROTOBUF_FOUND)
  find_package(PkgConfig QUIET)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PROTOBUF QUIET IMPORTED_TARGET protobuf)
  endif()
endif()

if(TARGET protobuf::libprotobuf)
  set(PROTOBUF_TARGET protobuf::libprotobuf)
elseif(TARGET PkgConfig::PROTOBUF)
  set(PROTOBUF_TARGET PkgConfig::PROTOBUF)
elseif(Protobuf_LIBRARIES)
  set(PROTOBUF_TARGET ${Protobuf_LIBRARIES})
elseif(PROTOBUF_LIBRARIES)
  set(PROTOBUF_TARGET ${PROTOBUF_LIBRARIES})
else()
  find_package(Protobuf REQUIRED)
  if(TARGET protobuf::libprotobuf)
    set(PROTOBUF_TARGET protobuf::libprotobuf)
  elseif(Protobuf_LIBRARIES)
    set(PROTOBUF_TARGET ${Protobuf_LIBRARIES})
  else()
    set(PROTOBUF_TARGET ${PROTOBUF_LIBRARIES})
  endif()
endif()

if(NOT Protobuf_INCLUDE_DIRS AND PROTOBUF_INCLUDE_DIRS)
  set(Protobuf_INCLUDE_DIRS ${PROTOBUF_INCLUDE_DIRS})
endif()

if(NOT Protobuf_PROTOC_EXECUTABLE AND PROTOBUF_PROTOC_EXECUTABLE)
  set(Protobuf_PROTOC_EXECUTABLE ${PROTOBUF_PROTOC_EXECUTABLE})
endif()

if(NOT Protobuf_PROTOC_EXECUTABLE)
  if(TARGET protobuf::protoc)
    set(Protobuf_PROTOC_EXECUTABLE protobuf::protoc)
  else()
    find_program(Protobuf_PROTOC_EXECUTABLE
      NAMES protoc
      HINTS
        "${CMAKE_BINARY_DIR}/vcpkg_installed/${VCPKG_HOST_TRIPLET}/tools/protobuf"
        "${CMAKE_BINARY_DIR}/vcpkg_installed/x64-windows/tools/protobuf"
        "${CMAKE_BINARY_DIR}/vcpkg_installed/${VCPKG_TARGET_TRIPLET}/tools/protobuf"
        "${Protobuf_DIR}/../../../${VCPKG_HOST_TRIPLET}/tools/protobuf"
        "${Protobuf_DIR}/../../../x64-windows/tools/protobuf"
        "${Protobuf_DIR}/../../${VCPKG_HOST_TRIPLET}/tools/protobuf"
        "${Protobuf_DIR}/../../x64-windows/tools/protobuf"
        "${Protobuf_DIR}/../../../tools/protobuf"
        "${Protobuf_DIR}/../../tools/protobuf"
        "${Protobuf_DIR}/../../../bin"
        "${Protobuf_DIR}/../../bin"
      REQUIRED
    )
  endif()
endif()

# WebP Discovery: Try CONFIG mode first (vcpkg / Homebrew / Linux), then module mode, then PkgConfig, then direct find
find_package(WebP CONFIG QUIET)
if(NOT TARGET WebP::webp AND NOT TARGET WebP::libwebp AND NOT WebP_FOUND AND NOT WEBP_FOUND)
  find_package(WebP QUIET)
endif()
if(NOT TARGET WebP::webp AND NOT TARGET WebP::libwebp AND NOT WebP_FOUND AND NOT WEBP_FOUND)
  find_package(PkgConfig QUIET)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(WEBP QUIET IMPORTED_TARGET libwebp)
  endif()
endif()
if(NOT TARGET WebP::webp AND NOT TARGET WebP::libwebp AND NOT WebP_FOUND AND NOT WEBP_FOUND AND NOT TARGET PkgConfig::WEBP AND NOT WebP_LIBRARIES AND NOT WEBP_LIBRARIES)
  find_path(WebP_INCLUDE_DIRS NAMES webp/decode.h PATH_SUFFIXES webp)
  find_library(WebP_LIBRARIES NAMES webp libwebp)
  if(WebP_INCLUDE_DIRS AND WebP_LIBRARIES)
    set(WebP_FOUND TRUE)
  endif()
endif()

if(TARGET WebP::webp)
  set(WEBP_TARGET WebP::webp)
elseif(TARGET WebP::libwebp)
  set(WEBP_TARGET WebP::libwebp)
elseif(TARGET PkgConfig::WEBP)
  set(WEBP_TARGET PkgConfig::WEBP)
elseif(WebP_LIBRARIES)
  set(WEBP_TARGET ${WebP_LIBRARIES})
elseif(WEBP_LIBRARIES)
  set(WEBP_TARGET ${WEBP_LIBRARIES})
else()
  message(FATAL_ERROR "WebP library could not be found via CMake or pkg-config")
endif()

# ------------------------------------------------------------------------------
# 2. Protobuf Code Generation Configuration
# ------------------------------------------------------------------------------
set(PROTO_SRC_DIR "${PROJECT_SOURCE_DIR}/../proto")
set(PROTO_GEN_DIR "${CMAKE_CURRENT_BINARY_DIR}/proto_gen")
file(MAKE_DIRECTORY "${PROTO_GEN_DIR}")

add_custom_command(
  OUTPUT "${PROTO_GEN_DIR}/dir_entry.pb.cc" "${PROTO_GEN_DIR}/dir_entry.pb.h"
  COMMAND ${Protobuf_PROTOC_EXECUTABLE}
          --cpp_out=${PROTO_GEN_DIR}
          -I=${PROTO_SRC_DIR}
          ${PROTO_SRC_DIR}/dir_entry.proto
  DEPENDS "${PROTO_SRC_DIR}/dir_entry.proto"
  COMMENT "Generating C++ files from dir_entry.proto"
  VERBATIM
)

# ------------------------------------------------------------------------------
# 3. Executable Target Definition
# ------------------------------------------------------------------------------
add_executable(crowleys_cloud_server
  # Core Entry Point
  src/main.cpp
  src/AppContext.cpp

  # Database Engine
  src/db/Database.cpp

  # Business Services
  src/services/UserService.cpp
  src/services/FileService.cpp
  src/services/FileIndexService.cpp
  src/services/ThumbnailQueue.cpp
  src/services/ShareService.cpp
  src/services/TrashService.cpp

  # Request Middleware
  src/middleware/JwtMiddleware.cpp
  src/middleware/RateLimiter.cpp

  # HTTP Controllers
  src/controllers/AuthController.cpp
  src/controllers/FileController.cpp
  src/controllers/ShareController.cpp

  # Utility Modules
  src/utils/Config.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
  src/utils/ZipWriter.cpp

  # Generated Protobuf Files
  "${PROTO_GEN_DIR}/dir_entry.pb.cc"
)

# ------------------------------------------------------------------------------
# 4. Include Directories & Linked Libraries
# ------------------------------------------------------------------------------
target_include_directories(crowleys_cloud_server PRIVATE
  include
  "${PROTO_GEN_DIR}"
  ${Protobuf_INCLUDE_DIRS}
  ${SQLite3_INCLUDE_DIRS}
  ${WebP_INCLUDE_DIRS}
  ${WEBP_INCLUDE_DIRS}
)

target_link_libraries(crowleys_cloud_server PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  ${WEBP_TARGET}
  ${PLATFORM_LIBS}
)

# ------------------------------------------------------------------------------
# 5. Tests
# ------------------------------------------------------------------------------
enable_testing()

add_executable(etag_adversarial_test
  test/etag_adversarial_test.cpp
)
target_include_directories(etag_adversarial_test PRIVATE include)
target_link_libraries(etag_adversarial_test PRIVATE drogon Threads::Threads ${PLATFORM_LIBS})
add_test(NAME etag_adversarial_test COMMAND etag_adversarial_test)

add_executable(webp_inmemory_test
  test/webp_inmemory_test.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
)
target_include_directories(webp_inmemory_test PRIVATE include ${WebP_INCLUDE_DIRS} ${WEBP_INCLUDE_DIRS})
target_link_libraries(webp_inmemory_test PRIVATE OpenSSL::Crypto Threads::Threads ${WEBP_TARGET} ${PLATFORM_LIBS})
add_test(NAME webp_inmemory_test COMMAND webp_inmemory_test)

add_executable(webp_adversarial_test
  test/webp_adversarial_test.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
)
target_include_directories(webp_adversarial_test PRIVATE include ${WebP_INCLUDE_DIRS} ${WEBP_INCLUDE_DIRS})
target_link_libraries(webp_adversarial_test PRIVATE OpenSSL::Crypto Threads::Threads ${WEBP_TARGET} ${PLATFORM_LIBS})
add_test(NAME webp_adversarial_test COMMAND webp_adversarial_test)

add_executable(blurhash_test
  test/blurhash_test.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
)
target_include_directories(blurhash_test PRIVATE include ${WebP_INCLUDE_DIRS} ${WEBP_INCLUDE_DIRS})
target_link_libraries(blurhash_test PRIVATE OpenSSL::Crypto Threads::Threads ${WEBP_TARGET} ${PLATFORM_LIBS})
add_test(NAME blurhash_test COMMAND blurhash_test)

add_executable(file_index_blurhash_test
  test/file_index_blurhash_test.cpp
  src/db/Database.cpp
  src/services/FileIndexService.cpp
  src/services/FileService.cpp
  src/utils/Config.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
  "${PROTO_GEN_DIR}/dir_entry.pb.cc"
)
target_include_directories(file_index_blurhash_test PRIVATE
  include
  "${PROTO_GEN_DIR}"
  ${Protobuf_INCLUDE_DIRS}
  ${SQLite3_INCLUDE_DIRS}
  ${WebP_INCLUDE_DIRS}
  ${WEBP_INCLUDE_DIRS}
)
target_link_libraries(file_index_blurhash_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  ${WEBP_TARGET}
  ${PLATFORM_LIBS}
)
add_test(NAME file_index_blurhash_test COMMAND file_index_blurhash_test)

add_executable(blurhash_adversarial_test
  test/blurhash_adversarial_test.cpp
  src/db/Database.cpp
  src/services/FileIndexService.cpp
  src/services/FileService.cpp
  src/utils/Config.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
  "${PROTO_GEN_DIR}/dir_entry.pb.cc"
)
target_include_directories(blurhash_adversarial_test PRIVATE
  include
  "${PROTO_GEN_DIR}"
  ${Protobuf_INCLUDE_DIRS}
  ${SQLite3_INCLUDE_DIRS}
  ${WebP_INCLUDE_DIRS}
  ${WEBP_INCLUDE_DIRS}
)
target_link_libraries(blurhash_adversarial_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  ${WEBP_TARGET}
  ${PLATFORM_LIBS}
)
add_test(NAME blurhash_adversarial_test COMMAND blurhash_adversarial_test)

add_executable(blurhash_adversarial_challenge_test
  test/blurhash_adversarial_challenge_test.cpp
  src/db/Database.cpp
  src/services/FileIndexService.cpp
  src/services/FileService.cpp
  src/utils/Config.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
  "${PROTO_GEN_DIR}/dir_entry.pb.cc"
)
target_include_directories(blurhash_adversarial_challenge_test PRIVATE
  include
  "${PROTO_GEN_DIR}"
  ${Protobuf_INCLUDE_DIRS}
  ${SQLite3_INCLUDE_DIRS}
  ${WebP_INCLUDE_DIRS}
  ${WEBP_INCLUDE_DIRS}
)
target_link_libraries(blurhash_adversarial_challenge_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  ${WEBP_TARGET}
  ${PLATFORM_LIBS}
)
add_test(NAME blurhash_adversarial_challenge_test COMMAND blurhash_adversarial_challenge_test)

add_executable(thumbnail_queue_test
  test/thumbnail_queue_test.cpp
  src/AppContext.cpp
  src/services/ThumbnailQueue.cpp
  src/db/Database.cpp
  src/services/FileIndexService.cpp
  src/services/FileService.cpp
  src/utils/Config.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
  "${PROTO_GEN_DIR}/dir_entry.pb.cc"
)
target_include_directories(thumbnail_queue_test PRIVATE
  include
  "${PROTO_GEN_DIR}"
  ${Protobuf_INCLUDE_DIRS}
  ${SQLite3_INCLUDE_DIRS}
  ${WebP_INCLUDE_DIRS}
  ${WEBP_INCLUDE_DIRS}
)
target_link_libraries(thumbnail_queue_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  ${WEBP_TARGET}
  ${PLATFORM_LIBS}
)
add_test(NAME thumbnail_queue_test COMMAND thumbnail_queue_test)

add_executable(thumbnail_worker_pool_test
  test/thumbnail_worker_pool_test.cpp
  src/AppContext.cpp
  src/services/ThumbnailQueue.cpp
  src/db/Database.cpp
  src/services/FileIndexService.cpp
  src/services/FileService.cpp
  src/utils/Config.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
  "${PROTO_GEN_DIR}/dir_entry.pb.cc"
)
target_include_directories(thumbnail_worker_pool_test PRIVATE
  include
  "${PROTO_GEN_DIR}"
  ${Protobuf_INCLUDE_DIRS}
  ${SQLite3_INCLUDE_DIRS}
  ${WebP_INCLUDE_DIRS}
  ${WEBP_INCLUDE_DIRS}
)
target_link_libraries(thumbnail_worker_pool_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  ${WEBP_TARGET}
  ${PLATFORM_LIBS}
)
add_test(NAME thumbnail_worker_pool_test COMMAND thumbnail_worker_pool_test)

add_executable(upload_queue_adversarial_test
  test/upload_queue_adversarial_test.cpp
  src/AppContext.cpp
  src/services/ThumbnailQueue.cpp
  src/db/Database.cpp
  src/services/FileIndexService.cpp
  src/services/FileService.cpp
  src/utils/Config.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
  "${PROTO_GEN_DIR}/dir_entry.pb.cc"
)
target_include_directories(upload_queue_adversarial_test PRIVATE
  include
  "${PROTO_GEN_DIR}"
  ${Protobuf_INCLUDE_DIRS}
  ${SQLite3_INCLUDE_DIRS}
  ${WebP_INCLUDE_DIRS}
  ${WEBP_INCLUDE_DIRS}
)
target_link_libraries(upload_queue_adversarial_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  ${WEBP_TARGET}
  ${PLATFORM_LIBS}
)
add_test(NAME upload_queue_adversarial_test COMMAND upload_queue_adversarial_test)

add_executable(thumbnail_adversarial_test
  test/thumbnail_adversarial_test.cpp
  src/AppContext.cpp
  src/services/ThumbnailQueue.cpp
  src/db/Database.cpp
  src/services/FileIndexService.cpp
  src/services/FileService.cpp
  src/utils/Config.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
  "${PROTO_GEN_DIR}/dir_entry.pb.cc"
)
target_include_directories(thumbnail_adversarial_test PRIVATE
  include
  "${PROTO_GEN_DIR}"
  ${Protobuf_INCLUDE_DIRS}
  ${SQLite3_INCLUDE_DIRS}
  ${WebP_INCLUDE_DIRS}
  ${WEBP_INCLUDE_DIRS}
)
target_link_libraries(thumbnail_adversarial_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  ${WEBP_TARGET}
  ${PLATFORM_LIBS}
)
add_test(NAME thumbnail_adversarial_test COMMAND thumbnail_adversarial_test)

add_executable(config_resolution_test
  test/config_resolution_test.cpp
  src/utils/Config.cpp
)
target_include_directories(config_resolution_test PRIVATE include)
target_link_libraries(config_resolution_test PRIVATE drogon Threads::Threads ${PLATFORM_LIBS})
add_test(NAME config_resolution_test COMMAND config_resolution_test)

# ------------------------------------------------------------------------------
# 6. Installation Rules (for .deb, .rpm, PKGBUILD, Homebrew)
# ------------------------------------------------------------------------------
include(GNUInstallDirs)
install(TARGETS crowleys_cloud_server DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY config/ DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/crowleys_cloud)

# ------------------------------------------------------------------------------
# 7. Licensing
# ------------------------------------------------------------------------------
set(PROJECT_LICENSE "AGPL-3.0-or-later")
