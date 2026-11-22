// main.cpp — 内容寻址 JIT 缓存（mori JIT v2 核心链路的独立复现）
//
// 上游出处: ROCm/mori @ c5bdc391
//   - docs/MORI_JIT_V2_DESIGN.md: 核心不变量 "Cfg 值 = 特化身份 = 渲染源码文本 = sha256 缓存 key"
//   - src/jit/v2/compiler.cpp:200-226  CacheDirFor（sha256 串接 name/compiler/nic/flags/include树/源码）
//   - src/jit/v2/compiler.cpp:233-294  EnsureCompiled（tmp 目录编译 → rename 原子发布，无文件锁）
//   - src/jit/v2/util.cpp:178-215      MakeUniqueTempDir / PublishDir（fsync + rename；输家删自己）
//   - src/jit/v2/compiler.cpp:106-130  HashTree（include 树哈希；本 demo 把 body.hpp 内容直接入 key）
//   - src/ops/dispatch_combine_v2/ep_spec.cpp:197-289  RenderEpSource（生成完整 TU 的实体）
//   - src/jit/v2/compiler.cpp:53-71    Module RAII（hipModuleLoad/GetFunction）
//
// 链路: RedCfg → RenderSource(cfg) 生成完整 TU → sha256(name+flags+body内容+源码) →
//       <cache>/kernel.<name>.<24hex>/ → 命中则跳过编译；未命中 tmp 编译 → rename 发布 →
//       hipModuleLoad/GetFunction → hipModuleLaunchKernel（gfx1030 实跑校验）。
//
// 验证等级目标: HARDWARE_PASS（kernel 实跑）+ REFERENCE_PASS（缓存/竞态语义）
//
// 用法:
//   jit_content_cache run <blockNum> <warpPerBlock>   # 全链路+正确性
//   jit_content_cache build-only <blockNum> <warpPerBlock>  # 仅构建（并发竞态测试用）
//   jit_content_cache selftest                        # 缓存命中/键分裂/竞态

#include <hip/hip_runtime_api.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <chrono>
#include <thread>
#include <future>
#include <set>
#include <cmath>
#include <sys/file.h>
#include <unistd.h>

namespace fs = std::filesystem;

