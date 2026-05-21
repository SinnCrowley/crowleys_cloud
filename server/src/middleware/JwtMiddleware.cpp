#include "server/middleware/JwtMiddleware.hpp"
#include "server/AppContext.hpp"

#include <drogon/drogon.h>

namespace server::middleware {

void JwtMiddleware::doFilter(const drogon::HttpRequestPtr &req,
                             drogon::FilterCallback &&fcb,
                             drogon::FilterChainCallback &&fccb) {
  const auto auth = req->getHeader("authorization");
  const auto prefix = std::string("Bearer ");
  if (auth.size() <= prefix.size() || auth.rfind(prefix, 0) != 0) {
    Json::Value err;
    err["error"] = "Missing or invalid authorization header";
    auto resp = drogon::HttpResponse::newHttpJsonResponse(err);
    resp->setStatusCode(drogon::k401Unauthorized);
    fcb(resp);
    return;
  }

  try {
    const auto token = auth.substr(prefix.size());
    const auto claims = server::ctx().userService->verifyAccessToken(token);
    if (!claims.has_value()) {
      throw std::runtime_error("invalid token");
    }
    req->attributes()->insert("user_id", claims->userId);
    req->attributes()->insert("role", claims->role);
  } catch (const std::exception &) {
    Json::Value err;
    err["error"] = "Unauthorized";
    auto resp = drogon::HttpResponse::newHttpJsonResponse(err);
    resp->setStatusCode(drogon::k401Unauthorized);
    fcb(resp);
    return;
  }

  fccb();
}

}  // namespace server::middleware
