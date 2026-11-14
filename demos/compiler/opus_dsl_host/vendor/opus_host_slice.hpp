// SPDX-License-Identifier: MIT
// Copyright (C) 2025-2026 carlus.huang@amd.com
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. all rights reserved.
//
// HOST-COMPILABLE SLICE of aiter's opus single-header DSL
// (csrc/include/opus/opus.hpp @ 1eab5ae12c93af3c8c660202d9a413f637c2f011,
// MIT). Extracted for the lab's host-unit-test demo
// (demos/compiler/opus_dsl_host): this slice covers the DEVICE-INDEPENDENT
// half — type traits, constants (number/bool_constant), the _I literal,
// constexpr functional math, the seq compile-time algebra (make_index_seq,
// transforms, reduce), static_ford, sub-byte packs (fp4/int4 bit-packing),
// array/vector containers, tuple algebra (make/get/size/transform/flatten/
// concat via __type_pack_element), the layout coordinate-to-linear math,
// the dtype finfo tables, and the slice fallback.
//
// CUT (device-line, kept upstream): everything from the GCN inline-asm
// type cast section onward (fp32_to_bf16_rtn_asm and below) — those bodies
// only compile for amdgcn. The slice boundary is line 1190 of the upstream
// header; the namespace opus brace is closed by this slice's tail.
//
// SHIM: this slice is meant to be included AFTER host_shim.hpp (which
// undefines __HIPCC__ and empties __host__/__device__ so the header's
// host path parses). Raw __host__/__device__ uses inside the slice: the
// tuple deduction guide only.

// ── host shim (must precede the slice) ──
#ifdef __HIPCC__
#undef __HIPCC__
#endif
#ifndef __host__
#define __host__
#endif
#ifndef __device__
#define __device__
#endif
/***************************************************************************************************
 * OPUS, AI (O)(P)erator Micro(U) (S)TD
 *
 * Crafting the micro standard templates for AI Operators on ROCm
 *
 * MIT License
 * Copyright (C) 2025-2026 carlus.huang@amd.com
 *
 **************************************************************************************************/
#pragma once

// clang-format off
#include <type_traits>
#include <utility>

#include "dtypes.hpp"

#ifndef OPUS_ENABLE_RUNTIME_QUERY
#define OPUS_ENABLE_RUNTIME_QUERY 0
#endif

#if OPUS_ENABLE_RUNTIME_QUERY && defined(__HIPCC__) && !defined(__HIP_DEVICE_COMPILE__)
#include <hip/hip_runtime_api.h>
#endif

#ifdef __HIPCC__
#define OPUS_H inline __host__
#define OPUS_D inline __device__
#define OPUS_H_D inline __host__ __device__
#define OPUS_D_EXTERN __device__
#define OPUS_H_D_EXTERN __host__ __device__
#else
#define OPUS_H inline
#define OPUS_D
#define OPUS_H_D inline
#define OPUS_D_EXTERN
#define OPUS_H_D_EXTERN
#endif

#ifndef OPUS_FP32_to_BF16_DEFAULT
#define OPUS_FP32_to_BF16_DEFAULT 2 // truncate, valid on gfx94* and before
#endif

#ifndef OPUS_TILE_CONTAINER
#define OPUS_TILE_CONTAINER 0 // 0:vector, 1:array of vector, 2:flattened array
#endif

namespace opus {
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// type traits
using std::remove_reference; using std::remove_reference_t; using std::remove_cv; using std::remove_cv_t; using std::is_same; using std::is_same_v;
template<typename T> struct remove_cvref { using type = remove_cv_t<remove_reference_t<T>>; };
template<typename T> using remove_cvref_t = remove_cv_t<remove_reference_t<T>>;
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// constant
using index_t = int;
using long_index_t = long long;

template<index_t I> struct number : public std::integral_constant<index_t, I> {};
template<bool B>    struct bool_constant : public std::bool_constant<B> {};
typedef bool_constant<true>  true_type;
typedef bool_constant<false> false_type;

template<typename>           struct is_constant : public false_type {};
template<typename T, auto I> struct is_constant<std::integral_constant<T, I>> : true_type {};
template<auto I>             struct is_constant<number<I>> : true_type {};
template<auto I>             struct is_constant<bool_constant<I>> : true_type {};
template <class T> static constexpr bool is_constant_v = is_constant<remove_cvref_t<T>>::value;    // prefer use this

// using opus::operator""_I; // => add this in your code to utilize the literal cast, e.g. 2_I, 3_I
template <char... Ds>
OPUS_H_D constexpr decltype(auto) operator""_I() {
    constexpr auto to_number_ = []() { index_t v = 0; ((v = v * 10 + (Ds - '0')), ...); return v; }; return number<to_number_()>{};
}

#define OPUS_LEFT_UNARY_OP(OP) template <auto x>         OPUS_H_D constexpr auto operator OP(number<x>)            { return number<(OP x)>{};   }
#define OPUS_BINARY_OP(OP)     template <auto x, auto y> OPUS_H_D constexpr auto operator OP(number<x>, number<y>) { return number<(x OP y)>{}; }

OPUS_LEFT_UNARY_OP(+) OPUS_LEFT_UNARY_OP(-) OPUS_LEFT_UNARY_OP(~) OPUS_LEFT_UNARY_OP(!)
OPUS_BINARY_OP(+)   OPUS_BINARY_OP(-)   OPUS_BINARY_OP(*)   OPUS_BINARY_OP(/)
OPUS_BINARY_OP(%)   OPUS_BINARY_OP(&)   OPUS_BINARY_OP(|)   OPUS_BINARY_OP(^)
OPUS_BINARY_OP(<<)  OPUS_BINARY_OP(>>)  OPUS_BINARY_OP(&&)  OPUS_BINARY_OP(||)
OPUS_BINARY_OP(==)  OPUS_BINARY_OP(!=)  OPUS_BINARY_OP(>)   OPUS_BINARY_OP(<)
OPUS_BINARY_OP(>=)  OPUS_BINARY_OP(<=)

#undef OPUS_LEFT_UNARY_OP
#undef OPUS_BINARY_OP

template<class T, class... R> constexpr bool is_any_of() noexcept { return (std::is_same_v<T, R> || ...); }
template<class T, class... R> static constexpr bool is_any_of_v = is_any_of<T, R...>();
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// underscore, useful struture to mock
struct underscore { /*who am I*/ };
static constexpr underscore _;
template <typename T> struct is_underscore : false_type {};
template <> struct is_underscore<underscore> : true_type {};
template <typename T> static constexpr bool is_underscore_v = is_underscore<T>::value;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// constexpr functional math
struct plus       { template<typename X, typename Y=X> OPUS_H_D constexpr decltype(auto) operator()(X a, Y b) const { return a + b; } };
struct minus      { template<typename X, typename Y=X> OPUS_H_D constexpr decltype(auto) operator()(X a, Y b) const { return a - b; } };
struct multiplies { template<typename X, typename Y=X> OPUS_H_D constexpr decltype(auto) operator()(X a, Y b) const { return a * b; } };
struct divides    { template<typename X, typename Y=X> OPUS_H_D constexpr decltype(auto) operator()(X a, Y b) const { return a / b; } };

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// seq
template <index_t... Is>
class seq {
public:
    using value_type = index_t;
    OPUS_H_D static constexpr index_t size() { return sizeof...(Is);}
    OPUS_H_D constexpr value_type operator[](index_t i) const { return data[i]; }
    OPUS_H_D static constexpr value_type at(index_t i) { return data[i]; }
    template <index_t I> OPUS_H_D static constexpr value_type at()          { return data[I]; }
    template <index_t I> OPUS_H_D static constexpr value_type at(number<I>) { return data[I]; }
private:
    static constexpr value_type data[sizeof...(Is) + 1] = {Is..., value_type{}};
};

template <index_t I, index_t... Is> OPUS_H_D constexpr auto seq_pop_front(seq<I, Is...>) { return seq<Is...>{}; }

template <index_t I, index_t... Is> OPUS_H_D constexpr decltype(auto) get(seq<Is...>const& ) { static_assert(I < sizeof...(Is)); return seq<Is...>::at(number<I>{}); }
template <index_t I, index_t... Is> OPUS_H_D constexpr decltype(auto) get(seq<Is...>& )      { static_assert(I < sizeof...(Is)); return seq<Is...>::at(number<I>{}); }
template <index_t I, index_t... Is> OPUS_H_D constexpr decltype(auto) get(seq<Is...>&& )     { static_assert(I < sizeof...(Is)); return seq<Is...>::at(number<I>{}); }

namespace impl {
template <typename T, T... Is> struct __integer_sequence;
template <index_t... Is>       struct __integer_sequence<index_t, Is...> { using seq_type = seq<Is...>; };
template<index_t, index_t, typename>                 struct __steped_integer_seq;
template<index_t Start, index_t Step, index_t... Is> struct __steped_integer_seq<Start, Step, seq<Is...>> { using seq_type = seq<(Start + Is * Step) ... >; };

template<typename>                   struct __make_index_seq;
template <index_t N>                 struct __make_index_seq<seq<N>>          { using seq_type = typename __make_integer_seq<__integer_sequence, index_t, N>::seq_type; };
template<index_t Start, index_t End> struct __make_index_seq<seq<Start, End>> { using seq_type = typename __steped_integer_seq<Start, 1, typename __make_index_seq< seq<(End-Start)/1> >::seq_type>::seq_type; };
template<index_t Start, index_t End, index_t Step>  struct __make_index_seq<seq<Start, End, Step>> {
    using seq_type = typename __steped_integer_seq<Start, Step, typename __make_index_seq< seq<(End-Start)/Step> >::seq_type>::seq_type;
};
} // namespace impl
// make_index_seq<5> -> seq<0,1,2,3,4> | make_index_seq<4, 9> -> seq<4,5,6,7,8> | make_index_seq<4, 8, 2> -> seq<4, 6>
template<index_t...Is> using make_index_seq = typename impl::__make_index_seq<seq<Is...>>::seq_type;

namespace impl {
template<index_t Value, index_t N>
struct __make_repeated_seq {
    template<index_t... I> static constexpr auto __make(seq<I...>) { return seq<(void(I), Value)...>{}; }
    using seq_type = decltype(__make(make_index_seq<N>{}));
};
} // namespace impl
template<index_t V, index_t N> using make_repeated_seq = typename impl::__make_repeated_seq<V, N>::seq_type;

template<index_t...Xs, index_t...Ys> OPUS_H_D constexpr auto concat_seq(seq<Xs...>, seq<Ys...>) { return seq<Xs..., Ys...>{}; }

namespace impl {
template<typename, typename>                                 struct reduce_seq_impl;
template <typename R, index_t I0, index_t I1, index_t... Is> struct reduce_seq_impl<R, seq<I0, I1, Is...>> { using type = typename reduce_seq_impl<R, seq<R{}(I0, I1), Is...>>::type; };
template <typename R, index_t I>                             struct reduce_seq_impl<R, seq<I>> { using type = seq<I>; };
template <typename R>                                        struct reduce_seq_impl<R, seq<>>  { using type = seq<>;  };
}
template<typename R, index_t...Xs> OPUS_H_D constexpr auto reduce_seq(seq<Xs...>) { return typename impl::reduce_seq_impl<R, seq<Xs...>>::type{}; }
template<index_t...Xs> OPUS_H_D constexpr auto reduce_seq_sum(seq<Xs...>) { if constexpr (sizeof...(Xs) == 0) return seq<>{}; else return seq<(Xs + ...)>{}; }
template<index_t...Xs> OPUS_H_D constexpr auto reduce_seq_mul(seq<Xs...>) { if constexpr (sizeof...(Xs) == 0) return seq<>{}; else return seq<(Xs * ...)>{}; }

template<typename T> struct is_seq : false_type {};
template<index_t... Is> struct is_seq<seq<Is...>> : true_type {};
template<typename T> constexpr bool is_seq_v = is_seq<remove_cvref_t<T>>::value;

template<typename T> OPUS_H_D constexpr std::enable_if_t<is_seq_v<T>, index_t> size(T&&) { return remove_cvref_t<T>::size(); /* tuple size */}
template<typename T> OPUS_H_D constexpr std::enable_if_t<is_seq_v<T>, index_t> size()    { return remove_cvref_t<T>::size(); /* tuple size */}

template <index_t I, typename T, std::enable_if_t<is_seq_v<T>, bool> = true> OPUS_H_D constexpr decltype(auto) get(T const& t) { static_assert(I < T::size()); return t[number<I>{}]; }
template <index_t I, typename T, std::enable_if_t<is_seq_v<T>, bool> = true> OPUS_H_D constexpr decltype(auto) get(T&  t)      { static_assert(I < T::size()); return t[number<I>{}]; }
template <index_t I, typename T, std::enable_if_t<is_seq_v<T>, bool> = true> OPUS_H_D constexpr decltype(auto) get(T&& t)      { static_assert(I < T::size()); return t[number<I>{}]; }
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// functional
namespace impl {
template <class T>       struct static_for_impl;
template <index_t... Is> struct static_for_impl<seq<Is...>> { template <class F> OPUS_H_D constexpr void operator()(F&& f) const { (f(number<Is>{}), ...); } };
}   // namespace impl
template<index_t N, typename F> OPUS_H_D constexpr void static_for(F f) { impl::static_for_impl<make_index_seq<N>>{}(f); }

template<typename F, typename... R, std::enable_if_t<(is_constant_v<R> && ...), bool> = true>
OPUS_H_D constexpr void static_for(F f, R...) { impl::static_for_impl<make_index_seq<R::value...>>{}(f); }

namespace impl {
// Flat static_ford: single-level static_for, non-recursive compile-time index decomposition via fold expressions
template <index_t D, index_t... Is, index_t... Ns> constexpr index_t ford_stride(seq<Is...>, seq<Ns...>) { return ((Is > D ? Ns : index_t(1)) * ... * index_t(1)); }
template <index_t D, index_t... Is, index_t... Ns> constexpr index_t ford_dim(seq<Is...>, seq<Ns...>) { return ((Is == D ? Ns : index_t(1)) * ...); }
template <index_t I, index_t D, index_t... Ns> constexpr index_t ford_at() { return (I / ford_stride<D>(make_index_seq<sizeof...(Ns)>{}, seq<Ns...>{})) % ford_dim<D>(make_index_seq<sizeof...(Ns)>{}, seq<Ns...>{}); }
template <typename Seq> struct static_ford_impl;
template <index_t... Ns> struct static_ford_impl<seq<Ns...>> {
    template <typename F, index_t I, index_t... Ds> OPUS_H_D static constexpr void call_one(F& f, number<I>, seq<Ds...>) { f(number<ford_at<I, Ds, Ns...>()>{}...); }
    template <typename F> OPUS_H_D constexpr void operator()(F f) const { static_for<(Ns * ... * 1)>([&](auto I) { call_one(f, I, make_index_seq<sizeof...(Ns)>{}); }); }
};
template <> struct static_ford_impl<seq<>> { template <typename F> OPUS_H_D constexpr void operator()(F f) const { f(); } };
}

template<index_t... N, typename F> OPUS_H_D constexpr void static_ford(F f) { impl::static_ford_impl<seq<N...>>{}(f); }
template<index_t... N, typename F> OPUS_H_D constexpr void static_ford(seq<N...>, F f) { impl::static_ford_impl<seq<N...>>{}(f); }
template <class... T> struct tuple;
template<index_t... N, typename F> OPUS_H_D constexpr void static_ford(tuple<number<N>...>, F f) { impl::static_ford_impl<seq<N...>>{}(f); }

template<typename T, typename R = void> struct get_value_type { using type = remove_cvref_t<T>; };
template<typename T, typename R = void> using get_value_t = typename get_value_type<T, R>::type;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// sub-byte "packs" (fp4_t/int4_t/uint4_t): ONE logical <8-bit element, cutlass float_e2m1_t style. Full byte standalone/in a C array; opus::array/vector bit-pack it (via is_packs_v) and hand out a proxy reference.
namespace impl {
// "pack" trait carrier. `storage` = smallest addressable unit; `num_packs` = logical elements per storage unit (for computing packed byte size).
template<typename storage_, unsigned int bits_, bool is_signed_ = true>
struct dpacks {
    using storage = remove_cvref_t<storage_>;
    static constexpr unsigned int bits = bits_;
    static constexpr unsigned int mask = (1 << bits) - 1;
    static constexpr bool is_signed = is_signed_;
    static constexpr unsigned int num_packs = sizeof(storage) * 8 / bits;   // logical elements per storage unit
    storage value;   // holds ONE logical element in the low `bits` bits when standalone
};

template<typename storage_, unsigned int bits_, unsigned int exp_bits_, unsigned int mantissa_bits_, bool is_signed_ = true>
struct fpacks : dpacks<storage_, bits_, is_signed_> {
    static constexpr unsigned int exp_bits = exp_bits_;
    static constexpr unsigned int mantissa_bits = mantissa_bits_;
};
} // namespace impl

template <typename> struct is_packs : false_type {};
template <typename S, unsigned int B, bool X> struct is_packs<impl::dpacks<S, B, X>> : true_type {};
template <typename S, unsigned int B, unsigned int E, unsigned int M, bool X> struct is_packs<impl::fpacks<S, B, E, M, X>> : true_type {};
template <typename T> static constexpr bool is_packs_v = is_packs<remove_cvref_t<T>>::value;

// how many logical elements fit in one storage byte (1 for non-pack scalars)
template <typename T, typename = void> struct num_packs { static constexpr int value = 1; };
template <typename T> struct num_packs<T, std::enable_if_t<is_packs_v<T>>> { static constexpr int value = T::num_packs; };
template <typename T> static constexpr int num_packs_v = num_packs<T>::value;

template <typename T> struct sizeof_bits { static constexpr int value = int(sizeof(T) * 8); };
template <> struct sizeof_bits<void> { static constexpr int value = 0; };
template <typename S, unsigned int B, bool X> struct sizeof_bits<impl::dpacks<S, B, X>> { static constexpr int value = impl::dpacks<S, B, X>::bits; };
template <typename S, unsigned int B, unsigned int E, unsigned int M, bool X> struct sizeof_bits<impl::fpacks<S, B, E, M, X>> { static constexpr int value = impl::fpacks<S, B, E, M, X>::bits; };
template <class T> static constexpr auto sizeof_bits_v = sizeof_bits<T>::value;

template <typename T, index_t N> static constexpr index_t packed_bytes_v = index_t((index_t(sizeof_bits<T>::value) * N + 7) / 8);

namespace impl {
template<typename T>
struct subbyte_reference {
    using storage = typename T::storage;
    static constexpr unsigned int bits = T::bits;
    static constexpr storage vmask = storage((storage(1) << bits) - 1);
    storage* ptr_;
    unsigned int idx_;   // logical element index within *ptr_ (0..num_packs-1)
    OPUS_H_D constexpr subbyte_reference(storage* p, unsigned int i) : ptr_(p), idx_(i) {}
    OPUS_H_D constexpr subbyte_reference(const subbyte_reference&) = default;
    OPUS_H_D constexpr T get() const {
        storage v = storage((storage(*ptr_) >> (idx_ * bits)) & vmask);
        return __builtin_bit_cast(T, v);
    }
    OPUS_H_D constexpr operator T() const { return get(); }
    OPUS_H_D constexpr const subbyte_reference& operator=(const T& x) const {
        storage item = storage(__builtin_bit_cast(storage, x) & vmask);
        storage clr  = storage(~(vmask << (idx_ * bits)));
        *ptr_ = storage((storage(*ptr_) & clr) | storage(item << (idx_ * bits)));
        return *this;
    }
    OPUS_H_D constexpr const subbyte_reference& operator=(const subbyte_reference& o) const { return *this = o.get(); }
};
template<typename T>
struct const_subbyte_reference {
    using storage = typename T::storage;
    static constexpr unsigned int bits = T::bits;
    static constexpr storage vmask = storage((storage(1) << bits) - 1);
    const storage* ptr_;
    unsigned int idx_;
    OPUS_H_D constexpr const_subbyte_reference(const storage* p, unsigned int i) : ptr_(p), idx_(i) {}
    OPUS_H_D constexpr const_subbyte_reference(const subbyte_reference<T>& r) : ptr_(r.ptr_), idx_(r.idx_) {}
    OPUS_H_D constexpr T get() const {
        storage v = storage((storage(*ptr_) >> (idx_ * bits)) & vmask);
        return __builtin_bit_cast(T, v);
    }
    OPUS_H_D constexpr operator T() const { return get(); }
};
} // namespace impl

namespace impl {
template<typename V, index_t N, bool = is_packs_v<V>> struct array_storage { using type = V; static constexpr index_t count = N; };
template<typename V, index_t N> struct array_storage<V, N, true> { using type = typename V::storage; static constexpr index_t count = packed_bytes_v<V, N>; };
}
template <typename T, index_t N>
struct array {
    using value_type = remove_cvref_t<T>;
    using type = array<value_type, N>;
    static constexpr bool is_packed = is_packs_v<value_type>;
    using storage = typename impl::array_storage<value_type, N>::type;             // value_type, or the pack's byte storage
    static constexpr index_t nstore = impl::array_storage<value_type, N>::count;   // N, or the packed byte count
    using reference       = std::conditional_t<is_packed, impl::subbyte_reference<value_type>, value_type&>;
    using const_reference = std::conditional_t<is_packed, impl::const_subbyte_reference<value_type>, const value_type&>;

