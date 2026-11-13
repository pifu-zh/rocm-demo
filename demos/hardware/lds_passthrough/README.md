# demo: lds_passthrough — buffer_load→LDS 直通（gfx1030 硬件机制）

## 验证等级

**HARDWARE_PASS**（gfx1030 / RX 6950 XT，ROCm 7.2.4，2026-11-13；32 lane 位级）

## 原理

RDNA2 的 MUBUF `lds=1` 形式：`buffer_load_dword ... lds` 把一个 dword 从
global memory **直接落入 LDS**（地址 = m0 + lane*4），完全绕过 VGPR——
aiter 只在 gfx942 用了这条通道（opus.hpp:1881-1906），而 RDNA2 硬件同样实现
了它（b32 为编译器路径上限；手写 ISA 可 b128）。这正是"上游不用 ≠ 硬件没有"
的代表性机制。

## 上游出处

- aiter 唯一使用点：`csrc/include/opus/opus.hpp:1881-1906`
  （`__builtin_amdgcn_raw_ptr_buffer_load_lds` / asm 声明的 llvm intrinsic）
- V# config 字：`opus.hpp:1752`（`buffer_default_config()`，gfx1030 =
  0x31014000，gfx1200/1201 predefine-typo 注）
- 谱系：`docs/ARCH_MATRIX.md` C3、`docs/EMULATION_CATALOG.md` E 系对照

## 独立实现（手写 ISA）

`src/lds_probe_pipeline.s`：`lds_probe` kernel——32 lane，每 lane 一 dword：
V# 装配（base + num_records + word3=0x31014000）→ `s_mov_b32 m0, 0` →
`buffer_load_dword v2, s[8:11], 0 offen lds` → `s_waitcnt vmcnt(0)` +
`lgkmcnt(0)` → `ds_read_b32` 读回 → global store。host 经
hipModuleLoadData/hipModuleLaunchKernel 启动并位级校验。

## Hardware Matrix 与实测约束（全部本 lab 实证）

| 事项 | 结论 |
|---|---|
| V# word3 config | **必须 0x31014000**（零 config 静默走 OOB fill-zero 路径，返回全 0——aiter make_gmem 教训） |
| LDS 操作数 | **波统一基址**（m0）；硬件自动加 lane*4（传 per-lane 地址会双重偏移） |
| 波约束 | **单波/workgroup**：双波共用 m0 → launch fault |
| f32 subnormal | UE8M0 byte 0 = 2^-127 是 f32 subnormal（指数域组装会 flush 到 0）——相邻 demo 教训 |
| 后续架构 | gfx942：aiter 原生使用点；gfx11+：`global_load_async_to_lds`（dlds）替代；未验证 |

## Build & Run

```bash
scripts/build_run.sh
# 即：
# clang -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx1030 \
#     src/lds_probe_pipeline.s -o lds_probe.co
# hipcc -x hip --offload-arch=gfx1030 -O3 src/main.hip -o lds_passthrough
# ./lds_passthrough lds_probe.co
```

## Results（2026-11-13）

PASS：32 lane 各自的 dword 经直通通道落入 LDS 槽（m0+lane*4），读回后与
输入位级一致（out[i] == 0xAB0000+i）。

负对照事实（同日实测）：零 config → 全 0 返回；双波 → launch fault；
builtin `__builtin_amdgcn_raw_ptr_buffer_load_lds` 路径整体 +32 dword 错位
（m0=0 折叠 vs 数组在 LDS 128）——详见 demos/emulation/warp_sync 的
对照与 toolchain.hip。

## 未验证事项

- b128 直通（catalogue 记录手写 ISA 可用；本 demo 用 b32 最小形式）
- 多块流水下的直通吞吐（相比 soft-TMA 的 VGPR 中转路线）
- gfx942 真机对照
