// SPDX-License-Identifier: Apache-2.0
// Tests for the dispatch design demo: tiered arch resolution, duplicate
// rejection, lazy binding with caching, and kernel-name codec errors.
#include "dispatch.hpp"
#include "test_util.hpp"

#include <string>
#include <vector>

namespace {

using aiter_design::DispatchError;
using aiter_design::OpRegistry;

template <typename Fn>
bool throws_dispatch(Fn&& fn) {
    try {
        fn();
        return false;
    } catch (const DispatchError&) {
        return true;
    }
}

OpRegistry::Impl tag_impl(const std::string& tag) {
    return [tag](const std::string& req, const std::string& cfg) {
        return tag + "(" + req + "," + cfg + ")";
    };
}

void tiered_resolution_chain() {
    OpRegistry r;
    r.register_impl("moe", "gfx942", tag_impl("specialized-942"));
    r.register_impl("moe", OpRegistry::kGenericTier, tag_impl("generic"));
    r.register_impl("moe", OpRegistry::kFallbackTier, tag_impl("fallback"));
    // Exact arch wins; any unknown arch lands on generic first — the
    // fallback tier only serves ops that lack a generic entry.
    CHECK(r.run("moe", "gfx942", "q", "cfg") == "specialized-942(q,cfg)");
    CHECK(r.run("moe", "gfx1030", "q", "cfg") == "generic(q,cfg)");
    CHECK(r.run("moe", "gfx9999", "q", "cfg") == "generic(q,cfg)");
    // No generic entry: the chain falls through to fallback.
    r.register_impl("rare", OpRegistry::kFallbackTier, tag_impl("fallback"));
    CHECK(r.run("rare", "gfx9999", "q", "cfg") == "fallback(q,cfg)");
}

void registration_order_within_tier() {
    OpRegistry r;
    r.register_impl("op", "gfx1030", tag_impl("first"));
    r.register_impl("op", "gfx1030-alt-tier", tag_impl("ignored"));
    // Two entries on the SAME tier key would be a duplicate; instead two
    // distinct arches both matching nothing fall to generic/fallback. The
    // documented rule: first registered per tier wins, so re-check exact.
    CHECK(r.run("op", "gfx1030", "x", "y") == "first(x,y)");
}

void duplicate_registration_rejected() {
    OpRegistry r;
    r.register_impl("op", "gfx942", tag_impl("a"));
    CHECK(throws_dispatch([&] { r.register_impl("op", "gfx942", tag_impl("b")); }));
    // Unknown op and no-candidate errors are distinct.
    CHECK(throws_dispatch([&] { (void)r.resolve("nope", "gfx942"); }));
    CHECK(throws_dispatch([&] { r.register_impl("lonely", "gfx942", tag_impl("x"));
                               (void)r.resolve("lonely", "gfx1030"); }));
}

void lazy_binding_resolves_once() {
    OpRegistry r;
    int resolver_calls = 0;
    r.set_resolver([&resolver_calls](const std::string& binding) -> OpRegistry::Impl {
        ++resolver_calls;
        if (binding == "broken:thing") return OpRegistry::Impl{};
        if (binding != "lib:fn") throw DispatchError("cannot import " + binding);
        return tag_impl("lazy");
    });
    r.register_lazy("op", "gfx1030", "lib:fn");
    r.register_lazy("bad", "gfx1030", "broken:thing");
    r.register_lazy("worse", "gfx1030", "unknown:place");
    CHECK(r.run("op", "gfx1030", "q", "c1") == "lazy(q,c1)");
    CHECK(r.run("op", "gfx1030", "q2", "c2") == "lazy(q2,c2)");
    CHECK_EQ(resolver_calls, 1);  // cached after first resolve
    CHECK(throws_dispatch([&] { (void)r.resolve("bad", "gfx1030"); }));
    CHECK(throws_dispatch([&] { (void)r.resolve("worse", "gfx1030"); }));
    CHECK_EQ(resolver_calls, 3);
}

void kernel_name_codec() {
    CHECK(OpRegistry::make_kernel_name("moe", "config-A") == "impl__moe__config-A");
    CHECK(throws_dispatch([&] { (void)OpRegistry::make_kernel_name("", "c"); }));
    CHECK(throws_dispatch([&] { (void)OpRegistry::make_kernel_name("a__b", "c"); }));

    const auto parsed = OpRegistry::parse_kernel_name("impl__moe__cfg__extra");
    CHECK(parsed.has_value());
    CHECK(parsed->first == "moe");
    CHECK(parsed->second == "cfg__extra");  // partition on the FIRST separator
    CHECK(!OpRegistry::parse_kernel_name("other__moe__c").has_value());  // no prefix
    CHECK(throws_dispatch([&] { (void)OpRegistry::parse_kernel_name("impl__moe"); }));
    CHECK(throws_dispatch([&] { (void)OpRegistry::parse_kernel_name("impl____cfg"); }));

    // Round trip feeds resolution: name+config select the bound impl.
    OpRegistry r;
    r.register_impl("moe", "gfx942", tag_impl("impl"));
    const auto [name, config] = *OpRegistry::parse_kernel_name(
        OpRegistry::make_kernel_name("moe", "deepseek"));
    CHECK(r.run(name, "gfx942", "req", config) == "impl(req,deepseek)");
}

void end_to_end_roster() {
    // The full pattern: per-arch specialized impls, one generic, one
    // fallback, one lazy — dispatched by hardware probe.
    OpRegistry r;
    const std::string arch = "gfx1030";  // imagine a runtime probe result
    r.register_impl("silu", "gfx942", tag_impl("mfma"));
    r.register_lazy("silu", OpRegistry::kFallbackTier, "torch:softsign");
    r.register_impl("norm", OpRegistry::kGenericTier, tag_impl("triton"));
    r.set_resolver([](const std::string&) { return tag_impl("torch"); });
    CHECK(r.run("silu", "gfx942", "x", "") == "mfma(x,)");
    CHECK(r.run("norm", "gfx1030", "x", "") == "triton(x,)");
    CHECK(r.run("silu", "gfx1030", "x", "") == "torch(x,)");  // no generic silu
    CHECK(r.run("silu", "gfx1201", "x", "") == "torch(x,)");
    (void)arch;
}

}  // namespace

int main() {
    RUN_TEST(tiered_resolution_chain);
    RUN_TEST(registration_order_within_tier);
    RUN_TEST(duplicate_registration_rejected);
    RUN_TEST(lazy_binding_resolves_once);
    RUN_TEST(kernel_name_codec);
    RUN_TEST(end_to_end_roster);
    return finish();
}
