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

#include "server/utils/BlurHashEncoder.hpp"
#include "server/utils/ImageUtils.hpp"
#include "server/utils/Crypto.hpp"
#include "server/db/Database.hpp"
#include "server/services/FileIndexService.hpp"
#include "server/services/FileService.hpp"
#include "dir_entry.pb.h"

#include <sqlite3.h>

#include <cassert>
#include <chrono>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <thread>
#include <vector>

using namespace server;
using namespace server::utils;
using namespace server::services;

static std::filesystem::path createTempDbPath() {
  auto tmpDir = std::filesystem::temp_directory_path() / ("blurhash_adv_test_" + randomTokenHex(8));
  std::filesystem::create_directories(tmpDir);
  return tmpDir / "test.db";
}

// -----------------------------------------------------------------------------
// 1. Extreme Dimensions & Buffer Anomalies
// -----------------------------------------------------------------------------
static void testExtremeDimensionsAndBufferAnomalies() {
  std::cout << "[TEST] 1. Testing extreme dimensions and buffer anomalies..." << std::endl;

  // 1.1: 1x1 Minimum Image
  {
    std::vector<uint8_t> pixel = {120, 80, 200, 255};
    std::string hash = encodeBlurHash(pixel.data(), 1, 1, 4, 3);
    assert(!hash.empty());
    assert(hash.length() == 28);
    assert(isValidBlurHash(hash));
  }

  // 1.2: 1x4000 Ultra-tall 1-pixel wide strip
  {
    const int w = 1;
    const int h = 4000;
    std::vector<uint8_t> tall(w * h * 4);
    for (int y = 0; y < h; ++y) {
      tall[y * 4 + 0] = static_cast<uint8_t>((y * 255) / h);
      tall[y * 4 + 1] = static_cast<uint8_t>(128);
      tall[y * 4 + 2] = static_cast<uint8_t>(255 - (y * 255) / h);
      tall[y * 4 + 3] = 255;
    }
    std::string hash = encodeBlurHash(tall.data(), w, h, 4, 3);
    assert(!hash.empty());
    assert(hash.length() == 28);
    assert(isValidBlurHash(hash));
  }

  // 1.3: 4000x1 Ultra-wide 1-pixel tall strip
  {
    const int w = 4000;
    const int h = 1;
    std::vector<uint8_t> wide(w * h * 4);
    for (int x = 0; x < w; ++x) {
      wide[x * 4 + 0] = static_cast<uint8_t>((x * 255) / w);
      wide[x * 4 + 1] = static_cast<uint8_t>(200);
      wide[x * 4 + 2] = static_cast<uint8_t>(50);
      wide[x * 4 + 3] = 255;
    }
    std::string hash = encodeBlurHash(wide.data(), w, h, 4, 3);
    assert(!hash.empty());
    assert(hash.length() == 28);
    assert(isValidBlurHash(hash));
  }

  // 1.4: 5000x5000 Large Image (25 MP)
  {
    const int w = 5000;
    const int h = 5000;
    // To avoid allocating 100MB repeatedly, test with solid pattern
    std::vector<uint8_t> bigImage(w * h * 4, 128);
    const auto t0 = std::chrono::high_resolution_clock::now();
    std::string hash = encodeBlurHash(bigImage.data(), w, h, 4, 3);
    const auto t1 = std::chrono::high_resolution_clock::now();
    const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
    std::cout << "  5000x5000 (25MP) encode completed in " << ms << " ms -> " << hash << std::endl;
    assert(!hash.empty());
    assert(hash.length() == 28);
    assert(isValidBlurHash(hash));
  }

  // 1.5: 0x0, Negative & Zero Dimensions
  {
    std::vector<uint8_t> dummy(64, 255);
    assert(encodeBlurHash(dummy.data(), 0, 0, 4, 3).empty());
    assert(encodeBlurHash(dummy.data(), 0, 100, 4, 3).empty());
    assert(encodeBlurHash(dummy.data(), 100, 0, 4, 3).empty());
    assert(encodeBlurHash(dummy.data(), -1, 100, 4, 3).empty());
    assert(encodeBlurHash(dummy.data(), 100, -1, 4, 3).empty());
    assert(encodeBlurHash(dummy.data(), -50, -50, 4, 3).empty());
  }

  // 1.6: Null pointers
  {
    assert(encodeBlurHash(nullptr, 100, 100, 4, 3).empty());
    assert(encodeBlurHash(nullptr, 0, 0, 4, 3).empty());
  }

  // 1.7: Boundary Component Counts (x in 1..9, y in 1..9)
  {
    std::vector<uint8_t> dummy(16 * 16 * 4, 180);
    // Invalid components
    assert(encodeBlurHash(dummy.data(), 16, 16, 0, 3).empty());
    assert(encodeBlurHash(dummy.data(), 16, 16, 10, 3).empty());
    assert(encodeBlurHash(dummy.data(), 16, 16, 4, 0).empty());
    assert(encodeBlurHash(dummy.data(), 16, 16, 4, 10).empty());
    assert(encodeBlurHash(dummy.data(), 16, 16, -1, 3).empty());
    assert(encodeBlurHash(dummy.data(), 16, 16, 4, -1).empty());

    // Valid bounds: (1, 1) -> 4 + 2*1*1 = 6 chars
    std::string h11 = encodeBlurHash(dummy.data(), 16, 16, 1, 1);
    assert(h11.length() == 6);
    assert(isValidBlurHash(h11));

    // Valid bounds: (9, 9) -> 4 + 2*9*9 = 166 chars
    std::string h99 = encodeBlurHash(dummy.data(), 16, 16, 9, 9);
    assert(h99.length() == 166);
    assert(isValidBlurHash(h99));

    // Valid bounds: (1, 9) -> 4 + 2*1*9 = 22 chars
    std::string h19 = encodeBlurHash(dummy.data(), 16, 16, 1, 9);
    assert(h19.length() == 22);
    assert(isValidBlurHash(h19));

    // Valid bounds: (9, 1) -> 4 + 2*9*1 = 22 chars
    std::string h91 = encodeBlurHash(dummy.data(), 16, 16, 9, 1);
    assert(h91.length() == 22);
    assert(isValidBlurHash(h91));
  }

  std::cout << "  [PASS] Extreme dimensions & buffer anomalies passed." << std::endl;
}

