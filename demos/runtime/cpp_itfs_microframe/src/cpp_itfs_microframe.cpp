// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Host reference for aiter's cpp_itfs runtime micro-framework
// (csrc/cpp_itfs/{lru_cache.h, utils.h, utils.py} @ 1eab5ae12, MIT).
// Four independently-extractable designs:
//
// [1] LRUCache (lru_cache.h): mutex + std::list + unordered_map<key,
//     list-iterator> O(1) LRU. get() splices the node to the front; put()
//     updates-in-place or evicts the back. Capacity -1 = unbounded
//     (AITER_MAX_CACHE_SIZE default). Ported verbatim minus the logger.
//
// [2] Content-addressed kernel identity (utils.py get_default_func_name):
//     func_name = "<module>_<md5(join(args, '_').lower())>" — the SAME
//     config tuple ALWAYS maps to the same build folder + exported symbol,
//     different configs never collide (md5), args are lowercased so
//     "Gfx950" and "gfx950" share one build. The C++ side mirrors it
//     (utils.h get_default_func_name + hash_signature via OpenSSL MD5);
//     this demo carries a compact public-domain MD5 so the demo has zero
//     external deps while keeping the exact contract (32-hex digest).
//
// [3] SharedLibrary RAII (utils.h): dlopen(RTLD_LAZY) / dlsym with
//     dlerror-clearing protocol / dlclose. run_lib() caches loaded
//     libraries in the same LRUCache keyed by func_name.
//
// [4] The two-sided build-if-missing pipeline (utils.py
//     compile_template_op + compile_lib): Python renders a jinja template
//     with the func_name, writes <folder>/<folder>.cpp, generates a
//     Makefile (hipcc -shared), builds under a FileBaton lock into
//     ~/.aiter/build/<folder>/lib.so, then ctypes.CDLL loads it; the C++
//     twin (not_built + run_lib) dlopens the same artifact. This demo
//     emulates the ORCHESTRATION (not_built -> build-once -> cached load
//     -> second call hits the cache) with a stub builder and libm as the
//     dlopen target, so the control flow is verified without a compiler.
//
// Scope note: opus --genco (csrc/opus_gemm/gen_co/build_co.py) is the
// compiler-line counterpart — opus is aiter's single-header C++ DSL and
// --genco compiles opus DSL into a clang offload bundle consumed by
// HsacoLauncher-style paths. Extracting it requires the opus toolchain
// build; this demo anchors the RUNTIME half of the pair. The hsaco
// launcher / HsacoKernel triton-caching layer is likewise not extracted
// (device-line scope).
//
// Verification level: SOURCE_VERIFIED + REFERENCE_PASS (CPU-only).
#include <dlfcn.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <list>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#define MAIN_RETURN_BAD 1

// ══════════════════════════════════════════════════════════════════════
// [1] LRUCache (ported from csrc/cpp_itfs/lru_cache.h; logger dropped)
// ══════════════════════════════════════════════════════════════════════
template <typename K, typename V>
class LRUCache {
   private:
    int m_capacity;
    std::mutex m;
    // Most recently used at front, least recently used at back
    std::list<std::pair<K, V>> m_items;
    std::unordered_map<K, typename std::list<std::pair<K, V>>::iterator> m_item_map;

   public:
    explicit LRUCache(int capacity) : m_capacity(capacity) {}

    // Get value by key. Returns nullptr if not found
    V* get(const K& key) {
        std::lock_guard<std::mutex> guard(m);
        auto it = m_item_map.find(key);
        if (it == m_item_map.end()) {
            return nullptr;
        }
        // Move accessed item to front (most recently used)
        m_items.splice(m_items.begin(), m_items, it->second);
        return &(it->second->second);
    }

    // Put key-value pair into cache
    void put(const K& key, const V& value) {
        std::lock_guard<std::mutex> guard(m);
        auto it = m_item_map.find(key);
        if (it != m_item_map.end()) {
            // Key exists, update value and move to front
            it->second->second = value;
            m_items.splice(m_items.begin(), m_items, it->second);
            return;
        }
        // Check if cache is full (capacity < 0 = unbounded)
        if (m_capacity >= 0 && int(m_items.size()) >= m_capacity) {
            // Remove least recently used item (back of list)
            auto last = m_items.back();
            m_item_map.erase(last.first);
            m_items.pop_back();
        }
        // Insert new item at front
        m_items.emplace_front(key, value);
        m_item_map[key] = m_items.begin();
    }

