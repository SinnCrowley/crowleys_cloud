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

#include "server/db/Database.hpp"
#include "server/services/FileIndexService.hpp"
#include "server/services/FileService.hpp"
#include "server/services/ThumbnailQueue.hpp"
#include "server/utils/Crypto.hpp"
#include "dir_entry.pb.h"

#include <cassert>
#include <filesystem>
#include <fstream>
#include <iostream>

using namespace server;
using namespace server::services;

static std::filesystem::path createTempDbPath() {
  auto tmpDir = std::filesystem::temp_directory_path() / ("file_index_test_" + utils::randomTokenHex(8));
  std::filesystem::create_directories(tmpDir);
  return tmpDir / "test.db";
}

static void testFreshDatabaseMigration() {
  std::cout << "[TEST] Running fresh database migration test..." << std::endl;
  auto dbPath = createTempDbPath();
  {
    db::Database db(dbPath.string());
    db.migrate();

    // Check if blurhash column exists in file_index
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
  std::cout << "  [PASS] Fresh database migration passed." << std::endl;
}

static void testLegacyDatabaseDynamicMigration() {
  std::cout << "[TEST] Running legacy database dynamic migration test..." << std::endl;
  auto dbPath = createTempDbPath();
  {
    // 1. Manually create legacy schema WITHOUT blurhash column
    sqlite3 *rawDb = nullptr;
    assert(sqlite3_open_v2(dbPath.string().c_str(), &rawDb, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nullptr) == SQLITE_OK);
    const char *legacySql = R"(
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        created_at INTEGER NOT NULL
      );
      CREATE TABLE IF NOT EXISTS file_index (
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
    )";
    char *errMsg = nullptr;
    assert(sqlite3_exec(rawDb, legacySql, nullptr, nullptr, &errMsg) == SQLITE_OK);
    sqlite3_close(rawDb);

    // 2. Open via Database wrapper and run Database::migrate()
    db::Database db(dbPath.string());
    db.migrate();

    // 3. Verify blurhash column was dynamically added
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
  std::cout << "  [PASS] Legacy database dynamic migration passed." << std::endl;
}

static void testFileIndexBlurHashOperations() {
  std::cout << "[TEST] Running FileIndexService BlurHash CRUD operations..." << std::endl;
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

    const int64_t userId = 1;
    const std::string relPath = "photos/summer.jpg";
    const std::string sha256Val = "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890";
    const std::string testBlurHash = "L6Pj0^jE.AyE_3t7t7R**0o#DgR4";

    // 1. Explicit Upsert with BlurHash
    indexService.upsertFileExplicit(
        userId,
        StorageScope::Private,
        relPath,
        "summer.jpg",
        1024 * 1024,
        1725134000,
        "photo",
        "image/jpeg",
        userId,
        sha256Val,
        "/api/thumb?path=photos%2Fsummer.jpg",
        testBlurHash);

    // 2. Query via listDirectory
    auto entries = indexService.listDirectory({
        .ownerUserId = userId,
        .scope = StorageScope::Private,
        .currentPath = "photos",
        .filterType = "all",
        .query = "",
        .sortBy = "name",
        .sortAscending = true,
        .includeDirs = true,
        .recursiveFiles = false,
    });
    assert(entries.size() == 1);
    assert(entries[0].name == "summer.jpg");
    assert(entries[0].blurhash == testBlurHash);

    // 3. Query via findFileByHash
    auto foundEntry = indexService.findFileByHash(userId, StorageScope::Private, sha256Val);
    assert(foundEntry.has_value());
    assert(foundEntry->blurhash == testBlurHash);

    // 4. Test BlurHash update via updateBlurHash
    const std::string updatedBlurHash1 = "L00000fQfQfQfQfQfQfQfQfQfQfQ";
    indexService.updateBlurHash(userId, StorageScope::Private, relPath, updatedBlurHash1);
    auto foundAfterUpdate1 = indexService.findFileByHash(userId, StorageScope::Private, sha256Val);
    assert(foundAfterUpdate1.has_value());
    assert(foundAfterUpdate1->blurhash == updatedBlurHash1);

    // 5. Test BlurHash update via updateBlurHashBySha256
    const std::string updatedBlurHash2 = "L~TSUA~qfQ~q~q%MfQ%MfQfQfQfQ";
    indexService.updateBlurHashBySha256(sha256Val, updatedBlurHash2);
    auto foundAfterUpdate2 = indexService.findFileByHash(userId, StorageScope::Private, sha256Val);
    assert(foundAfterUpdate2.has_value());
    assert(foundAfterUpdate2->blurhash == updatedBlurHash2);

    // 6. Test ON CONFLICT preservation: upsert with empty blurhash should NOT overwrite existing blurhash
    indexService.upsertFileExplicit(
        userId,
        StorageScope::Private,
        relPath,
        "summer.jpg",
        1024 * 1024,
        1725135000,
        "photo",
        "image/jpeg",
        userId,
        sha256Val,
        "/api/thumb?path=photos%2Fsummer.jpg",
        ""); // empty blurhash

    auto foundPreserved = indexService.findFileByHash(userId, StorageScope::Private, sha256Val);
    assert(foundPreserved.has_value());
    assert(foundPreserved->blurhash == updatedBlurHash2); // Kept the existing blurhash!
  }

  std::filesystem::remove_all(dbPath.parent_path());
  std::cout << "  [PASS] FileIndexService BlurHash operations passed." << std::endl;
}