    OPUS_H_D constexpr array() = default;
    template<typename... Z, std::enable_if_t<!is_packs_v<value_type> && sizeof...(Z) == N && (std::is_convertible_v<Z, value_type> && ...), bool> = true>
    OPUS_H_D constexpr array(Z&&... zs) : content{ static_cast<value_type>(zs)... } {}
    template<typename... Z, std::enable_if_t<is_packs_v<value_type> && sizeof...(Z) == N && (std::is_convertible_v<Z, value_type> && ...), bool> = true>
    OPUS_H_D constexpr array(Z... zs) { index_t i = 0; ((void)((*this)[i++] = static_cast<value_type>(zs)), ...); }

    OPUS_H_D constexpr reference       operator[](index_t pos)       { if constexpr (is_packed) return reference(&content[pos / value_type::num_packs], (unsigned)(pos % value_type::num_packs)); else return content[pos]; }
    OPUS_H_D constexpr const_reference operator[](index_t pos) const { if constexpr (is_packed) return const_reference(&content[pos / value_type::num_packs], (unsigned)(pos % value_type::num_packs)); else return content[pos]; }
    template<index_t I> OPUS_H_D constexpr reference       operator[](number<I>)       { if constexpr (is_packed) return reference(&content[I / value_type::num_packs], (unsigned)(I % value_type::num_packs)); else return content[I]; }
    template<index_t I> OPUS_H_D constexpr const_reference operator[](number<I>) const { if constexpr (is_packed) return const_reference(&content[I / value_type::num_packs], (unsigned)(I % value_type::num_packs)); else return content[I]; }

    OPUS_H_D constexpr void fill(const value_type& value) { for (index_t i = 0; i < N; ++i) (*this)[i] = value; }
    OPUS_H_D constexpr void clear() { if constexpr (is_packed) { for (index_t i = 0; i < nstore; ++i) content[i] = storage(0); } else { fill(static_cast<value_type>(0)); } }
    OPUS_H_D static constexpr bool empty() { return size() == 0; }
    OPUS_H_D static constexpr index_t size() { return N; }

