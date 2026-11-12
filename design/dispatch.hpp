// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Design demo ported from ROCm/aiter's per-op dispatch machinery
// (aiter/fused_moe_registry.py @ 1eab5ae12 — name registry, duplicate
// rejection, `impl__<name>__<config>` kernel names, lazy "module:attr"
// binding; plus the arch-keyed capability tiering of the handwritten op
// routers), reduced to a minimal C++17 library. See LICENSES/MIT.txt.
//
// Designs demonstrated:
// - Name-based implementation registry: register(name, arch, impl);
//   registering a DIFFERENT impl under the same (name, arch) is rejected
//   (upstream ValueError), re-registering the identical entry is a no-op.
// - Capability-tier resolution: candidates are tried arch-exact first,
//   then the "generic" tier, then "fallback" — the specialized -> generic
//   -> fallback chain every aiter op router implements by hand. Within a
//   tier, registration order decides (deterministic).
// - Late binding: an implementation may be registered as a binding string
//   (upstream "module:attribute") resolved on first use through an
//   injectable resolver; resolution failures surface as DispatchError,
//   and the resolved impl is cached (upstream importlib.import_module +
//   getattr once).
// - Kernel-name encoding: make/parse `impl__<name>__<config>` — names must
//   be non-empty and contain no "__"; missing prefix parses to nothing
//   (upstream returns None), malformed suffixed names raise.
#ifndef ROCM_DEMO_DESIGN_DISPATCH_HPP
#define ROCM_DEMO_DESIGN_DISPATCH_HPP

#include <functional>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace aiter_design {

struct DispatchError : std::runtime_error {
    using std::runtime_error::runtime_error;
};

class OpRegistry {
public:
    // request in, result out; config is bound at resolution time.
    using Impl = std::function<std::string(const std::string& request, const std::string& config)>;

    // Registers fn under (name, arch). Re-registering the same (name,
    // arch) with a different target rejects with DispatchError; the same
    // target again is accepted (upstream allows the identical re-register).
    void register_impl(const std::string& name, const std::string& arch, Impl fn);
    // Late-bound variant: `binding` is resolved via the resolver on first
    // use (upstream "module:attribute" strings).
    void register_lazy(const std::string& name, const std::string& arch,
                       const std::string& binding);
    void set_resolver(std::function<Impl(const std::string& binding)> resolver) {
        resolver_ = std::move(resolver);
    }

    // impl__<name>__<config>. Empty names or embedded "__" reject.
    static std::string make_kernel_name(const std::string& name, const std::string& config);
    // nullopt when the prefix is absent; DispatchError when malformed.
    static std::optional<std::pair<std::string, std::string>> parse_kernel_name(
        const std::string& kernel_name);

    // Resolves the implementation for (name, arch) through the tiers
    // {arch, "generic", "fallback"}. Throws on unknown op, no candidate, or
    // lazy-binding failure. Non-const: lazy bindings cache in place.
    Impl resolve(const std::string& name, const std::string& arch);
    // resolve + call with bound config.
    std::string run(const std::string& name, const std::string& arch,
                    const std::string& request, const std::string& config);

    static constexpr const char* kGenericTier = "generic";
    static constexpr const char* kFallbackTier = "fallback";
    static constexpr const char* kKernelPrefix = "impl__";

private:
    struct Entry {
        std::string arch;
        Impl fn;             // direct impl, or the lazy cache once resolved
        std::string binding; // non-empty for lazy entries
    };
    Impl materialize(Entry& e);
    Entry* find_exact(const std::string& name, const std::string& arch);

    // name -> entries in registration order.
    std::vector<std::pair<std::string, std::vector<Entry>>> ops_;
    std::function<Impl(const std::string&)> resolver_;
};

}  // namespace aiter_design

#endif  // ROCM_DEMO_DESIGN_DISPATCH_HPP
