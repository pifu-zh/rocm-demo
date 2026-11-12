// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
// Host reference for aiter's sampling family + a bit-exact Philox4x32-10
// engine port; see the header for pinned semantics and quirks.
#include "aiter_ref/sample.hpp"

#include <array>
#include <cassert>
#include <cfloat>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace aiter_ref {

namespace {

// rocrand constants (Random123).
constexpr std::uint32_t kPhiloxM0 = 0xD2511F53u;
constexpr std::uint32_t kPhiloxM1 = 0xCD9E8D57u;
constexpr std::uint32_t kPhiloxW0 = 0x9E3779B9u;
constexpr std::uint32_t kPhiloxW1 = 0xBB67AE85u;
// The decimal literal from rocrand_common.h, NOT exact 2^-32 (pinned).
constexpr float kTwoPow32Inv = 2.3283064e-10f;

std::array<std::uint32_t, 4> single_round(const std::array<std::uint32_t, 4>& counter,
                                          const std::array<std::uint32_t, 2>& key) {
    const std::uint64_t mul0 = static_cast<std::uint64_t>(kPhiloxM0) * counter[0];
    const std::uint32_t hi0  = static_cast<std::uint32_t>(mul0 >> 32);
    const std::uint32_t lo0  = static_cast<std::uint32_t>(mul0);
    const std::uint64_t mul1 = static_cast<std::uint64_t>(kPhiloxM1) * counter[2];
    const std::uint32_t hi1  = static_cast<std::uint32_t>(mul1 >> 32);
    const std::uint32_t lo1  = static_cast<std::uint32_t>(mul1);
    return {hi1 ^ counter[1] ^ key[0], lo1, hi0 ^ counter[3] ^ key[1], lo0};
}

std::array<std::uint32_t, 2> bumpkey(const std::array<std::uint32_t, 2>& key) {
    return {key[0] + kPhiloxW0, key[1] + kPhiloxW1};
}

// Sampler geometry (launcher block_size=1024, unroll_factor=4).
constexpr std::size_t kBlockSize = 1024;
constexpr std::size_t kVecSize   = 4;

struct ThreadAcc {
    float tmax = -FLT_MAX;       // thread-local running max of scaled logits
    float tsum = 0.0f;           // online softmax denominator (NeedSum variants)
    std::int32_t key = 0;        // thread-local best candidate
    float val = -FLT_MAX;        // thread-local best value (thread_kvp.value)
};

// Per-thread noise source: operator()(base) supplies the four additive
// noise values for the slot at [base, base+4), advancing any RNG state.
struct OuterNoise {
    const float* row;
    std::size_t row_len;
    // OOB lanes read 0 (upstream bounded descriptor), guarded out of the
    // race by sample_row's range check anyway.
    std::array<float, 4> operator()(std::size_t base) const {
        std::array<float, 4> r{0.0f, 0.0f, 0.0f, 0.0f};
        for (std::size_t i = 0; i < kVecSize; ++i) {
            if (base + i < row_len) r[i] = row[base + i];
        }
        return r;
    }
};

struct InnerNoise {
    float lambd;
    Philox4x32_10 rng;
    // hiprand_init(seed, m*1024 + tid, offset): the row folds into the
    // subsequence exactly like the kernel's idx. Every thread constructs
    // its engine up front, mirroring the kernel's unconditional init.
    InnerNoise(std::uint64_t seed, std::uint64_t offset, std::size_t subsequence, float lambd_)
        : lambd(lambd_), rng(seed, subsequence, offset) {}
    std::array<float, 4> operator()(std::size_t) {
        const std::array<float, 4> r = rng.uniform4();
        std::array<float, 4> t{};
        for (std::size_t i = 0; i < kVecSize; ++i) t[i] = exponential_transform(r[i], lambd);
        return t;
    }
};

// One row of the sampling core, mirroring random_sample_*_impl: per-thread
// online softmax with one noise draw per 4-wide slot, then the global
// rescale fold.
template <typename MakeNoise>
std::int32_t sample_row(const float* row_logits, std::size_t row_len, float temperature,
                        bool need_sum, float eps, MakeNoise&& make_noise) {
    temperature = temperature > 1e-5f ? temperature : 1e-5f;
    const float inv_t = 1.0f / temperature;

    std::vector<ThreadAcc> accs(kBlockSize);
    for (std::size_t tid = 0; tid < kBlockSize; ++tid) {
        // Threads whose first base is past the row never prefetch and never
        // draw; they stay at the init values and join only the fold.
        auto noise = make_noise(tid);
        ThreadAcc& th = accs[tid];
        for (std::size_t base = tid * kVecSize; base < row_len; base += kBlockSize * kVecSize) {
            const std::array<float, 4> draws = noise(base);
            // Pass 1: scaled logits + new running max (fmaxf skips NaN).
            float scaled[kVecSize];
            float new_max = th.tmax;
            for (std::size_t i = 0; i < kVecSize; ++i) {
                scaled[i] = (base + i) < row_len ? row_logits[base + i] * inv_t : -FLT_MAX;
                new_max = std::fmax(new_max, scaled[i]);
            }
            // Pass 2: exp values, running-max rescale of the best candidate.
            float e[kVecSize];
            for (std::size_t i = 0; i < kVecSize; ++i) {
                e[i] = std::exp(scaled[i] - new_max);
            }
            const float ratio = std::exp(th.tmax - new_max);
            th.val *= ratio;
            th.tmax = new_max;
            if (need_sum) {
                float new_sum = th.tsum * ratio;
                for (std::size_t i = 0; i < kVecSize; ++i) {
                    new_sum += e[i];
                }
                th.tsum = new_sum;
            }
            // Candidate race: exp value / (noise + eps); OOB and NaN lanes
            // are guarded out of the update.
            for (std::size_t i = 0; i < kVecSize; ++i) {
                const float u = draws[i] + eps;
                const float cand = e[i] / u;
                if ((base + i) < row_len && cand > th.val) {
                    th.key = static_cast<std::int32_t>(base + i);
                    th.val = cand;
                }
            }
        }
    }

    // Global fold: gmax = fmax over thread maxima; rescale each thread's
    // value by exp(tmax - gmax) [/ gsum]; ArgMax (ties to lower key).
    float gmax = -FLT_MAX;
    for (const ThreadAcc& th : accs) gmax = std::fmax(gmax, th.tmax);
    float gsum = 0.0f;
    if (need_sum) {
        for (const ThreadAcc& th : accs) gsum += th.tsum * std::exp(th.tmax - gmax);
    }
    std::int32_t best_key = accs[0].key;
    float best_val = accs[0].val * std::exp(accs[0].tmax - gmax);
    if (need_sum) best_val /= gsum;
    for (std::size_t tid = 1; tid < kBlockSize; ++tid) {
        const ThreadAcc& th = accs[tid];
        float v = th.val * std::exp(th.tmax - gmax);
        if (need_sum) v /= gsum;
        // aiter::ArgMax: higher value wins, exact ties to the lower key.
        if (v > best_val || (v == best_val && th.key < best_key)) {
            best_val = v;
            best_key = th.key;
        }
    }
    return best_key;
}

// One greedy row: raw-logit argmax, -INFINITY sentinel, ties to lower index.
std::int32_t greedy_row(const float* row_logits, std::size_t row_len) {
    std::int32_t best_key = 0;
    float best_val = -INFINITY;
    for (std::size_t i = 0; i < row_len; ++i) {
        const float v = row_logits[i];
        if (v > best_val) {  // NaN compares false: NaN lanes never win
            best_val = v;
            best_key = static_cast<std::int32_t>(i);
        }
    }
    return best_key;
}

}  // namespace

