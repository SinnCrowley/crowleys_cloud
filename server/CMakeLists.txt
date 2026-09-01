# ==============================================================================
# Crowley's Cloud Server — CMake Build Configuration
# Milestone 3 (R3): Build System & Dependency Audit
# ==============================================================================

cmake_minimum_required(VERSION 3.15)
project(crowleys_cloud_server VERSION 0.5.0 LANGUAGES C CXX)

# Require C++20 standard for modern standard library features (std::filesystem, etc.)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ------------------------------------------------------------------------------
# 1. External Frameworks & Dependencies
# ------------------------------------------------------------------------------
include(FetchContent)

# Disable Drogon examples and tests for faster, cleaner builds
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)

# Fetch and configure Drogon C++ Web Framework (v1.9.13)
FetchContent_Declare(
  drogon
  SOURCE_DIR "/tmp/drogon_source"
)
FetchContent_MakeAvailable(drogon)

# Locate required system libraries:
# - OpenSSL: Cryptographic operations (SHA256, HMAC, AES-256-CBC, RAND_bytes)
# - SQLite3: Embedded database engine for user accounting, index, and shares
# - Threads: POSIX thread support for async networking and concurrency
# - ZLIB: Zip archive compression & CRC32 calculation (ZipWriter)
# - Protobuf: Binary serialization protocol for directory entry responses
# - LibWebP: In-memory WebP image encoding and decoding (ImageUtils)
find_package(OpenSSL REQUIRED)
find_package(SQLite3 REQUIRED)
find_package(Threads REQUIRED)
find_package(ZLIB REQUIRED)
find_package(Protobuf REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(WEBP REQUIRED IMPORTED_TARGET libwebp)
pkg_check_modules(PROTOBUF REQUIRED IMPORTED_TARGET protobuf)
set(PROTOBUF_TARGET PkgConfig::PROTOBUF)


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
)

target_link_libraries(crowleys_cloud_server PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  PkgConfig::WEBP
)

# ------------------------------------------------------------------------------
# 5. Tests
# ------------------------------------------------------------------------------
add_executable(etag_adversarial_test
  test/etag_adversarial_test.cpp
)
target_include_directories(etag_adversarial_test PRIVATE include)
target_link_libraries(etag_adversarial_test PRIVATE drogon Threads::Threads)

add_executable(webp_inmemory_test
  test/webp_inmemory_test.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
)
target_include_directories(webp_inmemory_test PRIVATE include)
target_link_libraries(webp_inmemory_test PRIVATE OpenSSL::Crypto Threads::Threads PkgConfig::WEBP)

add_executable(webp_adversarial_test
  test/webp_adversarial_test.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
)
target_include_directories(webp_adversarial_test PRIVATE include)
target_link_libraries(webp_adversarial_test PRIVATE OpenSSL::Crypto Threads::Threads PkgConfig::WEBP)

add_executable(blurhash_test
  test/blurhash_test.cpp
  src/utils/Crypto.cpp
  src/utils/ImageUtils.cpp
  src/utils/BlurHashEncoder.cpp
)
target_include_directories(blurhash_test PRIVATE include)
target_link_libraries(blurhash_test PRIVATE OpenSSL::Crypto Threads::Threads PkgConfig::WEBP)

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
)
target_link_libraries(file_index_blurhash_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  PkgConfig::WEBP
)

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
)
target_link_libraries(blurhash_adversarial_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  PkgConfig::WEBP
)

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
)
target_link_libraries(blurhash_adversarial_challenge_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  PkgConfig::WEBP
)

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
)
target_link_libraries(thumbnail_queue_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  PkgConfig::WEBP
)

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
)
target_link_libraries(thumbnail_worker_pool_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  PkgConfig::WEBP
)

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
)
target_link_libraries(upload_queue_adversarial_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  PkgConfig::WEBP
)

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
)
target_link_libraries(thumbnail_adversarial_test PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  ${PROTOBUF_TARGET}
  PkgConfig::WEBP
)




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