    // default member initializer keeps the implicitly-defaulted default ctor constexpr
    // see: https://en.cppreference.com/w/cpp/language/constexpr.html#constexpr_constructor
    storage content[nstore] {};
};

template <typename T, index_t N, std::enable_if_t<!is_packs_v<T>, bool> = true>
OPUS_H_D constexpr bool operator==(const array<T,N>& x, const array<T,N>& y) { for (index_t i = 0; i < N; ++i) { if (x[i] != y[i]) { return false; } } return true; }

template <typename T, index_t N> OPUS_H_D constexpr void clear(array<T,N>& a) { a.clear(); }
template <typename T, index_t N> OPUS_H_D constexpr void fill(array<T,N>& a, T const& value) { a.fill(value); }

template<typename T> struct is_array : false_type {};
template<typename T, index_t N> struct is_array<array<T, N>> : true_type {};
template<typename T> constexpr bool is_array_v = is_array<remove_cvref_t<T>>::value;
template<typename T> struct get_value_type<T, std::enable_if_t<is_array_v<T>>> { using type = typename T::value_type; };

namespace impl {
template<typename> struct is_ref_wrapper : std::false_type{};
template<typename T> struct is_ref_wrapper<std::reference_wrapper<T>> : std::true_type{};
template<typename T> using not_ref_wrapper = std::negation<is_ref_wrapper<std::decay_t<T>>>;

template<typename D, typename...> struct array_return_type_helper { using type = D; };
template<typename... Types>
struct array_return_type_helper<void, Types...> : std::common_type<Types...> {
    static_assert(std::conjunction_v<not_ref_wrapper<Types>...>, "Types cannot contain reference_wrappers when D is void");
};
template<typename D, typename... Types> using array_return_type = opus::array<typename array_return_type_helper<D, Types...>::type, sizeof...(Types)>;
}
template<typename D = void, typename... Types> OPUS_H_D constexpr impl::array_return_type<D, Types...> make_array(Types&&... t) { return {std::forward<Types>(t)...}; }

// For packed arrays operator[] yields a proxy; get<> decays it to the value type so make_array/concat_array deduce the element type, not the proxy.
template <index_t I, typename T, std::enable_if_t<is_array_v<T>, bool> = true> OPUS_H_D constexpr decltype(auto) get(T const& t) { static_assert(I < T::size()); if constexpr (is_packs_v<typename T::value_type>) return typename T::value_type(t[number<I>{}]); else return t[number<I>{}]; }
template <index_t I, typename T, std::enable_if_t<is_array_v<T>, bool> = true> OPUS_H_D constexpr decltype(auto) get(T&  t)      { static_assert(I < T::size()); if constexpr (is_packs_v<typename T::value_type>) return typename T::value_type(t[number<I>{}]); else return t[number<I>{}]; }
template <index_t I, typename T, std::enable_if_t<is_array_v<T>, bool> = true> OPUS_H_D constexpr decltype(auto) get(T&& t)      { static_assert(I < T::size()); if constexpr (is_packs_v<typename T::value_type>) return typename T::value_type(t[number<I>{}]); else return t[number<I>{}]; }

namespace impl {
template <class T0, class T1, index_t... I0, index_t... I1>
OPUS_H_D constexpr auto concat_array(T0 const& t0, T1 const& t1, seq<I0...>, seq<I1...>) { return opus::make_array(get<I0>(t0)..., get<I1>(t1)...); }
template <class T0, class T1, class T2, index_t... I0, index_t... I1, index_t...I2>
OPUS_H_D constexpr auto concat_array(T0 const& t0, T1 const& t1, T2 const& t2, seq<I0...>, seq<I1...>, seq<I2...>) { return opus::make_array(get<I0>(t0)..., get<I1>(t1)..., get<I2>(t2)...); }
template <class T0, class T1, class T2, class T3, index_t... I0, index_t... I1, index_t...I2, index_t...I3>
OPUS_H_D constexpr auto concat_array(T0 const& t0, T1 const& t1, T2 const& t2, T3 const& t3, seq<I0...>, seq<I1...>, seq<I2...>, seq<I3...>) { return opus::make_array(get<I0>(t0)..., get<I1>(t1)..., get<I2>(t2)..., get<I3>(t3)...); }
}
template <class T0> OPUS_H_D  constexpr auto concat_array(T0 const& t0) { return t0; }
template <class T0, class T1>
OPUS_H_D  constexpr auto concat_array(T0 const& t0, T1 const& t1) { return impl::concat_array(t0, t1, make_index_seq<T0::size()>{}, make_index_seq<T1::size()>{}); }
template <class T0, class T1, class T2>
OPUS_H_D  constexpr auto concat_array(T0 const& t0, T1 const& t1, T2 const& t2) { return impl::concat_array(t0, t1, t2, make_index_seq<T0::size()>{}, make_index_seq<T1::size()>{}, make_index_seq<T2::size()>{}); }
template <class T0, class T1, class T2, class T3>
OPUS_H_D  constexpr auto concat_array(T0 const& t0, T1 const& t1, T2 const& t2, T3 const& t3) {
                                            return impl::concat_array(t0, t1, t2, t3, make_index_seq<T0::size()>{}, make_index_seq<T1::size()>{}, make_index_seq<T2::size()>{}, make_index_seq<T3::size()>{}); }
template <class T0, class T1, class T2, class T3, class T4, class... Ts>
OPUS_H_D  constexpr auto concat_array(T0 const& t0, T1 const& t1, T2 const& t2, T3 const& t3, T4 const& t4, Ts const&... ts) { return concat_array(concat_array(t0, t1, t2, t3), concat_array(t4, ts...)); }

template<typename T> OPUS_H_D constexpr std::enable_if_t<is_array_v<T>, index_t> size(T&&) { return remove_cvref_t<T>::size(); /* tuple size */}
template<typename T> OPUS_H_D constexpr std::enable_if_t<is_array_v<T>, index_t> size()    { return remove_cvref_t<T>::size(); /* tuple size */}
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// tuple
namespace impl {
template <index_t idx, typename T, bool is_empty = (std::is_empty_v<T> || std::is_void_v<T>)> struct tuple_object {}; // the place where content is stored

template <index_t idx, typename T>
struct tuple_object<idx, T, true> {
    OPUS_H_D constexpr tuple_object() {}
    template <typename U, typename std::enable_if<!std::is_same<remove_cvref_t<U>, tuple_object>::value, bool>::type = false>
    OPUS_H_D constexpr tuple_object(U&&) {}
};
template <index_t idx, typename T>
struct tuple_object<idx, T, false> {
    OPUS_H_D constexpr tuple_object() : element{} {}
    template <typename U, typename std::enable_if<!std::is_same<remove_cvref_t<U>, tuple_object>::value, bool>::type = false>
    OPUS_H_D constexpr tuple_object(U&& e) : element(std::forward<U>(e)) {}
    T element;
};

// NOTE: we return a instance(not a reference) if content is empty
template <index_t I, class T> OPUS_H_D constexpr T        getv(const tuple_object<I, T, true>&)    { return {}; }
template <index_t I, class T> OPUS_H_D constexpr const T& getv(const tuple_object<I, T, false>& x) { return x.element; }
template <index_t I, class T> OPUS_H_D constexpr T&       getv(tuple_object<I, T, false>& x)       { return x.element; }
template <index_t I, class T> OPUS_H_D constexpr T&&      getv(tuple_object<I, T, false>&& x)      { return static_cast<T&&>(x.element); }

template <typename index_seq, typename... T> struct tuple_base;

template <index_t... I, typename... T>
struct tuple_base<seq<I...>, T...> : tuple_object<I, T>... {
    OPUS_H_D constexpr tuple_base() = default;

    template <class U, typename std::enable_if<sizeof...(I) == 1 && sizeof...(T) == 1 && !std::is_same<remove_cvref_t<U>, tuple_base>::value, bool>::type = false>
    OPUS_H_D constexpr tuple_base(U&& u) : tuple_object<I, T>(std::forward<U>(u))... {}

    template <typename... U, typename std::enable_if<sizeof...(U) >= 2, bool>::type = false>
    OPUS_H_D constexpr tuple_base(U&&... u) : tuple_object<I, T>(std::forward<U>(u))... { static_assert(sizeof...(I) == sizeof...(T) && sizeof...(I) == sizeof...(U), "wrong!"); }
};
} // namespace impl
template <class... T>
struct tuple : impl::tuple_base<make_index_seq<sizeof...(T)>, T...> {
    OPUS_H_D static constexpr index_t size() { return sizeof...(T); }
    using base = impl::tuple_base<make_index_seq<sizeof...(T)>, T...>;
    OPUS_H_D constexpr tuple() = default;

    template <typename U, typename std::enable_if<sizeof...(T) == 1 && !std::is_same<remove_cvref_t<U>, tuple>::value, bool>::type = false>
    OPUS_H_D constexpr tuple(U&& u) : base(std::forward<U>(u)) {}

