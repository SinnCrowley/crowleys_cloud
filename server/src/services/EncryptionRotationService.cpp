// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later
#include "server/services/EncryptionRotationService.hpp"
#include "server/AppContext.hpp"
#include "server/utils/Crypto.hpp"
#include "server/utils/DurableFiles.hpp"
#include "server/utils/TimeUtils.hpp"
#include <algorithm>
#include <cstdlib>
#include <fstream>
#include <set>
#include <stdexcept>
#include <trantor/utils/Logger.h>

namespace server::services {
namespace {
bool hashName(const std::string &value) {
  return value.size() == 64 && value.find_first_not_of("0123456789abcdef") == std::string::npos;
}
void requireAdmin(std::int64_t actor) {
  auto user = ctx().userService->getUserById(actor);
  if (!user || user->role != "admin" || user->status != "active" || user->passwordResetRequired) throw std::runtime_error("forbidden");
}
void done(sqlite3_stmt *statement) {
  if (sqlite3_step(statement) != SQLITE_DONE) throw std::runtime_error("rotation_journal_failed");
}
std::string phase() {
  auto guard = ctx().database->getStatement("SELECT phase FROM encryption_rotation WHERE id = 1");
  if (sqlite3_step(guard.get()) != SQLITE_ROW) return "idle";
  return reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 0));
}
void setPhase(const std::string &value) {
  auto guard = ctx().database->getStatement("UPDATE encryption_rotation SET phase = ?, error_code = '' WHERE id = 1");
  sqlite3_bind_text(guard.get(), 1, value.c_str(), -1, SQLITE_TRANSIENT);
  done(guard.get());
}
}
std::filesystem::path EncryptionRotationService::keyPath() const {
  return std::filesystem::path(ctx().config.sourcePath).parent_path() / "encryption-rotation.keys.json";
}
Json::Value EncryptionRotationService::keys() const {
  Json::Value value;
  std::ifstream input(keyPath());
  try { input >> value; } catch (...) { throw std::runtime_error("rotation_keys_unreadable"); }
  if (!input || !value["job_id"].isString() || !value["old_key"].isString() ||
      !value["new_key"].isString() || value["new_key"].asString().size() < 32 || !value["storage_root"].isString())
    throw std::runtime_error("rotation_keys_unreadable");
  return value;
}
void EncryptionRotationService::initializeJournal(const Json::Value &value) {
  db::Database::TransactionGuard transaction(*ctx().database);
  {
    auto guard = ctx().database->getStatement("SELECT job_id, phase FROM encryption_rotation WHERE id = 1");
    if (sqlite3_step(guard.get()) == SQLITE_ROW) {
      const std::string job = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 0));
      const std::string current = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 1));
      if (job == value["job_id"].asString()) { transaction.commit(); return; }
      if (current != "complete") throw std::runtime_error("rotation_journal_conflict");
    }
  }
  {
    auto guard = ctx().database->getStatement("DELETE FROM encryption_objects");
    done(guard.get());
  }
  auto guard = ctx().database->getStatement("INSERT OR REPLACE INTO encryption_rotation(id, job_id, phase, actor_user_id, created_at, error_code) VALUES(1, ?, 'enumerating', ?, ?, '')");
  const auto job = value["job_id"].asString();
  sqlite3_bind_text(guard.get(), 1, job.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_int64(guard.get(), 2, value["actor"].asInt64());
  sqlite3_bind_int64(guard.get(), 3, utils::nowSeconds());
  done(guard.get());
  transaction.commit();
}
void EncryptionRotationService::launch() {
  if (running_.exchange(true)) throw std::runtime_error("rotation_running");
  if (worker_.joinable()) worker_.join();
  worker_ = std::jthread([this](std::stop_token stop) { run(stop); });
}
void EncryptionRotationService::recover() {
  std::lock_guard<std::mutex> lock(workerMutex_);
  if (std::filesystem::exists(keyPath()) || (phase() != "idle" && phase() != "complete")) {
    ctx().storageActivity.block();
    launch();
  }
}
void EncryptionRotationService::start(std::int64_t actor, const std::string &revision, const std::string &newKey) {
  std::lock_guard<std::mutex> workerLock(workerMutex_);
  std::unique_lock<std::shared_mutex> configLock(ctx().configMutex);
  requireAdmin(actor);
  if (running_ || ctx().storageActivity.blocked() || std::filesystem::exists(keyPath())) throw std::runtime_error("rotation_running");
  if (ctx().configService->revision() != revision) throw std::runtime_error("config_conflict");
  if (const auto envKey = std::getenv("CROWLEYS_ENCRYPTION_KEY"); envKey && *envKey != '\0') {
    throw std::runtime_error("config_from_environment");
  }
  if (newKey.size() < 32 || newKey.size() > 4096 || newKey.find('\0') != std::string::npos || newKey == ctx().config.encryptionKey) throw std::runtime_error("invalid_secret");
  {
    auto guard = ctx().database->getStatement("SELECT 1 FROM account_deletions LIMIT 1");
    if (sqlite3_step(guard.get()) == SQLITE_ROW) throw std::runtime_error("deletion_incomplete");
  }
  Json::Value value;
  value["job_id"] = utils::randomTokenHex(16);
  value["actor"] = Json::Int64(actor);
  value["old_key"] = ctx().config.encryptionKey;
  value["new_key"] = newKey;
  value["storage_root"] = ctx().config.storageRoot;
  value["hash_files"] = ctx().config.hashFiles;
  ctx().storageActivity.block();
  try {
    utils::writePrivateAtomic(keyPath(), Json::writeString(Json::StreamWriterBuilder(), value));
    initializeJournal(value);
    ctx().userService->audit(actor, "encryption.rotation_started", 0);
    launch();
  } catch (...) {
    if (!std::filesystem::exists(keyPath())) ctx().storageActivity.unblock();
    throw;
  }
}
void EncryptionRotationService::resume(std::int64_t actor) {
  std::lock_guard<std::mutex> workerLock(workerMutex_);
  std::shared_lock<std::shared_mutex> configLock(ctx().configMutex);
  requireAdmin(actor);
  if (running_) throw std::runtime_error("rotation_running");
  if (!ctx().storageActivity.blocked()) throw std::runtime_error("no_rotation");
  ctx().userService->audit(actor, "encryption.rotation_resumed", 0);
  launch();
}
Json::Value EncryptionRotationService::status() const {
  Json::Value result;
  result["maintenance"] = ctx().storageActivity.blocked();
  result["running"] = running_.load();
  result["phase"] = "idle";
  auto guard = ctx().database->getStatement("SELECT phase, error_code, "
      "(SELECT COUNT(*) FROM encryption_objects), "
      "(SELECT COUNT(*) FROM encryption_objects WHERE state = 'done'), "
      "(SELECT COALESCE(SUM(cipher_bytes), 0) FROM encryption_objects), "
      "(SELECT COALESCE(SUM(cipher_bytes), 0) FROM encryption_objects WHERE state = 'done') "
      "FROM encryption_rotation WHERE id = 1");
  if (sqlite3_step(guard.get()) == SQLITE_ROW) {
    result["phase"] = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 0));
    result["error_code"] = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 1));
    result["files_total"] = Json::Int64(sqlite3_column_int64(guard.get(), 2));
    result["files_done"] = Json::Int64(sqlite3_column_int64(guard.get(), 3));
    result["bytes_total"] = Json::Int64(sqlite3_column_int64(guard.get(), 4));
    result["bytes_done"] = Json::Int64(sqlite3_column_int64(guard.get(), 5));
  }
  return result;
}
void EncryptionRotationService::enumerate(const Json::Value &value) {
  db::Database::TransactionGuard transaction(*ctx().database);
  const auto directory = std::filesystem::path(value["storage_root"].asString()) / "data";
  std::set<std::string> names;
  if (value["hash_files"].asBool() && std::filesystem::exists(directory)) {
    for (const auto &entry : std::filesystem::directory_iterator(directory)) {
      const auto name = entry.path().filename().string();
      if (!hashName(name)) continue;
      if (!entry.is_regular_file() || entry.is_symlink()) throw std::runtime_error("rotation_invalid_object");
      names.insert(name);
      auto guard = ctx().database->getStatement("INSERT OR IGNORE INTO encryption_objects(name, cipher_bytes) VALUES(?, ?)");
      sqlite3_bind_text(guard.get(), 1, name.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_int64(guard.get(), 2, static_cast<std::int64_t>(entry.file_size()));
      done(guard.get());
    }
    auto guard = ctx().database->getStatement("SELECT sha256 FROM file_index WHERE sha256 != '' UNION SELECT sha256 FROM trash WHERE sha256 != ''");
    while (sqlite3_step(guard.get()) == SQLITE_ROW) {
      const std::string hash = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 0));
      if (!names.count(hash)) throw std::runtime_error("rotation_missing_object");
    }
  } else if (value["hash_files"].asBool()) {
    auto guard = ctx().database->getStatement("SELECT 1 FROM file_index WHERE sha256 != '' UNION ALL SELECT 1 FROM trash WHERE sha256 != '' LIMIT 1");
    if (sqlite3_step(guard.get()) == SQLITE_ROW) throw std::runtime_error("rotation_missing_object");
  }
  setPhase("rotating");
  transaction.commit();
}
void EncryptionRotationService::processObject(const Json::Value &value, const std::string &name) {
  const auto source = std::filesystem::path(value["storage_root"].asString()) / "data" / name;
  const auto staged = std::filesystem::path(source.string() + ".rotate-new");
  std::string state, oldDigest, newDigest;
  std::uintmax_t size = 0;
  {
    auto guard = ctx().database->getStatement("SELECT state, old_digest, new_digest, plain_bytes FROM encryption_objects WHERE name = ?");
    sqlite3_bind_text(guard.get(), 1, name.c_str(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(guard.get()) != SQLITE_ROW) throw std::runtime_error("rotation_journal_failed");
    state = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 0));
    oldDigest = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 1));
    newDigest = reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 2));
    size = sqlite3_column_int64(guard.get(), 3);
  }
  if (std::filesystem::is_symlink(source) || std::filesystem::is_symlink(staged)) throw std::runtime_error("rotation_invalid_object");
  if (state == "pending") {
    std::filesystem::remove(staged);
    if (std::filesystem::space(source.parent_path()).available < std::filesystem::file_size(source) + 4096)
      throw std::runtime_error("rotation_disk_full");
    oldDigest = utils::sha256FileHex(source);
    if (!utils::reencryptFile(source, staged, value["old_key"].asString(), value["new_key"].asString(), name, size))
      throw std::runtime_error("rotation_verification_failed");
    {
      auto guard = ctx().database->getStatement("SELECT size_bytes FROM file_index WHERE sha256 = ? AND type != 'directory' UNION SELECT size_bytes FROM trash WHERE sha256 = ? AND is_dir = 0");
      sqlite3_bind_text(guard.get(), 1, name.c_str(), -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(guard.get(), 2, name.c_str(), -1, SQLITE_TRANSIENT);
      while (sqlite3_step(guard.get()) == SQLITE_ROW)
        if (static_cast<std::uintmax_t>(sqlite3_column_int64(guard.get(), 0)) != size) throw std::runtime_error("rotation_size_mismatch");
    }
    utils::syncFile(staged);
    utils::syncDirectory(staged.parent_path());
    newDigest = utils::sha256FileHex(staged);
    auto guard = ctx().database->getStatement("UPDATE encryption_objects SET state = 'prepared', old_digest = ?, new_digest = ?, plain_bytes = ? WHERE name = ?");
    sqlite3_bind_text(guard.get(), 1, oldDigest.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(guard.get(), 2, newDigest.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(guard.get(), 3, static_cast<std::int64_t>(size));
    sqlite3_bind_text(guard.get(), 4, name.c_str(), -1, SQLITE_TRANSIENT);
    done(guard.get());
  }
  const auto current = utils::sha256FileHex(source);
  if (current != newDigest) {
    if (current != oldDigest || !std::filesystem::exists(staged) || utils::sha256FileHex(staged) != newDigest)
      throw std::runtime_error("rotation_object_conflict");
    std::uintmax_t verifiedSize = 0;
    if (!utils::verifyEncryptedFile(staged, value["new_key"].asString(), name, verifiedSize) || verifiedSize != size)
      throw std::runtime_error("rotation_verification_failed");
    utils::durableReplace(staged, source);
  }
  if (state != "done") {
    auto guard = ctx().database->getStatement("UPDATE encryption_objects SET state = 'done' WHERE name = ?");
    sqlite3_bind_text(guard.get(), 1, name.c_str(), -1, SQLITE_TRANSIENT);
    done(guard.get());
  }
}
void EncryptionRotationService::run(std::stop_token stop) {
  try {
    if (!ctx().storageActivity.drain(stop)) { running_ = false; return; }
    if (ctx().thumbnailQueue) ctx().thumbnailQueue->clear();
    const auto value = keys();
    {
      std::shared_lock<std::shared_mutex> configLock(ctx().configMutex);
      if (value["storage_root"].asString() != ctx().config.storageRoot || value["hash_files"].asBool() != ctx().config.hashFiles ||
          (ctx().config.encryptionKey != value["old_key"].asString() && ctx().config.encryptionKey != value["new_key"].asString()))
        throw std::runtime_error("encryption_key_conflict");
    }
    initializeJournal(value);
    {
      auto guard = ctx().database->getStatement("UPDATE encryption_rotation SET error_code = '' WHERE id = 1");
      done(guard.get());
    }
    if (phase() == "enumerating") enumerate(value);
    std::vector<std::string> names;
    {
      auto guard = ctx().database->getStatement("SELECT name FROM encryption_objects ORDER BY name");
      while (sqlite3_step(guard.get()) == SQLITE_ROW) names.emplace_back(reinterpret_cast<const char *>(sqlite3_column_text(guard.get(), 0)));
    }
    for (const auto &name : names) {
      if (stop.stop_requested()) { running_ = false; return; }
      processObject(value, name);
    }
    setPhase("finalizing");
    for (const auto &name : names) {
      if (stop.stop_requested()) { running_ = false; return; }
      std::uintmax_t size;
      if (!utils::verifyEncryptedFile(std::filesystem::path(value["storage_root"].asString()) / "data" / name,
                                      value["new_key"].asString(), name, size)) throw std::runtime_error("rotation_verification_failed");
    }
    const auto thumbRoot = std::filesystem::path(value["storage_root"].asString()) / ".thumbs";
    std::filesystem::remove_all(thumbRoot);
    {
      auto guard = ctx().database->getStatement("UPDATE file_index SET thumbnail_path = '', thumbnail_updated_at = NULL");
      done(guard.get());
    }
    ctx().configService->finishEncryptionRotation(value["old_key"].asString(), value["new_key"].asString());
    setPhase("complete");
    ctx().userService->audit(value["actor"].asInt64(), "encryption.rotation_completed", 0);
    std::filesystem::remove(keyPath());
    utils::syncDirectory(keyPath().parent_path());
    ctx().storageActivity.unblock();
  } catch (const std::exception &exception) {
    // Filesystem/parser diagnostics can contain paths or keys. Only known codes are exposed.
    std::string code = exception.what();
    const std::set<std::string> allowed{"rotation_keys_unreadable", "encryption_key_conflict", "rotation_disk_full", "rotation_verification_failed",
        "rotation_object_conflict", "rotation_missing_object", "rotation_invalid_object", "rotation_size_mismatch", "rotation_journal_conflict", "config_from_environment"};
    if (!allowed.count(code)) code = "rotation_io_error";
    try {
      auto guard = ctx().database->getStatement("UPDATE encryption_rotation SET error_code = ? WHERE id = 1");
      sqlite3_bind_text(guard.get(), 1, code.c_str(), -1, SQLITE_TRANSIENT);
      done(guard.get());
    } catch (...) {}
    LOG_ERROR << "Encryption rotation paused: " << code;
    // If final verification and configuration were committed and the private
    // key file is already gone, only its directory sync failed. Data is fully
    // usable, so do not strand the server in maintenance until a manual restart.
    try {
      std::error_code fsError;
      if (phase() == "complete" && !std::filesystem::exists(keyPath(), fsError) && !fsError)
        ctx().storageActivity.unblock();
    } catch (...) {}
  }
  running_ = false;
}
}
