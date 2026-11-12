// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Design demo ported from ROCm/aiter's runtime-compilation cache
// (aiter/jit/core.py, aiter/jit/utils/jit_cache.py + file_baton.py @
// 1eab5ae12, MIT), reduced to a minimal self-contained C++17 library. See
// LICENSES/MIT.txt.
//
// The designs demonstrated (each maps to its upstream mechanism):
// - Content-addressed cache key: FNV-1a over (source, flags, toolchain
//   version) — upstream hashes source + flags + gfxname/toolchain into the
//   build directory name, so any input change forces a fresh build.
// - Identity sidecar: a published artifact carries a sidecar recording the
//   key; lookups verify the sidecar before trusting the artifact (upstream
//   compiled_kids_are_current / _artifact_identity).
// - Atomic publish: build into a temp file in the final directory, then
//   rename(2) — readers never observe a half-written artifact (upstream
//   atomic_copy).
// - FileBaton: cross-process single-builder lock. Atomic O_CREAT|O_EXCL
//   create; the lock file records the owning pid so waiters can detect a
//   crashed holder (dead pid, or a stamp-less lock older than the grace
//   window — the crash-between-create-and-write case) and BREAK it, then
//   re-acquire and REDO the work: a stale lock means nobody ever finished.
//   (upstream FileBaton, POSIX port; _pid_alive via kill(pid, 0)).
//
// Scope: the compile step is an injectable callable (the demo has no real
// compiler); hostname stamping is dropped (single-host demos); the blob
// staging/generation machinery and Windows pid probes are not ported.
#ifndef ROCM_DEMO_DESIGN_JIT_CACHE_HPP
#define ROCM_DEMO_DESIGN_JIT_CACHE_HPP

#include <cstdint>
#include <functional>
#include <string>

namespace aiter_design {

// FNV-1a 64-bit content hash (self-contained, stable across runs).
std::uint64_t fnv1a64(const std::string& data);

// The upstream cache key: hash of (source, flags, toolchain version).
std::string cache_key(const std::string& source, const std::string& flags,
                      const std::string& toolchain_version);

// POSIX FileBaton (file_baton.py). All methods are blocking except
// try_acquire.
class FileBaton {
public:
    FileBaton(std::string lock_path, double wait_seconds = 0.05,
              double stale_grace_seconds = 10.0);
    ~FileBaton();

    // Atomically create the lock file and stamp our pid. False if held.
    bool try_acquire();
    // Spin until the holder releases (true) or a stale lock is broken
    // (false — the caller must re-acquire and redo the work).
    bool wait();
    void release();

private:
    bool is_stale();
    bool break_stale();
    std::string lock_path_;
    double wait_seconds_;
    double stale_grace_seconds_;
    int fd_ = -1;
    bool acquired_ = false;
};

struct JitCacheConfig {
    std::string cache_dir;        // root: <cache_dir>/<key>/artifact
    std::string toolchain_version = "demo-1";
    // The "compiler": receives the artifact destination path; returns false
    // on failure. Must be idempotent-per-key under the baton.
    std::function<bool(const std::string& artifact_path)> compile;
};

struct JitResult {
    bool hit = false;             // true: no compile happened
    bool stale_broken = false;    // a crashed holder's lock was broken
    std::string artifact_path;
};

// Look up <cache_dir>/<key>/artifact (verifying the sidecar); on miss,
// build it under the file baton (one builder, others wait).
JitResult jit_compile(const JitCacheConfig& config, const std::string& source,
                      const std::string& flags);

}  // namespace aiter_design

#endif  // ROCM_DEMO_DESIGN_JIT_CACHE_HPP
