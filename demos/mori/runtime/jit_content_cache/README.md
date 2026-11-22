# jit_content_cache — 内容寻址 JIT 缓存（mori JIT v2 核心链路复现）

**类目**: runtime ｜ **验证等级**: `HARDWARE_PASS` + `REFERENCE_PASS`
（gfx1030 上生成的 kernel 实跑正确；缓存键/命中/竞态语义 5 项自测全过，见 `results/`）

## 1. 原理说明

mori JIT v2 的核心不变量：**`Cfg 值 = 特化身份 = 渲染出的源码文本 = sha256 缓存 key`**。
一个配置想影响生成的二进制，只有一条路——变成 Cfg 字段、被渲染进源码文本；而那段文本
整个进了缓存 key。"配置变了但复用旧二进制" 在**结构上**不成立，而不是靠纪律维持。

本 demo 复刻完整链路：

```
RedCfg{blockNum,warpPerBlock}                     ← structural NTTP（Demo 2 已证）
   → RenderSource(cfg) 生成完整 TU                ← ep_spec.cpp RenderEpSource 的对应物
   → key = sha256(name $$ flags $$ body内容 $$ 源码文本)   ← CacheDirFor 的缩小版
   → <cache>/kernel.<name>.<24hex>/               ← 目录名即内容哈希
       命中 → 直接 hipModuleLoad
       未命中 → tmp 目录编译（hipcc --genco --offload-arch=gfx1030）
                → fsync → rename(tmp, final)       ← 无锁原子发布
                rename 失败 = 输家 → 删自己的 tmp，用赢家目录（内容字节等价）
   → hipModuleGetFunction(EntryName(cfg)) → hipModuleLaunchKernel
```

实测行为（`results/run_gfx1030.log`、`results/selftest.log`）：

| 检验 | 结果 |
|---|---|
| 同 Cfg 第三次构建 `[cache-hit]`（目录 mtime 不变、零编译） | PASS |
| 不同 Cfg → 不同目录（键分裂） | PASS |
| body.hpp 追加一行注释 → key 变（include 内容敏感性） | PASS |
| 恢复 body.hpp → key 精确还原 | PASS |
| 双进程并发同 key：**恰好一个 PUBLISHED**，另一个 REUSED 且目录相同 | PASS |
| 生成的 kernel 在 gfx1030 上结果正确（131072.0000 == host 参考，逐位精确） | PASS ×3 |

复现过程中撞上的两个真问题（正是 mori 文档警告过的）：

1. **host/device 分离纪律**（mori §3.5 约束 1）：Cfg 头一旦混入 device 代码
   （threadIdx 等），host g++ 编译直接失败 → 被迫拆分 `cfg.hpp`（无 HIP 头、两侧共用）
   与 `body.hpp`（只被生成的 device TU include）。这条纪律在 mori 是 `#error`/CI 守护，
   在本 demo 里是物理事实。
2. **kernel 的 grid 同步陷阱**：初版 body 用 block 0 读其他 block 的 scratch，无跨 block
   同步 → 结果非确定（-61.5/-111/-112.5 三次不同）。改为 per-block 原子累加 + 输入全部
   取 0.25 的倍数（中间和 < 2^24）使浮点归约**逐位精确**，才得到可断言的参考。

## 2. 上游出处

- `docs/MORI_JIT_V2_DESIGN.md`（§1 不变量、§3.4 缓存、§3.5 host/device 分离）
- `src/jit/v2/compiler.cpp:200-226`（CacheDirFor）、`:233-294`（EnsureCompiled tmp→rename）
- `src/jit/v2/util.cpp:178-215`（MakeUniqueTempDir/PublishDir；"Losing the publish race is fine"）
- `src/jit/v2/compiler.cpp:106-130`（HashTree include 哈希——本 demo 用 body.hpp 内容入 key 简化）
- `src/ops/dispatch_combine_v2/ep_spec.cpp:197-289`（RenderEpSource/EntryName）
- `src/jit/v2/compiler.cpp:53-71,183-188`（Module RAII/进程内 module 缓存）
- 考古报告：`docs/archaeology/05-jit-build-python.md` §1

## 3. 独立实现说明

- host 侧：单文件 C++20（sha256 自包含实现，无 OpenSSL）；链接 `hip::host`（构建期
  不需要 hipcc 设备编译——mori `src/jit/v2/CMakeLists.txt:8-11` 同款）。
- 生成 TU：`#include <hip/hip_runtime.h>`（device TU 自带 HIP 头）+ cfg/body 双头 +
  `__launch_bounds__(BlockThreads(kCfg))` 表达式化发射界（mori §3.3）。
- 缓存 key 与 mori 的差异：nic 未纳入（无 NIC）、flags/从命令行固定、include 树简化为
  body.hpp 单文件内容——结构同构，维度精简。

## 4. Reference / Correctness Test

- kernel 正确性：host 独立求和参考（输入为二进制精确可表示的 0.25 倍数 → 浮点归约
  顺序无关 → 容差 1e-6 实为逐位断言）。
- 缓存语义自测：键唯一性/内容敏感性/命中判定/竞态单发布者，全部由 host 侧独立判定。

## 5. 构建

```bash
demos/runtime/jit_content_cache/scripts/build_run.sh   # 容器内（CWD=仓库根，body.hpp 相对路径）
```

## 6. Inspection

`jit_cache_results/cache/kernel.<name>.<hash>/`：`kernel.hip`（渲染产物，可读）、
`kernel.hsaco`（--genco 产物）、`body.hpp/cfg.hpp`（快照）。目录名即 sha256 前 24 hex，
与 `selftest.log` 打印的 key 互相印证。

## 7. Hardware Matrix

生成 code object 以 `--offload-arch=gfx1030` 编译并在 RX 6950 XT 实跑。
同一框架对 gfx942/gfx1250 只需换 flags（flags 已入 key，自动分目录）——未实测（无硬件）。

## 8. Execution Result

- `results/run_gfx1030.log`：3 用例 ALL PASS（2 编译 + 1 命中，结果 131072.0000 精确）。
- `results/selftest.log`：键分裂/内容敏感/命中/双进程竞态全 PASS。

未验证事项：真并发编译的 hipcc 资源竞争（双进程错峰启动）；multi-GPU module 缓存
（compiler.cpp:183-188 的 (device, cacheDir) 键）；`MORI_JIT_KEEP_FAILED` 失败保留路径。