// -----------------------------------------------------------------------------
// 2. Test Vectors & Base83 Invariants
// -----------------------------------------------------------------------------
static void testVectorsAndBase83Invariants() {
  std::cout << "[TEST] 2. Testing reference test vectors and Base83 invariants..." << std::endl;

  // 2.1: Exact solid colors
  // Black
  {
    std::vector<uint8_t> black(8 * 8 * 4, 0);
    for (size_t i = 3; i < black.size(); i += 4) black[i] = 255;
    std::string hash = encodeBlurHash(black.data(), 8, 8, 4, 3);
    assert(hash == "L00000fQfQfQfQfQfQfQfQfQfQfQ");
  }
  // White
  {
    std::vector<uint8_t> white(4 * 4 * 4, 255);
    std::string hash = encodeBlurHash(white.data(), 4, 4, 4, 3);
    assert(hash == "L~TSUA~qfQ~q~q%MfQ%MfQfQfQfQ");
  }
  // Pure Red
  {
    std::vector<uint8_t> red(4 * 4 * 4, 0);
    for (size_t i = 0; i < red.size(); i += 4) {
      red[i] = 255;
      red[i + 3] = 255;
    }
    std::string hash = encodeBlurHash(red.data(), 4, 4, 4, 3);
    assert(hash == "L~TI:j|cfQ|c|c$5fQ$5fQfQfQfQ");
  }
  // Pure Blue
  {
    std::vector<uint8_t> blue(4 * 4 * 4, 0);
    for (size_t i = 0; i < blue.size(); i += 4) {
      blue[i + 2] = 255;
      blue[i + 3] = 255;
    }
    std::string hash = encodeBlurHash(blue.data(), 4, 4, 4, 3);
    assert(hash == "L~0036fZfQfZfZfVfQfVfQfQfQfQ");
  }

  // 2.2: Solid color scale invariance (1x1 vs 16x16 vs 64x64 must yield identical hash for solid colors)
  {
    std::vector<uint8_t> red4x4(4 * 4 * 4, 0);
    for (size_t i = 0; i < red4x4.size(); i += 4) {
      red4x4[i] = 255;
      red4x4[i + 3] = 255;
    }
    std::vector<uint8_t> red16x16(16 * 16 * 4, 0);
    for (size_t i = 0; i < red16x16.size(); i += 4) {
      red16x16[i] = 255;
      red16x16[i + 3] = 255;
    }
    auto h4 = encodeBlurHash(red4x4.data(), 4, 4, 4, 3);
    auto h16 = encodeBlurHash(red16x16.data(), 16, 16, 4, 3);
    assert(isValidBlurHash(h4));
    assert(isValidBlurHash(h16));
    assert(h4.substr(2, 4) == h16.substr(2, 4)); // DC component match (chars 2..5)
  }

  // 2.3: Alpha channel independence (BlurHash is RGB-based)
  {
    std::vector<uint8_t> redAlpha0(4 * 4 * 4, 0);
    std::vector<uint8_t> redAlpha255(4 * 4 * 4, 0);
    for (size_t i = 0; i < redAlpha0.size(); i += 4) {
      redAlpha0[i] = 255;
      redAlpha0[i + 3] = 0; // Transparent
      redAlpha255[i] = 255;
      redAlpha255[i + 3] = 255; // Opaque
    }
    assert(encodeBlurHash(redAlpha0.data(), 4, 4, 4, 3) == encodeBlurHash(redAlpha255.data(), 4, 4, 4, 3));
  }

  // 2.4: Adversarial string checks for isValidBlurHash
  {
    assert(!isValidBlurHash(""));
    assert(!isValidBlurHash("abc"));
    assert(!isValidBlurHash("L00000fQfQfQfQfQfQfQfQfQfQf"));    // 27 chars
    assert(!isValidBlurHash("L00000fQfQfQfQfQfQfQfQfQfQfQQ"));  // 29 chars
    assert(!isValidBlurHash("L 0000fQfQfQfQfQfQfQfQfQfQfQ"));   // Space
    assert(!isValidBlurHash("L!0000fQfQfQfQfQfQfQfQfQfQfQ"));   // Exclamation
    assert(!isValidBlurHash("L\"0000fQfQfQfQfQfQfQfQfQfQfQ"));  // Double quote
    assert(!isValidBlurHash("L(0000fQfQfQfQfQfQfQfQfQfQfQ"));   // Parenthesis
    assert(!isValidBlurHash("L)0000fQfQfQfQfQfQfQfQfQfQfQ"));
    assert(!isValidBlurHash("L/0000fQfQfQfQfQfQfQfQfQfQfQ"));   // Slash
    assert(!isValidBlurHash("L\\0000fQfQfQfQfQfQfQfQfQfQfQ"));  // Backslash
    assert(!isValidBlurHash("L\000000fQfQfQfQfQfQfQfQfQfQfQ")); // Embedded null
  }

  std::cout << "  [PASS] Reference test vectors and Base83 invariants passed." << std::endl;
}

