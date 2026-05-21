#pragma once

#include "server/services/UserService.hpp"
#include "server/utils/Config.hpp"

#include <drogon/HttpFilter.h>

namespace server::middleware {

class JwtMiddleware : public drogon::HttpFilter<JwtMiddleware> {
 public:
  JwtMiddleware() = default;

  void doFilter(const drogon::HttpRequestPtr &req,
                drogon::FilterCallback &&fcb,
                drogon::FilterChainCallback &&fccb) override;

};

}  // namespace server::middleware
