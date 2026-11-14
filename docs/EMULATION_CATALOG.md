# EMULATION_CATALOG — Software Emulation / Fallback 专项索引（重点研究方向）

对象：aiter @ `1eab5ae12` + 本实验室实测。分类纪律（charter §二.4）：
**[SIM]** 真软件模拟（缺失指令的替代序列）／**[LOWER]** Compiler Lowering／**[RT-FB]** Runtime Fallback（执行期换路）／**[DISPATCH]** 分发选择（构建/调用期选后端）／**[ALG]** 算法等价替代。
每案例八字段：原硬件功能 / 缺什么 / 哪层处理 / 替代路径 / 调用链 / 语义保证 / 代价 / demo 可行性。
验证等级照 charter §五。

## A. 设备内软件模拟（[SIM]——lab 主攻方向）

**E1. fp8 E4M3/E5M2 软转换** [SIM]
原功能：`cvt.rn.satfinite.e4m3x2.f32` 类硬件转换。缺：gfx1030 无任何 fp8 cvt。处理层：设备库（cuda-oxide fp8.rs / 本 lab soft_fp8.hpp）。路径：纯位操作 RNE + satfinite（denormal 算术解码 m·2⁻⁹、溢出 clamp、NaN 规范化）。调用链：kernel 内联函数，无外部依赖。语义保证：CUDA `cuda_fp8.h` 契约 + **450,852 项穷举零失败**（cuda-oxide）+ 本 lab 界内对拍。代价：转换占 ALU（吞吐分级：标量 91-98% of copy=完美档；packed decode 81-82%=优秀档）。demo：soft_fp8_test/bench（HARDWARE_PASS；cuda-oxide 侧 PERFORMANCE_MEASURED）。

**E2. MXFP4/E2M1+e8m0 软转换** [SIM]
同上；E2M1 表解码 + RNE satfinite（aiter 侧 scalar `even_round_e2m1` quant_mxfp4.cu:45-79 是 aiter 自己的 emu；cuda-oxide fp8.rs:207-245 独立实现）；e8m0 = 2^(b−127)（aiter 无 codec，lab 补齐）。demo：demos/emulation/soft_fp4（HARDWARE_PASS + PERFORMANCE_MEASURED）。

**E3. soft-TMA：gmem→LDS 深流水** [SIM]
原功能：TMA/cp.async.bulk（bulk 异步搬运）。缺：RDNA2 无 TDM/异步拷贝。处理层：手写 kernel。路径：prologue 发 B×dwordx4 → 循环发下 B + `s_waitcnt vmcnt(B)` 部分排空 → ds_write_b128 进 LDS 双缓冲（XOR 换相）→ 消费。语义保证：15/15 配置正确性（原工程）+ 本 lab 32768 lane 位级。代价：收线 553 GB/s=96.1% 经验上限=91.4% of D2D（完美替代档）。demo：demos/emulation/soft_tma（C++ vmcnt inline asm 版，HARDWARE_PASS + PERFORMANCE_MEASURED，91.1% of ISA）+ ISA 参照 gpu/soft_tma_pipeline.s。

**E4. 软 mbarrier** [SIM]
原功能：Hopper mbarrier（相位/计数/expect_tx）。缺：RDNA2 无。路径：单 i64 LDS 状态机 `{pending|expected|phase}`（amdgcn.rs:947,1131）：arrive=原子减+末者翻相；test_wait=非阻塞谓词；**expect_tx 字节级不支持**（开放缺口，等价物=vmcnt 部分排空）。代价：462.9 ns/op = 7.8× s_barrier（延迟型，低于 60% 线如实披露）。demo：warp_sync.hpp（计划）。

**E5. 计数屏障（编号 barrier）** [SIM]
路径：LDS 16 id 槽计数器 + generation spin（amdgcn.rs:1588,1650）；进入协议=entry 清零+一次组屏障。代价：527.5 ns = 8.8×。demo：warp_sync.hpp（计划）。

**E6. warp shuffle / redux.add** [SIM]
路径：`ds_bpermute`（NV lane→byte×4 核心差异）+ mbcnt lane id；redux=5 轮 xor 蝶形。代价：shfl 69.1 ns=1.2×（最可用）；redux 495.6 ns=8.3×。demo：warp_sync.hpp（计划）；lab 已有 ds_bpermute PASS（toolchain 2a）。

**E7. Hadamard 旋转（MX 量化前处理）** [SIM]
原功能：无直接硬件。路径：DPP `mov_dpp/upd_dpp` 蝶形（dsv4_rotate:118-129）或行内蝶形（lab core/hadamard_quant）；gfx950 上与 packed fp4 cvt 融合。代价：量化 MSE 双向实测（spike 行旋转赢 3×、平滑行反输）。demo：core/hadamard_quant（REFERENCE_PASS）。