// -----------------------------------------------------------------------------
// 3. Database Migration Idempotency & Concurrency
// -----------------------------------------------------------------------------
static void testDatabaseMigrationIdempotency() {
  std::cout << "[TEST] 3. Testing database migration idempotency & dynamic migration..." << std::endl;

  // 3.1: Fresh DB: Run Database::migrate() 10 times consecutively
  std::cout << "  3.1: Fresh DB consecutive migrations..." << std::endl;
  auto dbPath = createTempDbPath();
  {
    db::Database db(dbPath.string());
    for (int i = 0; i < 10; ++i) {
      db.migrate();
    }

    // Verify file_index columns
    bool hasBlurhash = false;
    sqlite3_stmt *stmt = nullptr;
    assert(sqlite3_prepare_v2(db.raw(), "PRAGMA table_info(file_index);", -1, &stmt, nullptr) == SQLITE_OK);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
      const auto *colName = sqlite3_column_text(stmt, 1);
      if (colName && std::string(reinterpret_cast<const char *>(colName)) == "blurhash") {
        hasBlurhash = true;
        break;
      }
    }
    sqlite3_finalize(stmt);
    assert(hasBlurhash);
  }
  std::filesystem::remove_all(dbPath.parent_path());
  std::cout << "  3.1 passed." << std::endl;

  // 3.2: Legacy DB: Populate legacy schema with data, migrate, verify, re-migrate
  std::cout << "  3.2: Legacy DB migration..." << std::endl;
  auto legacyDbPath = createTempDbPath();
  {
    sqlite3 *rawDb = nullptr;
    assert(sqlite3_open_v2(legacyDbPath.string().c_str(), &rawDb, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nullptr) == SQLITE_OK);
    const char *legacySchema = R"(
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        created_at INTEGER NOT NULL
      );
      CREATE TABLE file_index (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_user_id INTEGER NOT NULL,
        scope TEXT NOT NULL,
        rel_path TEXT NOT NULL,
        parent_path TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        modified_at INTEGER NOT NULL,
        uploaded_at INTEGER NOT NULL,
        thumbnail_path TEXT NOT NULL DEFAULT '',
        thumbnail_updated_at INTEGER,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        uploader_user_id INTEGER NOT NULL DEFAULT 0,
        sha256 TEXT NOT NULL DEFAULT '',
        is_shared INTEGER NOT NULL DEFAULT 0,
        is_explicit_shared INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        UNIQUE(owner_user_id, scope, rel_path)
      );
      INSERT INTO users(id, username, password_hash, role, created_at) VALUES(1, 'alice', 'hash123', 'user', 1000);
      INSERT INTO file_index(owner_user_id, scope, rel_path, parent_path, name, type, mime_type, size_bytes, modified_at, uploaded_at)
        VALUES(1, 'private', 'docs/readme.txt', 'docs', 'readme.txt', 'document', 'text/plain', 500, 1000, 1000);
    )";
    char *err = nullptr;
    assert(sqlite3_exec(rawDb, legacySchema, nullptr, nullptr, &err) == SQLITE_OK);
    sqlite3_close(rawDb);

    // Now migrate with Database class
    {
      db::Database db(legacyDbPath.string());
      db.migrate(); // 1st migration
      db.migrate(); // 2nd migration
      db.migrate(); // 3rd migration

      // Verify existing row is preserved and has empty blurhash string
      sqlite3_stmt *stmt = nullptr;
      assert(sqlite3_prepare_v2(db.raw(), "SELECT name, blurhash FROM file_index WHERE id = 1;", -1, &stmt, nullptr) == SQLITE_OK);
      assert(sqlite3_step(stmt) == SQLITE_ROW);
      assert(std::string(reinterpret_cast<const char *>(sqlite3_column_text(stmt, 0))) == "readme.txt");
      const auto *bh = sqlite3_column_text(stmt, 1);
      assert(bh != nullptr);
      assert(std::string(reinterpret_cast<const char *>(bh)) == "");
      sqlite3_finalize(stmt);
    }
  }
  std::filesystem::remove_all(legacyDbPath.parent_path());
  std::cout << "  3.2 passed." << std::endl;

  // 3.3: Multithreaded concurrent migrations
  std::cout << "  3.3: Multithreaded concurrent migrations..." << std::endl;
  auto concDbPath = createTempDbPath();
  {
    // First initialize the DB file so WAL is set up
    {
      db::Database initDb(concDbPath.string());
      initDb.migrate();
    }
    std::vector<std::thread> workers;
    std::atomic<int> errors{0};
    for (int t = 0; t < 4; ++t) {
      workers.emplace_back([&concDbPath, &errors]() {
        try {
          for (int i = 0; i < 5; ++i) {
            db::Database db(concDbPath.string());
            db.migrate();
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
          }
        } catch (const std::exception &e) {
          std::cerr << "Thread caught exception: " << e.what() << std::endl;
          errors++;
        }
      });
    }
    for (auto &w : workers) {
      w.join();
    }
    assert(errors.load() == 0);
  }
  std::filesystem::remove_all(concDbPath.parent_path());
  std::cout << "  3.3 passed." << std::endl;

  std::cout << "  [PASS] Database migration idempotency & dynamic migration passed." << std::endl;
}