    template <typename... U, typename std::enable_if<sizeof...(U) == sizeof...(T) && sizeof...(U) >= 2, bool>::type = false>
    OPUS_H_D constexpr tuple(U&&... u) : base(std::forward<U>(u)...) {}
};
template<typename... T> __host__ __device__ tuple(T&&...) -> tuple<remove_cvref_t<T>...>;

namespace impl {
template<typename T, typename S> struct tuple_array_helper;
template<typename T, index_t... Is> struct tuple_array_helper<T, seq<Is...>> { using type = tuple<decltype((Is, remove_cvref_t<T>{}))...>; };
}
template<typename T, index_t N> using tuple_array = typename impl::tuple_array_helper<T, make_index_seq<N>>::type;  // alias for tuple<T, T....>, Nx Ts

// get the I-th type within the tuple, O(1) via compiler intrinsic
template<index_t I, class T>     struct tuple_element;
template<index_t I, class... Ts> struct tuple_element<I, opus::tuple<Ts...>> { using type = __type_pack_element<I, Ts...>; };
template<index_t I, class T> using tuple_element_t = typename tuple_element<I, T>::type;

template <index_t I, class... T> OPUS_H_D constexpr decltype(auto) get(tuple<T...> const& t) { static_assert(I < sizeof...(T)); return impl::getv<I>(t); }
template <index_t I, class... T> OPUS_H_D constexpr decltype(auto) get(tuple<T...>& t)       { static_assert(I < sizeof...(T)); return impl::getv<I>(t); }
template <index_t I, class... T> OPUS_H_D constexpr decltype(auto) get(tuple<T...>&& t)      { static_assert(I < sizeof...(T)); return impl::getv<I>(std::move(t)); }

template <index_t I0, index_t I1, index_t... Is, class T>  /*recursive get*/
OPUS_H_D constexpr decltype(auto) get(T&& t) { return get<I1, Is...>(get<I0>(std::move(t))); }

template <typename... T> OPUS_H_D constexpr auto make_tuple(T&&... xs) { return tuple<remove_cvref_t<T>...>(std::forward<T>(xs)...); }

template<typename F, typename... R, std::enable_if_t<(std::is_integral_v<R> && ...), bool> = true>  // const integer based static_for loop
OPUS_H_D constexpr void static_for(F f, R... range) {
    if      constexpr (sizeof...(range) == 1) { auto end = get<0>(make_tuple(range...));        for(index_t i = 0; i < end; i++) { f(i); } }
    else if constexpr (sizeof...(range) == 2) { auto [start, end] = make_tuple(range...);       for(index_t i = start; i < end; i++) { f(i); } }
    else if constexpr (sizeof...(range) == 3) { auto [start, end, step] = make_tuple(range...); for(index_t i = start; i < end; i += step) { f(i); } }
}

namespace impl {
template <typename T, index_t... Is> OPUS_H_D constexpr auto make_repeated_tuple(T&& x, seq<Is...>) { return opus::make_tuple((void(Is), std::forward<T>(x))...); }
} // namespace impl
template <index_t N, typename T> OPUS_H_D constexpr auto make_repeated_tuple(T&& x) { return impl::make_repeated_tuple(std::forward<T>(x), make_index_seq<N>{}); }
template <typename T, index_t N> OPUS_H_D constexpr auto make_repeated_tuple(T&& x, number<N>) { return impl::make_repeated_tuple(std::forward<T>(x), make_index_seq<N>{}); }

namespace impl {
template <class T0, class T1, index_t... I0, index_t... I1>
OPUS_H_D constexpr auto concat_tuple(T0 const& t0, T1 const& t1, seq<I0...>, seq<I1...>) { return opus::make_tuple(get<I0>(t0)..., get<I1>(t1)...); }
template <class T0, class T1, class T2, index_t... I0, index_t... I1, index_t...I2>
OPUS_H_D constexpr auto concat_tuple(T0 const& t0, T1 const& t1, T2 const& t2, seq<I0...>, seq<I1...>, seq<I2...>) { return opus::make_tuple(get<I0>(t0)..., get<I1>(t1)..., get<I2>(t2)...); }
template <class T0, class T1, class T2, class T3, index_t... I0, index_t... I1, index_t...I2, index_t...I3>
OPUS_H_D constexpr auto concat_tuple(T0 const& t0, T1 const& t1, T2 const& t2, T3 const& t3, seq<I0...>, seq<I1...>, seq<I2...>, seq<I3...>) { return opus::make_tuple(get<I0>(t0)..., get<I1>(t1)..., get<I2>(t2)..., get<I3>(t3)...); }
}
template <class T0> OPUS_H_D  constexpr auto concat_tuple(T0 const& t0) { return t0; }
template <class T0, class T1>
OPUS_H_D  constexpr auto concat_tuple(T0 const& t0, T1 const& t1) { return impl::concat_tuple(t0, t1, make_index_seq<T0::size()>{}, make_index_seq<T1::size()>{}); }
template <class T0, class T1, class T2>
OPUS_H_D  constexpr auto concat_tuple(T0 const& t0, T1 const& t1, T2 const& t2) { return impl::concat_tuple(t0, t1, t2, make_index_seq<T0::size()>{}, make_index_seq<T1::size()>{}, make_index_seq<T2::size()>{}); }
template <class T0, class T1, class T2, class T3>
OPUS_H_D  constexpr auto concat_tuple(T0 const& t0, T1 const& t1, T2 const& t2, T3 const& t3) {
                                            return impl::concat_tuple(t0, t1, t2, t3, make_index_seq<T0::size()>{}, make_index_seq<T1::size()>{}, make_index_seq<T2::size()>{}, make_index_seq<T3::size()>{}); }
namespace impl { template <class T0, class T1, class T2, class T3, class T4, index_t... I0, index_t... I1, index_t... I2, index_t... I3, index_t... I4>
OPUS_H_D constexpr auto concat_tuple(T0 const& t0, T1 const& t1, T2 const& t2, T3 const& t3, T4 const& t4, seq<I0...>, seq<I1...>, seq<I2...>, seq<I3...>, seq<I4...>) { return opus::make_tuple(get<I0>(t0)..., get<I1>(t1)..., get<I2>(t2)..., get<I3>(t3)..., get<I4>(t4)...); } }
template <class T0, class T1, class T2, class T3, class T4>
OPUS_H_D constexpr auto concat_tuple(T0 const& t0, T1 const& t1, T2 const& t2, T3 const& t3, T4 const& t4) { return impl::concat_tuple(t0, t1, t2, t3, t4, make_index_seq<T0::size()>{}, make_index_seq<T1::size()>{}, make_index_seq<T2::size()>{}, make_index_seq<T3::size()>{}, make_index_seq<T4::size()>{}); }
template <class T0, class T1, class T2, class T3, class T4, class T5, class... Ts>
OPUS_H_D constexpr auto concat_tuple(T0 const& t0, T1 const& t1, T2 const& t2, T3 const& t3, T4 const& t4, T5 const& t5, Ts const&... ts) { return concat_tuple(concat_tuple(t0, t1, t2, t3, t4), concat_tuple(t5, ts...)); }

template <typename> struct is_tuple : false_type {};
template <typename... T> struct is_tuple<opus::tuple<T...>> : true_type {};
template <typename T> static constexpr bool is_tuple_v = is_tuple<remove_cvref_t<T>>::value;
template <typename T> struct is_static_tuple : is_constant<remove_cvref_t<T>> {};
template <> struct is_static_tuple<underscore> : true_type {};
template <typename... T> struct is_static_tuple<opus::tuple<T...>> : bool_constant<(is_static_tuple<T>::value && ...)> {};
template <typename T> static constexpr bool is_static_tuple_v = is_static_tuple<remove_cvref_t<T>>::value;
template<typename T> struct get_value_type<T, std::enable_if_t<is_tuple_v<T>>> { using type = tuple_element_t<0, T>; };   // TODO: get the first element type

template<typename T> OPUS_H_D constexpr std::enable_if_t<is_tuple_v<T>, index_t> size(T&&) { return remove_cvref_t<T>::size(); /* tuple size */}
template<typename T> OPUS_H_D constexpr std::enable_if_t<is_tuple_v<T>, index_t> size()    { return remove_cvref_t<T>::size(); /* tuple size */}

template <typename T, std::enable_if_t<!is_tuple_v<T>, bool> = true> OPUS_H_D constexpr auto explode_tuple(const T& t) { return opus::make_tuple(t); }
template <typename T, index_t... Is> OPUS_H_D constexpr auto                                 explode_tuple(const T&, seq<Is...>);
template <typename T, std::enable_if_t<is_tuple_v<T>, bool> = true> OPUS_H_D constexpr auto  explode_tuple(const T& t) { return explode_tuple(t, make_index_seq<size<T>()>{}); }
template <typename T, index_t... Is> OPUS_H_D constexpr auto                                 explode_tuple(const T& t, seq<Is...>) { return concat_tuple(explode_tuple(get<Is>(t))...); }

template <typename T, index_t... Is> OPUS_H_D constexpr auto flatten_tuple_general(const T& t, seq<Is...>) { return concat_tuple(explode_tuple(get<Is>(t))...); }
template <typename T, std::enable_if_t<is_tuple_v<T> && !(is_tuple_v<tuple_element_t<0, remove_cvref_t<T>>>), bool> = true>
OPUS_H_D constexpr auto flatten_tuple(const T& t) { return t; }  // already flat
template <typename T, std::enable_if_t<!is_tuple_v<T>, bool> = true>
OPUS_H_D constexpr auto flatten_tuple(const T& t) { return flatten_tuple_general(t, make_index_seq<size<T>()>{}); }  // non-tuple (e.g. seq)
namespace impl { // direct flatten for 1-level nested tuples -- bypasses concat_tuple + explode_tuple
template<typename T, index_t... Gs> constexpr auto group_sizes(seq<Gs...>) { return seq<size<tuple_element_t<Gs, T>>()...>{}; }
template<typename T, index_t... Gs> constexpr index_t group_total(seq<Gs...>) { return (size<tuple_element_t<Gs, T>>() + ...); }
template<index_t J, index_t... Gs, index_t... Ns> constexpr index_t flat_group(seq<Gs...>, seq<Ns...>) { index_t acc = 0, r = 0; ((void)(acc += Ns, (acc <= J ? (void)(r = Gs + 1) : (void)0)), ...); return r; }
template<typename T, index_t G, index_t... Gs> constexpr index_t group_offset(seq<Gs...>) { return ((Gs < G ? size<tuple_element_t<Gs, T>>() : 0) + ...); }
template<typename T, index_t J, typename GS> OPUS_H_D constexpr auto flatten_at(const T& t) {
    constexpr auto gs = make_index_seq<size<T>()>{}; constexpr index_t G = flat_group<J>(gs, GS{}); return get<J - group_offset<T, G>(gs)>(get<G>(t)); }
template<typename T, typename GS, index_t... Js> OPUS_H_D constexpr auto flatten_tuple_impl(const T& t, seq<Js...>) { return opus::make_tuple(flatten_at<T, Js, GS>(t)...); }
}
template <typename T, std::enable_if_t<is_tuple_v<T> && (is_tuple_v<tuple_element_t<0, remove_cvref_t<T>>>), bool> = true>
OPUS_H_D constexpr auto flatten_tuple(const T& t) { using U = remove_cvref_t<T>; constexpr auto gs = make_index_seq<size<U>()>{}; return impl::flatten_tuple_impl<U, decltype(impl::group_sizes<U>(gs))>(t, make_index_seq<impl::group_total<U>(gs)>{}); }

namespace impl {
template<typename Outer, typename Inner, index_t...Is>
OPUS_H_D constexpr auto embed_nested_tuple_impl(const Outer& ot, const Inner& it, seq<Is...>) { return opus::make_tuple(concat_tuple(get<Is>(ot), get<Is>(it))...); }

template<typename TargetType, typename T, index_t...Is>
OPUS_H_D constexpr auto tuple_count_impl(seq<Is...>) { return (number<std::is_same_v<remove_cvref_t<decltype(get<Is>(T{}))>, remove_cvref_t<TargetType>> ? 1 : 0>{} + ...); }
}
// Outer: tuple<tuple<X, X>, tuple<Y>>,  Inner: tuple<tuple<Z>, tuple<W>> => tuple<tuple<X, X, Z>, tuple<Y, W>>
template<typename Outer, typename Inner>
OPUS_H_D constexpr auto embed_nested_tuple(const Outer& ot, const Inner& it) {
    static_assert(size<Outer>() == size<Inner>());
    return impl::embed_nested_tuple_impl(ot, it, make_index_seq<size<Outer>()>{});
}

template< typename TargetType, typename T, std::enable_if_t<is_tuple_v<T>, bool> = true>
OPUS_H_D constexpr index_t tuple_count(const T& /*t*/) { return impl::tuple_count_impl<TargetType, remove_cvref_t<T>>(make_index_seq<size<T>()>{}).value; }

template< typename TargetType, typename T, std::enable_if_t<is_tuple_v<T>, bool> = true>
OPUS_H_D constexpr index_t tuple_count() { return impl::tuple_count_impl<TargetType, remove_cvref_t<T>>(make_index_seq<size<T>()>{}).value; }

template<index_t...Is> OPUS_H_D constexpr auto seq_to_tuple(seq<Is...>) { return opus::make_tuple(number<Is>{}...); }

template<index_t...Is>                                             OPUS_H_D constexpr auto to_tuple(seq<Is...>) { return opus::make_tuple(number<Is>{}...); }
template<typename T, std::enable_if_t<is_tuple_v<T>, bool> = true> OPUS_H_D constexpr auto to_tuple(const T& t) { return t; }

namespace impl {
template <typename R, typename T>            OPUS_H_D constexpr auto reduce_tuple_impl(const T& t, seq<>)  { return t; }
template <typename R, typename T, index_t I> OPUS_H_D constexpr auto reduce_tuple_impl(const T& t, seq<I>) { return t; }

template <typename R, typename T, index_t I0, index_t I1, index_t... Is>
OPUS_H_D constexpr auto reduce_tuple_impl(const T& t, seq<I0, I1, Is...>) {
    return reduce_tuple_impl<R>(opus::make_tuple(R{}(get<I0>(t), get<I1>(t)), get<Is>(t)...), make_index_seq<sizeof...(Is) + 1>{});
}
}
template<typename R, typename T, std::enable_if_t<is_tuple_v<T>, bool> = true>
OPUS_H_D constexpr auto reduce_tuple(const T & t) { return  impl::reduce_tuple_impl<R>(t, make_index_seq<size<T>()>{}); }
template<typename T, std::enable_if_t<is_tuple_v<T>, bool> = true> OPUS_H_D constexpr auto reduce_tuple_sum(const T & t) { return reduce_tuple<opus::plus>(t); }
template<typename T, std::enable_if_t<is_tuple_v<T>, bool> = true> OPUS_H_D constexpr auto reduce_tuple_mul(const T & t) { return reduce_tuple<opus::multiplies>(t); }
// Fast path: fold expression for tuple of number<> types (avoids N-1 intermediate tuple types)
template<typename... Ns, std::enable_if_t<sizeof...(Ns) != 0 && (is_constant_v<Ns> && ...), bool> = true>
OPUS_H_D constexpr auto reduce_tuple_mul(const tuple<Ns...>&) { return opus::tuple<number<(Ns::value * ...)>>{}; }

namespace impl {
template<typename PT, index_t... Js>
OPUS_H_D constexpr index_t underscore_count_in(seq<Js...>) { return ((is_underscore_v<remove_cvref_t<decltype(get<Js>(PT{}))>> ? 1 : 0) + ... + 0); }

template<typename PT, typename MaxN, index_t I>
OPUS_H_D constexpr index_t peephole_idx() { constexpr index_t c = underscore_count_in<PT>(make_index_seq<I>{}); return c < MaxN::value ? c : MaxN::value - 1; }

template<typename PT, typename MaxN, index_t... Is>
OPUS_H_D constexpr auto to_peepholed_seq_impl(seq<Is...>) { return seq<peephole_idx<PT, MaxN, Is>()...>{}; }

template<typename PeepholedTuple, typename IncomTuple, index_t...Ps,  index_t...Is>
OPUS_H_D constexpr decltype(auto) merge_peepholed_tuple_impl(PeepholedTuple&& pt, IncomTuple&& it, seq<Ps...>, seq<Is...>) {
    return opus::make_tuple([&](){ if constexpr (is_underscore_v<remove_cvref_t<decltype(get<Ps>(pt))>>) return get<Is>(it);
                                   else return get<Ps>(pt);}()... );
}
}
// (Peepholed)tuple<*, *, _, *, _> + (Income)tuple<#, @> -> tuple<*, *, #, *, @>.  "_"(underscore) indicate a peephole for income tuple to chime in
template<typename PeepholedTuple, typename IncomeTuple>
OPUS_H_D constexpr decltype(auto) merge_peepholed_tuple(PeepholedTuple&& pt, IncomeTuple&& it) {
    if constexpr (tuple_count<underscore, PeepholedTuple>() == 0) return pt;
    else {
        constexpr auto income_seq = impl::to_peepholed_seq_impl< remove_cvref_t<PeepholedTuple>,
                                                                 number<opus::size<IncomeTuple>()> >(make_index_seq<opus::size<PeepholedTuple>()>{});
        return impl::merge_peepholed_tuple_impl(std::forward<PeepholedTuple>(pt), std::forward<IncomeTuple>(it), make_index_seq<opus::size<PeepholedTuple>()>{}, income_seq);
    }
}
} // namespace opus

// implementing the "tuple-like binding protocol", don't use below directly
namespace std {
template <typename... Ts> struct tuple_size<opus::tuple<Ts...>>       : std::integral_constant<std::size_t, sizeof...(Ts)> {};
template <typename... Ts> struct tuple_size<const opus::tuple<Ts...>> : std::integral_constant<std::size_t, sizeof...(Ts)> {};
template <std::size_t I, typename... Ts> struct tuple_element<I, opus::tuple<Ts...>>       { using type = __type_pack_element<I, Ts...>; };
template <std::size_t I, typename... Ts> struct tuple_element<I, const opus::tuple<Ts...>> { using type = const __type_pack_element<I, Ts...>; };
} // namespace std