static void testProtobufSerialization() {
  std::cout << "[TEST] Running Protobuf serialization test..." << std::endl;

  server::proto::DirResponse response;
  auto *entry = response.add_entries();
  entry->set_name("sample.png");
  entry->set_path("sample.png");
  entry->set_is_dir(false);
  entry->set_size(4096);
  entry->set_modified_at(1725134000);
  entry->set_type("photo");
  entry->set_mime_type("image/png");
  entry->set_thumbnail_url("/api/thumb?path=sample.png");
  entry->set_id(42);
  entry->set_blurhash("L~TI:j|cfQ|c|c$5fQ$5fQfQfQfQ");

  std::string serialized = response.SerializeAsString();
  assert(!serialized.empty());

  server::proto::DirResponse parsed;
  assert(parsed.ParseFromString(serialized));
  assert(parsed.entries_size() == 1);
  assert(parsed.entries(0).name() == "sample.png");
  assert(parsed.entries(0).blurhash() == "L~TI:j|cfQ|c|c$5fQ$5fQfQfQfQ");

  std::cout << "  [PASS] Protobuf serialization test passed." << std::endl;
}

static void testSharedDirectoryPropagation() {
  std::cout << "[TEST] Running shared directory dynamic propagation test..." << std::endl;
  auto dbPath = createTempDbPath();
  {
    db::Database db(dbPath.string());
    db.migrate();

    utils::Config config;
    FileService fileService(config);
    FileIndexService indexService(db, fileService);

    const std::int64_t userId = 100;

    // 1. Create 'shared_docs' folder and mark it as explicitly shared
    indexService.upsertFileExplicit(
        userId,
        StorageScope::Private,
        "shared_docs",
        "shared_docs",
        0,
        1725135900,
        "directory",
        "inode/directory",
        userId,
        "");
    indexService.setSharedFlag(userId, "shared_docs", true);
    assert(indexService.isAncestorShared(userId, "shared_docs/subfolder/file.pdf"));

    // 2. Upload/Sync a new file into the shared folder
    indexService.upsertFileExplicit(
        userId,
        StorageScope::Private,
        "shared_docs/report.pdf",
        "report.pdf",
        5000,
        1725136000,
        "document",
        "application/pdf",
        userId,
        "sha256_report_1");

    auto foundReport = indexService.findFileByHash(userId, StorageScope::Private, "sha256_report_1");
    assert(foundReport.has_value());
    assert(foundReport->isShared == true);

    // 3. Sync/upload a nested file into a subfolder of the shared folder
    indexService.upsertFileExplicit(
        userId,
        StorageScope::Private,
        "shared_docs/subfolder/nested.png",
        "nested.png",
        12000,
        1725136100,
        "photo",
        "image/png",
        userId,
        "sha256_nested_1");

    auto foundNested = indexService.findFileByHash(userId, StorageScope::Private, "sha256_nested_1");
    assert(foundNested.has_value());
    assert(foundNested->isShared == true);

    // 4. File in a non-shared folder
    indexService.upsertFileExplicit(
        userId,
        StorageScope::Private,
        "private_docs/secret.pdf",
        "secret.pdf",
        3000,
        1725136200,
        "document",
        "application/pdf",
        userId,
        "sha256_secret_1");

    auto foundSecret = indexService.findFileByHash(userId, StorageScope::Private, "sha256_secret_1");
    assert(foundSecret.has_value());
    assert(foundSecret->isShared == false);

    // 5. Deleting a shared file removes its shared status
    indexService.markDeleted(userId, StorageScope::Private, "shared_docs/report.pdf");
    auto query = ListIndexQuery{
        .ownerUserId = 0,
        .scope = StorageScope::Shared,
        .currentPath = "",
        .filterType = "all",
        .query = "",
        .sortBy = "name",
        .sortAscending = true,
        .includeDirs = false,
        .recursiveFiles = true,
    };
    auto sharedFiles = indexService.listDirectory(query);
    bool foundDeletedInShared = false;
    for (const auto &item : sharedFiles) {
      if (item.path == "shared_docs/report.pdf") foundDeletedInShared = true;
    }
    assert(!foundDeletedInShared);

    // 6. Test getSharedFileOwner for nested shared files
    auto ownerNested = indexService.getSharedFileOwner("shared_docs/subfolder/nested.png");
    assert(ownerNested.has_value());
    assert(*ownerNested == userId);

    // 7. Test findFileByHash in Shared scope
    auto sharedFound = indexService.findFileByHash(0, StorageScope::Shared, "sha256_nested_1");
    assert(sharedFound.has_value());
    assert(sharedFound->uploaderUserId == userId);
    assert(sharedFound->name == "nested.png");

    // 8. Test that private and shared thumbnail keys match exactly
    const int thumbSize = 256;
    const auto privateKey = services::ThumbnailTask::makeKey(userId, "sha256_nested_1", thumbSize);
    const auto sharedOwnerId = *ownerNested;
    const auto sharedKey = services::ThumbnailTask::makeKey(sharedOwnerId, "sha256_nested_1", thumbSize);
    assert(privateKey == sharedKey);
  }

  std::filesystem::remove_all(dbPath.parent_path());
  std::cout << "  [PASS] Shared directory dynamic propagation passed." << std::endl;
}

int main() {
  std::cout << "========================================" << std::endl;
  std::cout << "   FileIndex BlurHash & Migration Test  " << std::endl;
  std::cout << "========================================" << std::endl;

  testFreshDatabaseMigration();
  testLegacyDatabaseDynamicMigration();
  testFileIndexBlurHashOperations();
  testProtobufSerialization();
  testSharedDirectoryPropagation();

  std::cout << "========================================" << std::endl;
  std::cout << " [ALL PASS] All FileIndex BlurHash & Sharing tests passed!" << std::endl;
  std::cout << "========================================" << std::endl;
  return 0;
}
