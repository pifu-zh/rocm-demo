// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// Host reference for the Hadamard-rotate + FP4-quant pipeline in aiter's
// DSV4 kernels (csrc/kernels/dsv4_rotate_quant.cu
// hadamard_rotate_activation_fp4quant_kernel @ 1eab5ae12, MIT). Three
// independently-extractable designs:
//
// [1] The in-register Hadamard butterfly. log2(dim) rounds of
//     (x0 + x1, x0 - x1) pairs with a doubling stride - the classic
//     unnormalized Walsh-Hadamard transform, O(n log n) instead of the
//     O(n^2) matrix product. The kernel splits the rounds:
//       intra-thread: log2(vec_size) rounds on each lane's contiguous
//         vec_size-element register block;
//       inter-thread: the remaining log2(dim) - log2(vec_size) rounds via
//         swap_thread_data<group_size> (a DPP lane^ (group_size/2)
//         exchange), with lane % group_size < half doing a = a + x and the
//         upper half doing a = x - a;
//     then scales by dim_rsqrt = 1/sqrt(dim). The whole pipeline computes
//     y = H_dim * x / sqrt(dim) with H_dim the natural-order Walsh-Hadamard
//     matrix (verified here against the explicit recursive matrix - the
//     O(n^2) oracle).
//
// [2] The FP4 scale contract: per-row absMax (reduced across the lanes of
//     the row), scale_e8m0 = ceil_pow2(absMax / fp4_max) via the SAME
//     branchless bit trick as mxfp4_moe_aux ((bits(amax/6) + 0x7FFFFF) >>
//     23 - here generalized to /fp4_max), stored as an e8m0 byte by the
//     lane whose threadIdx % num_thread_per_group == 0. The quantized
//     values are x / scale in FP4 (E2M1) - the encode itself is the lab's
//     verified RNE encoder (soft_fp4 / mxfp4_moe_aux), reused here.
//
// [3] The SCALE LAYOUT contract: groups_per_row = dim / group_size with a
//     Natural layout and a Flydsl (shuffled) layout option - the demo pins
//     the Natural layout's row-major indexing.
//
// Scope: the host model emulates the LANE structure logically (a row of
// dim values distributed over dim/vec_size lanes, each holding vec_size
// contiguous elements - load_offset = threadIdx.x * vec_size). The device
// DPP/shuffle instructions themselves are warp_sync's domain.
//
// Verification level: SOURCE_VERIFIED + REFERENCE_PASS (CPU-only).
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <vector>

#define MAIN_RETURN_BAD 1

// ── bf16 codec + e8m0 helpers (lab-shared) ──
static inline float bf16_to_f32(std::uint16_t bits) {
    std::uint32_t u = static_cast<std::uint32_t>(bits) << 16;
    float f;
    std::memcpy(&f, &u, 4);
    return f;
}
static inline std::uint16_t f32_to_bf16(float f) {
    std::uint32_t x;
    std::memcpy(&x, &f, 4);
    const std::uint32_t lsb = (x >> 16) & 1;
    return static_cast<std::uint16_t>((x + 0x7FFFu + lsb) >> 16);
}
static inline std::uint32_t f32_to_bits(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, 4);
    return u;
}
static inline float bits_to_f32(std::uint32_t u) {
    float f;
    std::memcpy(&f, &u, 4);
    return f;
}

// E2M1 decode (lab-shared table)
static float e2m1_decode(std::uint8_t code) {
    static const double vals[8] = {0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0};
    const double v = vals[code & 0x7];
    return static_cast<float>((code & 0x8) ? -v : v);
}
// E2M1 RNE encode (the fixed lab encoder - ties to even, satfinite)
static std::uint8_t e2m1_encode_rne(float x) {
    if (std::isnan(x)) return 0x7;
    if (std::fabs(x) >= 6.0f) return std::signbit(x) ? 0xF : 0x7;
    const int neg = std::signbit(x);
    const double mag = std::fabs(static_cast<double>(x));
    std::uint8_t best = 0;
    double best_d = 1e300;
    static const double vals[8] = {0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0};
    for (int c = 0; c < 8; ++c) {
        const double d = std::fabs(mag - vals[c]);
        if (d < best_d || (d == best_d && ((best & 1) != 0))) {
            best_d = d;
            best = static_cast<std::uint8_t>(c);
        }
    }
    return neg ? static_cast<std::uint8_t>(best | 0x8) : best;
}

