# shmem_bitcode_pipeline — shmem 设备 bitcode 流水线复现（B-08）

**类目**: compiler ｜ **验证等级**: `STATIC_ANALYSIS_PASS`（流水线产物：bitcode 链路
逐步骤验证 + ISA 逐指令等价证明）+ `HARDWARE_PASS`（源级等价消费实跑：bitcode 所
代表的 API/全局语义在 gfx1030 上端到端验证，addend=7 mism=0/1024）

**上游对应**: `python/mori/jit/core.py:99-171`（v1 JIT 的 shmem 设备 bitcode 管线）。
mori 把 shmem 设备 API 编译成 LLVM bitcode 供 Triton/FlyDSL kernel 作为 extern 库
链接——这是 mori 与 Triton 生态互操作的基础设施。

## 1. 原理说明与流水线

mori 的流水线（core.py:99-171）：
```
hipcc -c --cuda-device-only -emit-llvm -fgpu-rdc -mcode-object-version=5
  → llvm-link（多 TU 合并）
  → opt -S → 正则删除 llvm.lifetime.*（旧 Triton LLVM 不认识）
  → opt 回写 → opt -S 验证 _ZN4mori5shmem15globalGpuStatesE 符号存在
  → 产物供 Triton 链接（cov=5 给 Triton，cov=6 给 FlyDSL）
```

本 demo 复刻该链路（设备 API 用与上游同 namespace/同名的最小对应物）：

| 步骤 | 内容 | 结果 |
|---|---|---|
| 1 | 两 TU（api/globals）`--cuda-device-only -emit-llvm -fgpu-rdc cov5` | ✅ |
| 2 | `llvm-link` 合并 | ✅ |
| 3/3b | `opt -S` 可读 IR；-O0 变体对照 | ✅ |
| 4 | 正则删 llvm.lifetime（合成注入验证清除机制本身） | ✅ |
| 5 | `_ZN4mori5shmem15globalGpuStatesE` 符号精确验证（与上游 mangled name 逐字一致） | ✅ FOUND |
| 5.5 | **Triton 式链接**：消费端 IR + 流水线 bitcode → llvm-link → clang amdgcn codegen | ✅ |
| 6 | 源级等价消费实跑：consumer kernel 经 globalGpuStates.addend=7 完成 API 调用 | ✅ mism=0/1024 |
| 7 | **ISA 逐指令等价证明**：流水线 full.co vs 源级参考的 device_add_one，归一化后 32 条指令逐条一致 | ✅ IDENTICAL |

### 关键实测发现（工具链取证，全部有 log 证据）

1. **clang 24（HIP 7.16）不再生成 llvm.lifetime**（O0/O2 均 0 次）——mori 的 strip
   步骤在其撰写时针对旧 Triton LLVM；本 demo 向 IR 注入合成 lifetime 声明验证了
   清除机制本身仍然工作。
2. **裸 .bc 会被 hipcc rdc-link 当宿主输入**（x86_64 triple overriding 报错）；
   `.hipbc` bundle 被接受但 ld.lld 报 undefined hidden symbol——**rdc 链接不消费
   设备 bitcode bundle**。
3. **clang-offload-bundler 对 amdgcn relocatable 输入段错误**；clang-offload-packager
   新格式被 ld.lld 报 incompatible mach/unknown file type。
4. **`-x ir` codegen 必须显式 `-mcpu=gfx1030`**（IR 模块级无 target-cpu，缺省落
   R600 → "64-bit code requested"）；且必须用 hipcc 同款 clang
   （core-10.1 的 clang++）——`/opt/rocm/llvm/bin/clang` 不认 gfx1030。
5. **默认 cov(6) 走新 offload 流**：bundle 为长度前缀新格式（hip- kind），旧
   bundler "Can't find bundles"；cov5 走旧流（hipv4 kind）。（Demo 2 的 hipv4
   解包成功即因 cov5。）
6. **整程序设备编译会内联并删除未被 kernel 引用的 `__device__` 函数**——extern
   库必须 `noinline, used` 保活（mori 用 llvm.used 同理）。
7. objdump 双版本陷阱：`/opt/rocm/llvm/bin/llvm-objdump`（旧 LLVM）不支持
   gfx1030 反汇编，必须用 core-10.1 的。

### ISA 等价的判定口径

归一化两条规则（布局差异 vs 语义差异的区分）：丢弃 `s_nop`（assembler 对齐填充，
ref 有 55 条 full 为 0）；s_getpc 相对寻址立即数随链接布局变化 → 占位归一。
归一化后 32 条指令**逐条一致**。真实语义指令（global_load/add/global_store/
waitcnt/分支）无一差异。

## 2. 上游出处

- `python/mori/jit/core.py:99-171`（ensure_bitcode 管线全步骤）
- `docs/MORI_JIT_ARCHITECTURE.md:204-231`（Triton extern lib 消费方式）
- `include/mori/shmem/`（globalGpuStates 符号与设备 API 的对应物）
- 考古报告：`docs/archaeology/05-jit-build-python.md` §1.2、TECHNIQUE_CATALOG B-08

## 3. 独立实现说明

api/globals 两 TU + consumer（设备/宿主各一），与上游 namespace/名字精确对齐
（mangled name 逐字一致）。流水线脚本 `scripts/build_run.sh` 每步带产物落盘。

## 4. Reference / Correctness Test

- 符号验证：grep 精确 mangled name（上游同名）。
- IR 合法性：opt 重解析通过。
- ISA 等价：归一化（去 s_nop、s_getpc 偏移占位）后逐指令一致。
- 语义：消费 kernel 经 globalGpuStates.addend=7 产生 src+7（host 独立参考）。

## 5. 构建

```bash
demos/compiler/shmem_bitcode_pipeline/scripts/build_run.sh   # 容器内
```

## 6. Inspection

`results/ir/`：api.bc/globals.bc/linked.bc/linked.ll/linked_stripped.ll/
shmem_like.bc（最终 bitcode）/api_O0.ll（lifetime 形态）/full.ll/full.co（Triton 式
链接产物）/api_ref.s + full.s（ISA 对照）/isa_diff.txt（归一化判定）。

## 7. Hardware Matrix

| 架构 | 结论 |
|---|---|
| gfx1030 + HIP 7.16/clang 24（本机） | 流水线全链 ✅；源级语义实跑 ✅；**Triton 真实消费（hipModule/extern 链接路径）被四类工具链阻断**（见 §1 发现 2-5），Triton 新版是否兼容未测 |
| gfx942/950 | mori 生产路径，未在本机验证 |

## 8. Execution Result

`results/run_gfx1030.log`（2026-11-18/23，两轮稳定）：步骤 1-7 全过，consumer 实跑
PASS。未验证事项：真实 Triton 链接（本机 Triton 的 LLVM 版本与 hipcc IR 兼容性未
探）、cov6（FlyDSL）变体、-fgpu-rdc 之外的链接路径。