**E8. FFMA 软 GEMM** [SIM]
原功能：MFMA 矩阵核。缺：RDNA2 无 mai-insts。路径：解码→f32 FFMA（DeepGEMM 路线历史实证 3.05 TFLOPS 功能正确 [hist]；FFMA 上限 25.7 TFLOPS=92.3%）。demo：soft_fp8_gemm.hip（计划）。

**E9. 外置噪声采样（Gumbel 竞速的可测化改造）** [ALG]
噪声由调用方注入使 kernel 确定——不是模拟缺失硬件，而是算法等价改造换取可测试性。demo：core/sample（REFERENCE_PASS）。

## B. Runtime Fallback（[RT-FB]——aiter Python 层）

**E10. torch._scaled_mm → fp32 matmul 模拟**：fp8 GEMM 硬件路径不可用时退化 fp32 数学（tuned_gemm.py:573-599）。精度全保、速度换。层级：RUNTIME-FB。
**E11. opus import 失败 → torch_gemm**（tuned_gemm.py:33-36,724-753）：包级缺依赖降级。
**E12. FlyDSL launch 拒绝 → CK 回退**（gemm_op_a8w8.py:209-229）：形状契约（M>K 等）失败时换路，输出超 CK 2GiB 寻址则保留错误——回退有边界。
**E13. fused_norm_quant_gemm C++ 缺 → python 两步**（fused_norm_quant_gemm.py:22-34,73-95）：ImportError/OSError/调用期三态。
**E14. Windows 无 ROCm → AITER_TRITON_ONLY**（__init__.py:78-100）：包级降级到 Triton 子层（Linux fail-loud）。
**E15. fused_moe tuned 行弃用 + tier walk**（fused_moe.py:1810-1872,4276-4292）：tuned 快行不能跑就丢弃（"discard, not raise"），逐级 pad-M tiers，全灭才 NotImplementedError。

## C. 分发选择（[DISPATCH]——静默换后端，非故障回退）

**E16. CK a8w8 → Triton**（非 gfx9；gemm_op_a8w8.py:61-67,731-738）——SIGSEGV 预防性门（blockscale 版 :48-58 注释明确"uncatchable"）。
**E17. gfx1250 → Triton(gluon)/FlyDSL WMMA**（tuned_gemm.py:301-311; gemm_op_a8w8.py:943-969）——hipBLASLt 在 gfx1250 慢。
**E18. layer_norm CK→Triton**（norm.py:149-152，CK-free 或 gfx1250）。
**E19. gfx1250 topk 契约不匹配 → Triton exact sigmoid**（topk.py:28-107）。
**E20. moe_sum topk∉{2,4,5} → torch.sum**（moe_op.py:153-160）。
**E21. fp8 dtype fnuz(gfx942)/fn(其余)/uint8 兜底**（dtypes.py:10-41）——dtype 层的架构边界。

## D. 编译器 Lowering（[LOWER]）

**E22. PTX packed-math → AMDGPU 合法 IR**：cuda-oxide codegen 把 bf16x2/f16x2/f32x2、ex2 等 PTX 族展开为合法 AMDGPU IR（support_matrix:109）。
**E23. hipify**：CUDA→HIP 源转译（cpp_extension.py:1011-1029）——构建期源变换而非语义模拟。
**E24. ntid 追加参数化**：blockDim host 化 → kernel 尾参（amdgcn.rs rewrite_ir_for_amdgcn）——ABI 级 lowering。

## E. 算法等价替代（[ALG]）

**E25. mbarrier expect_tx ≈ vmcnt 部分排空**：字节级 expect_tx 不做，以 FIFO 排水语义替代（catalogue:36，公开开放缺口）。
**E26. TensorMap swizzle → 软件 padding**：行距 272/144B 先例 [hist]（aiter mha；catalogue §2.3）。
**E27. mhc bf16 MFMA 不可用 → fp32 GEMM 循环**（mhc_kernels.cu:40-45,845-851）——同文件内的编译期降档。

## F. 硬检查拒绝（对照面：aiter 选择 fail-loud 的地方）

quant_mxfp4_gemm:318 / quant_mxfp6_gemm:402 / iq2r:2262 / sparse_attn entry / fhmoe:73 / mla.py 多处 / asm_guard（gfx1250 A0 fail-closed）——**"支持"与"模拟"的边界以这些硬检查标定**；charter 纪律：无证据不得标称已模拟。

## G. lab 的 emu 攻线（M2 计划对应的 E 条目）

E1/E2（fp8/fp4 穷举+吞吐）→ E3（C++ soft-TMA）→ E4/E5/E6（warp_sync）→ E8（fp8 GEMM）。全部在 gfx1030 真机 HARDWARE_PASS 起步，吞吐按 60/70/80/90% 分级口径对参照路径报告。
