// SPDX-License-Identifier: Apache-2.0
// Minimal check-based test harness (no external test framework: the repo
// builds offline with nothing but a C++20 compiler and CMake >= 3.16).
#ifndef ROCM_DEMO_TESTS_TEST_UTIL_HPP
#define ROCM_DEMO_TESTS_TEST_UTIL_HPP

#include <cmath>
#include <cstdio>
#include <sstream>
#include <string>
#include <vector>

inline int g_checks = 0;
inline int g_failures = 0;

#define CHECK(cond)                                                                     \
    do {                                                                                \
        ++g_checks;                                                                     \
        if (!(cond)) {                                                                  \
            ++g_failures;                                                               \
            std::printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond);                 \
        }                                                                               \
    } while (0)

// Integer/enum equality only (prints via long long); use CHECK_NEAR for
// floats.
#define CHECK_EQ(a, b)                                                                  \
    do {                                                                                \
        ++g_checks;                                                                     \
        const long long va_ = static_cast<long long>(a);                                \
        const long long vb_ = static_cast<long long>(b);                                \
        if (!(va_ == vb_)) {                                                            \
            ++g_failures;                                                               \
            std::printf("FAIL %s:%d: %s == %s (lhs=%lld rhs=%lld)\n", __FILE__,         \
                        __LINE__, #a, #b, va_, vb_);                                    \
        }                                                                               \
    } while (0)

#define CHECK_NEAR(a, b, tol)                                                           \
    do {                                                                                \
        ++g_checks;                                                                     \
        const double va_ = static_cast<double>(a);                                      \
        const double vb_ = static_cast<double>(b);                                      \
        const double vt_ = static_cast<double>(tol);                                    \
        if (!(std::fabs(va_ - vb_) <= vt_)) {                                           \
            ++g_failures;                                                               \
            std::printf("FAIL %s:%d: |%s - %s| <= %s (lhs=%.9g rhs=%.9g)\n",            \
                        __FILE__, __LINE__, #a, #b, #tol, va_, vb_);                    \
        }                                                                               \
    } while (0)

template <typename T>
std::string vec_mismatch(const std::vector<T>& a, const std::vector<T>& b) {
    std::ostringstream os;
    if (a.size() != b.size()) {
        os << "size " << a.size() << " vs " << b.size();
        return os.str();
    }
    for (std::size_t i = 0; i < a.size(); ++i) {
        if (!(a[i] == b[i])) {
            os << "at [" << i << "] " << static_cast<double>(a[i]) << " vs "
               << static_cast<double>(b[i]);
            return os.str();
        }
    }
    return "";
}

#define CHECK_VEC_EQ(a, b)                                                              \
    do {                                                                                \
        ++g_checks;                                                                     \
        const std::string m_ = vec_mismatch((a), (b));                                  \
        if (!m_.empty()) {                                                              \
            ++g_failures;                                                               \
            std::printf("FAIL %s:%d: %s == %s (%s)\n", __FILE__, __LINE__, #a, #b,      \
                        m_.c_str());                                                    \
        }                                                                               \
    } while (0)

#define RUN_TEST(fn)                                                                    \
    do {                                                                                \
        const int before_ = g_failures;                                                 \
        std::printf("-- %s\n", #fn);                                                    \
        fn();                                                                           \
        if (g_failures == before_) std::printf("   ok\n");                              \
    } while (0)

inline int finish() {
    std::printf("%d checks, %d failures\n", g_checks, g_failures);
    return g_failures == 0 ? 0 : 1;
}

#endif  // ROCM_DEMO_TESTS_TEST_UTIL_HPP
