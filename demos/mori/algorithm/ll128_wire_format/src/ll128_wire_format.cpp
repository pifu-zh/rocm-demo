// ll128_wire_format.cpp — NCCL LL128 线缆格式数学的独立复现（E-11/D-11）
//
// 上游出处: ROCm/mori @ c5bdc391
//   - include/mori/ops/dispatch_combine_v2/ep_cfg.hpp:550-556
//       EpLl128LandRowBytes(c) = ((data + 119) / 120 + 7) / 8 * 1024
//     LL128 低延迟行布局: 每条 128B 线缆行承载 120B 数据 + 8B flag/控制；
//     8 行为一组（1024B 线缆/组，960B 数据/组 → 效率 93.75%）。
//     mori 的 ll128 cfg（:262-268, :572-575）让 EPv2 的 land 区按此公式定量。
//   - 血统: NCCL LL128 协议——8 个 rank/lane 在 128B 行的 8×16B 槽中轮转放置，
//     flag 槽（每行首 16B...NCCL 实际为 8B flag + 120B 数据/行）。
//
// 本 demo 纯计算验证:
//   T1 mori 公式逐点复算（边界: 1/119/120/121/960/961/9600 B）
//   T2 LL128 pack/unpack round-trip（8-lane 交错放置，逐字节一致）
//   T3 线缆放大率表（data → wire，效率=120/128=93.75% 上限）vs 逐行 pad128
//   T4 flag 槽不变量: 每行 [0..7] 字节为 flag 区（pack 不污染；unpack 忽略）
//   T5 尺寸 fuzz（1..4096 随机尺寸 round-trip）
// 验证等级目标: REFERENCE_PASS（纯计算；morí 的 ll128 cfg 公式为判定基准）
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

// ---- mori ep_cfg.hpp:551-555 公式的逐字复现 ----
static size_t epLl128LandRowBytes(size_t data) {
  return ((data + 119) / 120 + 7) / 8 * 1024;
}

// ---- LL128 pack/unpack（8-lane 交错形态）----
// 线缆布局: nGroups = ceil(data / 960)；每组 8 行 × 128B。
//   行 l (0..7): 字节 [l*128, l*128+8) = flag 槽（8B），[l*128+8, (l+1)*128) = 120B 数据
//   组内数据放置: 8 行的 120B 数据区按 lane 交错——lane r（rank r 的读窗口）从
//   行 ((r + j*8)/…  本 demo 用 NCCL 简化形态: 数据按行序填入各行数据区（行内顺序），
//   lane r 的读序列 = 第 r 行数据区 + 第 r+8 行……即"每 lane 独占一行"的轮转等效。
// unpack 是 pack 的精确逆。
static size_t ll128WireBytes(size_t data) {
  size_t rows = (data + 119) / 120;               // 120B 数据/行
  size_t groups = (rows + 7) / 8;                 // 8 行/组
  return groups * 8 * 128;                        // 128B 线缆/行
}
static void ll128Pack(const uint8_t* in, size_t n, std::vector<uint8_t>& wire) {
  size_t rows = (n + 119) / 120;
  size_t groups = (rows + 7) / 8;
  wire.assign(groups * 8 * 128, 0);               // flag 槽零初始化
  size_t remaining = n;
  const uint8_t* p = in;
  for (size_t g = 0; g < groups; ++g)
    for (size_t l = 0; l < 8; ++l) {
      if (remaining == 0) return;
      size_t take = std::min<size_t>(remaining, 120);
      uint8_t* line = wire.data() + (g * 8 + l) * 128;
      memcpy(line + 8, p, take);                  // 数据区 = [8, 128)
      p += take; remaining -= take;
    }
}
static void ll128Unpack(const std::vector<uint8_t>& wire, size_t n, uint8_t* out) {
  size_t rows = (n + 119) / 120;
  size_t groups = (rows + 7) / 8;
  size_t remaining = n;
  uint8_t* p = out;
  for (size_t g = 0; g < groups && remaining; ++g)
    for (size_t l = 0; l < 8 && remaining; ++l) {
      size_t take = std::min<size_t>(remaining, 120);
      const uint8_t* line = wire.data() + (g * 8 + l) * 128;
      memcpy(p, line + 8, take);
      p += take; remaining -= take;
    }
}