// -----------------------------------------------------------------------------
// 4. FileIndex ON CONFLICT Preservation & CRUD Semantics
// -----------------------------------------------------------------------------
static void testFileIndexOnConflictAndCrud() {
  std::cout << "[TEST] 4. Testing FileIndexService ON CONFLICT preservation & CRUD..." << std::endl;

  auto dbPath = createTempDbPath();
  auto storageRoot = dbPath.parent_path() / "storage";
  std::filesystem::create_directories(storageRoot);

  {
    db::Database db(dbPath.string());
    db.migrate();
    utils::Config config;
    config.storageRoot = storageRoot.string();
    FileService fileService(config);
    FileIndexService indexService(db, fileService);

    const int64_t userId = 10;
    const std::string relPath = "gallery/photo.png";
    const std::string sha256 = "11223344556677889900aabbccddeeff11223344556677889900aabbccddeeff";
    const std::string initialBlurHash = "L6Pj0^jE.AyE_3t7t7R**0o#DgR4";

    // Step 1: Initial upsert with BlurHash
    indexService.upsertFileExplicit(
        userId,
        StorageScope::Private,
        relPath,
        "photo.png",
        2048,
        1700000000,
        "photo",
        "image/png",
        userId,
        sha256,
        "/api/thumb?path=gallery%2Fphoto.png",
        initialBlurHash);

    auto item1 = indexService.findFileByHash(userId, StorageScope::Private, sha256);
    assert(item1.has_value());
    assert(item1->blurhash == initialBlurHash);
    assert(item1->size == 2048);

    // Step 2: Re-upsert file with updated size/mtime but EMPTY blurhash (standard re-index)
    // CRITICAL: ON CONFLICT must PRESERVE the existing BlurHash!
    indexService.upsertFileExplicit(
        userId,
        StorageScope::Private,
        relPath,
        "photo.png",
        4096, // updated size
        1700005000, // updated mtime
        "photo",
        "image/png",
        userId,
        sha256,
        "/api/thumb?path=gallery%2Fphoto.png",
        ""); // empty blurhash

    auto item2 = indexService.findFileByHash(userId, StorageScope::Private, sha256);
    assert(item2.has_value());
    assert(item2->size == 4096);
    assert(item2->modifiedAt == 1700005000);
    assert(item2->blurhash == initialBlurHash); // PRESERVED!

    // Step 3: Re-upsert with NEW non-empty blurhash
    const std::string newBlurHash = "L~TSUA~qfQ~q~q%MfQ%MfQfQfQfQ";
    indexService.upsertFileExplicit(
        userId,
        StorageScope::Private,
        relPath,
        "photo.png",
        4096,
        1700006000,
        "photo",
        "image/png",
        userId,
        sha256,
        "/api/thumb?path=gallery%2Fphoto.png",
        newBlurHash);

    auto item3 = indexService.findFileByHash(userId, StorageScope::Private, sha256);
    assert(item3.has_value());
    assert(item3->blurhash == newBlurHash); // UPDATED!

    // Step 4: updateBlurHash by path
    const std::string pathUpdatedHash = "L00000fQfQfQfQfQfQfQfQfQfQfQ";
    indexService.updateBlurHash(userId, StorageScope::Private, relPath, pathUpdatedHash);
    auto item4 = indexService.findFileByHash(userId, StorageScope::Private, sha256);
    assert(item4.has_value());
    assert(item4->blurhash == pathUpdatedHash);

    // Step 5: updateBlurHash with empty string -> should be a safe no-op
    indexService.updateBlurHash(userId, StorageScope::Private, relPath, "");
    auto item5 = indexService.findFileByHash(userId, StorageScope::Private, sha256);
    assert(item5.has_value());
    assert(item5->blurhash == pathUpdatedHash); // Kept!

    // Step 6: updateBlurHashBySha256
    const std::string shaUpdatedHash = "L~TI:j|cfQ|c|c$5fQ$5fQfQfQfQ";
    indexService.updateBlurHashBySha256(sha256, shaUpdatedHash);
    auto item6 = indexService.findFileByHash(userId, StorageScope::Private, sha256);
    assert(item6.has_value());
    assert(item6->blurhash == shaUpdatedHash);

    // Step 7: listDirectory query verification
    auto dirList = indexService.listDirectory({
        .ownerUserId = userId,
        .scope = StorageScope::Private,
        .currentPath = "gallery",
        .filterType = "all",
        .query = "",
        .sortBy = "name",
        .sortAscending = true,
        .includeDirs = true,
        .recursiveFiles = false,
    });
    assert(dirList.size() == 1);
    assert(dirList[0].name == "photo.png");
    assert(dirList[0].blurhash == shaUpdatedHash);
  }

  std::filesystem::remove_all(dbPath.parent_path());
  std::cout << "  [PASS] FileIndexService ON CONFLICT preservation & CRUD passed." << std::endl;
}

