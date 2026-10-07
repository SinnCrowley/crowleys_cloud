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

#include <iostream>
#include <cassert>
#include <cerrno>
#include <climits>
#include <cstring>
#include "server/utils/GlibcCompat.hpp"

#define TEST_ASSERT(cond, msg) \
  do { \
    if (!(cond)) { \
      std::cerr << "[FAIL] Line " << __LINE__ << ": " << (msg) << std::endl; \
      std::exit(1); \
    } \
  } while (0)

#if defined(__linux__) && !defined(__ANDROID__)

void testDecimalAndWhitespace() {
    std::cout << "[TEST] Running testDecimalAndWhitespace..." << std::endl;
    char *end = nullptr;

    TEST_ASSERT(__isoc23_strtoll("0", &end, 10) == 0, "Zero conversion");
    TEST_ASSERT(*end == '\0', "Endptr at end");

    TEST_ASSERT(__isoc23_strtoll("  12345", &end, 10) == 12345, "Leading spaces");
    TEST_ASSERT(*end == '\0', "Endptr at end");

    TEST_ASSERT(__isoc23_strtoll("\t\r\n-6789abc", &end, 10) == -6789, "Negative with trailing");
    TEST_ASSERT(std::strcmp(end, "abc") == 0, "Endptr at trailing chars");

    TEST_ASSERT(__isoc23_strtoull("+42", &end, 10) == 42, "Plus sign unsigned");
    TEST_ASSERT(*end == '\0', "Endptr at end");
}

void testHexAndOctal() {
    std::cout << "[TEST] Running testHexAndOctal..." << std::endl;
    char *end = nullptr;

    TEST_ASSERT(__isoc23_strtoll("0x1a", &end, 0) == 26, "Hex 0x prefix base 0");
    TEST_ASSERT(*end == '\0', "Endptr at end");

    TEST_ASSERT(__isoc23_strtoll("0XFF", &end, 16) == 255, "Hex 0X prefix base 16");
    TEST_ASSERT(*end == '\0', "Endptr at end");

    TEST_ASSERT(__isoc23_strtoll("ff", &end, 16) == 255, "Hex without prefix");
    TEST_ASSERT(*end == '\0', "Endptr at end");

    TEST_ASSERT(__isoc23_strtoll("077", &end, 0) == 63, "Octal 0 prefix base 0");
    TEST_ASSERT(*end == '\0', "Endptr at end");

    TEST_ASSERT(__isoc23_strtoll("0x", &end, 0) == 0, "0x without hex digits");
    TEST_ASSERT(std::strcmp(end, "x") == 0, "Endptr stops at x");
}

void testBinaryC23() {
    std::cout << "[TEST] Running testBinaryC23..." << std::endl;
    char *end = nullptr;

    TEST_ASSERT(__isoc23_strtoll("0b1010", &end, 0) == 10, "Binary 0b base 0");
    TEST_ASSERT(*end == '\0', "Endptr at end");

    TEST_ASSERT(__isoc23_strtoll("-0b11", &end, 0) == -3, "Negative binary 0b base 0");
    TEST_ASSERT(*end == '\0', "Endptr at end");

    TEST_ASSERT(__isoc23_strtoull("0B1111", &end, 2) == 15, "Binary 0B base 2");
    TEST_ASSERT(*end == '\0', "Endptr at end");

    TEST_ASSERT(__isoc23_strtoll("1010", &end, 2) == 10, "Binary without prefix base 2");
    TEST_ASSERT(*end == '\0', "Endptr at end");

    TEST_ASSERT(__isoc23_strtoll("0b", &end, 0) == 0, "0b without binary digits");
    TEST_ASSERT(std::strcmp(end, "b") == 0, "Endptr stops at b");
}