Philox4x32_10::Philox4x32_10(std::uint64_t seed, std::uint64_t subsequence,
                             std::uint64_t offset) {
    key_[0] = static_cast<std::uint32_t>(seed);
    key_[1] = static_cast<std::uint32_t>(seed >> 32);
    // restart(): zero counter, subsequence skip (counter.z/w), offset skip
    // (substate + counter.x/y with carries), then one ten_rounds.
    counter_  = {0, 0, 0, 0};
    result_   = {0, 0, 0, 0};
    substate_ = 0;
    {
        const std::uint32_t lo   = static_cast<std::uint32_t>(subsequence);
        const std::uint32_t hi   = static_cast<std::uint32_t>(subsequence >> 32);
        const std::uint32_t temp = counter_[2];
        counter_[2] += lo;
        counter_[3] += hi + (counter_[2] < temp ? 1u : 0u);
    }
    {
        substate_ += static_cast<unsigned>(offset & 3);
        std::uint64_t counter_offset = offset / 4;
        counter_offset += substate_ < 4 ? 0 : 1;
        substate_ += substate_ < 4 ? 0u : (0u - 4u);
        const std::uint32_t lo = static_cast<std::uint32_t>(counter_offset);
        const std::uint32_t hi = static_cast<std::uint32_t>(counter_offset >> 32);
        const std::array<std::uint32_t, 4> temp = counter_;
        counter_[0] += lo;
        counter_[1] += hi + (counter_[0] < temp[0] ? 1u : 0u);
        counter_[2] += (counter_[1] < temp[1] ? 1u : 0u);
        counter_[3] += (counter_[2] < temp[2] ? 1u : 0u);
    }
    result_ = ten_rounds(counter_, key_);
}