// -----------------------------------------------------------------------------
// 5. Gradients, Checkerboard & Odd Dimension Patterns
// -----------------------------------------------------------------------------
static void testGradientAndCheckerboardPatterns() {
  std::cout << "[TEST] 5. Testing gradients, checkerboard & odd dimension patterns..." << std::endl;

  // 5.1: Checkerboard 32x32
  {
    const int w = 32;
    const int h = 32;
    std::vector<uint8_t> checker(w * h * 4);
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        const int idx = (y * w + x) * 4;
        uint8_t val = ((x / 4 + y / 4) % 2 == 0) ? 255 : 0;
        checker[idx + 0] = val;
        checker[idx + 1] = val;
        checker[idx + 2] = val;
        checker[idx + 3] = 255;
      }
    }
    std::string hash = encodeBlurHash(checker.data(), w, h, 4, 3);
    assert(hash.length() == 28);
    assert(isValidBlurHash(hash));
  }

  // 5.2: Diagonal Color Gradient 37x19 (Odd dimensions)
  {
    const int w = 37;
    const int h = 19;
    std::vector<uint8_t> grad(w * h * 4);
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        const int idx = (y * w + x) * 4;
        grad[idx + 0] = static_cast<uint8_t>((x * 255) / w);
        grad[idx + 1] = static_cast<uint8_t>((y * 255) / h);
        grad[idx + 2] = static_cast<uint8_t>(((x + y) * 255) / (w + h));
        grad[idx + 3] = 255;
      }
    }
    std::string hash = encodeBlurHash(grad.data(), w, h, 4, 3);
    assert(hash.length() == 28);
    assert(isValidBlurHash(hash));
  }

  // 5.3: Prime dimensions: 13x17, 3x5, 2x3
  {
    std::vector<uint8_t> p13x17(13 * 17 * 4, 100);
    std::string h13x17 = encodeBlurHash(p13x17.data(), 13, 17, 4, 3);
    assert(h13x17.length() == 28);
    assert(isValidBlurHash(h13x17));

    std::vector<uint8_t> p3x5(3 * 5 * 4, 200);
    std::string h3x5 = encodeBlurHash(p3x5.data(), 3, 5, 4, 3);
    assert(h3x5.length() == 28);
    assert(isValidBlurHash(h3x5));
  }

  std::cout << "  [PASS] Gradients, checkerboard & odd dimension patterns passed." << std::endl;
}

