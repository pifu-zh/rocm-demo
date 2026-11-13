# demo: warp_sync — 无硬件屏障/归约指令的波同步原语（gfx1030）

## 验证等级

**HARDWARE_PASS + PERFORMANCE_MEASURED**（gfx1030 / RX 6950 XT，ROCm 7.2.4，2026-11-13）
四原语正确性全 PASS（含双并发部分组、3 轮重入、生产者/消费者可见性）；延迟已测。

## 原理

RDNA2 无 mbarrier、无 named/counted barrier、无 redux.sync。等价实现（全部
HIP C++，仅用 `__builtin_amdgcn_ds_bpermute` + LDS 原子 + `s_sleep`）：

1. **lane_id**：`mbcnt_lo/hi` 对（波大小正确）。
2. **shuffle_bfly**：`ds_bpermute`，NV lane → 字节偏移规则（off = lane*4）。
3. **redux_add**：5 轮 xor 蝶形，每 lane 持有波总和。
4. **计数屏障**：单 64 位 LDS 字 `{parity:1 | count:31 | round:32}`，
   **atomicAdd-only**——到达 = `atomicAdd(+1)`；最后一个到达者的翻转 = 一次
   `atomicAdd((1<<31) - expected)`（count 归零 + parity 翻转单原子完成）。
   到达计数守恒：迟到线程的 +1 自然归入下一轮，无丢失。
5. **软 mbarrier**：同一 64 位字，arrive 返回相位 token，wait 等 parity
   变化；parity 自动逐轮翻转，**无需 re-arm**（消掉上游 re-arm+barrier 舞蹈）。

## 上游出处

- 语义参照：cuda-oxide `crates/cuda-oxide-codegen/src/amdgcn.rs`
  （MB_HELPERS:947,1131 / COUNTED_BARRIER_HELPERS:1588,1650，GPU-verified IR）
  与 `crates/cuda-device/src/barrier.rs`。
- 上游实测：`docs/research/2026-11-11-sync-costs-and-small-items.md`
  （counted 527.5 ns=8.8×、mbarrier 462.9 ns=7.8×、shfl 69.1 ns=1.2×、
  redux 495.6 ns=8.3×，native s_barrier 59.8 ns）。
- aiter 自家 spin 屏障的退避先例：`csrc/kernels/topk_per_row_kernels.cu:530-546`
  （`s_sleep` + 跨块到达计数器）。
- 谱系：`docs/EMULATION_CATALOG.md` E4/E5/E6。

## 两个实测发现（本 demo 期间抓到，均为设备级）

1. **64 位 LDS atomicCAS 挂死**：gfx1030/ROCm 7.2 上，last-arriver 的
   64 位 LDS atomicCAS 在 255 个 spinner 压同地址时不返回（atomicAdd 同条件
   可靠——256 线程穷举通过）。修复 = 翻转改用 atomicAdd（parity 位技巧），
   全程零 CAS。
2. **SIMT 波陷阱**：`if(flip) else spin` 的分支结构会让编译器把 spin 路径
   排在 flip 之前——flipper 所在 lane 被困在同一 wave 的 spin PC 后（32 线程
   单波即挂，与波数无关）。修复 = flip 在前、**无分支统一 spin**（flipper 的
   退出谓词立即为假）。调试期间还发现：debug mark 的普通全局 store 会被
   重排/合并，挂死观测必须用 atomicExch 或独立流轮询显存。

## Hardware Matrix

| 架构 | 状态 |
|---|---|
| gfx1030 | ✅ 本 demo（真机正确性 + 延迟） |
| gfx942/950 | 同构（u64 LDS 原子 + s_sleep 均存在），未验证 |
| gfx1250 | 原生 mbarrier 存在（aiter TDM 路径），软件版冗余 |
| 通用 | 64 位 LDS atomicAdd 必需（gfx90a+）；wave32 编译 |

## Build & Run

```bash
hipcc -x hip --offload-arch=gfx1030 -O3 src/main.hip -I include -o warp_sync_demo
./warp_sync_demo
```

## Results（2026-11-13，容器 gfx-m1，256 线程单 CTA，64 ops/launch）

| 原语 | ns/op | vs native __syncthreads (141.9) | 上游参照 |
|---|---|---|---|
| counted barrier | 624.4 | 4.4× | 上游 527.5 / 8.8×（Rust-LLVM 路径） |
| soft mbarrier | **230.6** | **1.6×** | 上游 462.9 / 7.8× |
| shuffle bfly | 145.6 | 1.0× | 上游 69.1 / 1.2×（时钟差异） |
| redux add | 227.5 | 1.6× | 上游 495.6 / 8.3× |

诚实披露（charter 纪律）：功能替代全部实证（正确性 PASS）；屏障族延迟属
latency-primitive 性质，按参照路径相对分级低于 60% 线的部分如实标注，
不宣称性能胜利。mbarrier 的 atomicAdd-only flip + 退避组合优于上游
Rust-LLVM CAS 路径（1.6× vs 7.8×），值得上游复测。

## 未验证事项

- 多 CTA / 大规模并发下计数屏障的公平性（单 CTA 已验）
- mbarrier expect_tx 字节级（开放缺口，与上游一致）
- wave64 形态（lane_id 的 mbcnt 对已波大小正确，spin 未验）
