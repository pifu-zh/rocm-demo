// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
// Minimal C++ port of aiter's per-op dispatch designs; see the header.
#include "dispatch.hpp"

#include <cassert>

namespace aiter_design {

void OpRegistry::register_impl(const std::string& name, const std::string& arch, Impl fn) {
    assert(fn);
    for (auto& [op_name, entries] : ops_) {
        if (op_name != name) continue;
        for (auto& e : entries) {
            if (e.arch == arch) {
                // Same (name, arch): identical target re-register is a no-op,
                // a different one is a conflict (upstream ValueError).
                if (e.binding.empty() && e.fn) throw DispatchError("already registered: " + name);
                e.binding.clear();
                e.fn = std::move(fn);
                return;
            }
        }
        entries.push_back({arch, std::move(fn), {}});
        return;
    }
    ops_.push_back({name, {{arch, std::move(fn), {}}}});
}

void OpRegistry::register_lazy(const std::string& name, const std::string& arch,
                               const std::string& binding) {
    assert(!binding.empty());
    for (auto& [op_name, entries] : ops_) {
        if (op_name != name) continue;
        for (auto& e : entries) {
            if (e.arch == arch) {
                if (!e.binding.empty() && e.binding == binding) return;  // identical
                throw DispatchError("already registered: " + name);
            }
        }
        entries.push_back({arch, nullptr, binding});
        return;
    }
    ops_.push_back({name, {{arch, nullptr, binding}}});
}

std::string OpRegistry::make_kernel_name(const std::string& name, const std::string& config) {
    if (name.empty() || name.find("__") != std::string::npos) {
        throw DispatchError("invalid implementation name: " + name);
    }
    return std::string(kKernelPrefix) + name + "__" + config;
}

std::optional<std::pair<std::string, std::string>> OpRegistry::parse_kernel_name(
    const std::string& kernel_name) {
    // No prefix: not ours (upstream resolve returns None).
    const std::string prefix = kKernelPrefix;
    if (kernel_name.rfind(prefix, 0) != 0) return std::nullopt;
    const std::string rest = kernel_name.substr(prefix.size());
    const auto sep = rest.find("__");
    if (sep == std::string::npos || sep == 0) {
        throw DispatchError("invalid kernel name: " + kernel_name);
    }
    return std::make_pair(rest.substr(0, sep), rest.substr(sep + 2));
}

OpRegistry::Impl OpRegistry::materialize(Entry& e) {
    if (e.fn) return e.fn;
    if (!resolver_) throw DispatchError("no resolver for lazy binding: " + e.binding);
    e.fn = resolver_(e.binding);  // propagates the resolver's failures
    if (!e.fn) throw DispatchError("lazy binding not callable: " + e.binding);
    return e.fn;
}

OpRegistry::Entry* OpRegistry::find_exact(const std::string& name, const std::string& arch) {
    for (auto& [op_name, entries] : ops_) {
        if (op_name != name) continue;
        for (auto& e : entries) {
            if (e.arch == arch) return &e;
        }
    }
    return nullptr;
}

OpRegistry::Impl OpRegistry::resolve(const std::string& name, const std::string& arch) {
    // Capability tiers, in hand-written-router order: exact arch, generic,
    // fallback. Registration order decides within a tier.
    const std::string tiers[] = {arch, kGenericTier, kFallbackTier};
    for (const auto& tier : tiers) {
        if (Entry* e = find_exact(name, tier)) return materialize(*e);
    }
    const bool known = [&] {
        for (const auto& [op_name, entries] : ops_) {
            if (op_name == name) return true;
        }
        return false;
    }();
    if (!known) throw DispatchError("unknown op: " + name);
    throw DispatchError("no candidate for " + name + " on " + arch);
}

std::string OpRegistry::run(const std::string& name, const std::string& arch,
                            const std::string& request, const std::string& config) {
    return resolve(name, arch)(request, config);
}

}  // namespace aiter_design
