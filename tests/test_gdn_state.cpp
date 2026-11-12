// SPDX-License-Identifier: Apache-2.0
// Tests for the GDN fwd_h host reference. The kernel's k/w/u are the
// PRE-SOLVED outputs of the upstream intra-chunk kernel (not raw k/v), so
// the tests validate the pinned inter-chunk recurrence itself: a hand-
// computed scalar case (including the delta-rule key-collision behavior),
// pure decay, a double-precision independent reference within accumulation
// bounds, initial-state seeding, and the exp2 path.
#include "aiter_ref/gdn_state.hpp"
#include "aiter_ref/rng.hpp"
#include "test_util.hpp"

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {

using aiter_ref::bf16_to_f32;
using aiter_ref::f32_to_bf16_rne;
using aiter_ref::kGdnBT;
using aiter_ref::kGdnK;
using aiter_ref::kGdnV;

std::uint16_t bf16_of(float v) { return f32_to_bf16_rne(v); }

void hand_case_key_collision() {
    // H starts at zero. Only element (0,0) is nonzero in k/w/u (=1), g = 0.
    // Chunk 0: snapshot 0, corr 0, vnew[0,0] = 1, gated 1 -> H[0,0] = 1.
    // Chunk 1: snapshot H[0,0]=1, corr[0,0] = w*k*H = 1, vnew[0,0] = 1-1 = 0
    // -> H stays 1: the delta rule cancels a repeated key/value pair.
    aiter_ref::GdnInputs in;
    in.k.assign(2 * kGdnBT * kGdnK, 0);
    in.w.assign(2 * kGdnBT * kGdnK, 0);
    in.u.assign(2 * kGdnBT * kGdnV, 0);
    in.g.assign(2 * kGdnBT, 0.0f);
    in.k[0 * kGdnK + 0] = bf16_of(1.0f);
    in.w[0 * kGdnK + 0] = bf16_of(1.0f);
    in.u[0 * kGdnV + 0] = bf16_of(1.0f);

    const auto out = aiter_ref::gdn_fwd_h(in, 2, /*save_new_value=*/true);
    // Chunk 0 snapshot all zero; H[0,0] = 1 after chunk 0.
    for (std::size_t i = 0; i < kGdnK * kGdnV; ++i) CHECK_EQ(out.snapshots[0][i], 0.0f);
    CHECK_NEAR(out.snapshots[1][0], 1.0f, 0.0f);
    CHECK_NEAR(out.final_state[0], 1.0f, 1e-7f);
    for (std::size_t i = 1; i < kGdnK * kGdnV; ++i) CHECK_NEAR(out.final_state[i], 0.0f, 0.0f);
    // v_new: token 0 value 1 in chunk 0, 0 in chunk 1 (cancelled).
    CHECK_NEAR(bf16_to_f32(out.v_new[0]), 1.0f, 0.0f);
    CHECK_NEAR(bf16_to_f32(out.v_new[kGdnBT * kGdnV + 0]), 0.0f, 0.0f);
}

void pure_decay_ladder() {
    // k = w = 0, u = 0: H only decays by exp(g_last) per chunk; snapshots
    // show the ladder exactly (same expf on both sides).
    aiter_ref::GdnInputs in;
    const std::size_t chunks = 3;
    in.k.assign(chunks * kGdnBT * kGdnK, 0);
    in.w.assign(chunks * kGdnBT * kGdnK, 0);
    in.u.assign(chunks * kGdnBT * kGdnV, 0);
    in.g.assign(chunks * kGdnBT, 0.0f);
    for (std::size_t c = 0; c < chunks; ++c)
        in.g[(c + 1) * kGdnBT - 1] = -0.5f * static_cast<float>(c + 1);
    std::vector<float> init(kGdnK * kGdnV);
    aiter_ref::Rng rng(0xDECA);
    for (float& v : init) v = rng.f32_sym();
    in.initial_state = init;

    const auto out = aiter_ref::gdn_fwd_h(in, chunks, false);
    std::vector<float> expect = init;
    for (std::size_t c = 0; c < chunks; ++c) {
        for (std::size_t i = 0; i < kGdnK * kGdnV; ++i) {
            CHECK_EQ(out.snapshots[c][i], bf16_to_f32(f32_to_bf16_rne(expect[i])));
            expect[i] *= std::exp(in.g[(c + 1) * kGdnBT - 1]);
        }
    }
    for (std::size_t i = 0; i < kGdnK * kGdnV; ++i) {
        CHECK_NEAR(out.final_state[i], expect[i], 1e-6f);
    }
}

// Independent double-precision reference for the first `upto` chunks;
// returns all snapshots (chunks+1 entries? no: one per chunk) and optionally
// the final state. Same quantization points, double accumulation.
struct DoubleRef {
    std::vector<std::vector<float>> snapshots;  // per chunk
    std::vector<float> final_state;
};

DoubleRef ref_double(const aiter_ref::GdnInputs& in, std::size_t num_chunks) {
    const std::size_t T = in.k.size() / kGdnK;
    std::vector<double> H(kGdnK * kGdnV, 0.0);
    if (in.initial_state.size() == kGdnK * kGdnV)
        for (std::size_t i = 0; i < kGdnK * kGdnV; ++i) H[i] = in.initial_state[i];
    DoubleRef out;
    for (std::size_t c = 0; c < num_chunks; ++c) {
        const std::size_t t0 = c * kGdnBT;
        const std::size_t bt = std::min(kGdnBT, T - t0);
        std::vector<float> snap(kGdnK * kGdnV);
        for (std::size_t i = 0; i < kGdnK * kGdnV; ++i)
            snap[i] = bf16_to_f32(f32_to_bf16_rne(static_cast<float>(H[i])));
        out.snapshots.push_back(snap);
        const double g_last = in.g[t0 + bt - 1];
        std::vector<double> corr(bt * kGdnV);
        for (std::size_t r = 0; r < bt; ++r)
            for (std::size_t v = 0; v < kGdnV; ++v) {
                double acc = 0.0;
                for (std::size_t k = 0; k < kGdnK; ++k)
                    acc += static_cast<double>(bf16_to_f32(in.w[(t0 + r) * kGdnK + k])) *
                           snap[k * kGdnV + v];
                corr[r * kGdnV + v] = acc;
            }
        std::vector<double> gated(bt * kGdnV);
        for (std::size_t r = 0; r < bt; ++r) {
            const double gscale = std::exp(g_last - in.g[t0 + r]);
            for (std::size_t v = 0; v < kGdnV; ++v) {
                // Same quantization point as the kernel: gated is bf16.
                const float g = static_cast<float>(
                    (static_cast<double>(bf16_to_f32(in.u[(t0 + r) * kGdnV + v])) -
                     corr[r * kGdnV + v]) * gscale);
                gated[r * kGdnV + v] = bf16_to_f32(f32_to_bf16_rne(g));
            }
        }
        const double decay = std::exp(g_last);
        for (std::size_t k = 0; k < kGdnK; ++k)
            for (std::size_t v = 0; v < kGdnV; ++v) {
                H[k * kGdnV + v] *= decay;
                double delta = 0.0;
                for (std::size_t r = 0; r < bt; ++r)
                    delta += static_cast<double>(bf16_to_f32(in.k[(t0 + r) * kGdnK + k])) *
                             gated[r * kGdnV + v];
                H[k * kGdnV + v] += delta;
            }
    }
    out.final_state.resize(kGdnK * kGdnV);
    for (std::size_t i = 0; i < kGdnK * kGdnV; ++i) out.final_state[i] = static_cast<float>(H[i]);
    return out;
}

aiter_ref::GdnInputs random_inputs(std::size_t chunks, std::size_t tail, std::uint64_t seed) {
    aiter_ref::Rng rng(seed);
    aiter_ref::GdnInputs in;
    const std::size_t T = chunks * kGdnBT + tail;
    in.k.resize(T * kGdnK);
    in.w.resize(T * kGdnK);
    in.u.resize(T * kGdnV);
    in.g.assign(T, 0.0f);
    for (std::size_t t = 0; t < T; ++t) {
        for (std::size_t k = 0; k < kGdnK; ++k) {
            in.k[t * kGdnK + k] = bf16_of(std::floor(rng.f32_sym() * 4.0f) / 4.0f);
            in.w[t * kGdnK + k] = bf16_of(std::floor(rng.f32_sym() * 4.0f) / 4.0f);
        }
        for (std::size_t v = 0; v < kGdnV; ++v)
            in.u[t * kGdnV + v] = bf16_of(std::floor(rng.f32_sym() * 4.0f) / 4.0f);
        in.g[t] = -0.02f * static_cast<float>(std::floor(rng.f32_unit() * 5.0));
    }
    return in;
}

void matches_double_reference_within_bounds() {
    // f32 accumulation (port) vs double accumulation (reference): drift is
    // bounded by eps * ops * the running state magnitude; the grid inputs
    // keep magnitudes tame. Tail chunk covered with tail=17.
    for (std::size_t tail : {std::size_t(0), std::size_t(17)}) {
        const std::size_t chunks = 2;
        const aiter_ref::GdnInputs in = random_inputs(chunks, tail, 0x6D4C + tail);
        const auto out = aiter_ref::gdn_fwd_h(in, chunks + (tail ? 1 : 0), true);
        const auto want = ref_double(in, chunks + (tail ? 1 : 0));

        double max_state = 1.0;
        for (float v : out.final_state) max_state = std::fmax(max_state, std::fabs(v));
        const double bound = 1.1920929e-07 * (chunks + 1) * (kGdnK + kGdnBT) * max_state;
        int bad = 0;
        double worst = 0.0;
        for (std::size_t i = 0; i < kGdnK * kGdnV; ++i) {
            const double diff = std::fabs(static_cast<double>(out.final_state[i]) -
                                          want.final_state[i]);
            if (diff > bound) ++bad;
            worst = std::fmax(worst, diff / bound);
        }
        std::printf("   [info] gdn double-ref (tail=%zu): worst err/bound = %.3f\n", tail,
                    worst);
        CHECK_EQ(bad, 0);
        // Snapshots are bf16 values whose inputs drifted by the f32-vs-
        // double accumulation: allow one bf16 ulp at each value's scale.
        auto bf16_ulp = [](double x) {
            x = std::fabs(x);
            if (x == 0) return 1e-30;
            int e;
            std::frexp(x, &e);
            return std::ldexp(1.0, e - 8);
        };
        for (std::size_t c = 0; c < out.snapshots.size(); ++c)
            for (std::size_t i = 0; i < kGdnK * kGdnV; ++i) {
                const double tol = 1.01 * bf16_ulp(want.snapshots[c][i]);
                CHECK(std::fabs(static_cast<double>(out.snapshots[c][i]) -
                                want.snapshots[c][i]) <= tol);
            }
    }
}

void initial_state_seeds_recurrence() {
    aiter_ref::GdnInputs in;
    in.k.assign(kGdnBT * kGdnK, 0);
    in.w.assign(kGdnBT * kGdnK, 0);
    in.u.assign(kGdnBT * kGdnV, 0);
    in.g.assign(kGdnBT, 0.0f);
    in.g[kGdnBT - 1] = -1.0f;
    std::vector<float> init(kGdnK * kGdnV, 2.0f);
    in.initial_state = init;
    const auto out = aiter_ref::gdn_fwd_h(in, 1, false);
    for (std::size_t i = 0; i < kGdnK * kGdnV; ++i) {
        CHECK_NEAR(out.final_state[i], 2.0f * std::exp(-1.0f), 1e-6f);
        CHECK_NEAR(out.snapshots[0][i], 2.0f, 0.0f);
    }
}

void exp2_path_agrees() {
    // use_exp2 = exp2(x*log2e): matches the expf path within a few ulp per
    // step across a multi-chunk run.
    const aiter_ref::GdnInputs base = random_inputs(2, 0, 0xE2F2);
    aiter_ref::GdnInputs a = base;
    a.use_exp2 = true;
    const auto out2 = aiter_ref::gdn_fwd_h(a, 2, false);
    const auto oute = aiter_ref::gdn_fwd_h(base, 2, false);
    double max_diff = 0.0;
    for (std::size_t i = 0; i < kGdnK * kGdnV; ++i)
        max_diff = std::fmax(max_diff,
                             std::fabs(static_cast<double>(out2.final_state[i]) -
                                       oute.final_state[i]));
    CHECK(max_diff < 1e-2);
}

}  // namespace

int main() {
    RUN_TEST(hand_case_key_collision);
    RUN_TEST(pure_decay_ladder);
    RUN_TEST(matches_double_reference_within_bounds);
    RUN_TEST(initial_state_seeds_recurrence);
    RUN_TEST(exp2_path_agrees);
    return finish();
}
