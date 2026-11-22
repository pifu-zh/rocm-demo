// cfg.hpp — ① Cfg + 共享算术（host g++ 与 device hipcc 两侧共用；禁 include 任何 HIP 头）
// mori §3.5 约束 1："Cfg 头不得 include 任何 HIP 头"（host/device 分离纪律）
#ifndef MORI_LAB_DEMO5_CFG_HPP
#define MORI_LAB_DEMO5_CFG_HPP

struct RedCfg {
  int blockNum;      // 网格
  int warpPerBlock;  // 每 block 的 warp 数
};
inline bool operator==(const RedCfg& a, const RedCfg& b) {
  return a.blockNum == b.blockNum && a.warpPerBlock == b.warpPerBlock;
}

// host/device 共享算术（mori §3.5：无属性 constexpr，两侧各编一份）
constexpr int kWaveSize = 32;
constexpr int BlockThreads(const RedCfg& c) { return c.warpPerBlock * kWaveSize; }
constexpr int ScratchFloats(const RedCfg& c) { return c.blockNum; }
constexpr bool RedCfgValid(const RedCfg& c) {
  return c.blockNum > 0 && c.warpPerBlock > 0 && c.warpPerBlock <= 16 && c.blockNum <= 1024;
}
#endif
