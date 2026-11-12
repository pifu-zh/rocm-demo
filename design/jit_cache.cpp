// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
// Minimal C++ port of aiter's runtime-compile cache designs; see the header
// for the pinned mechanisms and scope.
#include "jit_cache.hpp"

#include <cassert>
#include <cerrno>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include <fcntl.h>
#include <signal.h>
#include <unistd.h>

namespace aiter_design {

namespace fs = std::filesystem;

namespace {

std::string read_file(const std::string& path) {
    std::ifstream in(path, std::ios::binary);
    std::ostringstream os;
    os << in.rdbuf();
    return os.str();
}

// Temp-then-rename atomic publish (upstream atomic_copy): the artifact
// becomes visible whole, never half-written.
bool atomic_write(const std::string& path, const std::string& content) {
    const std::string tmp = path + ".tmp." + std::to_string(::getpid());
    {
        std::ofstream out(tmp, std::ios::binary | std::ios::trunc);
        if (!out) return false;
        out << content;
        out.flush();
        if (!out) {
            ::unlink(tmp.c_str());
            return false;
        }
    }
    if (::rename(tmp.c_str(), path.c_str()) != 0) {
        ::unlink(tmp.c_str());
        return false;
    }
    return true;
}

bool pid_alive(int pid) {
    if (pid <= 0) return false;
    return ::kill(pid, 0) == 0 || errno == EPERM;  // exists (maybe not ours)
}

}  // namespace

std::uint64_t fnv1a64(const std::string& data) {
    std::uint64_t h = 0xcbf29ce484222325ull;
    for (const unsigned char c : data) {
        h ^= c;
        h *= 0x100000001b3ull;
    }
    return h;
}

std::string cache_key(const std::string& source, const std::string& flags,
                      const std::string& toolchain_version) {
    std::ostringstream os;
    os << fnv1a64(source) << "-" << fnv1a64(flags) << "-" << fnv1a64(toolchain_version);
    return os.str();
}

FileBaton::FileBaton(std::string lock_path, double wait_seconds, double stale_grace_seconds)
    : lock_path_(std::move(lock_path)), wait_seconds_(wait_seconds),
      stale_grace_seconds_(stale_grace_seconds) {}

FileBaton::~FileBaton() { release(); }

bool FileBaton::try_acquire() {
    // O_CREAT|O_EXCL: exactly one process creates the file — the whole lock.
    const int fd = ::open(lock_path_.c_str(), O_CREAT | O_EXCL | O_WRONLY, 0644);
    if (fd < 0) return false;
    const std::string stamp = std::to_string(::getpid()) + "\n";
    const ssize_t written = ::write(fd, stamp.data(), stamp.size());
    (void)written;  // upstream tolerates a failed stamp (grace window covers it)
    fd_ = fd;
    acquired_ = true;
    return true;
}

bool FileBaton::wait() {
    while (true) {
        if (!fs::exists(lock_path_)) return true;  // holder released normally
        if (is_stale() && break_stale()) return false;  // caller redoes work
        const struct timespec ts = {0, static_cast<long>(wait_seconds_ * 1e9)};
        ::nanosleep(&ts, nullptr);
    }
}

void FileBaton::release() {
    if (fd_ >= 0) {
        ::close(fd_);
        fd_ = -1;
    }
    if (acquired_) {
        ::unlink(lock_path_.c_str());
        acquired_ = false;
    }
}

bool FileBaton::is_stale() {
    // A readable stamp: stale iff the owning pid is dead. A stamp-less lock
    // (crash between create and write): stale after the grace window.
    std::ifstream in(lock_path_);
    std::string line;
    if (std::getline(in, line) && !line.empty()) {
        char* end = nullptr;
        const long pid = std::strtol(line.c_str(), &end, 10);
        if (end != line.c_str()) return !pid_alive(static_cast<int>(pid));
    }
    std::error_code ec;
    const auto age = fs::last_write_time(lock_path_, ec).time_since_epoch().count();
    if (ec) return false;
    const auto now = fs::file_time_type::clock::now().time_since_epoch().count();
    return age <= 0 || now - age > static_cast<long long>(stale_grace_seconds_ * 1e9);
}

bool FileBaton::break_stale() {
    // unlink (not overwrite): the broken waiter re-runs the whole protocol.
    return ::unlink(lock_path_.c_str()) == 0;
}

JitResult jit_compile(const JitCacheConfig& config, const std::string& source,
                      const std::string& flags) {
    assert(config.compile);
    const std::string key = cache_key(source, flags, config.toolchain_version);
    const fs::path dir = fs::path(config.cache_dir) / key;
    const fs::path artifact = dir / "artifact";
    const fs::path sidecar = dir / "identity";
    const std::string identity = key + "\n" + flags + "\n";

    JitResult result;
    // Level 1: published artifact with a matching identity sidecar.
    if (fs::exists(artifact) && fs::exists(sidecar) && read_file(sidecar) == identity) {
        result.hit = true;
        result.artifact_path = artifact.string();
        return result;
    }

    // Miss: build under the baton (one builder per key machine-wide).
    fs::create_directories(dir);
    FileBaton baton((dir / "build.lock").string());
    while (!baton.try_acquire()) {
        result.stale_broken = !baton.wait();
        if (result.stale_broken) continue;  // nobody finished: rebuild
    }
    // Double-check after acquiring (the previous builder may have won).
    if (fs::exists(artifact) && fs::exists(sidecar) && read_file(sidecar) == identity) {
        result.hit = true;
        result.artifact_path = artifact.string();
        baton.release();
        return result;
    }
    if (!config.compile(artifact.string())) {
        baton.release();
        assert(false && "demo compile failure");
    }
    atomic_write(sidecar.string(), identity);
    baton.release();
    result.artifact_path = artifact.string();
    return result;
}

}  // namespace aiter_design
