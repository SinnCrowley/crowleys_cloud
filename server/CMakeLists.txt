# ==============================================================================
# Crowley's Cloud Server — CMake Build Configuration
# Milestone 3 (R3): Build System & Dependency Audit
# ==============================================================================

cmake_minimum_required(VERSION 3.15)
project(crowleys_cloud_server LANGUAGES CXX)

# Require C++20 standard for modern standard library features (std::filesystem, etc.)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ------------------------------------------------------------------------------
# 1. External Frameworks & Dependencies
# ------------------------------------------------------------------------------
include(FetchContent)

# Fetch and configure Drogon C++ Web Framework (v1.9.13)
FetchContent_Declare(
  drogon
  GIT_REPOSITORY https://github.com/drogonframework/drogon.git
  GIT_TAG v1.9.13
)
FetchContent_MakeAvailable(drogon)

# Locate required system libraries:
# - OpenSSL: Cryptographic operations (SHA256, HMAC, AES-256-CBC, RAND_bytes)
# - SQLite3: Embedded database engine for user accounting, index, and shares
# - Threads: POSIX thread support for async networking and concurrency
# - ZLIB: Zip archive compression & CRC32 calculation (ZipWriter)
find_package(OpenSSL REQUIRED)
find_package(SQLite3 REQUIRED)
find_package(Threads REQUIRED)
find_package(ZLIB REQUIRED)
find_package(Protobuf REQUIRED)

find_package(PkgConfig REQUIRED)
pkg_check_modules(PROTOBUF REQUIRED IMPORTED_TARGET protobuf)

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

  # Database Engine
  src/db/Database.cpp

  # Business Services
  src/services/UserService.cpp
  src/services/FileService.cpp
  src/services/FileIndexService.cpp
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
  src/utils/ZipWriter.cpp

  # Generated Protobuf Files
  "${PROTO_GEN_DIR}/dir_entry.pb.cc"
)

# ------------------------------------------------------------------------------
# 4. Include Directories & Linked Libraries
# ------------------------------------------------------------------------------
target_include_directories(crowleys_cloud_server PRIVATE include "${PROTO_GEN_DIR}" ${PROTOBUF_INCLUDE_DIRS} ${SQLite3_INCLUDE_DIRS})
target_link_directories(crowleys_cloud_server PRIVATE ${PROTOBUF_LIBRARY_DIRS})

target_link_libraries(crowleys_cloud_server PRIVATE
  drogon
  OpenSSL::Crypto
  ${SQLite3_LIBRARIES}
  Threads::Threads
  ZLIB::ZLIB
  PkgConfig::PROTOBUF
)

# ------------------------------------------------------------------------------
# 5. Installation Rules (for .deb, .rpm, PKGBUILD, Homebrew)
# ------------------------------------------------------------------------------
include(GNUInstallDirs)
install(TARGETS crowleys_cloud_server DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY config/ DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/crowleys_cloud)

# ------------------------------------------------------------------------------
# 6. Licensing
# ------------------------------------------------------------------------------
set(PROJECT_LICENSE "AGPL-3.0-or-later")