// -----------------------------------------------------------------------------
// 6. Base83 Special Characters & SQL Injection / Escape Safety
// -----------------------------------------------------------------------------
static void testSpecialCharactersAndInjectionSafety() {
  std::cout << "[TEST] 6. Testing Base83 special characters & SQL safety..." << std::endl;

  auto dbPath = createTempDbPath();
  auto storageRoot = dbPath.parent_path() / "storage";
  std::filesystem::create_directories(storageRoot);

  {
    db::Database db(dbPath.string());
    db.migrate();
    utils::Config config;
    config.storageRoot = storageRoot.string();
    FileService fileService(config);
    FileIndexService indexService(db, fileService);

    // Adversarial hash string containing all Base83 punctuation: #, $, %, *, +, -, ., :, ;, =, ?, @, [, ], ^, _, {, |, }, ~
    const std::string trickyBlurHash = "L#$%*+,-.:;=?@[]^_{|}~012345";
    const int64_t userId = 42;
    const std::string relPath = "tricky/file.jpg";
    const std::string sha256 = "deadbeefcafebabe0123456789abcdefdeadbeefcafebabe0123456789abcdef";

    indexService.upsertFileExplicit(
        userId,
        StorageScope::Private,
        relPath,
        "file.jpg",
        1000,
        1700000000,
        "photo",
        "image/jpeg",
        userId,
        sha256,
        "/api/thumb?path=tricky%2Ffile.jpg",
        trickyBlurHash);

    auto item = indexService.findFileByHash(userId, StorageScope::Private, sha256);
    assert(item.has_value());
    assert(item->blurhash == trickyBlurHash);

    auto list = indexService.listDirectory({
        .ownerUserId = userId,
        .scope = StorageScope::Private,
        .currentPath = "tricky",
        .filterType = "all",
        .query = "",
        .sortBy = "name",
        .sortAscending = true,
        .includeDirs = true,
        .recursiveFiles = false,
    });
    assert(list.size() == 1);
    assert(list[0].blurhash == trickyBlurHash);
  }

  std::filesystem::remove_all(dbPath.parent_path());
  std::cout << "  [PASS] Base83 special characters & SQL safety passed." << std::endl;
}