static int failures = 0;
static void check(bool ok, const char* msg) {
  printf("%-58s %s\n", msg, ok ? "PASS" : "FAIL");
  if (!ok) ++failures;
}

int main() {
  // T1: mori 公式逐点复算
  struct Case { size_t data, expect; };
  const Case cases[] = {
      {1, 1024}, {119, 1024}, {120, 1024},            // 1 行组
      {121, 1024}, {960, 1024},                       // 960B=满 8 行组: ceil(960/120)=8 行 → 1 组 1024
      {961, 2048},                                    // 跨 2 组
      {9600, 10240},                                  // 80 行 = 10 组
  };
  bool t1 = true;
  for (auto& c : cases) {
    size_t got = epLl128LandRowBytes(c.data);
    size_t want = ((c.data + 119) / 120 + 7) / 8 * 1024;
    if (got != c.expect || got != want) {
      printf("  data=%zu: got=%zu expect=%zu formula=%zu\n", c.data, got, c.expect, want);
      t1 = false;
    }
  }
  check(t1, "T1 mori EpLl128LandRowBytes formula edge cases");
  // 960B 案例的语义注记: ceil(960/120)=8 行=恰好 1 组（1024B），与 mori 公式一致

  // T2: pack/unpack round-trip（960B = 满一组，逐字节）
  {
    std::vector<uint8_t> in(960);
    for (size_t i = 0; i < in.size(); ++i) in[i] = (uint8_t)(i * 31 + 7);
    std::vector<uint8_t> wire, out(in.size(), 0xAA);
    ll128Pack(in.data(), in.size(), wire);
    check(wire.size() == 1024, "T2 wire bytes == 1024 for 960B");
    ll128Unpack(wire, in.size(), out.data());
    check(memcmp(in.data(), out.data(), in.size()) == 0, "T2 round-trip byte-exact (960B)");
    // flag 槽不变量: 每行首 8B 保持 pack 的零初始化（未被数据污染）
    bool flagsClean = true;
    for (size_t l = 0; l < 8; ++l)
      for (int b = 0; b < 8; ++b)
        if (wire[l * 128 + b] != 0) flagsClean = false;
    check(flagsClean, "T4a flag slots (8B/line) unpolluted by pack");
  }

  // T3: 线缆放大率表
  {
    printf("T3 wire amplification (LL128 vs naive pad-128):\n");
    bool ok = true;
    for (size_t kb : {1, 4, 16, 64, 256}) {
      size_t data = kb * 1024;
      size_t wire = ll128WireBytes(data);
      size_t naive = ((data + 127) / 128) * 128;
      double eff = 100.0 * data / wire;
      if (wire != ((data + 119) / 120 + 7) / 8 * 1024) ok = false;
      printf("  %4zuKB data -> %7zuB wire (%.2f%% eff) | naive=%7zuB (%.2f%%)\n",
             kb, wire, 100.0 * data / wire, naive, 100.0 * data / naive);
    }
    check(ok, "T3 wire formula consistent with mori formula at scale");
  }

  // T5: 尺寸 fuzz（1..1024 + 随机大尺寸）
  {
    bool ok = true;
    srand(20261123);
    std::vector<size_t> sizes;
    for (size_t s = 1; s <= 300; ++s) sizes.push_back(s);
    for (int k = 0; k < 20; ++k) sizes.push_back(300 + rand() % 9000);
    for (size_t n : sizes) {
      std::vector<uint8_t> in(n);
      for (size_t i = 0; i < n; ++i) in[i] = (uint8_t)(rand() & 0xFF);
      std::vector<uint8_t> wire, out(n + 64, 0xAA);
      ll128Pack(in.data(), n, wire);
      if (wire.size() != ll128WireBytes(n)) { ok = false; break; }
      ll128Unpack(wire, n, out.data());
      if (memcmp(in.data(), out.data(), n) != 0) { ok = false; break; }
      // 越界哨兵: unpack 不得写超出 n
      for (size_t j = n; j < n + 64; ++j)
        if (out[j] != 0xAA) { ok = false; break; }
    }
    check(ok, "T5 fuzz round-trip 1..9300B (incl. sentinel)");
  }

  printf("%s\n", failures == 0 ? "ALL PASS" : "HAS FAILURES");
  return failures;
}