std::array<std::uint32_t, 4> Philox4x32_10::ten_rounds(
    const std::array<std::uint32_t, 4>& counter, const std::array<std::uint32_t, 2>& key) {
    std::array<std::uint32_t, 4> c = counter;
    std::array<std::uint32_t, 2> k = key;
    for (int r = 0; r < 9; ++r) {
        c = single_round(c, k);
        k = bumpkey(k);
    }
    return single_round(c, k);
}

void Philox4x32_10::discard_state() {
    // bump_counter
    counter_[0]++;
    unsigned add = counter_[0] == 0 ? 1u : 0u;
    counter_[1] += add; add = counter_[1] == 0 ? add : 0u;
    counter_[2] += add; add = counter_[2] == 0 ? add : 0u;
    counter_[3] += add;
}

std::uint32_t Philox4x32_10::next() {
    const std::uint32_t ret = result_[substate_];
    substate_++;
    if (substate_ == 4) {
        substate_ = 0;
        discard_state();
        result_ = ten_rounds(counter_, key_);
    }
    return ret;
}

std::array<std::uint32_t, 4> Philox4x32_10::next4() {
    const std::array<std::uint32_t, 4> prev = result_;
    discard_state();
    const std::array<std::uint32_t, 4> nxt = ten_rounds(counter_, key_);
    result_ = nxt;
    // interleave(prev, nxt) by substate
    switch (substate_) {
        case 0: return prev;
        case 1: return {prev[1], prev[2], prev[3], nxt[0]};
        case 2: return {prev[2], prev[3], nxt[0], nxt[1]};
        default: return {prev[3], nxt[0], nxt[1], nxt[2]};
    }
}

std::array<float, 4> Philox4x32_10::uniform4() {
    const std::array<std::uint32_t, 4> v = next4();
    return {philox_uniform(v[0]), philox_uniform(v[1]), philox_uniform(v[2]),
            philox_uniform(v[3])};
}

float philox_uniform(std::uint32_t v) {
    return kTwoPow32Inv + (static_cast<float>(v) * kTwoPow32Inv);
}

float exponential_transform(float u, float lambd) {
    constexpr float a = 1.0f - 1.1920929e-07f / 2;  // 1 - FLT_EPSILON/2
    constexpr float b = 1.1920929e-07f / 2;         // FLT_EPSILON/2 == 2^-24
    const float c = static_cast<float>(-1.0 / lambd);
    const float log_val = u >= a ? b : std::log(u);
    return c * log_val;
}

std::uint64_t philox_counter_offset(std::uint64_t numel, std::uint64_t num_rows) {
    return ((numel - 1) / (kBlockSize * num_rows * kVecSize) + 1) * 4;
}

std::vector<std::int32_t> greedy_sample(const std::vector<float>& logits, std::size_t num_rows,
                                        std::size_t row_len) {
    assert(num_rows > 0 && row_len > 0 && logits.size() >= num_rows * row_len);
    std::vector<std::int32_t> out(num_rows);
    for (std::size_t m = 0; m < num_rows; ++m) {
        out[m] = greedy_row(logits.data() + m * row_len, row_len);
    }
    return out;
}