namespace opus {
// fwd-decl mma adaptors -- needed so make_tiled_mma() parses on archs (gfx12) where full defs are gated out.
struct mfma_adaptor; struct mfma_adaptor_swap_ab; struct wmma_adaptor; struct wmma_adaptor_swap_ab;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// transforms
template<typename X, typename Y, index_t... Is> constexpr auto embed(const X& x, const Y& y, seq<Is...>) { return ( ... + (get<Is>(x) * get<Is>(y))); }
template<typename X, typename Y>                constexpr auto embed(const X& x, const Y& y) { return embed(x, y, make_index_seq<X::size()>{}); }

namespace impl {
template <typename F, typename X, index_t... Is> OPUS_H_D constexpr auto transform_tuple_impl(F f, const X& x, seq<Is...>) { return opus::make_tuple(f(get<Is>(x))...); }
template <typename F, typename X, index_t... Is> OPUS_H_D constexpr auto transform_tuple_with_idx_impl(F f, const X& x, seq<Is...>) { return opus::make_tuple(f(get<Is>(x), number<Is>{})...); }
} // namespace impl
// f(auto item)
template <typename F, typename X> OPUS_H_D constexpr auto transform_tuple(F f, const X& x) { return impl::transform_tuple_impl(f, x, make_index_seq<size<X>()>{}); }
// f(auto item, auto index)
template <typename F, typename X> OPUS_H_D constexpr auto transform_tuple_with_idx(F f, const X& x) { return impl::transform_tuple_with_idx_impl(f, x, make_index_seq<size<X>()>{}); }

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// layout, simple linear nd layout with stride, static or dynamic supported
namespace impl {
template<typename Shape, index_t I, index_t... Js>
OPUS_H_D constexpr auto packed_stride_at(seq<Js...>) { return (get<I + 1 + Js>(Shape{}) * ... * number<1>{}); }

template<typename Shape, index_t... Is>
OPUS_H_D constexpr auto packed_shape_to_stride_impl(seq<Is...>) { return opus::make_tuple(packed_stride_at<Shape, Is>(make_index_seq<Shape::size() - Is - 1>{})...); }
}

template<typename Shape>
OPUS_H_D constexpr auto packed_shape_to_stride(const Shape&) { return impl::packed_shape_to_stride_impl<Shape>(make_index_seq<Shape::size()>{}); }

template<typename Layout, typename Coord>
OPUS_H_D constexpr decltype(auto) coord_to_linear(const Layout& layout, const Coord& coord) { static_assert(size<decltype(layout.stride())>() == size<Coord>()); return embed(layout.stride(), coord); }

// Shape/Stride/Coord, they are all tuples. if Coord is not false_type, will use merge_peepholed_tuple() to construct real coord
template<typename Shape_, typename Stride_, typename Coord_ = false_type>
struct layout : public tuple<remove_cvref_t<Shape_>, remove_cvref_t<Stride_>, remove_cvref_t<Coord_>> {
    using base   = tuple<remove_cvref_t<Shape_>, remove_cvref_t<Stride_>, remove_cvref_t<Coord_>>;
    using Shape  = remove_cvref_t<Shape_>;
    using Stride = remove_cvref_t<Stride_>;
    using Coord  = remove_cvref_t<Coord_>;  // peepholed coord

    static constexpr index_t rank = Shape::size();
    static_assert(Shape::size() == Stride::size());
    static_assert(std::is_same_v<Coord, false_type> || size<std::conditional_t<std::is_same_v<Coord, false_type>, Shape, Coord>>() == rank, "Coord should be either false_type or a tuple with same size as Shape");
    static constexpr index_t coord_rank = [](){
        if constexpr (std::is_same_v<Coord, false_type>) return rank;
        else          return rank - tuple_count<underscore>(Coord{});
    }();

    OPUS_H_D constexpr layout(const Shape& shape, const Stride& stride, const Coord& coord = {}) : base(shape, stride, coord){}
    OPUS_H_D constexpr layout(Shape&& shape, Stride&& stride, Coord&& coord = {}) : base(shape, stride, coord){}

    // get ith element from shape/stride. if no I, then get the shape/stride as tuple
    template <int... I> OPUS_H_D constexpr decltype(auto) shape()        { return get<0,I...>(static_cast<base&>(*this)); }
    template <int... I> OPUS_H_D constexpr decltype(auto) shape()  const { return get<0,I...>(static_cast<const base&>(*this)); }
    template <int... I> OPUS_H_D constexpr decltype(auto) stride()       { return get<1,I...>(static_cast<base&>(*this)); }
    template <int... I> OPUS_H_D constexpr decltype(auto) stride() const { return get<1,I...>(static_cast<const base&>(*this)); }
    template <int... I> OPUS_H_D constexpr decltype(auto) coord()        { return get<2,I...>(static_cast<base&>(*this)); }
    template <int... I> OPUS_H_D constexpr decltype(auto) coord() const  { return get<2,I...>(static_cast<const base&>(*this)); }

    template <typename... Cs, std::enable_if_t<(!is_tuple_v<Cs> && ...), bool> = true>
    OPUS_H_D constexpr decltype(auto) operator()(Cs&&... cs) const { return this->operator()(opus::make_tuple(std::forward<Cs>(cs)...)); }

    template <typename InCoord, std::enable_if_t<is_tuple_v<InCoord>, bool> = true>
    OPUS_H_D constexpr decltype(auto) operator()(InCoord&& c) const {
        if constexpr (std::is_same_v<Coord, false_type>) return coord_to_linear(*this, c);
        else                                             return coord_to_linear(*this, merge_peepholed_tuple(coord(), c)); }
};

template <typename Layout> struct layout_linear;
template<index_t cached_vec_, typename Layout> struct layout_cached;

// use cached_vec to dispatch which layout implementation. cached_vec < 0 : "layout", cached_vec == 0 : "layout_linear", cached_vec > 0 : "layout_cached"
template <index_t cached_vec = 0, typename Sx, typename Sy> OPUS_H_D constexpr auto make_layout(Sx&& s, Sy&& t) {
    if      constexpr (cached_vec < 0)  return layout<Sx, Sy>(std::forward<Sx>(s), std::forward<Sy>(t));
    else if constexpr (cached_vec == 0) return layout_linear<layout<Sx, Sy>>(std::forward<Sx>(s), std::forward<Sy>(t));
    else                                return layout_cached<cached_vec, layout<Sx, Sy>>(std::forward<Sx>(s), std::forward<Sy>(t)); }
template <index_t cached_vec = 0, typename Sx, typename Sy, typename Sz>
OPUS_H_D constexpr auto                       make_layout(Sx&& s, Sy&& t, Sz&& c) {
    if      constexpr (cached_vec < 0)  return layout<Sx, Sy, Sz>(std::forward<Sx>(s), std::forward<Sy>(t), std::forward<Sz>(c));
    else if constexpr (cached_vec == 0) return layout_linear<layout<Sx, Sy, Sz>>(std::forward<Sx>(s), std::forward<Sy>(t), std::forward<Sz>(c));
    else                                return layout_cached<cached_vec, layout<Sx, Sy, Sz>>(std::forward<Sx>(s), std::forward<Sy>(t), std::forward<Sz>(c)); }
template <index_t cached_vec = 0, typename... Ts, std::enable_if_t<(!is_tuple_v<Ts> && ...), bool> = true>
OPUS_H_D constexpr auto                       make_layout(Ts&&... ss) { return make_layout<cached_vec>(opus::make_tuple(ss...), packed_shape_to_stride(opus::make_tuple(ss...))); }
template <index_t cached_vec = 0, typename S> OPUS_H_D constexpr auto make_layout(S&& s) { return make_layout<cached_vec>(std::forward<S>(s), packed_shape_to_stride(s)); }

template <index_t cached_vec = 0, typename S> OPUS_H_D constexpr auto               make_layout_packed(S&& s) { return make_layout<cached_vec>(std::forward<S>(s), packed_shape_to_stride(s)); } // same as single arg make_layout
template <index_t cached_vec = 0, typename Sx, typename Sz> OPUS_H_D constexpr auto make_layout_packed(Sx&& s, Sz&& c) { return make_layout<cached_vec>(std::forward<Sx>(s), packed_shape_to_stride(s), std::forward<Sz>(c)); }

template <typename Layout>
struct layout_linear : public remove_cvref_t<Layout>{
    using base = remove_cvref_t<Layout>;

    template<typename Shape, typename Stride, typename Coord = false_type>
    OPUS_H_D constexpr layout_linear(const Shape& shape, const Stride& stride, const Coord& coord = {}) : base(shape, stride, coord), linear_offset(0){}

    template<typename Shape, typename Stride, typename Coord = false_type>
    OPUS_H_D constexpr layout_linear(Shape&& shape, Stride&& stride, Coord&& coord = {}) : base(shape, stride, coord), linear_offset(0){}

    template <typename... Cs, std::enable_if_t<(!is_tuple_v<Cs> && ...), bool> = true>
    OPUS_H_D constexpr decltype(auto) operator()(Cs&&... cs) const { return this->operator()(opus::make_tuple(std::forward<Cs>(cs)...)); }

    template <typename InCoord, std::enable_if_t<is_tuple_v<InCoord>, bool> = true>
    OPUS_H_D constexpr decltype(auto) operator()(InCoord&& c) const {
        if constexpr (std::is_same_v<typename base::Coord, false_type>) return linear_offset + coord_to_linear(*this, c);
        else                                             return linear_offset + coord_to_linear(*this, merge_peepholed_tuple(base::coord(), c)); }

    OPUS_H_D constexpr void inc(index_t offset) { linear_offset += offset; }
    OPUS_H_D constexpr layout_linear& operator+=(index_t offset) { inc(offset); return *this; }
    OPUS_H_D constexpr layout_linear operator+(index_t offset) const { layout_linear result(*this); result += offset; return result; }

    index_t linear_offset;
};

template <index_t vec, typename Layout> OPUS_H_D constexpr auto layout_to_vectorized_issue_space();
template<index_t vec, typename Layout> OPUS_H_D constexpr auto layout_to_offsets(const Layout& u);

template<index_t cached_vec_, typename Layout>
struct layout_cached : public remove_cvref_t<Layout> {
    using base = remove_cvref_t<Layout>;
    static constexpr index_t cached_vec = cached_vec_;

    static constexpr auto issue_space_vec = layout_to_vectorized_issue_space<cached_vec, base>();
    static constexpr index_t num_issues = get<0>(reduce_tuple_mul(issue_space_vec)).value;

    template<typename Shape, typename Stride, typename Coord = false_type>
    OPUS_H_D constexpr layout_cached(const Shape& shape, const Stride& stride, const Coord& coord = {}) : base(shape, stride, coord), offsets{layout_to_offsets<cached_vec>(static_cast<base>(*this))}{}

    template<typename Shape, typename Stride, typename Coord = false_type>
    OPUS_H_D constexpr layout_cached(Shape&& shape, Stride&& stride, Coord&& coord = {}) : base(shape, stride, coord), offsets{layout_to_offsets<cached_vec>(static_cast<base>(*this))}{}

    template <typename... Cs, std::enable_if_t<(!is_tuple_v<Cs> && ...), bool> = true>
    OPUS_H_D constexpr decltype(auto) operator()(Cs&&... cs) const { return this->operator()(opus::make_tuple(std::forward<Cs>(cs)...)); }

    template <typename InCoord, std::enable_if_t<is_tuple_v<InCoord>, bool> = true>
    OPUS_H_D constexpr decltype(auto) operator()(InCoord&& c) const { constexpr auto u_linear = make_layout<-1>(issue_space_vec); return offsets[u_linear(c)]; }

    OPUS_H_D constexpr void inc(index_t offset) { static_for<num_issues>([&](auto i){ offsets[i] += offset; }); }
    OPUS_H_D constexpr layout_cached& operator+=(index_t offset) { inc(offset); return *this; }
    OPUS_H_D constexpr layout_cached operator+(index_t offset) const { layout_cached result(*this); result += offset; return result; }

    array<index_t, num_issues> offsets;
};

// Wraps a layout with a *compile-time* offset N. Keeping N in the type lets smem::tr_load lower it into the `offset:` immediate of ds_read_b64_tr_*.
// Construct it as `layout/layout_linear/layout_cached + number<N>{}`
template<typename Layout, index_t N>
struct layout_shifted : public remove_cvref_t<Layout> {
    using base = remove_cvref_t<Layout>;
    OPUS_H_D constexpr layout_shifted(const base& layout) : base(layout) {}
    template<typename Shape, typename Stride, typename Coord = false_type>
    OPUS_H_D constexpr layout_shifted(const Shape& shape, const Stride& stride, const Coord& coord = {}) : base(shape, stride, coord) {}
    template <typename... Cs>
    OPUS_H_D constexpr auto operator()(Cs&&... cs) const { return base::operator()(std::forward<Cs>(cs)...) + N; }

