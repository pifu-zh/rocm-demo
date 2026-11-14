# v_dot2_probe — RDNA2 V_DOT2 指令的语义与吞吐实测（gfx1030）

**类目**: hardware · **验证级别**: HARDWARE_PASS（RX 6950 XT / gfx1030 / ROCm 7.2.4 真机执行，2026-11-14）
**动机**: gfx1030 替代分析的核心问题之一——RDNA2 的点积指令能覆盖哪些
aiter/MI300 用例、数值语义是否可精确建模。本探针测量，不假设。

## 一、测量结论（三条硬事实）

1. **gfx1030 有 f16 dot2、无 bf16 dot2**（替换分析关键事实）：
   - `__builtin_amdgcn_fdot2(__half2, __half2, float acc, bool clamp)` ✓
     编译通过，产物 ISA = **`v_dot2c_f32_f16`**（results/dot2_kernel.s，
     3 处 v_dot2 指令）；
   - `__builtin_amdgcn_fdot2_bf16_bf16` 需要 **dot9-insts** target feature
     （gfx950/MI300 级），对 gfx1030 编译报错——bf16 dot2 到 dot9 才有。
     本卡上的 bf16 点积只能 bf16→f32 展开 fma，或（溢出域允许时）bf16→f16
     转换后走 f16 dot2。
2. **数值模型位级精确**（1,048,576 次随机单步，f16 ∈ [1,2)、c ∈ [−2,2]）：
   两种候选累加顺序
   `fl32(a0b0 + fl32(a1b1 + c))` 与 `fl32(a1b1 + fl32(a0b0 + c))` **都与硬件
   逐位一致**——f16×f16 积只需 22 位有效数字 ≤ f32 的 24 位，**乘积本身
   精确**，在这些量级域上累加顺序不影响舍入。主机参考模型是精确模型
   （非近似），可直接用于替换分析。域外（极端量级混合）未测、不下结论。
3. **吞吐比 = 2.0–2.2× fma**（256 lane × 64 block × 200k 步，事件计时）：
   dot2 1.35 TMAC/s（2 MAC/指令）vs fma 0.67 TMAC/s——每指令 2 MAC 的
   设计比率实测成立。

## 二、调试链

1. `fdot2` 的 bf16 变体签名是 3 参（无 clamp）——先按 4 参调用报"too many
   arguments"，修正后再报 dot9-insts 缺失（测量点 1 的来源）。
2. 初版正确性测试用 8192 步链式累积——单步偏差会复利放大，两个模型都
   0/256。改为 **1M 次独立单步**后才可判定（方法学：位级语义测量必须
   单步隔离，链式只做端到端佐证）。
3. 宏 `CK` 带 return 1，在 void/float 返回的辅助函数里编译错——补了
   非返回版 `CKQ`。

## 三、文件

| 文件 | 内容 |
|---|---|
| `src/main.hip` | 单步语义测量（1M 步）+ 吞吐对比 kernel + 主机精确模型 |
| `results/execution.log` | 真机运行日志（PASS） |
| `results/dot2_kernel.s` | -O3 ISA 留档（v_dot2c_f32_f16 ×3） |
| `scripts/build_run.sh` | hipcc 构建 + 运行 + 日志落盘 |

## 四、复现

```bash
cd demos/hardware/v_dot2_probe && ./scripts/build_run.sh   # 容器内，需真机
```
