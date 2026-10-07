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

#if defined(__linux__) && !defined(__ANDROID__)
#include <cstdint>

extern "C" {
long __isoc23_strtol(const char *nptr, char **endptr, int base);
long long __isoc23_strtoll(const char *nptr, char **endptr, int base);
unsigned long __isoc23_strtoul(const char *nptr, char **endptr, int base);
unsigned long long __isoc23_strtoull(const char *nptr, char **endptr, int base);
intmax_t __isoc23_strtoimax(const char *nptr, char **endptr, int base);
uintmax_t __isoc23_strtoumax(const char *nptr, char **endptr, int base);
long __isoc23_strtol_l(const char *nptr, char **endptr, int base, void *loc);
long long __isoc23_strtoll_l(const char *nptr, char **endptr, int base, void *loc);
unsigned long __isoc23_strtoul_l(const char *nptr, char **endptr, int base, void *loc);
unsigned long long __isoc23_strtoull_l(const char *nptr, char **endptr, int base, void *loc);
intmax_t __isoc23_strtoimax_l(const char *nptr, char **endptr, int base, void *loc);
uintmax_t __isoc23_strtoumax_l(const char *nptr, char **endptr, int base, void *loc);
}
#endif