// -----------------------------------------------------------------------------
// 7. StorageScope::Shared BlurHash Propagation
// -----------------------------------------------------------------------------
static void testSharedDirectoryBlurHashPropagation() {
  std::cout << "[TEST] 7. Testing StorageScope::Shared BlurHash propagation..." << std::endl;

  auto dbPath = createTempDbPath();
  auto storageRoot = dbPath.parent_path() / "storage";
  std::filesystem::create_directories(storageRoot);

  {
    db::Database db(dbPath.string());
    db.migrate();
    utils::Config config;
    config.storageRoot = storageRoot.string();
    FileService fileService(config);
    FileIndexService indexService(db, fileService);

    const int64_t ownerId = 100;
    const std::string sharedDir = "public_photos";
    const std::string sharedFile = "public_photos/sunset.jpg";
    const std::string sha256 = "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd";
    const std::string blurHash = "L~TI:j|cfQ|c|c$5fQ$5fQfQfQfQ";

    // 1. Create shared directory row
    indexService.upsertFileExplicit(
        ownerId,
        StorageScope::Private,
        sharedDir,
        "public_photos",
        0,
        1700000000,
        "directory",
        "inode/directory",
        ownerId,
        "",
        "",
        "");

    // 2. Add file inside directory
    indexService.upsertFileExplicit(
        ownerId,
        StorageScope::Private,
        sharedFile,
        "sunset.jpg",
        5000,
        1700000000,
        "photo",
        "image/jpeg",
        ownerId,
        sha256,
        "/api/thumb?path=public_photos%2Fsunset.jpg",
        blurHash);

    // 3. Mark folder as shared
    indexService.setSharedFlag(ownerId, sharedDir, true);

    // 4. Query via StorageScope::Shared
    auto sharedEntries = indexService.listDirectory({
        .ownerUserId = ownerId,
        .scope = StorageScope::Shared,
        .currentPath = "public_photos",
        .filterType = "all",
        .query = "",
        .sortBy = "name",
        .sortAscending = true,
        .includeDirs = true,
        .recursiveFiles = false,
    });

    assert(sharedEntries.size() == 1);
    assert(sharedEntries[0].name == "sunset.jpg");
    assert(sharedEntries[0].blurhash == blurHash);
  }

  std::filesystem::remove_all(dbPath.parent_path());
  std::cout << "  [PASS] StorageScope::Shared BlurHash propagation passed." << std::endl;
}

int main() {
  std::cout << "==========================================================" << std::endl;
  std::cout << "   Milestone M3 BlurHash & SQLite Adversarial Test Suite  " << std::endl;
  std::cout << "==========================================================" << std::endl;

  testExtremeDimensionsAndBufferAnomalies();
  testVectorsAndBase83Invariants();
  testDatabaseMigrationIdempotency();
  testFileIndexOnConflictAndCrud();
  testGradientAndCheckerboardPatterns();
  testSpecialCharactersAndInjectionSafety();
  testSharedDirectoryBlurHashPropagation();

  std::cout << "==========================================================" << std::endl;
  std::cout << " [ALL PASS] All M3 Adversarial Tests Passed Successfully! " << std::endl;
  std::cout << "==========================================================" << std::endl;
  return 0;
}
