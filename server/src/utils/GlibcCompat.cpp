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

#include "server/utils/GlibcCompat.hpp"

#if defined(__linux__) && !defined(__ANDROID__)

#include <cerrno>
#include <climits>
#include <cstdint>

#define COMPAT_EXPORT extern "C" __attribute__((visibility("default")))

namespace {

unsigned long long parse_u64(const char *nptr, char **endptr, int base, bool *is_negative, bool *overflow) {
    const char *s = nptr;
    *is_negative = false;
    *overflow = false;

    // Skip leading ASCII whitespace
    while (*s && (*s == ' ' || *s == '\t' || *s == '\n' || *s == '\r' || *s == '\f' || *s == '\v')) {
        s++;
    }

    // Optional sign
    if (*s == '+') {
        s++;
    } else if (*s == '-') {
        *is_negative = true;
        s++;
    }

    // Determine radix and handle prefixes
    if ((base == 0 || base == 16) && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
        char c2 = s[2];
        if ((c2 >= '0' && c2 <= '9') || (c2 >= 'a' && c2 <= 'f') || (c2 >= 'A' && c2 <= 'F')) {
            s += 2;
            base = 16;
        } else if (base == 0) {
            base = 8;
        }
    } else if ((base == 0 || base == 2) && s[0] == '0' && (s[1] == 'b' || s[1] == 'B')) {
        // ISO C23 binary integer literal prefix 0b / 0B
        char c2 = s[2];
        if (c2 == '0' || c2 == '1') {
            s += 2;
            base = 2;
        } else if (base == 0) {
            base = 8;
        }
    } else if (base == 0) {
        if (*s == '0') {
            base = 8;
        } else {
            base = 10;
        }
    }

    // Validate radix range
    if (base < 2 || base > 36) {
        errno = EINVAL;
        if (endptr) {
            *endptr = const_cast<char *>(nptr);
        }
        return 0;
    }

    const char *digits_start = s;
    unsigned long long cutoff = ULLONG_MAX / static_cast<unsigned long long>(base);
    unsigned int cutlim = static_cast<unsigned int>(ULLONG_MAX % static_cast<unsigned long long>(base));
    unsigned long long res = 0;

    for (;; s++) {
        unsigned char c = static_cast<unsigned char>(*s);
        int digit;
        if (c >= '0' && c <= '9') {
            digit = c - '0';
        } else if (c >= 'a' && c <= 'z') {
            digit = c - 'a' + 10;
        } else if (c >= 'A' && c <= 'Z') {
            digit = c - 'A' + 10;
        } else {
            break;
        }

        if (digit >= base) {
            break;
        }

        if (*overflow) {
            continue;
        }

        if (res > cutoff || (res == cutoff && static_cast<unsigned int>(digit) > cutlim)) {
            *overflow = true;
            errno = ERANGE;
        } else {
            res = res * static_cast<unsigned long long>(base) + static_cast<unsigned long long>(digit);
        }
    }

    if (s == digits_start) {
        if (endptr) {
            *endptr = const_cast<char *>(nptr);
        }
        return 0;
    }

    if (endptr) {
        *endptr = const_cast<char *>(s);
    }

    return res;
}

} // namespace

COMPAT_EXPORT long long __isoc23_strtoll(const char *nptr, char **endptr, int base) {
    bool neg = false;
    bool overflow = false;
    unsigned long long val = parse_u64(nptr, endptr, base, &neg, &overflow);
    if (overflow) {
        return neg ? LLONG_MIN : LLONG_MAX;
    }
    if (!neg) {
        if (val > static_cast<unsigned long long>(LLONG_MAX)) {
            errno = ERANGE;
            return LLONG_MAX;
        }
        return static_cast<long long>(val);
    } else {
        constexpr unsigned long long llong_min_mag = static_cast<unsigned long long>(-(LLONG_MIN + 1)) + 1ULL;
        if (val > llong_min_mag) {
            errno = ERANGE;
            return LLONG_MIN;
        }
        if (val == llong_min_mag) {
            return LLONG_MIN;
        }
        return -static_cast<long long>(val);
    }
}

COMPAT_EXPORT unsigned long long __isoc23_strtoull(const char *nptr, char **endptr, int base) {
    bool neg = false;
    bool overflow = false;
    unsigned long long val = parse_u64(nptr, endptr, base, &neg, &overflow);
    if (overflow) {
        return ULLONG_MAX;
    }
    return neg ? -val : val;
}

COMPAT_EXPORT long __isoc23_strtol(const char *nptr, char **endptr, int base) {
    bool neg = false;
    bool overflow = false;
    unsigned long long val = parse_u64(nptr, endptr, base, &neg, &overflow);
    if (overflow) {
        return neg ? LONG_MIN : LONG_MAX;
    }
    if (!neg) {
        if (val > static_cast<unsigned long long>(LONG_MAX)) {
            errno = ERANGE;
            return LONG_MAX;
        }
        return static_cast<long>(val);
    } else {
        constexpr unsigned long long long_min_mag = static_cast<unsigned long long>(-(LONG_MIN + 1)) + 1ULL;
        if (val > long_min_mag) {
            errno = ERANGE;
            return LONG_MIN;
        }
        if (val == long_min_mag) {
            return LONG_MIN;
        }
        return -static_cast<long>(val);
    }
}

COMPAT_EXPORT unsigned long __isoc23_strtoul(const char *nptr, char **endptr, int base) {
    bool neg = false;
    bool overflow = false;
    unsigned long long val = parse_u64(nptr, endptr, base, &neg, &overflow);
    if (overflow || val > ULONG_MAX) {
        errno = ERANGE;
        return ULONG_MAX;
    }
    unsigned long u = static_cast<unsigned long>(val);
    return neg ? -u : u;
}

COMPAT_EXPORT intmax_t __isoc23_strtoimax(const char *nptr, char **endptr, int base) {
    return static_cast<intmax_t>(__isoc23_strtoll(nptr, endptr, base));
}

COMPAT_EXPORT uintmax_t __isoc23_strtoumax(const char *nptr, char **endptr, int base) {
    return static_cast<uintmax_t>(__isoc23_strtoull(nptr, endptr, base));
}

COMPAT_EXPORT long __isoc23_strtol_l(const char *nptr, char **endptr, int base, void * /*loc*/) {
    return __isoc23_strtol(nptr, endptr, base);
}

COMPAT_EXPORT long long __isoc23_strtoll_l(const char *nptr, char **endptr, int base, void * /*loc*/) {
    return __isoc23_strtoll(nptr, endptr, base);
}

COMPAT_EXPORT unsigned long __isoc23_strtoul_l(const char *nptr, char **endptr, int base, void * /*loc*/) {
    return __isoc23_strtoul(nptr, endptr, base);
}

COMPAT_EXPORT unsigned long long __isoc23_strtoull_l(const char *nptr, char **endptr, int base, void * /*loc*/) {
    return __isoc23_strtoull(nptr, endptr, base);
}

COMPAT_EXPORT intmax_t __isoc23_strtoimax_l(const char *nptr, char **endptr, int base, void * /*loc*/) {
    return __isoc23_strtoimax(nptr, endptr, base);
}

COMPAT_EXPORT uintmax_t __isoc23_strtoumax_l(const char *nptr, char **endptr, int base, void * /*loc*/) {
    return __isoc23_strtoumax(nptr, endptr, base);
}

#else

// Non-Linux platforms do not use or require glibc compatibility shims
[[maybe_unused]] static int g_glibc_compat_unused = 0;

#endif