    void clear() {
        std::lock_guard<std::mutex> guard(m);
        m_items.clear();
        m_item_map.clear();
    }

    size_t size() const { return m_items.size(); }
    int capacity() const { return m_capacity; }
};

// ══════════════════════════════════════════════════════════════════════
// [2] Compact MD5 (RFC 1321 reference algorithm, public domain) — keeps
//     the content-addressed naming contract exact with zero dependencies
//     (upstream uses OpenSSL EVP via utils.h / hashlib via utils.py)
// ══════════════════════════════════════════════════════════════════════
namespace md5 {

struct Ctx {
    std::uint32_t a, b, c, d;
    std::uint64_t len;
    std::uint8_t buf[64];
    std::size_t buf_len;
};

static std::uint32_t rotl(std::uint32_t x, int c) { return (x << c) | (x >> (32 - c)); }

static void block(Ctx& ctx, const std::uint8_t* p) {
    static const std::uint32_t K[64] = {
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613,
        0xfd469501, 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193,
        0xa679438e, 0x49b40821, 0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d,
        0x02441453, 0xd8a1e681, 0xe7d3fbc8, 0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
        0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a, 0xfffa3942, 0x8771f681, 0x6d9d6122,
        0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, 0x289b7ec6, 0xeaa127fa,
        0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665, 0xf4292244,
        0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb,
        0xeb86d391};
    static const int S[64] = {7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
                              5, 9,  14, 20, 5, 9,  14, 20, 5, 9,  14, 20, 5, 9,  14, 20,
                              4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
                              6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21};
    std::uint32_t m[16];
    for (int i = 0; i < 16; ++i)
        m[i] = p[4 * i] | (p[4 * i + 1] << 8) | (p[4 * i + 2] << 16) |
               (std::uint32_t(p[4 * i + 3]) << 24);
    std::uint32_t a = ctx.a, b = ctx.b, c = ctx.c, d = ctx.d;
    for (int i = 0; i < 64; ++i) {
        std::uint32_t f;
        int g;
        if (i < 16) {
            f = (b & c) | (~b & d);
            g = i;
        } else if (i < 32) {
            f = (d & b) | (~d & c);
            g = (5 * i + 1) % 16;
        } else if (i < 48) {
            f = b ^ c ^ d;
            g = (3 * i + 5) % 16;
        } else {
            f = c ^ (b | ~d);
            g = (7 * i) % 16;
        }
        const std::uint32_t tmp = d;
        d = c;
        c = b;
        b = b + rotl(a + f + K[i] + m[g], S[i]);
        a = tmp;
    }
    ctx.a += a;
    ctx.b += b;
    ctx.c += c;
    ctx.d += d;
}

static void init(Ctx& ctx) {
    ctx.a = 0x67452301;
    ctx.b = 0xefcdab89;
    ctx.c = 0x98badcfe;
    ctx.d = 0x10325476;
    ctx.len = 0;
    ctx.buf_len = 0;
}

static void update(Ctx& ctx, const std::string& data) {
    ctx.len += data.size();
    const auto* p = reinterpret_cast<const std::uint8_t*>(data.data());
    std::size_t n = data.size();
    while (n > 0) {
        const std::size_t take = std::min(n, std::size_t(64) - ctx.buf_len);
        std::memcpy(ctx.buf + ctx.buf_len, p, take);
        ctx.buf_len += take;
        p += take;
        n -= take;
        if (ctx.buf_len == 64) {
            block(ctx, ctx.buf);
            ctx.buf_len = 0;
        }
    }
}

static std::string final_hex(Ctx& ctx) {
    const std::uint64_t bitlen = ctx.len * 8;
    std::uint8_t pad = 0x80;
    update(ctx, std::string(1, char(pad)));
    const std::uint8_t zero = 0;
    while (ctx.buf_len != 56) update(ctx, std::string(1, char(zero)));
    std::uint8_t lenb[8];
    for (int i = 0; i < 8; ++i) lenb[i] = std::uint8_t(bitlen >> (8 * i));
    // append length bytes (bypass the streaming path's len accounting)
    std::memcpy(ctx.buf + ctx.buf_len, lenb, 8);
    ctx.buf_len += 8;
    block(ctx, ctx.buf);
    ctx.buf_len = 0;
    const std::uint32_t regs[4] = {ctx.a, ctx.b, ctx.c, ctx.d};
    char out[33];
    for (int i = 0; i < 4; ++i)
        std::snprintf(out + 8 * i, 9, "%02x%02x%02x%02x", regs[i] & 0xFF,
                      (regs[i] >> 8) & 0xFF, (regs[i] >> 16) & 0xFF, (regs[i] >> 24) & 0xFF);
    out[32] = 0;
    return std::string(out);
}

}  // namespace md5