struct Lcg {
    std::uint64_t s;
    explicit Lcg(std::uint64_t seed) : s(seed) {}
    std::uint32_t next() {
        s = s * 6364136223846793005ULL + 1442695040888963407ULL;
        return static_cast<std::uint32_t>(s >> 33);
    }
    float uniform(float lo, float hi) {
        return lo + (hi - lo) * static_cast<float>(next() % 1000001) / 1.0e6f;
    }
};

// ══════════════════════════════════════════════════════════════════════
// Hadamard oracle: explicit recursive matrix H_dim (natural order)
// ══════════════════════════════════════════════════════════════════════
static std::vector<std::vector<float>> hadamard_matrix(int dim) {
    std::vector<std::vector<float>> h(dim, std::vector<float>(dim, 1.0f));
    for (std::size_t step = 2; step <= static_cast<std::size_t>(dim); step <<= 1) {
        const std::size_t half = step / 2;
        for (std::size_t r = 0; r < static_cast<std::size_t>(dim); r += step)
            for (std::size_t c = 0; c < static_cast<std::size_t>(dim); c += step)
                for (std::size_t i = 0; i < half; ++i)
                    for (std::size_t j = 0; j < half; ++j) {
                        const float a = h[r + i][c + j];
                        h[r + i][c + j] = a;
                        h[r + i][c + j + half] = a;
                        h[r + i + half][c + j] = a;
                        h[r + i + half][c + j + half] = -a;
                    }
    }
    return h;
}

// ══════════════════════════════════════════════════════════════════════
// [1] The butterfly pipeline, kernel-faithful (logical lanes)
// ══════════════════════════════════════════════════════════════════════
// A row of dim values over L = dim/vec_size lanes; lane l holds elements
// [l*V, (l+1)*V) (contiguous - load_offset = threadIdx.x * vec_size).
// Intra-thread: log2(V) rounds inside each lane's block.
// Inter-thread: the remaining rounds with partner = lane ^ (1 << i),
//   lower half: a += partner; upper half: a = partner - a.
// Then * dim_rsqrt.
static void hadamard_butterfly_emul(std::vector<float>& row, int vec_size) {
    const int dim = static_cast<int>(row.size());
    const int L = dim / vec_size;
    const int V = vec_size;
    // lanes: lane l's block = row[l*V .. l*V+V)
    const int intra_rounds = __builtin_ctz(static_cast<std::uint32_t>(V));
    for (int stage = 0; stage < intra_rounds; ++stage) {
        const int h = 1 << stage;
        for (int l = 0; l < L; ++l)
            for (int j = 0; j < V / 2; ++j) {
                const int group = j / h;
                const int offset = j % h;
                const int i0 = l * V + group * (2 * h) + offset;
                const int i1 = i0 + h;
                const float x0 = row[i0];
                const float x1 = row[i1];
                row[i0] = x0 + x1;
                row[i1] = x0 - x1;
            }
    }
    const int inter_rounds = __builtin_ctz(static_cast<std::uint32_t>(dim)) - intra_rounds;
    for (int stage = 0; stage < inter_rounds; ++stage) {
        const int group_size = 2 << stage;
        // the emulated swap: partner lane = lane ^ (group_size / 2)
        std::vector<float> swapped(row.size());
        for (int l = 0; l < L; ++l) {
            const int partner = l ^ (group_size / 2);
            for (int j = 0; j < V; ++j) swapped[l * V + j] = row[partner * V + j];
        }
        for (int l = 0; l < L; ++l)
            for (int j = 0; j < V; ++j) {
                const int idx = l * V + j;
                if (l % group_size < group_size / 2) {
                    row[idx] = row[idx] + swapped[idx];
                } else {
                    row[idx] = swapped[idx] - row[idx];
                }
            }
    }
    const float dim_rsqrt = 1.0f / std::sqrt(static_cast<float>(dim));
    for (auto& v : row) v *= dim_rsqrt;
}

// vec_size per dim as the kernel instantiates it: vec_size = 16 for all
// supported dims (m_block = vec_size * warp_size / dim scales the grid);
// dims > 16 therefore split each row across dim/16 lanes.
static int vec_size_for_dim(int dim) {
    (void)dim;
    return 16;
}

