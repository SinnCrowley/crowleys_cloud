cmake_minimum_required(VERSION 3.15)
project(crowleys_cloud_server LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(FetchContent)

FetchContent_Declare(
  drogon
  GIT_REPOSITORY https://github.com/drogonframework/drogon.git
  GIT_TAG v1.9.8
)
FetchContent_MakeAvailable(drogon)

find_package(OpenSSL REQUIRED)
find_package(SQLite3 REQUIRED)
find_package(Threads REQUIRED)
find_package(ZLIB REQUIRED)

add_executable(crowleys_cloud_server
  src/main.cpp
  src/db/Database.cpp
  src/services/UserService.cpp
  src/services/FileService.cpp
  src/services/FileIndexService.cpp
  src/services/ShareService.cpp
  src/services/TrashService.cpp
  src/middleware/JwtMiddleware.cpp
  src/middleware/RateLimiter.cpp
  src/controllers/AuthController.cpp
  src/controllers/FileController.cpp
  src/controllers/ShareController.cpp
  src/utils/Config.cpp
  src/utils/Crypto.cpp
  src/utils/ZipWriter.cpp
)

target_include_directories(crowleys_cloud_server PRIVATE include)

target_link_libraries(crowleys_cloud_server PRIVATE
  drogon
  OpenSSL::Crypto
  SQLite3::SQLite3
  Threads::Threads
  ZLIB::ZLIB
)
