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

// JwtMiddleware implementation for HTTP request authentication and authorization filtering.
// Token Format & Verification: Inspects "Authorization: Bearer <token>" headers and validates
// HMAC-SHA256 signature and expiration via UserService::verifyAccessToken.
// Role-Based Access Control (RBAC): Enforces scoped endpoint restrictions for special roles (e.g., 'sync').
// Context Propagation: Attaches authenticated user_id and role as Drogon request attributes.

#include "server/middleware/JwtMiddleware.hpp"
#include "server/AppContext.hpp"
#include "server/utils/HttpHelpers.hpp"

#include <drogon/drogon.h>

namespace server::middleware {

void JwtMiddleware::doFilter(const drogon::HttpRequestPtr &req,
                             drogon::FilterCallback &&fcb,
                             drogon::FilterChainCallback &&fccb) {
  // Step 1: Extract and validate Authorization HTTP header format
  auto auth = req->getHeader("authorization");
  const auto prefix = std::string("Bearer ");
  if (auth.size() <= prefix.size() || auth.rfind(prefix, 0) != 0) {
    const auto tokenParam = req->getParameter("token");
    const auto accessTokenParam = req->getParameter("access_token");
    const auto queryToken = !tokenParam.empty() ? tokenParam : accessTokenParam;
    if (!queryToken.empty()) {
      auth = prefix + queryToken;
    }
  }

  if (auth.size() <= prefix.size() || auth.rfind(prefix, 0) != 0) {
    fcb(utils::jsonError(drogon::k401Unauthorized, "Missing or invalid authorization header"));
    return;
  }

  try {
    // Step 2: Strip 'Bearer ' prefix and verify token claims and cryptographic HMAC signature
    const auto token = auth.substr(prefix.size());
    const auto claims = server::ctx().userService->verifyAccessToken(token);
    if (!claims.has_value()) {
      throw std::runtime_error("invalid token");
    }

    // Step 3: Enforce Role-Based Access Control (RBAC) route restrictions for background sync tokens
    if (claims->role == "sync") {
      const auto &path = req->path();
      const auto method = req->method();
      bool allowed = false;

      // Restrict 'sync' role to file listing/upload/download and folder creation endpoints only
      if (path == "/api/files") {
        allowed = (method == drogon::Post || method == drogon::Head || method == drogon::Get);
      } else if (path == "/api/files/check-hashes") {
        allowed = (method == drogon::Post);
      } else if (path == "/api/folders") {
        allowed = (method == drogon::Post);
      }

      if (!allowed) {
        fcb(utils::jsonError(drogon::k403Forbidden, "Forbidden for sync role"));
        return;
      }
    }

    // Step 4: Attach authenticated claims to Drogon request context attributes for downstream controllers
    req->attributes()->insert("user_id", claims->userId);
    req->attributes()->insert("role", claims->role);
  } catch (const std::exception &) {
    fcb(utils::jsonError(drogon::k401Unauthorized, "Unauthorized"));
    return;
  }

  // Step 5: Token is valid; proceed to next middleware filter or target controller handler
  fccb();
}

}  // namespace server::middleware