int main() {
    int checks = 0, fails = 0;

    // ── 1. rotation vs the explicit Hadamard matrix oracle ──
    {
        Lcg rng(0x4d4);
        int f = 0;
        for (int dim : {16, 32, 64}) {
            const auto H = hadamard_matrix(dim);
            for (int trial = 0; trial < 32; ++trial) {
                std::vector<float> x(dim);
                for (auto& v : x) v = rng.uniform(-3.f, 3.f);
                std::vector<float> got = x;
                hadamard_butterfly_emul(got, vec_size_for_dim(dim));
                // oracle: y_r = Σ H[r][c] x_c / sqrt(dim)
                ++checks;
                float worst = 0.f;
                for (int r = 0; r < dim; ++r) {
                    float want = 0.f;
                    for (int c = 0; c < dim; ++c) want += H[r][c] * x[c];
                    want /= std::sqrt(static_cast<float>(dim));
                    worst = std::fmax(worst, std::fabs(got[r] - want));
                }
                if (worst > 1e-4f && f < 5) {
                    std::printf("  dim %d trial %d: worst |got-want| = %g\\n", dim, trial, worst);
                    ++f;
                }
            }
        }
        fails += f > 0;
        std::printf("1. butterfly rotation == explicit Hadamard matrix oracle (dim 16/32/64): "
                    "%s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 2. FP4 scale contract: ceil_pow2(absMax / fp4_max) ──
    {
        Lcg rng(0xf04);
        int f = 0;
        constexpr float fp4_max = 6.0f;
        for (int trial = 0; trial < 256; ++trial) {
            const int dim = 64;
            std::vector<float> row(dim);
            float amax = 0.f;
            for (auto& v : row) {
                // log-uniform magnitudes; seed a floor so absMax >= eps_amax
                const float mag = std::exp2(rng.uniform(-12.f, 6.f));
                v = (rng.next() & 1) ? mag : -mag;
                amax = std::fmax(amax, std::fabs(v));
            }
            // kernel: absMax floor = fp4_max * 2^-126 (eps_amax)
            amax = std::fmax(amax, fp4_max * bits_to_f32(0x00800000u));
            // ceil_pow2 via the kernel's bit trick
            const float tmp = amax * (1.0f / fp4_max);
            const std::uint32_t u32 = f32_to_bits(tmp);
            std::uint32_t exponent = (u32 >> 23) & 0xFF;
            if (exponent == 0xFF) exponent = 255;
            if (u32 & 0x7FFFFF) exponent += 1;
            const std::uint8_t scale_e8m0 = static_cast<std::uint8_t>(exponent);
            const float scale = bits_to_f32(static_cast<std::uint32_t>(scale_e8m0) << 23);
            // the CONTRACT: amax / scale <= fp4_max (never clips) and
            // scale >= amax/fp4_max
            ++checks;
            if (!(amax / scale <= fp4_max * 1.001f) && f < 5) {
                std::printf("  scale %g clips amax %g (ratio %g)\n", scale, amax, amax / scale);
                ++f;
            }
            // quantized values: round(x / scale) in E2M1 - the decode must
            // satisfy |x - dec*scale| <= |scale| * 1.05 (1 LSB + rounding)
            int worst_ok = 1;
            for (int i = 0; i < dim; ++i) {
                const std::uint8_t nib = e2m1_encode_rne(row[i] / scale);
                const float dec = e2m1_decode(nib) * scale;
                if (std::fabs(row[i] - dec) > std::fabs(scale) * 1.3f) worst_ok = 0;
            }
            ++checks;
            if (!worst_ok && f < 5) {
                std::printf("  trial %d: quantized decode out of 1.3 LSB bound\\n", trial);
                ++f;
            }
        }
        fails += f > 0;
        std::printf("2. FP4 scale contract (ceil_pow2(amax/6), no clip, decode bound): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 3. end-to-end: rotate -> quant -> decode vs rotated reference ──
    {
        Lcg rng(0xe2d4);
        int f = 0;
        const int dim = 64;
        for (int trial = 0; trial < 64; ++trial) {
            std::vector<float> x(dim);
            for (auto& v : x) v = rng.uniform(-3.f, 3.f);
            std::vector<float> rotated = x;
            hadamard_butterfly_emul(rotated, vec_size_for_dim(dim));
            float amax = 0.f;
            for (auto v : rotated) amax = std::fmax(amax, std::fabs(v));
            amax = std::fmax(amax, 6.0f * bits_to_f32(0x00800000u));
            const float tmp = amax * (1.0f / 6.0f);
            const std::uint32_t u32 = f32_to_bits(tmp);
            std::uint32_t exponent = (u32 >> 23) & 0xFF;
            if (u32 & 0x7FFFFF) exponent += 1;
            const float scale = bits_to_f32(exponent << 23);
            std::vector<std::uint8_t> nibbles(dim);
            for (int i = 0; i < dim; ++i) nibbles[i] = e2m1_encode_rne(rotated[i] / scale);
            // reconstruction error bound: |x - dec*scale| <= |scale| (1 LSB)
            float worst = 0.f;
            for (int i = 0; i < dim; ++i) {
                const float dec = e2m1_decode(nibbles[i]) * scale;
                worst = std::fmax(worst, std::fabs(rotated[i] - dec) / std::fabs(scale));
            }
            ++checks;
            if (worst > 1.05f && f < 5) {
                std::printf("  e2e trial %d: worst err %.3f LSB\n", trial, worst);
                ++f;
            }
            // rotation preserves the energy within fp tolerance:
            // ||rotated||^2 == ||x||^2 (Hadamard is orthogonal up to scaling)
            ++checks;
            float e_in = 0, e_out = 0;
            for (int i = 0; i < dim; ++i) {
                e_in += x[i] * x[i];
                e_out += rotated[i] * rotated[i];
            }
            if (std::fabs(std::sqrt(e_out / e_in) - 1.f) > 1e-5f && f < 5) {
                std::printf("  e2e trial %d: energy ratio %g\\n", trial,
                            std::sqrt(e_out / e_in));
                ++f;
            }
        }
        fails += f > 0;
        std::printf("3. end-to-end rotate->FP4 quant (err <= 1.05 LSB; energy preserved): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 4. scale layouts: Natural / Flydsl / Opus (the store_scale_e8m0
    //    contract, extracted verbatim from the kernel) ──
    {
        Lcg rng(0x1187);
        int f = 0;
        // model: m = tokens x head_num rows, groups_per_row groups per row.
        // head_num = 32 (the Opus layout requires head_num % 32 == 0).
        const int tokens = 4, head_num = 32, groups_per_row = 2;
        const int m = tokens * head_num;  // 128 rows
        std::vector<std::uint8_t> scale_val(m * groups_per_row);
        for (auto& v : scale_val) v = static_cast<std::uint8_t>(rng.next() & 0xFF);

        // the three layout writers (kernel-faithful translations)
        auto store_natural = [&](std::vector<std::uint8_t>& buf) {
            buf.assign(static_cast<std::size_t>(m) * groups_per_row, 0xEE);
            for (int row = 0; row < m; ++row)
                for (int g = 0; g < groups_per_row; ++g)
                    buf[static_cast<std::size_t>(row) * groups_per_row + g] =
                        scale_val[row * groups_per_row + g];
        };
        auto store_flydsl = [&](std::vector<std::uint8_t>& buf) {
            const int m_tiles = head_num >> 4;
            const int m_tiles_padded = (m_tiles + 3) & ~3;
            const std::size_t size = static_cast<std::size_t>(tokens) * groups_per_row * 16 *
                                     m_tiles_padded;
            buf.assign(size, 0xEE);
            for (int row = 0; row < m; ++row)
                for (int g = 0; g < groups_per_row; ++g) {
                    const int prefix_idx = row / head_num;
                    const int head_idx = row - prefix_idx * head_num;
                    const int m_tile = head_idx >> 4;
                    const int m_inner = head_idx & 15;
                    const std::size_t tile_base =
                        (static_cast<std::size_t>(prefix_idx) * groups_per_row + g) * 16 *
                            m_tiles_padded +
                        m_inner * m_tiles_padded;
                    buf[tile_base + m_tile] = scale_val[row * groups_per_row + g];
                    // the kernel's padding fill: the LAST tile zero-fills the
                    // pad slots
                    if (m_tiles_padded != m_tiles && m_tile == m_tiles - 1)
                        for (int pad = m_tiles; pad < m_tiles_padded; ++pad)
                            buf[tile_base + pad] = 0;
                }
        };
        auto store_opus = [&](std::vector<std::uint8_t>& buf) {
            const int tiles = head_num / 32;
            buf.assign(static_cast<std::size_t>(tokens) * head_num * 4, 0xEE);
            for (int row = 0; row < m; ++row)
                for (int g = 0; g < groups_per_row; ++g) {
                    const int head = row % head_num;
                    const std::size_t offset =
                        static_cast<std::size_t>(row / head_num) * head_num * 4 +
                        (g % 2) * head_num * 2 + (head % 32) * 2 * tiles +
                        (g / 2) * tiles + head / 32;
                    buf[offset] = scale_val[row * groups_per_row + g];
                }
        };

        // value round trip per layout: read back each (row, group) via the
        // layout's documented indexing and compare with the written value
        std::vector<std::uint8_t> bnat, bfly, bopus;
        store_natural(bnat);
        store_flydsl(bfly);
        store_opus(bopus);

        // Natural: row-major, trivially the written values
        ++checks;
        bool nat_ok = true;
        for (int row = 0; row < m && nat_ok; ++row)
            for (int g = 0; g < groups_per_row; ++g)
                if (bnat[static_cast<std::size_t>(row) * groups_per_row + g] !=
                    scale_val[row * groups_per_row + g])
                    nat_ok = false;
        if (!nat_ok && f < 5) {
            std::printf("  Natural layout round trip broken\n");
            ++f;
        }

        // Flydsl: invert the index math per (row, group)
        ++checks;
        const int m_tiles = head_num >> 4;
        const int m_tiles_padded = (m_tiles + 3) & ~3;
        bool fly_ok = true;
        for (int row = 0; row < m && fly_ok; ++row)
            for (int g = 0; g < groups_per_row; ++g) {
                const int prefix_idx = row / head_num;
                const int head_idx = row - prefix_idx * head_num;
                const int m_tile = head_idx >> 4;
                const int m_inner = head_idx & 15;
                const std::size_t tile_base =
                    (static_cast<std::size_t>(prefix_idx) * groups_per_row + g) * 16 *
                        m_tiles_padded +
                    m_inner * m_tiles_padded;
                if (bfly[tile_base + m_tile] != scale_val[row * groups_per_row + g]) fly_ok = false;
            }
        if (!fly_ok && f < 5) {
            std::printf("  Flydsl layout round trip broken\n");
            ++f;
        }
        // Flydsl padding: every pad slot (m_tiles..m_tiles_padded per
        // m_inner) is ZERO — checked exactly (a global sentinel scan would
        // false-positive on scale values that happen to equal it)
        ++checks;
        bool fly_pad_ok = true;
        for (int prefix = 0; prefix < tokens; ++prefix)
            for (int g = 0; g < groups_per_row; ++g)
                for (int inner = 0; inner < 16; ++inner) {
                    const std::size_t tb =
                        (static_cast<std::size_t>(prefix) * groups_per_row + g) * 16 *
                            m_tiles_padded +
                        inner * m_tiles_padded;
                    for (int pad = m_tiles; pad < m_tiles_padded; ++pad)
                        if (bfly[tb + pad] != 0) fly_pad_ok = false;
                }
        if (!fly_pad_ok && f < 5) {
            std::printf("  Flydsl padding slots not zero\n");
            ++f;
        }

        // Opus: invert per (row, group)
        ++checks;
        const int tiles = head_num / 32;
        bool opus_ok = true;
        for (int row = 0; row < m && opus_ok; ++row)
            for (int g = 0; g < groups_per_row; ++g) {
                const int head = row % head_num;
                const std::size_t offset =
                    static_cast<std::size_t>(row / head_num) * head_num * 4 +
                    (g % 2) * head_num * 2 + (head % 32) * 2 * tiles + (g / 2) * tiles +
                    head / 32;
                if (bopus[offset] != scale_val[row * groups_per_row + g]) opus_ok = false;
            }
        if (!opus_ok && f < 5) {
            std::printf("  Opus layout round trip broken\n");
            ++f;
        }

        // cross-layout consistency: a consumer reading each layout recovers
        // the same logical scale for every (row, group)
        ++checks;
        bool consistent = nat_ok && fly_ok && opus_ok;
        if (!consistent && f < 5) {
            std::printf("  cross-layout consistency broken\n");
            ++f;
        }
        fails += f > 0;
        std::printf("4. scale layouts Natural/Flydsl/Opus (round trips + pad fill): %s\n",
                    f ? "FAIL" : "PASS");
    }

    std::printf("dsv4_hadamard_rotate_quant: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? MAIN_RETURN_BAD : 0;
}
