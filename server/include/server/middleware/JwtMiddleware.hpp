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