// utils.h hash_signature contract: lowercase hex MD5 of the signature.
static std::string hash_signature(const std::string& signature) {
    md5::Ctx ctx;
    md5::init(ctx);
    md5::update(ctx, signature);
    return md5::final_hex(ctx);
}

// utils.py get_default_func_name contract:
//   func_name = f"{md_name}_{md5('_'.join(str(a).lower() for a in args))}"
// with an LRUCache keyed by the joined signature.
static std::string get_default_func_name(const std::string& md_name,
                                         const std::vector<std::string>& args,
                                         LRUCache<std::string, std::string>& names) {
    std::string sig;
    for (size_t i = 0; i < args.size(); ++i) {
        std::string a = args[i];
        std::transform(a.begin(), a.end(), a.begin(),
                       [](unsigned char c) { return char(std::tolower(c)); });
        if (i) sig += "_";
        sig += a;
    }
    std::string* cached = names.get(sig);
    if (!cached) {
        names.put(sig, md_name + "_" + hash_signature(sig));
        cached = names.get(sig);
    }
    return *cached;
}

// ══════════════════════════════════════════════════════════════════════
// [3] SharedLibrary RAII (ported from utils.h: dlopen/dlsym/dlclose with
//     the dlerror-clearing protocol) + [4] the build-if-missing pipeline
// ══════════════════════════════════════════════════════════════════════
class SharedLibrary {
   private:
    void* handle;

   public:
    explicit SharedLibrary(const std::string& path) {
        handle = dlopen(path.c_str(), RTLD_LAZY);
        if (!handle) {
            throw std::runtime_error(dlerror());
        }
    }
    ~SharedLibrary() {
        if (handle) {
            dlclose(handle);
        }
    }
    SharedLibrary(const SharedLibrary&) = delete;
    SharedLibrary& operator=(const SharedLibrary&) = delete;

    void* get_raw_function(const char* func_name) {
        dlerror();  // clear any existing error
        void* func_ptr = dlsym(handle, func_name);
        const char* error = dlerror();
        if (error) {
            throw std::runtime_error(error);
        }
        return func_ptr;
    }

    template <typename ReturnType, typename... Args>
    ReturnType call(const std::string& func_name, Args... args) {
        auto func = reinterpret_cast<ReturnType (*)(Args...)>(get_raw_function(func_name.c_str()));
        return func(args...);
    }
};

// Build-if-missing + cached-load orchestration (compile_template_op /
// run_lib semantics, with a stub builder standing in for the hipcc
// Makefile step and libm standing in for the generated lib.so).
class MicroFrame {
   public:
    static constexpr int UNLIMITED = -1;

    explicit MicroFrame(const std::string& build_root)
        : build_root_(build_root),
          libs_(UNLIMITED),            // AITER_MAX_CACHE_SIZE default: -1
          func_names_(UNLIMITED) {}

    // utils.py not_built: the build folder lacks its artifact
    bool not_built(const std::string& folder) const {
        return !std::filesystem::exists(build_root_ / std::filesystem::path(folder) / "lib.so");
    }

    // compile_lib stub: renders the "source" (here: just marks the build
    // time and writes the artifact). Counts invocations for the tests.
    void build(const std::string& folder) {
        const auto dir = build_root_ / std::filesystem::path(folder);
        std::filesystem::create_directories(dir);
        {
            std::ofstream f(dir / "lib.so");
            f << "stub artifact for " << folder << "\n";
        }
        ++builds_;
    }

    // compile_template_op: name -> (maybe build) -> dlopen + cache -> call
    template <typename ReturnType, typename... Args>
    ReturnType run(const std::string& func_name, const std::string& folder,
                   const std::string& symbol, Args... args) {
        if (not_built(folder)) {
            build(folder);
        }
        std::shared_ptr<SharedLibrary>* lib = libs_.get(func_name);
        if (!lib) {
            // upstream keys the lib cache by func_name but loads
            // build/<folder>/lib.so; the stub artifact is a text marker, so
            // the dlopen target here is libm (documented substitution)
            libs_.put(func_name,
                      std::make_shared<SharedLibrary>("/lib/x86_64-linux-gnu/libm.so.6"));
            lib = libs_.get(func_name);
        }
        return (*lib)->call<ReturnType>(symbol, args...);
    }

