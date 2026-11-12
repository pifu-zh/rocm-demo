// SPDX-License-Identifier: Apache-2.0
// Tests for the rope host reference: the Python _apply_rotary_emb semantics
// (independent double-precision reference), the two-angle general form,
// nope_first slicing, positions indirection, uncached-vs-cached agreement,
// and the inverse-rotation identity.
#include "aiter_ref/rope.hpp"
#include "aiter_ref/rng.hpp"
#include "test_util.hpp"

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <vector>

namespace {

using aiter_ref::RotateStyle;

using AngleFn = std::function<double(std::size_t pos, std::size_t idx)>;

struct Table {
    std::vector<float> cos_tab, sin_tab;  // [max_pos, size_f]
    std::size_t size_f;
};

Table make_table(std::size_t max_pos, std::size_t size_f, const AngleFn& angle) {
    Table t;
    t.size_f = size_f;
    t.cos_tab.resize(max_pos * size_f);
    t.sin_tab.resize(max_pos * size_f);
    for (std::size_t p = 0; p < max_pos; ++p) {
        for (std::size_t i = 0; i < size_f; ++i) {
            t.cos_tab[p * size_f + i] = static_cast<float>(std::cos(angle(p, i)));
            t.sin_tab[p * size_f + i] = static_cast<float>(std::sin(angle(p, i)));
        }
    }
    return t;
}

double angle_at(const AngleFn& angle, std::size_t pos, std::size_t idx) { return angle(pos, idx); }

// Independent reference: the pair rotation in double, with the kernel's
// lane/table indexing (reuse -> one angle per pair, else per-lane angles).
std::vector<float> ref_rope(const std::vector<float>& in, std::size_t heads, std::size_t dim,
                            std::size_t size_f, const AngleFn& angle,
                            const std::vector<std::int32_t>& positions, RotateStyle style,
                            bool reuse, bool nope_first) {
    const std::size_t size_r = reuse ? 2 * size_f : size_f;
    const std::size_t half_r = size_r / 2;
    const std::size_t did_start = nope_first ? dim - size_r : 0;
    const std::size_t rows = positions.size();
    std::vector<float> out(in.size(), 0.0f);
    for (std::size_t r = 0; r < rows; ++r) {
        const std::size_t pos = static_cast<std::size_t>(positions[r]);
        for (std::size_t h = 0; h < heads; ++h) {
            float* o = out.data() + (r * heads + h) * dim;
            const float* x = in.data() + (r * heads + h) * dim;
            for (std::size_t p = 0; p < half_r; ++p) {
                double th0, th1;
                if (reuse) {
                    th0 = th1 = angle_at(angle, pos, p);
                } else if (style == RotateStyle::NeoX) {
                    th0 = angle_at(angle, pos, p);
                    th1 = angle_at(angle, pos, p + half_r);
                } else {
                    th0 = angle_at(angle, pos, 2 * p);
                    th1 = angle_at(angle, pos, 2 * p + 1);
                }
                std::size_t lane0, lane1;
                if (style == RotateStyle::NeoX) {
                    lane0 = did_start + p;
                    lane1 = lane0 + half_r;
                } else {
                    lane0 = did_start + 2 * p;
                    lane1 = lane0 + 1;
                }
                o[lane0] = static_cast<float>(x[lane0] * std::cos(th0) - x[lane1] * std::sin(th0));
                o[lane1] = static_cast<float>(x[lane1] * std::cos(th1) + x[lane0] * std::sin(th1));
            }
            const std::size_t ns = nope_first ? 0 : size_r;
            const std::size_t ne = nope_first ? dim - size_r : dim;
            for (std::size_t d = ns; d < ne; ++d) o[d] = x[d];
        }
    }
    return out;
}

void compare_near(const std::vector<float>& got, const std::vector<float>& want, float tol) {
    CHECK_EQ(got.size(), want.size());
    for (std::size_t i = 0; i < want.size() && i < got.size(); ++i) {
        CHECK_NEAR(got[i], want[i], tol);
    }
}

struct Shape {
    std::size_t rows, hx, hy, dim;
};

// Fills shapes + grid-quantized inputs and known angles.
struct Fixture {
    Shape shape;
    std::vector<float> x, y;
    AngleFn angle;
    std::vector<std::int32_t> positions;
    Fixture(std::size_t rows_, std::size_t hx, std::size_t hy, std::size_t dim,
            std::uint64_t seed)
        : shape{rows_, hx, hy, dim} {
        aiter_ref::Rng rng(seed);
        x.resize(rows_ * hx * dim);
        for (float& v : x) v = std::floor(rng.f32_sym() * 100.0f) / 100.0f;
        y.resize(rows_ * hy * dim);
        for (float& v : y) v = std::floor(rng.f32_sym() * 100.0f) / 100.0f;
        positions.resize(rows_);
        for (std::size_t r = 0; r < rows_; ++r) positions[r] = static_cast<std::int32_t>(r % 7);
        angle = [](std::size_t pos, std::size_t idx) {
            return 0.1 * static_cast<double>(pos) + 0.37 * static_cast<double>(idx) + 0.05;
        };
    }
    std::size_t rows() const { return shape.rows; }
};

void both_styles_match_reference_reuse() {
    const std::size_t dim = 16;
    for (RotateStyle style : {RotateStyle::NeoX, RotateStyle::GptJ}) {
        Fixture f(5, 3, 2, dim, 0xA11CE);
        const std::size_t size_f = dim / 2;  // reuse: size_r == dim
        Table t = make_table(7, size_f, f.angle);
        auto got = aiter_ref::rope_cached_positions_2c_fwd(
            f.x, f.y, f.shape.hx, f.shape.hy, dim, size_f, t.cos_tab, t.sin_tab, f.positions,
            style, /*reuse=*/true, /*nope_first=*/false);
        compare_near(got.out_x, ref_rope(f.x, f.shape.hx, dim, size_f, f.angle, f.positions,
                                         style, true, false),
                     1e-4f);
        compare_near(got.out_y, ref_rope(f.y, f.shape.hy, dim, size_f, f.angle, f.positions,
                                         style, true, false),
                     1e-4f);
    }
}

void non_reuse_two_angles_match_reference() {
    const std::size_t dim = 12;
    for (RotateStyle style : {RotateStyle::NeoX, RotateStyle::GptJ}) {
        Fixture f(4, 2, 4, dim, 0xB0B);
        const std::size_t size_f = dim;  // non-reuse: table width == rotate width
        Table t = make_table(7, size_f, f.angle);
        auto got = aiter_ref::rope_cached_positions_2c_fwd(
            f.x, f.y, f.shape.hx, f.shape.hy, dim, size_f, t.cos_tab, t.sin_tab, f.positions,
            style, /*reuse=*/false, /*nope_first=*/false);
        compare_near(got.out_x, ref_rope(f.x, f.shape.hx, dim, size_f, f.angle, f.positions,
                                         style, false, false),
                     1e-4f);
    }
}

void nope_first_slices_the_tail() {
    // dim 16, rotate width 8: nope_first=false rotates [0,8); =true rotates
    // [8,16) and copies [0,8) verbatim.
    Fixture f(3, 2, 2, 16, 0x1001);
    const std::size_t size_f = 4;  // reuse -> size_r = 8
    Table t = make_table(7, size_f, f.angle);
    const auto fwd = aiter_ref::rope_cached_positions_2c_fwd(
        f.x, f.y, f.shape.hx, f.shape.hy, 16, size_f, t.cos_tab, t.sin_tab, f.positions,
        RotateStyle::NeoX, true, /*nope_first=*/false);
    const auto tail = aiter_ref::rope_cached_positions_2c_fwd(
        f.x, f.y, f.shape.hx, f.shape.hy, 16, size_f, t.cos_tab, t.sin_tab, f.positions,
        RotateStyle::NeoX, true, /*nope_first=*/true);
    for (std::size_t r = 0; r < f.rows(); ++r) {
        for (std::size_t h = 0; h < f.shape.hx; ++h) {
            const float* in = f.x.data() + (r * f.shape.hx + h) * 16;
            const float* o_f = fwd.out_x.data() + (r * f.shape.hx + h) * 16;
            const float* o_t = tail.out_x.data() + (r * f.shape.hx + h) * 16;
            for (std::size_t d = 0; d < 8; ++d) {
                CHECK_EQ(o_f[d + 8], in[d + 8]);  // front rotates: tail copied
                CHECK_EQ(o_t[d], in[d]);          // tail rotates: front copied
            }
        }
    }
    // And the tail-rotated slice equals the reference.
    compare_near(tail.out_x, ref_rope(f.x, f.shape.hx, 16, size_f, f.angle, f.positions,
                                      RotateStyle::NeoX, true, true),
                 1e-4f);
}

void positions_select_the_table_row() {
    Fixture f(4, 2, 2, 8, 0x9999);
    const std::size_t size_f = 4;
    Table t = make_table(7, size_f, f.angle);
    auto got = aiter_ref::rope_cached_positions_2c_fwd(
        f.x, f.y, f.shape.hx, f.shape.hy, 8, size_f, t.cos_tab, t.sin_tab, f.positions,
        RotateStyle::NeoX, true, false);
    CHECK(f.rows() >= 3);
    // Duplicate rows with equal positions must rotate identically: build a
    // second input where row 2 copies row 0, positions[2] == positions[0].
    std::vector<float> x2 = f.x;
    const std::size_t hx8 = f.shape.hx * 8;
    for (std::size_t i = 0; i < hx8; ++i) x2[2 * hx8 + i] = x2[0 * hx8 + i];
    std::vector<std::int32_t> pos2 = {0, 1, 0, 2};
    auto dup = aiter_ref::rope_cached_positions_2c_fwd(
        x2, f.y, f.shape.hx, f.shape.hy, 8, size_f, t.cos_tab, t.sin_tab, pos2,
        RotateStyle::NeoX, true, false);
    for (std::size_t i = 0; i < hx8; ++i) {
        CHECK_EQ(dup.out_x[0 * hx8 + i], dup.out_x[2 * hx8 + i]);
    }
    // A different position yields a different rotation (angles differ).
    std::vector<std::int32_t> pos_other = {1, 1, 1, 1};
    auto got1 = aiter_ref::rope_cached_positions_2c_fwd(
        f.x, f.y, f.shape.hx, f.shape.hy, 8, size_f, t.cos_tab, t.sin_tab, pos_other,
        RotateStyle::NeoX, true, false);
    int diffs = 0;
    for (std::size_t i = 0; i < got1.out_x.size(); ++i) {
        if (got1.out_x[i] != got.out_x[i]) ++diffs;
    }
    CHECK(diffs > 0);
}

void uncached_matches_cached_tables() {
    // Uncached computes cos/sin(freqs) in float; precomputing the same
    // freqs into tables must agree within float sincos tolerance.
    Fixture f(4, 2, 3, 12, 0xC05C);
    const std::size_t size_f = 12;  // non-reuse: freqs row width == rotate width
    std::vector<float> freqs(f.rows() * size_f);
    for (std::size_t r = 0; r < f.rows(); ++r) {
        for (std::size_t i = 0; i < size_f; ++i)
            freqs[r * size_f + i] = static_cast<float>(f.angle(r, i));
    }
    auto unc = aiter_ref::rope_uncached_2c_fwd(f.x, f.y, f.shape.hx, f.shape.hy, 12, size_f,
                                               freqs, RotateStyle::NeoX, false, false);
    // Identity positions + per-row tables == the uncached path.
    std::vector<float> cos_tab, sin_tab;
    for (std::size_t r = 0; r < f.rows(); ++r) {
        for (std::size_t i = 0; i < size_f; ++i) {
            cos_tab.push_back(std::cos(freqs[r * size_f + i]));
            sin_tab.push_back(std::sin(freqs[r * size_f + i]));
        }
    }
    // Build per-row tables as one [rows, size_f] table and identity positions.
    std::vector<std::int32_t> ident(f.rows());
    for (std::size_t r = 0; r < f.rows(); ++r) ident[r] = static_cast<std::int32_t>(r);
    auto cached = aiter_ref::rope_cached_positions_2c_fwd(
        f.x, f.y, f.shape.hx, f.shape.hy, 12, size_f, cos_tab, sin_tab, ident, RotateStyle::NeoX,
        false, false);
    compare_near(unc.out_x, cached.out_x, 1e-5f);
    compare_near(unc.out_y, cached.out_y, 1e-5f);
}

void quarter_turn_hand_case() {
    // theta = pi/2 rotates each pair (a, b) -> (-b, a). The styles differ in
    // pairing: NEOX pairs (0,2)/(1,3), GPT-J pairs (0,1)/(2,3) — pinned both.
    const std::size_t dim = 4, size_f = 2;
    Table t = make_table(1, size_f, [](std::size_t, std::size_t) { return 1.57079632679; });
    std::vector<float> x = {1, 2, 3, 4};
    std::vector<std::int32_t> pos = {0};
    const auto neox = aiter_ref::rope_cached_positions_1c_fwd(
        x, 1, dim, size_f, t.cos_tab, t.sin_tab, pos, RotateStyle::NeoX, true, false);
    CHECK_NEAR(neox[0], -3.0f, 1e-6f);
    CHECK_NEAR(neox[1], -4.0f, 1e-6f);
    CHECK_NEAR(neox[2], 1.0f, 1e-6f);
    CHECK_NEAR(neox[3], 2.0f, 1e-6f);
    const auto gptj = aiter_ref::rope_cached_positions_1c_fwd(
        x, 1, dim, size_f, t.cos_tab, t.sin_tab, pos, RotateStyle::GptJ, true, false);
    CHECK_NEAR(gptj[0], -2.0f, 1e-6f);
    CHECK_NEAR(gptj[1], 1.0f, 1e-6f);
    CHECK_NEAR(gptj[2], -4.0f, 1e-6f);
    CHECK_NEAR(gptj[3], 3.0f, 1e-6f);
}

void inverse_rotation_restores_input() {
    Fixture f(3, 2, 2, 12, 0xF00D);
    const std::size_t size_f = 6;
    Table t = make_table(7, size_f, f.angle);
    AngleFn neg = [&f](std::size_t pos, std::size_t idx) { return -f.angle(pos, idx); };
    Table tn = make_table(7, size_f, neg);
    auto fwd = aiter_ref::rope_cached_positions_2c_fwd(
        f.x, f.y, f.shape.hx, f.shape.hy, 12, size_f, t.cos_tab, t.sin_tab, f.positions,
        RotateStyle::GptJ, true, false);
    auto back = aiter_ref::rope_cached_positions_2c_fwd(
        fwd.out_x, fwd.out_y, f.shape.hx, f.shape.hy, 12, size_f, tn.cos_tab, tn.sin_tab,
        f.positions, RotateStyle::GptJ, true, false);
    compare_near(back.out_x, f.x, 1e-3f);
    compare_near(back.out_y, f.y, 1e-3f);
}

void one_channel_matches_two_channel() {
    Fixture f(3, 4, 2, 10, 0x777);
    const std::size_t size_f = 5;  // reuse, size_r = 10
    Table t = make_table(7, size_f, f.angle);
    auto two = aiter_ref::rope_cached_positions_2c_fwd(
        f.x, f.y, f.shape.hx, f.shape.hy, 10, size_f, t.cos_tab, t.sin_tab, f.positions,
        RotateStyle::NeoX, true, false);
    auto one_x = aiter_ref::rope_cached_positions_1c_fwd(
        f.x, f.shape.hx, 10, size_f, t.cos_tab, t.sin_tab, f.positions, RotateStyle::NeoX, true,
        false);
    auto one_y = aiter_ref::rope_cached_positions_1c_fwd(
        f.y, f.shape.hy, 10, size_f, t.cos_tab, t.sin_tab, f.positions, RotateStyle::NeoX, true,
        false);
    CHECK_VEC_EQ(two.out_x, one_x);
    CHECK_VEC_EQ(two.out_y, one_y);
}

}  // namespace

int main() {
    RUN_TEST(both_styles_match_reference_reuse);
    RUN_TEST(non_reuse_two_angles_match_reference);
    RUN_TEST(nope_first_slices_the_tail);
    RUN_TEST(positions_select_the_table_row);
    RUN_TEST(uncached_matches_cached_tables);
    RUN_TEST(quarter_turn_hand_case);
    RUN_TEST(inverse_rotation_restores_input);
    RUN_TEST(one_channel_matches_two_channel);
    return finish();
}