    OPUS_H_D constexpr layout_shifted& operator+=(index_t offset) { static_cast<base&>(*this) += offset; return *this; }
    OPUS_H_D constexpr layout_shifted operator+(index_t offset) const { layout_shifted result(*this); static_cast<base&>(result) += offset; return result; }
};

template<typename T> struct is_layout : false_type {};
template<typename X, typename Y, typename Z> struct is_layout<layout<X, Y, Z>> : true_type {};
template<index_t cached_vec, typename Layout> struct is_layout<layout_cached<cached_vec, Layout>> : true_type {};
template<typename Layout> struct is_layout<layout_linear<Layout>> : true_type {};
template<typename Layout, index_t N> struct is_layout<layout_shifted<Layout, N>> : true_type {};
template<typename T> constexpr bool is_layout_v = is_layout<remove_cvref_t<T>>::value;

template<typename Layout> struct layout_shift_traits { using base = Layout; static constexpr index_t value = 0; };
template<typename Layout, index_t N> struct layout_shift_traits<layout_shifted<Layout, N>> { using base = remove_cvref_t<Layout>; static constexpr index_t value = N; };
template<typename Layout, index_t N, std::enable_if_t<is_layout_v<remove_cvref_t<Layout>>, bool> = true>
OPUS_H_D constexpr auto operator+(const Layout& layout, number<N>) {
    using shift = layout_shift_traits<remove_cvref_t<Layout>>;
    if constexpr (N == 0) return layout;
    else                  return layout_shifted<typename shift::base, shift::value + N>(static_cast<const typename shift::base&>(layout));
}

template <typename Layout>
OPUS_H_D constexpr auto layout_to_issue_space() {
    using maybe_coord = std::conditional_t<std::is_same_v<typename Layout::Coord, false_type>, typename Layout::Shape, typename Layout::Coord>;
    using issue_space_y = remove_cvref_t<decltype(pickup_shape(typename Layout::Shape{}, maybe_coord{}, underscore{}))>;
    using single_issue_space = remove_cvref_t<decltype(make_repeated_tuple(number<1>{}, number<size<typename Layout::Shape>()>{}))>;
    using fallback_issue_space_y = std::conditional_t<std::is_same_v<issue_space_y, opus::tuple<>>, single_issue_space, issue_space_y>;
    using issue_space = std::conditional_t<std::is_same_v<typename Layout::Coord, false_type>, single_issue_space, fallback_issue_space_y>;
    return issue_space{};
}
template<typename issue_space, int vec = 1>
OPUS_H_D constexpr auto vectorize_issue_space(issue_space, number<vec> = {}) {
    constexpr index_t vec_from_issue_space = get<size<issue_space>() - 1>(issue_space{}).value;     // here we get the original last dim length(which should be y dim)
    static_assert(vec_from_issue_space % vec == 0, "please make sure requested vec size can be dividable of vec from issue space");

    constexpr auto issue_space_vec = transform_tuple_with_idx([&](auto item, auto index){           // modify the last dim, divide it by vec. Result is still a tuple
        if constexpr (index.value == size<issue_space>() - 1) return number<item.value / vec>{};
        else                                                  return item;    }, issue_space{});
    return issue_space_vec;
}
template <index_t vec, typename Layout>
OPUS_H_D constexpr auto layout_to_vectorized_issue_space() {
    constexpr auto issue_space = layout_to_issue_space<Layout>();
    constexpr auto issue_space_vec = vectorize_issue_space(issue_space, number<vec>{});
    return issue_space_vec;
}

// Cache issue-space computations for load/store (avoids redundant evaluation across methods)
template<typename Layout, index_t vec = 1> struct layout_load_traits {
    static constexpr auto issue_space = layout_to_issue_space<Layout>();
    static constexpr auto issue_space_vec = vectorize_issue_space(issue_space, number<vec>{}); static constexpr auto r_elem = get<0>(reduce_tuple_mul(issue_space_vec));
};
// Runtime flat index -> multi-index tuple (all index_t) -- avoids per-iteration template instantiation
template<index_t... Is, index_t... Ns> OPUS_H_D constexpr auto flat_to_coords(index_t flat, seq<Is...>, tuple<number<Ns>...>) {
    constexpr index_t strides[] = {impl::ford_stride<Is>(make_index_seq<sizeof...(Ns)>{}, seq<Ns...>{})...}, dims[] = {Ns...};
    return opus::make_tuple(static_cast<index_t>((flat / strides[Is]) % dims[Is])...); }
// Pre-compute offsets via runtime loop -- 1 coord_to_linear instantiation per layout instead of N
template<index_t vec, typename Layout> OPUS_H_D constexpr auto layout_to_offsets(const Layout& u) {
    using LT = layout_load_traits<Layout, vec>; constexpr auto issue_space_vec = LT::issue_space_vec;
    constexpr index_t num_issues = LT::r_elem.value, ndim = size<remove_cvref_t<decltype(issue_space_vec)>>();
    array<index_t, num_issues> offsets;
    for (index_t i = 0; i < num_issues; i++) offsets[i] = u(flat_to_coords(i, make_index_seq<ndim>{}, issue_space_vec));
    return offsets; }
// Compile-time per-issue offsets for layouts with static Shape/Stride
template<typename Layout, index_t vec>
inline constexpr auto layout_imm_offsets_v = layout_to_offsets<vec>(Layout{typename Layout::Shape{}, typename Layout::Stride{}, typename Layout::Coord{}});
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// vector, a wrapper for __attribute__((ext_vector_type(*)))
namespace impl {
template <typename T, index_t N> struct packed_vec : opus::array<T, N> { using base = opus::array<T, N>; using base::base; };
template<typename V, index_t N, bool = is_packs_v<V>> struct vector_storage { using type = V __attribute__((ext_vector_type(N))); };
template<typename V, index_t N> struct vector_storage<V, N, true> { using type = packed_vec<V, N>; };
}
template <typename V_, index_t N_> // V_ must be literal type, otherwise clang ext_vector_type will not recognize
struct vector {
    static constexpr index_t N = N_;
    using value_type           = remove_cvref_t<V_>;
    using type = typename impl::vector_storage<value_type, N_>::type;
};
template <typename T, index_t N> using vector_t = typename vector<T, N>::type;

template <typename> struct is_vector : false_type {};
template <typename T, index_t N> struct is_vector<impl::packed_vec<T, N>>    : true_type {};
template <typename T, index_t N> struct is_vector<impl::packed_vec<T, N>&>   : true_type {};
template <typename T, index_t N> struct is_vector<const impl::packed_vec<T, N>&> : true_type {};
template <typename T, index_t N> struct is_vector<impl::packed_vec<T, N>&&>  : true_type {};
template <typename T, index_t N> struct is_vector<T __attribute((ext_vector_type(N)))> : true_type {};
template <typename T, index_t N> struct is_vector<T __attribute((ext_vector_type(N)))&> : true_type {};
template <typename T, index_t N> struct is_vector<const T __attribute((ext_vector_type(N)))&> : true_type {};
template <typename T, index_t N> struct is_vector<T __attribute((ext_vector_type(N)))&&> : true_type {};
template <typename E> static constexpr bool is_vector_v = is_vector<E>::value;

namespace impl {
template <typename T>            struct vector_traits_impl { using dtype = remove_cvref_t<T>; static constexpr index_t size() { return 1; } };
template <typename T, index_t N> struct vector_traits_impl<T __attribute__((ext_vector_type(N)))> { using dtype = T; static constexpr index_t size() { return N; } };
template <typename T, index_t N> struct vector_traits_impl<array<T, N>> { using dtype = T; static constexpr index_t size() { return N; } };
template <typename T, index_t N> struct vector_traits_impl<impl::packed_vec<T, N>> { using dtype = T; static constexpr index_t size() { return N; } };
template <typename... T>         struct vector_traits_impl<tuple<T...>> { using dtype = __type_pack_element<0, T...> /*TODO: use first type*/; static constexpr index_t size() { return sizeof...(T); } };
}
template <typename T> struct vector_traits : public impl::vector_traits_impl<remove_cvref_t<T>> {};

template<typename T> OPUS_H_D constexpr std::enable_if_t<is_vector_v<T>, index_t> size(T&&) {  return vector_traits<T>::size();   /* vector size */}
template<typename T> OPUS_H_D constexpr std::enable_if_t<is_vector_v<T>, index_t> size()    {  return vector_traits<T>::size();   /* vector size */}

template<typename T> struct get_value_type<T, std::enable_if_t<is_vector_v<T>>> { using type = typename vector_traits<T>::dtype; };

namespace impl {
template<typename D, typename...> struct vector_return_type_helper { using type = D; };
template<typename... Types>
struct vector_return_type_helper<void, Types...> : std::common_type<Types...> { static_assert(std::conjunction_v<not_ref_wrapper<Types>...>, "Types cannot contain reference_wrappers when D is void"); };
template<typename D, typename... Types> using vector_return_type = opus::vector_t<typename vector_return_type_helper<D, Types...>::type, sizeof...(Types)>;
}
template<typename D = void, typename... Types> constexpr impl::vector_return_type<D, Types...> make_vector(Types&&... t) { return {std::forward<Types>(t)...}; }

namespace impl {
template <typename T, index_t... Is> OPUS_H_D constexpr auto make_repeated_vector(T&& x, seq<Is...>) { return opus::make_vector((void(Is), std::forward<T>(x))...); }
} // namespace impl
template <index_t N, typename T> OPUS_H_D constexpr auto make_repeated_vector(T&& x) { return impl::make_repeated_vector(std::forward<T>(x), make_index_seq<N>{}); }
template <typename T, index_t N> OPUS_H_D constexpr auto make_repeated_vector(T&& x, number<N>) { return impl::make_repeated_vector(std::forward<T>(x), make_index_seq<N>{}); }

// vector type can't return reference! error: non-const reference cannot bind to vector element
template <index_t I, typename T, std::enable_if_t<is_vector_v<T>, bool> = true> OPUS_H_D constexpr typename vector_traits<T>::dtype get(T const& t) { static_assert(I < vector_traits<T>::size()); return t[I]; }
template <index_t I, typename T, std::enable_if_t<is_vector_v<T>, bool> = true> OPUS_H_D constexpr typename vector_traits<T>::dtype get(T&& t)      { static_assert(I < vector_traits<T>::size()); return t[I]; }

namespace impl {
template <class T0, class T1, index_t... I0, index_t... I1>
OPUS_H_D constexpr auto concat_vector(T0 const& t0, T1 const& t1, seq<I0...>, seq<I1...>) {
    if constexpr (std::is_same_v<remove_cvref_t<T0>, remove_cvref_t<T1>> && sizeof...(I0) > 1) {
        using R = vector_t<typename vector_traits<remove_cvref_t<T0>>::dtype, sizeof...(I0) + sizeof...(I1)>;
        return __builtin_bit_cast(R, __builtin_shufflevector(t0, t1, I0..., (sizeof...(I0) + I1)...));
    } else { return opus::make_vector(get<I0>(t0)..., get<I1>(t1)...); }
}
template <class T0, class T1, class T2, index_t... I0, index_t... I1, index_t...I2>
OPUS_H_D constexpr auto concat_vector(T0 const& t0, T1 const& t1, T2 const& t2, seq<I0...>, seq<I1...>, seq<I2...>) { return opus::make_vector(get<I0>(t0)..., get<I1>(t1)..., get<I2>(t2)...); }
template <class T0, class T1, class T2, class T3, index_t... I0, index_t... I1, index_t...I2, index_t...I3>
OPUS_H_D constexpr auto concat_vector(T0 const& t0, T1 const& t1, T2 const& t2, T3 const& t3, seq<I0...>, seq<I1...>, seq<I2...>, seq<I3...>) { return opus::make_vector(get<I0>(t0)..., get<I1>(t1)..., get<I2>(t2)..., get<I3>(t3)...); }
}
template <class T0> OPUS_H_D  constexpr auto concat_vector(T0 const& t0) { return t0; }
template <class T0, class T1>
OPUS_H_D  constexpr auto concat_vector(T0 const& t0, T1 const& t1) { return impl::concat_vector(t0, t1, make_index_seq<size<T0>()>{}, make_index_seq<size<T1>()>{}); }
template <class T0, class T1, class T2>
OPUS_H_D  constexpr auto concat_vector(T0 const& t0, T1 const& t1, T2 const& t2) { return impl::concat_vector(t0, t1, t2, make_index_seq<T0::size()>{}, make_index_seq<T1::size()>{}, make_index_seq<T2::size()>{}); }
template <class T0, class T1, class T2, class T3>
OPUS_H_D  constexpr auto concat_vector(T0 const& t0, T1 const& t1, T2 const& t2, T3 const& t3) {
                                            return impl::concat_vector(t0, t1, t2, t3, make_index_seq<T0::size()>{}, make_index_seq<T1::size()>{}, make_index_seq<T2::size()>{}, make_index_seq<T3::size()>{}); }
template <class T0, class T1, class T2, class T3, class T4, class... Ts>
OPUS_H_D  constexpr auto concat_vector(T0 const& t0, T1 const& t1, T2 const& t2, T3 const& t3, T4 const& t4, Ts const&... ts) { return concat_vector(concat_vector(t0, t1, t2, t3), concat_vector(t4, ts...)); }

template <typename T, std::enable_if_t<is_vector_v<T>, bool> = true> OPUS_H_D constexpr void fill(T& a, typename vector_traits<T>::dtype const& value) {
    if constexpr (size<T>() <= 4) { static_for<size<T>()>([&](auto i){ a[i.value] = value; }); }
    else { for (index_t i = 0; i < size<T>(); ++i) a[i] = value; }  // runtime loop for large vectors
}
template <typename T, std::enable_if_t<is_vector_v<T>, bool> = true> OPUS_H_D constexpr void clear(T& a) { a = {}; }

namespace impl {
template<typename T, index_t... Is, std::enable_if_t<is_vector_v<T>, bool> = true>
OPUS_H_D constexpr auto to_array_impl(const T& t, seq<Is...>) { return opus::make_array(t[Is]...); }

template<typename T, index_t... Is, std::enable_if_t<is_array_v<T>, bool> = true>
OPUS_H_D constexpr auto to_array_impl(const T& t, seq<Is...>) { return opus::concat_array(to_array_impl(get<Is>(t), make_index_seq< size(get<Is>(T{})) >{})...); }

template<typename T, index_t... Is, std::enable_if_t<is_array_v<T> && !is_vector_v<typename T::value_type>, bool> = true>
OPUS_H_D constexpr vector_t<typename T::value_type, T::size()> to_vector_impl(const T& t, seq<Is...>) { return {get<Is>(t)...}; }

template<typename T, index_t... Is, std::enable_if_t<is_array_v<T> && is_vector_v<typename T::value_type>, bool> = true>
OPUS_H_D constexpr vector_t<typename T::value_type, T::size()> to_vector_impl(const T& t, seq<Is...>) { return opus::concat_vector(to_vector_impl(get<Is>(t))...); }
}

template<typename T, std::enable_if_t<is_vector_v<T>, bool> = true> // vector type to array
OPUS_H_D constexpr auto to_array(const T& t) { return impl::to_array_impl(t, make_index_seq<size<T>()>{}); }

template<typename T, std::enable_if_t<is_array_v<T>, bool> = true>  // array of vector type to array
OPUS_H_D constexpr auto to_array(const T& t) { return impl::to_array_impl(t, make_index_seq<size<T>()>{}); }

template<typename T, std::enable_if_t<is_array_v<T>, bool> = true>
OPUS_H_D constexpr auto to_vector(const T& t) { return impl::to_vector_impl(t, make_index_seq<size<T>()>{}); }

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// slice
namespace impl {
template<typename C, index_t...Is, std::enable_if_t<is_vector_v<C>, bool> = true> OPUS_H_D constexpr auto slice_impl(C&& c, seq<Is...>) {
    if constexpr (sizeof...(Is) == 1) return opus::make_vector(get<Is>(c)...);
    else { using R = vector_t<typename vector_traits<remove_cvref_t<C>>::dtype, sizeof...(Is)>; return __builtin_bit_cast(R, __builtin_shufflevector(c, c, Is...)); }
}
template<typename C, index_t...Is, std::enable_if_t<is_array_v<C>, bool> = true>  OPUS_H_D constexpr auto slice_impl(C&& c, seq<Is...>) { return opus::make_array(get<Is>(c)...); }
template<typename C, index_t...Is, std::enable_if_t<is_tuple_v<C>, bool> = true>  OPUS_H_D constexpr auto slice_impl(C&& c, seq<Is...>) { return opus::make_tuple(get<Is>(c)...); }

template<index_t len, typename C, typename...Ts, std::enable_if_t<is_vector_v<C>, bool> = true>
OPUS_H_D constexpr auto slice_impl_i(C&& c, Ts... ss) { vector_t<typename vector_traits<C>::dtype, len> r;  index_t d = 0;  static_for([&](auto i){r[d++] = c[i]; }, ss...);  return r; }

template<index_t len, typename C, typename...Ts, std::enable_if_t<is_array_v<C>, bool> = true>
OPUS_H_D constexpr auto slice_impl_i(C&& c, Ts... ss) { array<typename C::value_type, len> r;  index_t d = 0;  static_for([&](auto i){r[d++] = c[i]; }, ss...);  return r; }

template<index_t... Is>
OPUS_H_D constexpr bool is_contiguous_seq(seq<Is...>) {
    if constexpr (sizeof...(Is) < 2) return true;
    else { constexpr index_t idx[] = {Is...}; for (index_t i = 1; i < sizeof...(Is); ++i) { if (idx[i] != idx[i - 1] + 1) return false; } return true; }
}

template<typename C, typename V, index_t...Ds, index_t...Ss, std::enable_if_t<(is_vector_v<C> || is_array_v<C> || is_tuple_v<C>), bool> = true>
OPUS_H_D constexpr auto set_slice_impl(C&& dst_c, V&& src_c, seq<Ds...>, seq<Ss...>) {
    using dst_t = remove_cvref_t<C>; using src_t = remove_cvref_t<V>; using scalar = typename vector_traits<dst_t>::dtype;
    constexpr index_t len = sizeof...(Ds);
    // Copy at dword granularity for sub-dword scalar types with dword-aligned contiguous slices
    if constexpr ((is_vector_v<dst_t> || is_array_v<dst_t>) && (is_vector_v<src_t> || is_array_v<src_t>) && is_contiguous_seq(seq<Ds...>{}) && is_contiguous_seq(seq<Ss...>{}) && sizeof(scalar) < 4 && len > 1) {
        constexpr index_t epd = 4 / sizeof(scalar);
        constexpr index_t d0 = seq<Ds...>::at(number<0>{}), s0 = seq<Ss...>::at(number<0>{}), dn = vector_traits<dst_t>::size(), sn = vector_traits<src_t>::size();
        if constexpr (d0 % epd == 0 && s0 % epd == 0 && len % epd == 0 && dn % epd == 0 && sn % epd == 0) {
            auto dst_i32 = __builtin_bit_cast(vector_t<int, dn / epd>, dst_c);
            const auto src_i32 = __builtin_bit_cast(vector_t<int, sn / epd>, src_c);
            static_for<len / epd>([&](auto i) { dst_i32[d0 / epd + i.value] = src_i32[s0 / epd + i.value]; });
            dst_c = __builtin_bit_cast(dst_t, dst_i32); return;
        }
    }
    if constexpr (is_contiguous_seq(seq<Ds...>{}) && is_contiguous_seq(seq<Ss...>{}) && (is_vector_v<dst_t> || is_array_v<dst_t>) && len > 2) {
        constexpr index_t d0 = seq<Ds...>::at(number<0>{}), s0 = seq<Ss...>::at(number<0>{});
        for (index_t i = 0; i < len; ++i) dst_c[d0 + i] = src_c[s0 + i];  // runtime loop avoids N-element fold instantiation
    } else { ((dst_c[Ds] = src_c[Ss]), ...); }
}
}

// static/dynamic slice. SS could be either number<x>, or const integer. Note tuple type does not support dynamic slice (ss is integral)
// (1).[end] : 0.... end, (2).[start, end] : start...end, (3).[start, end, step], start...end but with step as interval (default is 1)
template<typename C, typename... S, std::enable_if_t<is_vector_v<C> && (is_constant_v<S> && ...), bool> = true>
OPUS_H_D constexpr auto slice(C&& c, S&&.../*ss*/) { return impl::slice_impl(std::forward<C>(c), make_index_seq<(S::value) ...>{}); }
template<index_t len, typename C, typename... S, std::enable_if_t<is_vector_v<C> && (std::is_integral_v<S> && ...), bool> = true>
OPUS_H_D constexpr auto slice(C&& c, S&&...ss) { return impl::slice_impl_i<len>(std::forward<C>(c), ss...); }
template<typename C, typename... S, std::enable_if_t<is_array_v<C> && (is_constant_v<S> && ...), bool> = true>
OPUS_H_D constexpr auto slice(C&& c, S&&.../*ss*/) { return impl::slice_impl(std::forward<C>(c), make_index_seq<(S::value) ...>{}); }
template<index_t len, typename C, typename... S, std::enable_if_t<is_array_v<C> && (std::is_integral_v<S> && ...), bool> = true>
OPUS_H_D constexpr auto slice(C&& c, S&&...ss) { return impl::slice_impl_i<len>(std::forward<C>(c), ss...); }
template<typename C, typename... S, std::enable_if_t<is_tuple_v<C> && (is_constant_v<S> && ...), bool> = true>
OPUS_H_D constexpr auto slice(C&& c, S&&.../*ss*/) { return impl::slice_impl(std::forward<C>(c), make_index_seq<(S::value) ...>{}); }

template<typename C, typename V, typename... S, std::enable_if_t<(is_vector_v<C> || is_array_v<C> || is_tuple_v<C>) && (is_constant_v<S> && ...), bool> = true>
OPUS_H_D constexpr auto set_slice(C&& dst_c, V&& src_c, S&&.../*ss*/) {
    static_assert(std::is_same_v<typename vector_traits<C>::dtype, typename vector_traits<V>::dtype>);
    using dst_seq = make_index_seq<(S::value) ...>;
    return impl::set_slice_impl(std::forward<C>(dst_c), std::forward<V>(src_c), dst_seq{}, make_index_seq<size<dst_seq>()>{});
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// BELOW IS AMDGPU SPECIFIC TYPES/ARCH/INTRINSICS
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// address space attribute
#if defined(__HIP_DEVICE_COMPILE__)
    #define OPUS_LDS_ADDR __attribute__((address_space(3)))
#else
    #define OPUS_LDS_ADDR
#endif

// dtype, suffix is "_t", and register corresponding ext_vector_type, and a specialization of is_dtype
#define REGISTER_DTYPE(dtype_base_, dtype_impl_)        \
    using dtype_base_ ## _t    = dtype_impl_;           \
    using dtype_base_ ## x1_t  = dtype_base_ ## _t __attribute__((ext_vector_type(1 )));    \
    using dtype_base_ ## x2_t  = dtype_base_ ## _t __attribute__((ext_vector_type(2 )));    \
    using dtype_base_ ## x4_t  = dtype_base_ ## _t __attribute__((ext_vector_type(4 )));    \
    using dtype_base_ ## x8_t  = dtype_base_ ## _t __attribute__((ext_vector_type(8 )));    \
    using dtype_base_ ## x16_t = dtype_base_ ## _t __attribute__((ext_vector_type(16)));    \
    using dtype_base_ ## x32_t = dtype_base_ ## _t __attribute__((ext_vector_type(32)));    \
    using dtype_base_ ## x64_t = dtype_base_ ## _t __attribute__((ext_vector_type(64)));    \
    template<> struct is_dtype<dtype_base_ ## _t> : true_type {};

template<typename T> struct is_dtype : false_type {};
template<typename T> constexpr bool is_dtype_v = is_dtype<remove_cvref_t<T>>::value;    // use this!

REGISTER_DTYPE(fp32, float)
REGISTER_DTYPE(bf16, dtypes::bf16)
REGISTER_DTYPE(fp16, dtypes::fp16)
REGISTER_DTYPE(fp8 , _BitInt(8))
REGISTER_DTYPE(bf8 , unsigned _BitInt(8))
REGISTER_DTYPE(i32 , int)
REGISTER_DTYPE(u32 , unsigned int)
REGISTER_DTYPE(i16 , short)
#if __clang_major__ >= 20
REGISTER_DTYPE(u16 , unsigned short)
#endif
REGISTER_DTYPE(i8  , signed char)
REGISTER_DTYPE(u8  , unsigned char)
REGISTER_DTYPE(i64 , long long)
REGISTER_DTYPE(u64 , unsigned long long)

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// numeric_limits -- returns min/max/lowest/quiet_nan/infinity in the *original* dtype (see finfo below for float-valued properties like eps/max/min/tiny)
template<typename T> struct numeric_limits;

template<> struct numeric_limits<fp32_t> {
    static constexpr unsigned int bin_min = 0x00800000, bin_max = 0x7F7FFFFF, bin_lowest = 0xFF7FFFFF, bin_qnan = 0x7FC00000, bin_inf = 0x7F800000;
    OPUS_H_D static constexpr fp32_t min()       { return __builtin_bit_cast(fp32_t, bin_min); }
    OPUS_H_D static constexpr fp32_t max()       { return __builtin_bit_cast(fp32_t, bin_max); }
    OPUS_H_D static constexpr fp32_t lowest()    { return __builtin_bit_cast(fp32_t, bin_lowest); }
    OPUS_H_D static constexpr fp32_t quiet_nan() { return __builtin_bit_cast(fp32_t, bin_qnan); }
    OPUS_H_D static constexpr fp32_t infinity()  { return __builtin_bit_cast(fp32_t, bin_inf); }
};
template<> struct numeric_limits<fp16_t> {
    static constexpr unsigned short bin_min = 0x0400, bin_max = 0x7BFF, bin_lowest = 0xFBFF, bin_qnan = 0x7E00, bin_inf = 0x7C00;
    OPUS_H_D static constexpr fp16_t min()       { return __builtin_bit_cast(fp16_t, bin_min); }
    OPUS_H_D static constexpr fp16_t max()       { return __builtin_bit_cast(fp16_t, bin_max); }
    OPUS_H_D static constexpr fp16_t lowest()    { return __builtin_bit_cast(fp16_t, bin_lowest); }
    OPUS_H_D static constexpr fp16_t quiet_nan() { return __builtin_bit_cast(fp16_t, bin_qnan); }
    OPUS_H_D static constexpr fp16_t infinity()  { return __builtin_bit_cast(fp16_t, bin_inf); }
};
template<> struct numeric_limits<bf16_t> {
    static constexpr unsigned short bin_min = 0x0080, bin_max = 0x7F7F, bin_lowest = 0xFF7F, bin_qnan = 0x7FC0, bin_inf = 0x7F80;
    OPUS_H_D static constexpr bf16_t min()       { return __builtin_bit_cast(bf16_t, bin_min); }
    OPUS_H_D static constexpr bf16_t max()       { return __builtin_bit_cast(bf16_t, bin_max); }
    OPUS_H_D static constexpr bf16_t lowest()    { return __builtin_bit_cast(bf16_t, bin_lowest); }
    OPUS_H_D static constexpr bf16_t quiet_nan() { return __builtin_bit_cast(bf16_t, bin_qnan); }
    OPUS_H_D static constexpr bf16_t infinity()  { return __builtin_bit_cast(bf16_t, bin_inf); }
};
// fp8 E4M3: gfx950=OCP(ieee-like, NaN=0x7F), gfx942=fnuz(NaN=0x80). No infinity in either format.
// NOTE: __builtin_bit_cast with _BitInt(8) is not yet constexpr in clang, so use static_cast via signed char.
template<> struct numeric_limits<fp8_t> {
#if defined(__gfx942__)
    static constexpr unsigned char bin_min = 0x08, bin_max = 0x7F, bin_lowest = 0xFF, bin_qnan = 0x80, bin_inf = 0x00;
#else
    static constexpr unsigned char bin_min = 0x08, bin_max = 0x7E, bin_lowest = 0xFE, bin_qnan = 0x7F, bin_inf = 0x00;
#endif
    OPUS_H_D static constexpr fp8_t min()       { return static_cast<fp8_t>(static_cast<signed char>(bin_min)); }
    OPUS_H_D static constexpr fp8_t max()       { return static_cast<fp8_t>(static_cast<signed char>(bin_max)); }
    OPUS_H_D static constexpr fp8_t lowest()    { return static_cast<fp8_t>(static_cast<signed char>(bin_lowest)); }
    OPUS_H_D static constexpr fp8_t quiet_nan() { return static_cast<fp8_t>(static_cast<signed char>(bin_qnan)); }
    OPUS_H_D static constexpr fp8_t infinity()  { return static_cast<fp8_t>(static_cast<signed char>(bin_inf)); }
};
// bf8 E5M2: gfx950=OCP(ieee, has inf=0x7C, NaN=0x7E), gfx942=fnuz(no inf, NaN=0x80)
template<> struct numeric_limits<bf8_t> {
#if defined(__gfx942__)
    static constexpr unsigned char bin_min = 0x04, bin_max = 0x7F, bin_lowest = 0xFF, bin_qnan = 0x80, bin_inf = 0x00;
#else
    static constexpr unsigned char bin_min = 0x04, bin_max = 0x7B, bin_lowest = 0xFB, bin_qnan = 0x7F, bin_inf = 0x7C;
#endif
    OPUS_H_D static constexpr bf8_t min()       { return static_cast<bf8_t>(bin_min); }
    OPUS_H_D static constexpr bf8_t max()       { return static_cast<bf8_t>(bin_max); }
    OPUS_H_D static constexpr bf8_t lowest()    { return static_cast<bf8_t>(bin_lowest); }
    OPUS_H_D static constexpr bf8_t quiet_nan() { return static_cast<bf8_t>(bin_qnan); }
    OPUS_H_D static constexpr bf8_t infinity()  { return static_cast<bf8_t>(bin_inf); }
};
template<> struct numeric_limits<i32_t> {
    OPUS_H_D static constexpr i32_t min()       { return -2147483647 - 1; }
    OPUS_H_D static constexpr i32_t max()       { return  2147483647; }
    OPUS_H_D static constexpr i32_t lowest()    { return -2147483647 - 1; }
    OPUS_H_D static constexpr i32_t quiet_nan() { return 0; }
    OPUS_H_D static constexpr i32_t infinity()  { return 0; }
};
template<> struct numeric_limits<u32_t> {
    OPUS_H_D static constexpr u32_t min()       { return 0; }
    OPUS_H_D static constexpr u32_t max()       { return 4294967295U; }
    OPUS_H_D static constexpr u32_t lowest()    { return 0; }
    OPUS_H_D static constexpr u32_t quiet_nan() { return 0; }
    OPUS_H_D static constexpr u32_t infinity()  { return 0; }
};
template<> struct numeric_limits<i16_t> {
    OPUS_H_D static constexpr i16_t min()       { return -32768; }
    OPUS_H_D static constexpr i16_t max()       { return  32767; }
    OPUS_H_D static constexpr i16_t lowest()    { return -32768; }
    OPUS_H_D static constexpr i16_t quiet_nan() { return 0; }
    OPUS_H_D static constexpr i16_t infinity()  { return 0; }
};
#if __clang_major__ >= 20
template<> struct numeric_limits<u16_t> {
    OPUS_H_D static constexpr u16_t min()       { return 0; }
    OPUS_H_D static constexpr u16_t max()       { return 65535; }
    OPUS_H_D static constexpr u16_t lowest()    { return 0; }
    OPUS_H_D static constexpr u16_t quiet_nan() { return 0; }
    OPUS_H_D static constexpr u16_t infinity()  { return 0; }
};
#endif
template<> struct numeric_limits<i8_t> {
    OPUS_H_D static constexpr i8_t min()       { return -128; }
    OPUS_H_D static constexpr i8_t max()       { return  127; }
    OPUS_H_D static constexpr i8_t lowest()    { return -128; }
    OPUS_H_D static constexpr i8_t quiet_nan() { return 0; }
    OPUS_H_D static constexpr i8_t infinity()  { return 0; }
};
template<> struct numeric_limits<u8_t> {
    OPUS_H_D static constexpr u8_t min()       { return 0; }
    OPUS_H_D static constexpr u8_t max()       { return 255; }
    OPUS_H_D static constexpr u8_t lowest()    { return 0; }
    OPUS_H_D static constexpr u8_t quiet_nan() { return 0; }
    OPUS_H_D static constexpr u8_t infinity()  { return 0; }
};

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// finfo -- like torch.finfo: eps/max/min/tiny as float, bits as int
template<typename T> struct finfo;

template<> struct finfo<fp32_t> {
    static constexpr int bits = 32;
    OPUS_H_D static constexpr float eps()  { return __builtin_bit_cast(float, 0x34000000u); }  // 2^-23
    OPUS_H_D static constexpr float max()  { return __builtin_bit_cast(float, 0x7F7FFFFFu); }  // 3.4028235e+38
    OPUS_H_D static constexpr float min()  { return __builtin_bit_cast(float, 0xFF7FFFFFu); }  // -3.4028235e+38
    OPUS_H_D static constexpr float tiny() { return __builtin_bit_cast(float, 0x00800000u); }  // 2^-126
};
template<> struct finfo<fp16_t> {
    static constexpr int bits = 16;
    OPUS_H_D static constexpr float eps()  { return __builtin_bit_cast(float, 0x3A800000u); }  // 2^-10 = 9.765625e-4
    OPUS_H_D static constexpr float max()  { return __builtin_bit_cast(float, 0x477FE000u); }  // 65504.0
    OPUS_H_D static constexpr float min()  { return __builtin_bit_cast(float, 0xC77FE000u); }  // -65504.0
    OPUS_H_D static constexpr float tiny() { return __builtin_bit_cast(float, 0x38800000u); }  // 2^-14
};
template<> struct finfo<bf16_t> {
    static constexpr int bits = 16;
    OPUS_H_D static constexpr float eps()  { return __builtin_bit_cast(float, 0x3C000000u); }  // 2^-7 = 0.0078125
    OPUS_H_D static constexpr float max()  { return __builtin_bit_cast(float, 0x7F7F0000u); }  // 3.389531e+38
    OPUS_H_D static constexpr float min()  { return __builtin_bit_cast(float, 0xFF7F0000u); }  // -3.389531e+38
    OPUS_H_D static constexpr float tiny() { return __builtin_bit_cast(float, 0x00800000u); }  // 2^-126
};
// fp8 E4M3: gfx950=OCP(float8_e4m3fn, bias=7), gfx942=fnuz(float8_e4m3fnuz, bias=8)
template<> struct finfo<fp8_t> {
    static constexpr int bits = 8;
    OPUS_H_D static constexpr float eps()  { return __builtin_bit_cast(float, 0x3E000000u); }  // 2^-3 = 0.125
#if defined(__gfx942__)
    OPUS_H_D static constexpr float max()  { return __builtin_bit_cast(float, 0x43700000u); }  // 240.0
    OPUS_H_D static constexpr float min()  { return __builtin_bit_cast(float, 0xC3700000u); }  // -240.0
    OPUS_H_D static constexpr float tiny() { return __builtin_bit_cast(float, 0x3C000000u); }  // 2^-7 = 0.0078125
#else
    OPUS_H_D static constexpr float max()  { return __builtin_bit_cast(float, 0x43E00000u); }  // 448.0
    OPUS_H_D static constexpr float min()  { return __builtin_bit_cast(float, 0xC3E00000u); }  // -448.0
    OPUS_H_D static constexpr float tiny() { return __builtin_bit_cast(float, 0x3C800000u); }  // 2^-6 = 0.015625
#endif
};
// bf8 E5M2: gfx950=OCP(float8_e5m2, bias=15), gfx942=fnuz(float8_e5m2fnuz, bias=16)
template<> struct finfo<bf8_t> {
    static constexpr int bits = 8;
#if defined(__gfx942__)
    OPUS_H_D static constexpr float eps()  { return __builtin_bit_cast(float, 0x3E000000u); }  // 2^-3 = 0.125
    OPUS_H_D static constexpr float max()  { return __builtin_bit_cast(float, 0x47600000u); }  // 57344.0
    OPUS_H_D static constexpr float min()  { return __builtin_bit_cast(float, 0xC7600000u); }  // -57344.0
    OPUS_H_D static constexpr float tiny() { return __builtin_bit_cast(float, 0x38000000u); }  // 2^-15
#else
    OPUS_H_D static constexpr float eps()  { return __builtin_bit_cast(float, 0x3E800000u); }  // 2^-2 = 0.25
    OPUS_H_D static constexpr float max()  { return __builtin_bit_cast(float, 0x47600000u); }  // 57344.0
    OPUS_H_D static constexpr float min()  { return __builtin_bit_cast(float, 0xC7600000u); }  // -57344.0
    OPUS_H_D static constexpr float tiny() { return __builtin_bit_cast(float, 0x38800000u); }  // 2^-14
#endif
};
template<> struct finfo<i8_t> {
    static constexpr int bits = 8;
    OPUS_H_D static constexpr float max()  { return 127.0f; }
    OPUS_H_D static constexpr float min()  { return -128.0f; }
};

template<typename C, typename... S, std::enable_if_t<is_dtype_v<C> && (is_constant_v<S> && ...), bool> = true>
OPUS_H_D constexpr auto slice(C&& container, S&&.../*ss*/) { return container; }    // TODO: fallback slice a normal value does nonthing
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// type cast
} // namespace opus (slice close)
