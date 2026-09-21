// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later
#include "server/controllers/AdminController.hpp"
#include "server/AppContext.hpp"
#include "server/utils/HttpHelpers.hpp"

namespace server::controllers {
namespace {
bool requireAdmin(const drogon::HttpRequestPtr &req, const std::function<void(const drogon::HttpResponsePtr &)> &callback) {
  const auto id = utils::getAuthUserId(req);
  const auto actor = id ? ctx().userService->getUserById(*id) : std::nullopt;
  const auto role = utils::getAuthRole(req);
  if ((role == "admin" || role == "superuser") && actor && (actor->role == "admin" || actor->role == "superuser") && actor->role == role && actor->status == "active" && !actor->passwordResetRequired) return true;
  callback(utils::jsonError(drogon::k403Forbidden, "Administrator access required", "forbidden"));
  return false;
}
bool requireSuperuser(const drogon::HttpRequestPtr &req, const std::function<void(const drogon::HttpResponsePtr &)> &callback) {
  const auto id = utils::getAuthUserId(req);
  const auto actor = id ? ctx().userService->getUserById(*id) : std::nullopt;
  if (utils::getAuthRole(req) == "superuser" && actor && actor->role == "superuser" && actor->status == "active" && !actor->passwordResetRequired) return true;
  callback(utils::jsonError(drogon::k403Forbidden, "Superuser access required", "forbidden"));
  return false;
}
void list(const drogon::HttpRequestPtr &req, const std::function<void(const drogon::HttpResponsePtr &)> &callback, bool pending) {
  if (!requireAdmin(req, callback)) return;
  Json::Value body(Json::arrayValue);
  for (const auto &user : ctx().userService->listUsers(pending)) {
    Json::Value item;
    item["id"] = Json::Int64(user.id);
    item["username"] = user.username;
    item["role"] = user.role;
    item["status"] = user.status;
    item["quota_bytes"] = user.quotaBytes ? Json::Value(Json::Int64(*user.quotaBytes)) : Json::Value();
    const auto usage = ctx().quotaService->usage(user.id);
    item["used_bytes"] = Json::Int64(usage.used);
    item["reserved_bytes"] = Json::Int64(usage.reserved);
    item["effective_quota_bytes"] = Json::Int64(usage.limit);
    item["created_at"] = Json::Int64(user.createdAt);
    item["password_reset_required"] = user.passwordResetRequired;
    body.append(item);
  }
  auto response = drogon::HttpResponse::newHttpJsonResponse(body);
  response->addHeader("Cache-Control", "no-store");
  callback(response);
}
void failure(const std::function<void(const drogon::HttpResponsePtr &)> &callback, const std::string &error) {
  callback(utils::jsonError(error == "forbidden" || error == "cannot_demote_admin" ? drogon::k403Forbidden :
                           error.ends_with("not_found") ? drogon::k404NotFound :
                           (error == "last_admin" || error == "cannot_block_self" || error == "cannot_block_superuser" ||
                            error == "cannot_modify_superuser" || error == "cannot_delete_superuser" ||
                            error == "quota_exceeded" || error == "quota_exceeded_default" ||
                            error == "deletion_incomplete" || error == "config_conflict" ||
                            error == "manual_migration_required") ? drogon::k409Conflict : drogon::k400BadRequest, error, error));
}
}
void AdminController::maintenance(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  if (!requireAdmin(req, callback)) return;
  auto response = drogon::HttpResponse::newHttpJsonResponse(ctx().encryptionRotation->status());
  response->addHeader("Cache-Control", "no-store");
  callback(response);
}
void AdminController::rotateEncryption(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  if (!requireSuperuser(req, callback)) return;
  const auto json = req->getJsonObject();
  if (!json || !(*json)["revision"].isString() || !(*json)["secret"].isString()) { failure(callback, "invalid_config_patch"); return; }
  try {
    ctx().encryptionRotation->start(*utils::getAuthUserId(req), (*json)["revision"].asString(), (*json)["secret"].asString());
    auto response = drogon::HttpResponse::newHttpJsonResponse(ctx().encryptionRotation->status());
    response->setStatusCode(drogon::k202Accepted);
    callback(response);
  } catch (const std::exception &e) { failure(callback, e.what()); }
}
void AdminController::resumeEncryption(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  if (!requireSuperuser(req, callback)) return;
  try {
    ctx().encryptionRotation->resume(*utils::getAuthUserId(req));
    auto response = drogon::HttpResponse::newHttpJsonResponse(ctx().encryptionRotation->status());
    response->setStatusCode(drogon::k202Accepted);
    callback(response);
  } catch (const std::exception &e) { failure(callback, e.what()); }
}
void AdminController::configuration(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  if (!requireAdmin(req, callback)) return;
  try {
    auto response = drogon::HttpResponse::newHttpJsonResponse(ctx().configService->snapshot());
    response->addHeader("Cache-Control", "no-store");
    callback(response);
  } catch (const std::exception &) { failure(callback, "config_unreadable"); }
}
void AdminController::saveConfiguration(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  if (!requireSuperuser(req, callback)) return;
  const auto json = req->getJsonObject();
  if (!json || !(*json)["revision"].isString() || !(*json)["changes"].isObject()) { failure(callback, "invalid_config_patch"); return; }
  try {
    auto response = drogon::HttpResponse::newHttpJsonResponse(ctx().configService->save(*utils::getAuthUserId(req), (*json)["revision"].asString(), (*json)["changes"]));
    response->addHeader("Cache-Control", "no-store");
    callback(response);
  } catch (const std::exception &e) { failure(callback, e.what()); }
}
void AdminController::rotateSigningSecret(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  if (!requireSuperuser(req, callback)) return;
  const auto json = req->getJsonObject();
  if (!json || !(*json)["revision"].isString() || !(*json)["secret"].isString()) { failure(callback, "invalid_config_patch"); return; }
  try {
    ctx().configService->rotateSigningSecret(*utils::getAuthUserId(req), (*json)["revision"].asString(), (*json)["secret"].asString());
    callback(utils::jsonOk());
  } catch (const std::exception &e) { failure(callback, e.what()); }
}
void AdminController::users(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(ctx().configMutex);
  list(req, callback, false);
}
void AdminController::applications(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(ctx().configMutex);
  list(req, callback, true);
}
void AdminController::updateUser(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback, std::int64_t id) {
  std::shared_lock<std::shared_mutex> configLock(ctx().configMutex);
  if (!requireAdmin(req, callback)) return;
  std::lock_guard<std::recursive_mutex> storageLock(ctx().storageMutex);
  const auto json = req->getJsonObject();
  if (!json) { failure(callback, "invalid_user_patch"); return; }
  std::string error;
  if (!ctx().userService->updateUser(*utils::getAuthUserId(req), id, *json, error)) { failure(callback, error); return; }
  callback(utils::jsonOk());
}
void AdminController::deleteUser(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback, std::int64_t id) {
  std::shared_lock<std::shared_mutex> configLock(ctx().configMutex);
  auto activity = ctx().storageActivity.enter();
  if (!activity) { callback(utils::maintenanceResponse()); return; }
  if (!requireAdmin(req, callback)) return;
  std::string error;
  if (!ctx().userService->deleteUser(*utils::getAuthUserId(req), id, error)) { failure(callback, error); return; }
  callback(utils::jsonOk());
}
void AdminController::userAction(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback,
                                 std::int64_t id, const std::string &action) {
  std::shared_lock<std::shared_mutex> configLock(ctx().configMutex);
  if (!requireAdmin(req, callback)) return;
  const auto actor = *utils::getAuthUserId(req);
  std::string error;
  if (action == "approve" || action == "reject") {
    if (!ctx().userService->decideApplication(actor, id, action == "approve", error)) { failure(callback, error); return; }
  } else if (action == "reset-password") {
    std::string code;
    if (!ctx().userService->adminResetPassword(actor, id, code, error)) { failure(callback, error); return; }
    Json::Value body;
    body["code"] = code;
    body["expires_in"] = 600;
    auto response = drogon::HttpResponse::newHttpJsonResponse(body);
    response->addHeader("Cache-Control", "no-store");
    callback(response);
    return;
  } else if (action == "revoke-sessions") {
    if (!ctx().userService->getUserById(id)) { failure(callback, "user_not_found"); return; }
    ctx().userService->revokeSessions(id);
    ctx().userService->audit(actor, "user.revoke_sessions", id);
  } else { failure(callback, "unknown_action"); return; }
  callback(utils::jsonOk());
}
void AdminController::resetCodes(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback) {
  std::shared_lock<std::shared_mutex> configLock(ctx().configMutex);
  if (!requireAdmin(req, callback)) return;
  const auto actorId = *utils::getAuthUserId(req);
  const auto codes = ctx().userService->listResetCodes(actorId);
  Json::Value body(Json::arrayValue);
  for (const auto &rc : codes) {
    Json::Value item;
    item["id"] = Json::Int64(rc.id);
    item["user_id"] = Json::Int64(rc.userId);
    item["username"] = rc.username;
    item["role"] = rc.role;
    item["code"] = rc.code;
    item["created_at"] = Json::Int64(rc.createdAt);
    item["expires_at"] = Json::Int64(rc.expiresAt);
    body.append(item);
  }
  auto response = drogon::HttpResponse::newHttpJsonResponse(body);
  response->addHeader("Cache-Control", "no-store");
  callback(response);
}
void AdminController::deleteResetCode(const drogon::HttpRequestPtr &req, std::function<void(const drogon::HttpResponsePtr &)> &&callback, std::int64_t id) {
  std::shared_lock<std::shared_mutex> configLock(ctx().configMutex);
  if (!requireAdmin(req, callback)) return;
  const auto actorId = *utils::getAuthUserId(req);
  std::string error;
  if (!ctx().userService->deleteResetCode(actorId, id, error)) { failure(callback, error); return; }
  callback(utils::jsonOk());
}
}