    std::string func_name(const std::string& md_name, const std::vector<std::string>& args) {
        return get_default_func_name(md_name, args, func_names_);
    }

    long builds() const { return builds_; }

   private:
    std::filesystem::path build_root_;
    LRUCache<std::string, std::shared_ptr<SharedLibrary>> libs_;
    LRUCache<std::string, std::string> func_names_;
    long builds_ = 0;
};

// ══════════════════════════════════════════════════════════════════════
// Tests
// ══════════════════════════════════════════════════════════════════════
int main() {
    int checks = 0, fails = 0;

    // ── 1. LRUCache semantics ──
    {
        int f = 0;
        LRUCache<std::string, int> c(3);
        c.put("a", 1);
        c.put("b", 2);
        c.put("c", 3);
        ++checks;
        if (c.size() != 3 && f < 5) {
            std::printf("  size %zu != 3\n", c.size());
            ++f;
        }
        c.put("d", 4);  // evicts LRU = "a"
        ++checks;
        if (c.get("a") != nullptr && f < 5) {
            std::printf("  a should have been evicted\n");
            ++f;
        }
        ++checks;
        if ((c.get("b") == nullptr || *c.get("b") != 2) && f < 5) {
            std::printf("  b missing/corrupt\n");
            ++f;
        }
        // get() moves to front: touching b makes c the LRU
        (void)c.get("b");
        c.put("e", 5);  // evicts "c"
        ++checks;
        if (c.get("c") != nullptr && f < 5) {
            std::printf("  c should have been evicted after touch-b\n");
            ++f;
        }
        // put() on existing key updates and moves to front
        LRUCache<std::string, int> c2(2);
        c2.put("x", 1);
        c2.put("y", 2);
        c2.put("x", 9);  // update, x now MRU
        c2.put("z", 3);  // evicts y
        ++checks;
        if ((c2.get("x") == nullptr || *c2.get("x") != 9 || c2.get("y") != nullptr) && f < 5) {
            std::printf("  update-in-place/evict-after-update wrong\n");
            ++f;
        }
        // unbounded mode
        LRUCache<int, int> cu(-1);
        for (int i = 0; i < 10000; ++i) cu.put(i, i);
        ++checks;
        if ((cu.size() != 10000 || cu.get(9999) == nullptr) && f < 5) {
            std::printf("  unbounded cache evicted (size %zu)\n", cu.size());
            ++f;
        }
        fails += f > 0;
        std::printf("1. LRUCache (splice-to-front, update-in-place, evict, unbounded): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 2. Content-addressed naming ──
    {
        int f = 0;
        LRUCache<std::string, std::string> names(-1);
        const std::string n1 = get_default_func_name("top_k_renorm_probs", {"1024.0", "True"},
                                                     names);
        // md5 format: 32 lowercase hex chars
        const std::string h = n1.substr(n1.rfind('_') + 1);
        ++checks;
        bool hex_ok = h.size() == 32 &&
                      std::all_of(h.begin(), h.end(), [](char ch) {
                          return (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f');
                      });
        if (!hex_ok && f < 5) {
            std::printf("  digest %s not 32-hex\n", h.c_str());
            ++f;
        }
        // determinism: same args -> same name (and cache hit path)
        const std::string n2 = get_default_func_name("top_k_renorm_probs", {"1024.0", "True"},
                                                     names);
        ++checks;
        if (n1 != n2 && f < 5) {
            std::printf("  naming not deterministic\n");
            ++f;
        }
        // case normalization: "TRUE" vs "true" share the build
        const std::string n3 = get_default_func_name("top_k_renorm_probs", {"1024.0", "TRUE"},
                                                     names);
        ++checks;
        if (n1 != n3 && f < 5) {
            std::printf("  args not lowercased\n");
            ++f;
        }
        // distinct configs -> distinct names
        const std::string n4 = get_default_func_name("top_k_renorm_probs", {"512.0", "True"},
                                                     names);
        ++checks;
        if (n1 == n4 && f < 5) {
            std::printf("  different configs collided\n");
            ++f;
        }
        // MD5 correctness against published vectors
        ++checks;
        if (hash_signature("") != "d41d8cd98f00b204e9800998ecf8427e" && f < 5) {
            std::printf("  md5(\"\") wrong: %s\n", hash_signature("").c_str());
            ++f;
        }
        ++checks;
        if (hash_signature("abc") != "900150983cd24fb0d6963f7d28e17f72" && f < 5) {
            std::printf("  md5(\"abc\") wrong: %s\n", hash_signature("abc").c_str());
            ++f;
        }
        ++checks;
        if (hash_signature("The quick brown fox jumps over the lazy dog") !=
            "9e107d9d372bb6826bd81d3542a419d6" &&
            f < 5) {
            std::printf("  md5(fox) wrong: %s\n",
                        hash_signature("The quick brown fox jumps over the lazy dog").c_str());
            ++f;
        }
        fails += f > 0;
        std::printf("2. content-addressed naming (md5 vectors, case-fold, cache): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 3. SharedLibrary RAII over libm ──
    {
        int f = 0;
        try {
            SharedLibrary lib("/lib/x86_64-linux-gnu/libm.so.6");
            const double r = lib.call<double>("sqrt", 144.0);
            ++checks;
            if (std::fabs(r - 12.0) > 1e-12 && f < 5) {
                std::printf("  sqrt(144) = %g\n", r);
                ++f;
            }
            ++checks;
            bool threw = false;
            try {
                lib.get_raw_function("no_such_symbol_xyz");
            } catch (const std::exception&) {
                threw = true;
            }
            if (!threw && f < 5) {
                std::printf("  missing symbol did not throw\n");
                ++f;
            }
        } catch (const std::exception& e) {
            std::printf("  libm dlopen failed (%s) — dlopen unavailable?\n", e.what());
            ++fails;
        }
        fails += f > 0;
        std::printf("3. SharedLibrary RAII (dlopen libm, dlsym sqrt, error path): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 4. Build-if-missing orchestration + lib cache ──
    {
        int f = 0;
        const auto root =
            std::filesystem::temp_directory_path() / "cpp_itfs_microframe_test_build";
        std::filesystem::remove_all(root);
        MicroFrame mf(root.string());
        const std::vector<std::string> cfg = {"1024.0", "True"};
        const std::string fn = mf.func_name("top_k_renorm_probs", cfg);
        const std::string folder = fn;  // folder defaults to func_name
        ++checks;
        if (!mf.not_built(folder) && f < 5) {
            std::printf("  fresh root reported built\n");
            ++f;
        }
        // two runs of the same config: ONE build, two cached calls
        const double r1 = mf.run<double>(fn, folder, "sqrt", 144.0);
        ++checks;
        if (mf.not_built(folder) && f < 5) {
            std::printf("  artifact missing after run\n");
            ++f;
        }
        const double r2 = mf.run<double>(fn, folder, "sqrt", 144.0);
        ++checks;
        if (mf.builds() != 1 && f < 5) {
            std::printf("  builds %ld != 1 (cache miss on second call)\n", mf.builds());
            ++f;
        }
        ++checks;
        if (std::fabs(r1 - 12.0) > 1e-12 || std::fabs(r2 - 12.0) > 1e-12) {
            std::printf("  sqrt through the pipeline wrong\n");
            ++f;
        }
        // a different config gets its own folder + build
        const std::string fn2 = mf.func_name("top_k_renorm_probs", {"512.0", "True"});
        mf.run<double>(fn2, fn2, "sqrt", 9.0);
        ++checks;
        if (mf.builds() != 2 && f < 5) {
            std::printf("  second config did not build (builds %ld)\n", mf.builds());
            ++f;
        }
        std::filesystem::remove_all(root);
        fails += f > 0;
        std::printf("4. build-if-missing + cached-load orchestration (stub builder): %s\n",
                    f ? "FAIL" : "PASS");
    }

    // ── 5. Concurrent cache hammering (mutex smoke) ──
    {
        int f = 0;
        static LRUCache<int, int> c(1024);
        auto worker = [](int base) {
            for (int i = 0; i < 20000; ++i) {
                const int k = base + (i % 512);
                c.put(k, k);
                int* v = c.get(k);
                if (v && *v != k) std::printf("  corrupt value for %d\n", k);
            }
        };
        std::thread t1(worker, 0), t2(worker, 512), t3(worker, 1024);
        t1.join();
        t2.join();
        t3.join();
        ++checks;
        if (c.size() == 0 || c.size() > 1024) {
            std::printf("  size %zu out of bounds after hammering\n", c.size());
            ++f;
        }
        fails += f > 0;
        std::printf("5. concurrent LRUCache hammering (3 threads x 20k ops): %s\n",
                    f ? "FAIL" : "PASS");
    }

    std::printf("cpp_itfs_microframe: %d checks, %d failures -> %s\n", checks, fails,
                fails ? "FAIL" : "PASS");
    return fails ? MAIN_RETURN_BAD : 0;
}
