# nttp_cfg_specialization — structural NTTP 配置特化（mori JIT v2 的编译期核心机制）

**类目**: compiler ｜ **验证等级**: `HARDWARE_PASS` + `STATIC_ANALYSIS_PASS`
（gfx1030 容器实跑正确性 5/5 PASS；ISA 产物与统计见 `results/isa/`）

## 1. 原理说明

mori JIT v2 的核心不变量是 `Cfg 值 = 特化身份 = 渲染源码文本 = sha256 缓存 key`。
其编译侧支柱是 **C++20 structural NTTP**：整个配置 struct 作为**非类型模板参数**
传入 kernel body，所有开关用 `if constexpr (kCfg.xxx)` 而非 `#if`：

- `#if` 的条件来自命令行 `-D`——带外、不进缓存 key、散落各处，"配置变了但复用旧二进制"
  无人拦截；
- `if constexpr` 的条件来自 Cfg 字段——进 key、有类型、有守护，未选中的分支**不存在**
  于编译产物中；
- 相对 DeepEP/CK 的位置模板参数串，具名字段消掉"调换两个同类型参数照样编过"的隐患。

本 demo 用一个向量化拷贝 kernel 复刻该机制，并使其**可观察**：

1. **符号名证据**：mangled name 直接编码 Cfg 值
   `_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi4ELb1EEE…`——`tl`=structural literal，
   `Li16ELi4ELb1` = `{vecBytes=16, unroll=4, nontemporal=true}`。Cfg 的**值**就是特化身份，
   写进了符号，与 mori "EntryName 自编码 Cfg" 的设计同源。
2. **ISA 证据**（llvm-objdump on gfx1030 code object，`results/isa/isa_summary.txt`）：

   | 特化 | global_load 形态 | slc(NT 提示) | s_waitcnt |
   |---|---|---|---|
   | cfg_v16_u4_nt | dwordx4 ×5 | 10 | 7 |
   | cfg_v8_u4_nt | dwordx2 ×5 | 10 | 7 |
   | cfg_v16_u1（非 NT） | dwordx4 ×2 | **0** | 4 |
   | cfg_v4_u2 | dword ×3 | **0** | 5 |
   | rt_if_version（运行时 if） | 全形态混合 | 2 | 7 |

   不同 Cfg 值 → 不同指令序列：未选中的分支完全不在产物里；nontemporal 在 GFX10 ISA
   落为 `slc` 位。**意外发现**：v16-NT 路径我写的是两个 8B NT load（镜像 mori 的做法），
   clang 直接合并成单条 16B `global_load_dwordx4 slc`——NTTP + 编译器合并让 mori 的
   "16B 由两个 8B NT 组成" 源码形态在 ISA 层消失（对 gfx1030 是好事：一条 16B NT load）。
3. **运行时对照**：同一逻辑用运行时 if（vecBytes/nt 为参数）——所有路径共存于产物
   （dwordx4/dwordx2/dword 全出现），编译器无法按调用点特化。

## 2. 上游出处

- `include/mori/ops/dispatch_combine_v2/ep_cfg.hpp`（EpCfg structural type + VisitFields）
- `docs/MORI_JIT_V2_DESIGN.md` §3.1/§3.3（NTTP 设计论证；RenderSource 生成的 TU）
- `src/ops/dispatch_combine_v2/ep_spec.cpp:197-289`（RenderSource/EntryName 实体）
- `include/mori/core/transport/p2p/device_primitives.hpp:130-220`（宽度阶梯 + 16B=2×8B NT）
- 考古报告：`docs/archaeology/05-jit-build-python.md` §1、`docs/archaeology/02-shmem-cco-kiwi.md` §4.1

## 3. 独立实现说明

单文件 HIP C++，`-std=c++20`（mori v2 的 device TU 同样强制 C++20；考古 05 §1.1 的
Flags 表印证）。不依赖 mori 源码。`entry_name<Cfg>()` 复刻 mori EntryName 的
"Cfg 自编码名字"思想。

## 4. Reference / Correctness Test

Host 侧 memcmp 全量比对（12MB+3,000,003 字节，刻意含非整除尾巴触发逐字节尾部路径）；
4 个 NTTP 特化 + 1 个运行时版全部独立校验。

## 5. 构建

```bash
demos/compiler/nttp_cfg_specialization/scripts/build_run.sh   # 容器内执行
```

## 6. Inspection

`results/isa/`：`nttp.hsaco`（--genco 产物，__CLANG_OFFLOAD_BUNDLE__）、`gfx1030.co`
（clang-offload-bundler 解包出的裸 amdgcn ELF——ROCm 7 的 hipcc 产物必须先解包）、
`nttp.full.s`（完整反汇编）、`isa_summary.txt`（按 mangled name 切分统计）。

## 7. Hardware Matrix

gfx1030 实测（RDNA2，wave32）。NT 语义 = `slc` 位是 RDNA 系编码；CDNA（gfx942）
同为 slc 位但ocache 行为不同——上游 mori 仅在 gfx9 下经验证，本 demo 的 slc 观察
限于 gfx1030。gfx1250（wave32 但无 s_waitcnt）未测。

## 8. Execution Result

`results/run_gfx1030.log`：5/5 PASS。信息性计时：nttp_v16u4=891 GB/s vs
rt_v16_nt=1597 GB/s —— **NTTP 版更慢**，原因是本 demo 的 unroll 主循环把 4 个
chunk 按 stride 间隔摊开（`i + u*stride`），对 NT load 的内存级并行不友好；
这不是 NTTP 机制本身的代价（mori 用它做正确性/缓存键，不承诺同一代码更快的
通用性）。诚实记录，不修饰。

未验证事项：gfx942/gfx1250 上的 ISA 对照未做（无硬件）；host/device 分离纪律
（check_host_device_split.sh）在 Demo 5 的 JIT 框架复现中覆盖。
