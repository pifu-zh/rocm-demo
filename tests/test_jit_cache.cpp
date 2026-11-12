// SPDX-License-Identifier: Apache-2.0
// Tests for the jit_cache design demo: key sensitivity, cache hit, identity
// tamper detection, atomic publish, stale-baton breaking across processes,
// and the single-builder guarantee (two processes racing on one key).
#include "jit_cache.hpp"
#include "test_util.hpp"

#include <chrono>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <string>
#include <thread>
#include <vector>

#include <sys/wait.h>
#include <unistd.h>

namespace fs = std::filesystem;

namespace {

aiter_design::JitCacheConfig make_config(const std::string& dir, const std::string& key_source,
                                         int sleep_ms) {
    aiter_design::JitCacheConfig cfg;
    cfg.cache_dir = dir;
    cfg.compile = [dir, key_source, sleep_ms](const std::string& artifact_path) {
        const std::string key = fs::path(artifact_path).parent_path().filename().string();
        // Slow build so a contender can only wait; a per-event marker
        // (pid + process-local counter) counts compile invocations.
        std::this_thread::sleep_for(std::chrono::milliseconds(sleep_ms));
        static int events = 0;
        {
            std::ofstream m(fs::path(dir) / key /
                            ("compile." + std::to_string(::getpid()) + "." +
                             std::to_string(++events)));
            m << "ok\n";
        }
        std::ofstream a(artifact_path);
        a << "binary-of(" << key_source << ")\n";
        return true;
    };
    return cfg;
}

int count_markers(const std::string& dir, const std::string& key) {
    int n = 0;
    for (const auto& e : fs::directory_iterator(fs::path(dir) / key)) {
        const std::string name = e.path().filename().string();
        if (name.rfind("compile.", 0) == 0) ++n;
    }
    return n;
}

bool wait_for_file(const std::string& path, int timeout_ms) {
    for (int i = 0; i < timeout_ms / 5; ++i) {
        if (fs::exists(path)) return true;
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    return fs::exists(path);
}

void cache_key_sensitivity() {
    const auto k1 = aiter_design::cache_key("src", "-O2", "t1");
    const auto k2 = aiter_design::cache_key("src", "-O2", "t1");
    const auto k3 = aiter_design::cache_key("src!", "-O2", "t1");
    const auto k4 = aiter_design::cache_key("src", "-O3", "t1");
    const auto k5 = aiter_design::cache_key("src", "-O2", "t2");
    CHECK(k1 == k2);
    CHECK(k1 != k3);
    CHECK(k1 != k4);
    CHECK(k1 != k5);
    // Hash is stable across runs (content-addressed, not pointer-based).
    CHECK_EQ(aiter_design::fnv1a64(""), 0xcbf29ce484222325ull);
    CHECK_EQ(aiter_design::fnv1a64("a"), 0xaf63dc4c8601ec8cull);
}

void cache_hit_skips_recompile() {
    const std::string dir = "/tmp/rocm-demo-jit-hit";
    fs::remove_all(dir);
    auto cfg = make_config(dir, "src", 0);
    const auto r1 = aiter_design::jit_compile(cfg, "src", "-O2");
    CHECK(!r1.hit);
    const auto r2 = aiter_design::jit_compile(cfg, "src", "-O2");
    CHECK(r2.hit);
    CHECK(r1.artifact_path == r2.artifact_path);
    CHECK_EQ(count_markers(dir, aiter_design::cache_key("src", "-O2", cfg.toolchain_version)), 1);
    // The artifact content is what the compile wrote.
    std::ifstream in(r2.artifact_path);
    std::string content;
    std::getline(in, content);
    CHECK(content == "binary-of(src)");
    // No temp files left by the atomic publish.
    for (const auto& e : fs::directory_iterator(fs::path(dir))) {
        CHECK(e.path().filename().string().find(".tmp.") == std::string::npos);
    }
    fs::remove_all(dir);
}

void changed_inputs_force_recompile() {
    const std::string dir = "/tmp/rocm-demo-jit-key";
    fs::remove_all(dir);
    auto cfg = make_config(dir, "x", 0);
    (void)aiter_design::jit_compile(cfg, "src", "-O2");
    (void)aiter_design::jit_compile(cfg, "src", "-O2");
    CHECK_EQ(count_markers(dir, aiter_design::cache_key("src", "-O2", cfg.toolchain_version)), 1);
    (void)aiter_design::jit_compile(cfg, "src v2", "-O2");  // source change
    (void)aiter_design::jit_compile(cfg, "src", "-O3");     // flags change
    CHECK_EQ(count_markers(dir, aiter_design::cache_key("src", "-O2", cfg.toolchain_version)), 1);
    CHECK_EQ(count_markers(dir, aiter_design::cache_key("src v2", "-O2", cfg.toolchain_version)),
             1);
    CHECK_EQ(count_markers(dir, aiter_design::cache_key("src", "-O3", cfg.toolchain_version)), 1);
    fs::remove_all(dir);
}

void identity_tamper_forces_recompile() {
    const std::string dir = "/tmp/rocm-demo-jit-tamper";
    fs::remove_all(dir);
    auto cfg = make_config(dir, "src", 0);
    (void)aiter_design::jit_compile(cfg, "src", "-O2");
    const auto key = aiter_design::cache_key("src", "-O2", cfg.toolchain_version);
    // A stale/corrupt sidecar (upstream identity check) is not trusted.
    { std::ofstream s(fs::path(dir) / key / "identity"); s << "garbage\n"; }
    const auto r = aiter_design::jit_compile(cfg, "src", "-O2");
    CHECK(!r.hit);
    CHECK_EQ(count_markers(dir, key), 2);
    fs::remove_all(dir);
}

void stale_baton_is_broken_and_redone() {
    // Child acquires the lock and dies holding it (no release). The parent
    // waiter must detect the dead pid, break the lock, and re-acquire.
    const std::string lock = "/tmp/rocm-demo-jit-stale/hold.lock";
    fs::remove_all("/tmp/rocm-demo-jit-stale");
    fs::create_directories("/tmp/rocm-demo-jit-stale");
    const pid_t child = ::fork();
    CHECK(child >= 0);
    if (child == 0) {
        aiter_design::FileBaton b(lock);
        while (!b.try_acquire()) usleep(1000);
        _exit(0);  // die holding the baton
    }
    CHECK(wait_for_file(lock, 2000));
    int status = 0;
    ::waitpid(child, &status, 0);

    aiter_design::FileBaton b(lock);
    CHECK(!b.try_acquire());  // held by the dead child
    const bool released_normally = b.wait();
    CHECK(!released_normally);  // false: a stale lock was broken
    CHECK(b.try_acquire());     // re-acquire and redo the work
    b.release();
    fs::remove_all("/tmp/rocm-demo-jit-stale");
}

void two_processes_single_builder() {
    // Parent and child race on the same key with a 120ms compile. Exactly
    // one may compile; the loser must observe a cache hit via the
    // post-acquire double-check.
    const std::string dir = "/tmp/rocm-demo-jit-race";
    fs::remove_all(dir);
    int fds[2];
    CHECK(::pipe(fds) == 0);
    const pid_t child = ::fork();
    CHECK(child >= 0);
    if (child == 0) {
        ::close(fds[0]);
        g_failures = 0;  // child accounting starts clean
        auto cfg = make_config(dir, "shared", 120);
        const auto r = aiter_design::jit_compile(cfg, "shared-src", "-O2");
        const char hit = r.hit ? '1' : '0';
        CHECK_EQ(::write(fds[1], &hit, 1), 1);
        _exit(g_failures == 0 ? 0 : 1);  // child CHECK failures fail the pipe too
    }
    ::close(fds[1]);
    // Parent races immediately; its own compile also takes 120ms.
    auto cfg = make_config(dir, "shared", 120);
    const auto r = aiter_design::jit_compile(cfg, "shared-src", "-O2");
    CHECK(fs::exists(r.artifact_path));

    int status = 0;
    ::waitpid(child, &status, 0);
    char child_hit = '?';
    CHECK_EQ(::read(fds[0], &child_hit, 1), 1);
    ::close(fds[0]);
    CHECK_EQ(status, 0);  // child checks all passed

    const auto key = aiter_design::cache_key("shared-src", "-O2", cfg.toolchain_version);
    CHECK_EQ(count_markers(dir, key), 1);                      // one builder only
    CHECK_EQ((r.hit ? 1 : 0) + (child_hit == '1' ? 1 : 0), 1);  // exactly one hit
    fs::remove_all(dir);
}

}  // namespace

int main() {
    RUN_TEST(cache_key_sensitivity);
    RUN_TEST(cache_hit_skips_recompile);
    RUN_TEST(changed_inputs_force_recompile);
    RUN_TEST(identity_tamper_forces_recompile);
    RUN_TEST(stale_baton_is_broken_and_redone);
    RUN_TEST(two_processes_single_builder);
    return finish();
}
