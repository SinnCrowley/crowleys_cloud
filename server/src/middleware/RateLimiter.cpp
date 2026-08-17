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

// RateLimiter implementation for endpoint throttling and anti-abuse protection.
// Throttling Model: Fixed 1-minute window algorithm per IP/key.
// Memory Management: Periodic pruning removes inactive client buckets older than 2 minutes, preventing memory leaks under heavy traffic or IP spoofing.

#include "server/middleware/RateLimiter.hpp"