// ================= sha256（自包含，无依赖） =================
static void sha256(const void* data, size_t len, unsigned char out[32]) {
  static const unsigned int K[64] = {
      0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
      0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
      0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
      0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
      0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
      0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
      0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
      0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
  unsigned int h[8] = {0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
                       0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
  std::vector<unsigned char> msg((const unsigned char*)data, (const unsigned char*)data + len);
  msg.push_back(0x80);
  while (msg.size() % 64 != 56) msg.push_back(0);
  unsigned long long bits = (unsigned long long)len * 8;
  for (int i = 7; i >= 0; --i) msg.push_back((unsigned char)(bits >> (i * 8)));
  auto rotr = [](unsigned int x, int n) { return (x >> n) | (x << (32 - n)); };
  for (size_t off = 0; off < msg.size(); off += 64) {
    unsigned int w[64];
    for (int i = 0; i < 16; ++i)
      w[i] = (msg[off+i*4]<<24)|(msg[off+i*4+1]<<16)|(msg[off+i*4+2]<<8)|msg[off+i*4+3];
    for (int i = 16; i < 64; ++i) {
      unsigned int s0 = rotr(w[i-15],7)^rotr(w[i-15],18)^(w[i-15]>>3);
      unsigned int s1 = rotr(w[i-2],17)^rotr(w[i-2],19)^(w[i-2]>>10);
      w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    unsigned int a=h[0],b=h[1],c=h[2],d=h[3],e=h[4],f=h[5],g=h[6],hh=h[7];
    for (int i = 0; i < 64; ++i) {
      unsigned int S1 = rotr(e,6)^rotr(e,11)^rotr(e,25);
      unsigned int ch = (e&f)^((~e)&g);
      unsigned int t1 = hh + S1 + ch + K[i] + w[i];
      unsigned int S0 = rotr(a,2)^rotr(a,13)^rotr(a,22);
      unsigned int maj = (a&b)^(a&c)^(b&c);
      unsigned int t2 = S0 + maj;
      hh=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
    }
    h[0]+=a;h[1]+=b;h[2]+=c;h[3]+=d;h[4]+=e;h[5]+=f;h[6]+=g;h[7]+=hh;
  }
  for (int i = 0; i < 8; ++i)
    for (int j = 3; j >= 0; --j) out[i*4+(3-j)] = (unsigned char)(h[i] >> (j*8));
}
static std::string sha256_hex(const std::string& s, size_t truncate = 32) {
  unsigned char d[32]; sha256(s.data(), s.size(), d);
  char hex[65];
  for (int i = 0; i < 32; ++i) sprintf(hex + i * 2, "%02x", d[i]);
  return std::string(hex, truncate);
}

// ================= 与 mori 对应的三件套 =================
#include "cfg.hpp"    // ① Cfg + 共享算术（host 安全；body.hpp 只进生成的 device TU）

static const char* kCacheRoot = "./jit_cache_results/cache";

// ③ RenderSource：生成完整 TU（ep_spec.cpp:197-289 的对应物）
static std::string RenderSource(const RedCfg& cfg, const std::string& entryName) {
  std::ostringstream os;
  os << "// mori lab demo5 — generated, do not edit.\n"
     << "#include <hip/hip_runtime.h>\n"          // device TU 自带 HIP 头（body 刻意不含——host/device 分离）
     << "#include \"body.hpp\"\n"
     << "constexpr RedCfg kCfg = RedCfg{ .blockNum = " << cfg.blockNum
     << ", .warpPerBlock = " << cfg.warpPerBlock << " };\n"
     << "extern \"C\" __global__ void __launch_bounds__("
     << "BlockThreads(kCfg)) " << entryName
     << "(const float* in, float* out, int n) { ReductionBody<kCfg>(in, out, n); }\n";
  return os.str();
}
// EntryName：Cfg 自编码（ep_spec.cpp:199-216 思想）
static std::string EntryName(const RedCfg& cfg) {
  char buf[64];
  snprintf(buf, sizeof buf, "reduction_b%dp%d", cfg.blockNum, cfg.warpPerBlock);
  return buf;
}

// 缓存 key：sha256(name $$ flags $$ body内容(代表 include 树) $$ 源码文本)
// （mori CacheDirFor 的缩小版：nic 省略，flags 显式进 key）
static std::string CacheKeyFor(const RedCfg& cfg) {
  std::string body;
  { std::ifstream f("src/body.hpp"); std::stringstream ss; ss << f.rdbuf(); body = ss.str(); }
  std::string flags = "--genco --offload-arch=gfx1030 -O2 -std=c++20";
  std::string code = RenderSource(cfg, EntryName(cfg));
  std::string all = EntryName(cfg) + "$$" + flags + "$$" + body + "$$" + code;
  return sha256_hex(all, 24);
}

static int& sTmpCounter() { static int c = 0; return c; }

// 编译并原子发布（EnsureCompiled 的复现：tmp → hipcc → fsync → rename）
static fs::path EnsureCompiled(const RedCfg& cfg, bool* didCompile, bool* lostRace) {
  fs::create_directories(kCacheRoot);
  const std::string key = CacheKeyFor(cfg);
  const std::string name = EntryName(cfg);
  const fs::path finalDir = fs::path(kCacheRoot) / ("kernel." + name + "." + key);
  *didCompile = false; *lostRace = false;
  if (fs::exists(finalDir / "kernel.hsaco")) return finalDir;   // 缓存命中

  fs::path tmp = fs::path(kCacheRoot) / ("tmp." + std::to_string(getpid()) + "." +
                                          std::to_string(++sTmpCounter()) + ".attempt");
  fs::create_directories(tmp);
  fs::copy("src/body.hpp", tmp / "body.hpp");
  fs::copy("src/cfg.hpp", tmp / "cfg.hpp");     // body include cfg —— 两份都要进 tmp（mori _jit-sources 的缩小版）
  { std::ofstream f(tmp / "kernel.hip"); f << RenderSource(cfg, name); }
  std::string cmd = "hipcc --genco --offload-arch=gfx1030 -O2 -std=c++20 " +
                    (tmp / "kernel.hip").string() + " -o " + (tmp / "kernel.hsaco").string() +
                    " 2>&1";
  FILE* p = popen(cmd.c_str(), "r");
  std::string out; char line[256];
  while (p && fgets(line, sizeof line, p)) out += line;
  int rc = p ? pclose(p) : -1;
  if (rc != 0) { fprintf(stderr, "hipcc failed rc=%d:\n%s\n", rc, out.c_str()); exit(2); }
  if (!fs::exists(tmp / "kernel.hsaco")) { fprintf(stderr, "hipcc produced no hsaco\n%s\n", out.c_str()); exit(2); }

  *didCompile = true;
  // 原子发布：rename 失败 = 输家（赢家内容与自家字节等价，目录名就是内容哈希）
  std::error_code ec;
  fs::rename(tmp, finalDir, ec);
  if (ec) { fs::remove_all(tmp); *lostRace = true; }
  return finalDir;
}

// hipModule 发射（compiler.cpp:53-71 Module RAII + hip_driver launch_struct 思想）
static void LaunchCompiled(const fs::path& dir, const RedCfg& cfg,
                           const float* dIn, float* dOut, int n) {
  static std::set<std::string> loaded;   // 进程内 module 缓存（compiler.cpp:183-188 思想）
  const std::string key = dir.string();
  if (loaded.count(key)) { /* 已加载则仅取函数再发射，demo 简化为每用例一次加载 */ }
  hipModule_t mod;
  hipError_t e = hipModuleLoad(&mod, (dir / "kernel.hsaco").c_str());
  if (e != hipSuccess) { fprintf(stderr, "hipModuleLoad failed %s (%s)\n", (dir/"kernel.hsaco").c_str(), hipGetErrorString(e)); exit(3); }
  hipFunction_t fn;
  e = hipModuleGetFunction(&fn, mod, EntryName(cfg).c_str());
  if (e != hipSuccess) { fprintf(stderr, "hipModuleGetFunction(%s) failed %s\n", EntryName(cfg).c_str(), hipGetErrorString(e)); exit(3); }
  unsigned gridX = (unsigned)cfg.blockNum, blockX = (unsigned)BlockThreads(cfg);
  struct Args { const float* in; float* out; int n; } args{dIn, dOut, n};
  void* params[] = {&args.in, &args.out, &args.n};
  e = hipModuleLaunchKernel(fn, gridX, 1, 1, blockX, 1, 1, 0, nullptr, params, nullptr);
  if (e != hipSuccess) { fprintf(stderr, "hipModuleLaunchKernel failed %s\n", hipGetErrorString(e)); exit(3); }
}

// ================= 场景 =================
static int RunCase(const RedCfg& cfg, bool verbose) {
  const int N = 1 << 20;
  std::vector<float> hIn(N);
  for (int i = 0; i < N; ++i) { hIn[i] = (float)((i % 8) - 3) * 0.25f; }  // 0.25 的倍数：中间和 < 2^24，浮点逐位精确
  float *dIn, *dOut;
  hipMalloc(&dIn, N * 4); hipMalloc(&dOut, 4);
  hipMemcpy(dIn, hIn.data(), N * 4, hipMemcpyHostToDevice);
  hipMemset(dOut, 0, 4);   // atomicAdd 累加目标清零
  bool didCompile, lostRace;
  auto dir = EnsureCompiled(cfg, &didCompile, &lostRace);
  if (verbose) printf("cfg{b=%d,w=%d} dir=%s %s%s\n", cfg.blockNum, cfg.warpPerBlock,
                      dir.filename().c_str(), didCompile ? "[compiled]" : "[cache-hit]",
                      lostRace ? "[lost-race]" : "");
  LaunchCompiled(dir, cfg, dIn, dOut, N);
  hipDeviceSynchronize();
  float got = -1; hipMemcpy(&got, dOut, 4, hipMemcpyDeviceToHost);
  float refF = 0; for (int i = 0; i < N; ++i) refF += hIn[i];
  bool ok = std::fabs(got - refF) < 1e-6f;   // 逐位精确归约：容差极小
  if (verbose) printf("  result=%.4f ref=%.4f -> %s\n", got, refF, ok ? "PASS" : "FAIL");
  hipFree(dIn); hipFree(dOut);
  return ok ? 0 : 1;
}

static int SelfTest(const char* self) {
  int failures = 0;
  RedCfg c1{16, 8}, c2{32, 4};
  const std::string k1 = CacheKeyFor(c1), k2 = CacheKeyFor(c2);
  printf("selftest: key(c1)=%s key(c2)=%s distinct=%s\n", k1.c_str(), k2.c_str(),
         k1 != k2 ? "y" : "N");
  if (k1 == k2) ++failures;

  // 键的内容敏感性：改 body.hpp 内容 → 键变（include 哈希语义）
  {
    std::ofstream f("src/body.hpp", std::ios::app); f << "// touch-for-key-test\n";
  }
  const std::string k1b = CacheKeyFor(c1);
  printf("selftest: after-touch key(c1)=%s changed=%s\n", k1b.c_str(), k1b != k1 ? "y" : "N");
  if (k1b == k1) ++failures;
  {  // 恢复：移除 touch 行，恢复到原始字节
    std::ifstream in("src/body.hpp"); std::stringstream ss; ss << in.rdbuf();
    std::string s = ss.str();
    const std::string tag = "// touch-for-key-test\n";
    size_t p = s.find(tag);
    if (p != std::string::npos) s.erase(p, tag.size());
    std::ofstream out("src/body.hpp"); out << s;
  }
  const std::string k1c = CacheKeyFor(c1);
  if (k1c != k1) { printf("selftest: WARN restore mismatch (%s vs %s)\n", k1c.c_str(), k1.c_str()); }
  else printf("selftest: restore ok (key back to %s)\n", k1.c_str());

  // 缓存命中：同 Cfg 二次构建不触发编译，目录 mtime 不变
  {
    bool didCompile, lostRace;
    auto dir = EnsureCompiled(c1, &didCompile, &lostRace);
    auto mt0 = fs::last_write_time(dir);
    auto dir2 = EnsureCompiled(c1, &didCompile, &lostRace);
    auto mt1 = fs::last_write_time(dir2);
    bool hit = !didCompile && dir == dir2 && mt0 == mt1;
    printf("selftest: cache-hit(no recompile)=%s\n", hit ? "PASS" : "FAIL");
    if (!hit) ++failures;
  }

  // 双进程竞态：同 key 并发 build-only，恰好一个发布，两者拿到同一目录
  {
    auto buildOnly = [self]() {
      std::string cmd = std::string(self) + " build-only 64 8";
      FILE* p = popen(cmd.c_str(), "r");
      std::string out; char line[256];
      while (p && fgets(line, sizeof line, p)) out += line;
      pclose(p);
      return out;   // 输出 "PUBLISHED <dir>" 或 "REUSED <dir>"
    };
    auto f1 = std::async(std::launch::async, buildOnly);
    auto f2 = std::async(std::launch::async, buildOnly);
    std::string o1 = f1.get(), o2 = f2.get();
    int published = (o1.find("PUBLISHED") != std::string::npos) +
                    (o2.find("PUBLISHED") != std::string::npos);
    std::string d1 = o1.find("PUBLISHED") != std::string::npos
        ? o1.substr(o1.find("PUBLISHED") + 10, 24)
        : o1.substr(o1.find("REUSED") + 7, 24);
    std::string d2 = o2.find("PUBLISHED") != std::string::npos
        ? o2.substr(o2.find("PUBLISHED") + 10, 24)
        : o2.substr(o2.find("REUSED") + 7, 24);
    bool ok = published == 1 && d1 == d2;
    printf("selftest: race two-process published=%d same-dir=%s -> %s\n", published,
           d1 == d2 ? "y" : "N", ok ? "PASS" : "FAIL");
    printf("  proc1: %s", o1.c_str());
    printf("  proc2: %s", o2.c_str());
    if (!ok) ++failures;
  }
  return failures;
}

int main(int argc, char** argv) {
  std::string mode = argc > 1 ? argv[1] : "run";
  if (mode == "build-only") {
    RedCfg cfg{atoi(argv[2]), atoi(argv[3])};
    bool didCompile, lostRace;
    auto dir = EnsureCompiled(cfg, &didCompile, &lostRace);
    // PUBLISHED = 我编译且我的 rename 赢了；REUSED = 命中缓存或输家改用赢家目录
    // （mori compiler.cpp:287-288 "Losing the publish race is fine"）
    printf("%s %s\n", (didCompile && !lostRace) ? "PUBLISHED" : "REUSED", dir.filename().c_str());
    return 0;
  }
  if (mode == "selftest") {
    int f = SelfTest(argv[0]);
    printf("%s\n", f == 0 ? "SELFTEST PASS" : "SELFTEST FAIL");
    return f;
  }
  // run: 全链路 + 正确性（两个 Cfg 各自渲染/编译/发射/校验）
  int failures = 0;
  hipDeviceProp_t prop; hipGetDeviceProperties(&prop, 0);
  printf("device=%s warpSize=%d\n", prop.gcnArchName, prop.warpSize);
  failures += RunCase(RedCfg{16, 8}, true);
  failures += RunCase(RedCfg{32, 4}, true);
  failures += RunCase(RedCfg{16, 8}, true);   // 第三次应命中缓存
  printf("%s\n", failures == 0 ? "ALL PASS" : "HAS FAILURES");
  return failures;
}