std::vector<std::int32_t> random_sample(const std::vector<float>& logits, std::size_t num_rows,
                                        std::size_t row_len,
                                        const std::vector<float>& temperatures, float lambd,
                                        std::uint64_t philox_seed, std::uint64_t philox_offset,
                                        float eps) {
    assert(num_rows > 0 && row_len > 0 && logits.size() >= num_rows * row_len);
    assert(temperatures.size() >= num_rows);
    std::vector<std::int32_t> out(num_rows);
    for (std::size_t m = 0; m < num_rows; ++m) {
        auto make_noise = [&](std::size_t tid) {
            return InnerNoise(philox_seed, philox_offset, m * kBlockSize + tid, lambd);
        };
        out[m] = sample_row(logits.data() + m * row_len, row_len, temperatures[m], false, eps,
                            make_noise);
    }
    return out;
}

std::vector<std::int32_t> random_sample_outer_exponential(
    const std::vector<float>& logits, std::size_t num_rows, std::size_t row_len,
    const std::vector<float>& exponentials, const std::vector<float>& temperatures, float eps) {
    assert(num_rows > 0 && row_len > 0 && logits.size() >= num_rows * row_len);
    assert(exponentials.size() >= num_rows * row_len);
    assert(temperatures.size() >= num_rows);
    std::vector<std::int32_t> out(num_rows);
    for (std::size_t m = 0; m < num_rows; ++m) {
        auto make_noise = [&, m](std::size_t) {
            return OuterNoise{exponentials.data() + m * row_len, row_len};
        };
        out[m] = sample_row(logits.data() + m * row_len, row_len, temperatures[m], true, eps,
                            make_noise);
    }
    return out;
}

std::vector<std::int32_t> mixed_sample(const std::vector<float>& logits, std::size_t num_rows,
                                       std::size_t row_len,
                                       const std::vector<float>& temperatures, float lambd,
                                       std::uint64_t philox_seed, std::uint64_t philox_offset,
                                       float eps) {
    assert(num_rows > 0 && row_len > 0 && logits.size() >= num_rows * row_len);
    assert(temperatures.size() >= num_rows);
    std::vector<std::int32_t> out(num_rows);
    for (std::size_t m = 0; m < num_rows; ++m) {
        if (temperatures[m] == 0.0f) {
            out[m] = greedy_row(logits.data() + m * row_len, row_len);
        } else {
            auto make_noise = [&](std::size_t tid) {
                return InnerNoise(philox_seed, philox_offset, m * kBlockSize + tid, lambd);
            };
            out[m] = sample_row(logits.data() + m * row_len, row_len, temperatures[m], false, eps,
                                make_noise);
        }
    }
    return out;
}

std::vector<std::int32_t> mixed_sample_outer_exponential(
    const std::vector<float>& logits, std::size_t num_rows, std::size_t row_len,
    const std::vector<float>& exponentials, const std::vector<float>& temperatures, float eps) {
    assert(num_rows > 0 && row_len > 0 && logits.size() >= num_rows * row_len);
    assert(exponentials.size() >= num_rows * row_len);
    assert(temperatures.size() >= num_rows);
    std::vector<std::int32_t> out(num_rows);
    for (std::size_t m = 0; m < num_rows; ++m) {
        if (temperatures[m] == 0.0f) {
            out[m] = greedy_row(logits.data() + m * row_len, row_len);
        } else {
            auto make_noise = [&, m](std::size_t) {
                return OuterNoise{exponentials.data() + m * row_len, row_len};
            };
            out[m] = sample_row(logits.data() + m * row_len, row_len, temperatures[m], true, eps,
                                make_noise);
        }
    }
    return out;
}

std::vector<float> exponential_noise(std::size_t num_rows, std::size_t row_len, float lambd,
                                     std::uint64_t philox_seed, std::uint64_t philox_offset,
                                     float eps) {
    assert(num_rows > 0 && row_len > 0);
    std::vector<float> out(num_rows * row_len, 0.0f);
    for (std::size_t m = 0; m < num_rows; ++m) {
        for (std::size_t tid = 0; tid < kBlockSize; ++tid) {
            if (tid * kVecSize >= row_len) break;
            Philox4x32_10 rng(philox_seed, m * kBlockSize + tid, philox_offset);
            for (std::size_t base = tid * kVecSize; base < row_len;
                 base += kBlockSize * kVecSize) {
                const std::array<float, 4> r = rng.uniform4();
                for (std::size_t i = 0; i < kVecSize; ++i) {
                    if (base + i < row_len) {
                        out[m * row_len + base + i] = exponential_transform(r[i], lambd) + eps;
                    }
                }
            }
        }
    }
    return out;
}

}  // namespace aiter_ref