void testLimitsAndOverflow() {
    std::cout << "[TEST] Running testLimitsAndOverflow..." << std::endl;
    char *end = nullptr;

    // Boundary checks
    TEST_ASSERT(__isoc23_strtoll("9223372036854775807", &end, 10) == LLONG_MAX, "LLONG_MAX");
    TEST_ASSERT(__isoc23_strtoll("-9223372036854775808", &end, 10) == LLONG_MIN, "LLONG_MIN");

    // Positive overflow
    errno = 0;
    TEST_ASSERT(__isoc23_strtoll("99999999999999999999999999", &end, 10) == LLONG_MAX, "Positive overflow LLONG_MAX");
    TEST_ASSERT(errno == ERANGE, "errno ERANGE on positive overflow");

    // Negative overflow
    errno = 0;
    TEST_ASSERT(__isoc23_strtoll("-99999999999999999999999999", &end, 10) == LLONG_MIN, "Negative overflow LLONG_MIN");
    TEST_ASSERT(errno == ERANGE, "errno ERANGE on negative overflow");

    // Unsigned negation per standard
    TEST_ASSERT(__isoc23_strtoull("-1", &end, 10) == ULLONG_MAX, "Unsigned negation returns ULLONG_MAX");
    TEST_ASSERT(__isoc23_strtoul("-1", &end, 10) == ULONG_MAX, "Unsigned long negation returns ULONG_MAX");
}

void testInvalidInputs() {
    std::cout << "[TEST] Running testInvalidInputs..." << std::endl;
    char *end = nullptr;

    // Invalid base
    const char *str = "123";
    errno = 0;
    TEST_ASSERT(__isoc23_strtoll(str, &end, 1) == 0, "Base 1 returns 0");
    TEST_ASSERT(errno == EINVAL, "Base 1 sets EINVAL");
    TEST_ASSERT(end == str, "Base 1 leaves endptr at nptr");

    errno = 0;
    TEST_ASSERT(__isoc23_strtoll(str, &end, 37) == 0, "Base 37 returns 0");
    TEST_ASSERT(errno == EINVAL, "Base 37 sets EINVAL");
    TEST_ASSERT(end == str, "Base 37 leaves endptr at nptr");

    // No digits
    const char *no_digits = "invalid";
    TEST_ASSERT(__isoc23_strtoll(no_digits, &end, 10) == 0, "No digits returns 0");
    TEST_ASSERT(end == no_digits, "No digits leaves endptr at nptr");

    const char *only_sign = "-";
    TEST_ASSERT(__isoc23_strtoll(only_sign, &end, 10) == 0, "Only sign returns 0");
    TEST_ASSERT(end == only_sign, "Only sign leaves endptr at nptr");
}

void testIntMaxAndLocaleVariants() {
    std::cout << "[TEST] Running testIntMaxAndLocaleVariants..." << std::endl;
    char *end = nullptr;

    TEST_ASSERT(__isoc23_strtoimax("12345", &end, 10) == 12345, "strtoimax conversion");
    TEST_ASSERT(__isoc23_strtoumax("54321", &end, 10) == 54321, "strtoumax conversion");

    TEST_ASSERT(__isoc23_strtol_l("42", &end, 10, nullptr) == 42, "strtol_l conversion");
    TEST_ASSERT(__isoc23_strtoll_l("4242", &end, 10, nullptr) == 4242, "strtoll_l conversion");
    TEST_ASSERT(__isoc23_strtoul_l("42", &end, 10, nullptr) == 42, "strtoul_l conversion");
    TEST_ASSERT(__isoc23_strtoull_l("4242", &end, 10, nullptr) == 4242, "strtoull_l conversion");
    TEST_ASSERT(__isoc23_strtoimax_l("4242", &end, 10, nullptr) == 4242, "strtoimax_l conversion");
    TEST_ASSERT(__isoc23_strtoumax_l("4242", &end, 10, nullptr) == 4242, "strtoumax_l conversion");
}

#endif

int main() {
#if defined(__linux__) && !defined(__ANDROID__)
    testDecimalAndWhitespace();
    testHexAndOctal();
    testBinaryC23();
    testLimitsAndOverflow();
    testInvalidInputs();
    testIntMaxAndLocaleVariants();
    std::cout << "[SUCCESS] All glibc compat tests passed!" << std::endl;
#else
    std::cout << "[INFO] glibc compat tests skipped on non-Linux platform." << std::endl;
#endif
    return 0;
}
