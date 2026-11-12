# TECHNIQUE_CATALOG — AITER 技术知识目录

对象：aiter @ `1eab5ae12`。每条 = 一个可独立拆解的技术原理。字段：类别 / 上游出处(file:line) / 原理 / 硬件依赖 / 适用架构 / 软件替代 / demo 进度 / 验证等级。
验证等级（charter §五）：SOURCE_VERIFIED < REFERENCE_PASS < STATIC_ANALYSIS_PASS < COMPILE_PASS < HARDWARE_PASS < PERFORMANCE_MEASURED；不可互替。

demo 进度标记：`rocm-demo` 现有模块按其所在层标注（core=CPU 参考、gpu=HIP 真机）。

## A. 算法类

**A1. MoE 分组偏置路由（fused gate）** — `moe_fused_gate.cu:91-404`
原理：sigmoid+ bias → 组内 top-2 和为组分 → 组间 ArgMin 淘汰 → 全局 ArgMax top-k → renorm；DPP 多线程归约的平局规则（值优先、平局取小 key）使结果与归约树形状无关（hip_reduce.h:122-141）。
替代：无（纯 VALU 通用）。demo：`core/moe_fused_gate`（REFERENCE_PASS，含排序式独立参考 + 排除清单首条）。

**A2. MoE token-block 对齐** — `moe_align_block_size_kernels.cu:35-127`
原理：单 kernel 内直方图→块前缀和→原子游标 scatter；设备 scatter 顺序非确定（atomicAdd 游标），上位比较必须按段 multiset。demo：`core/moe_align`（REFERENCE_PASS）。

**A3. 采样族（外置噪声 Gumbel 竞速）** — `sample_kernels.cu:27-302,164-302`
原理：winner = argmax softmax_i/(u_i+eps)；噪声外置（exponentials 张量）使 kernel 成为 (logits,noise) 的确定函数；核内 philox 路径与外置路径同 (seed,offset) 逐位一致（每线程 subsequence = m*1024+tid，每 slot 一次 uniform4）；u≥1-2^-24 clamp 反号 quirk。demo：`core/sample`（REFERENCE_PASS，Philox 位级对齐 hiprand 实测向量）。

**A4. 块间 GDN 状态递归（fwd_h）** — `chunk_gated_delta_rule_fwd_h.cu:895-1088`
原理：快照(bf16)→corr=W·Hb→gated=bf16((U−corr)·gscale)→H 先衰减后加 Kᵀ·gated；w/u 为上游块内 kernel 预解矩阵。MFMA 16x16x16 bf16（gfx12 WMMA 双路 :324-339）。
demo：`core/gdn_state`（REFERENCE_PASS，双精度参考量化点对齐界内 0.1%）。

**A5. RoPE 布局族** — `rope/rope_common.h` + 16 TU
原理：NEOX/GPT-J 两种配对 × cached/uncached × positions 间接 × 1c/2c × sbhd/thd/2d；gfx94 10 指令 vs gfx95 单指令 bf16 转换（rope_common.h:7515-7518）。
demo：`core/rope`（REFERENCE_PASS，前向切片）。

**A6. KV-cache 块表散射** — `cache_kernels.cu:289-343`
原理：slot→(block,offset) 分解、−1 padding 跳过、量化融合写。demo：`core/kv_cache`（REFERENCE_PASS）。

**A7. Radix/自适应 top-k 策略阶梯** — `topk_plain_kernels.cu:59-1399`、`topk_per_row_kernels.cu`
原理：ballot 过滤（稀疏）→ bitonic sort/merge（中等）→ radix（大 K/行长）按 occupancy 与形状自适应；multiblock 原子直方图 + 跨块到达计数器 + spin 屏障（:508-546）；NaN 感知 fp32 key 排序（topk_fp32_key.h）。demo：未建（候选）。

**A8. 通信：IPC all-reduce 族 / 量化 all-reduce** — `custom_all_reduce.cuh`、`quick_all_reduce.cuh`
原理：注册 IPC 缓冲 + 信号旗 + 1/2-stage reduce；QuickReduce 按编解码把通信字节压到 bits/element（Q4/Q3/Q6/FP8 codec），CodecFP 全精度兜底；Lamport 3-buffer 方案；gfx1250 无 hipIpc → 指针式独立模块。demo：未建（候选，需多卡）。

**A9. MHC / Mega-MHC 超连接混合** — `mhc_kernels.cu`、`mega_mhc.cu`
原理：残差/子层流与混合矩阵的 bf16 GEMM（fn hi/lo 拆分），LDS XOR swizzle，split-K 设备计数器；gfx1250 TDM ring 双缓冲；**fp32 GEMM 回退路径**（MHC_BF16_MFMA=0，:40-45,845-851）= 算法等价替代案例。demo：未建（CDNA/gfx1250 依赖重）。

**A10. FlashAttention d64 split-KV（native）** — `mha_native/fused/pipeline.hpp`
原理：LDS 旋转序列 `LdsSeq={1,2,1,0}`（:103）、MFMA 32x32x8 bf16、有界 SRD 使尾块 OOB 读零（:78-90）；sched_barrier 对齐 CK 结构。demo：未建（CDNA MFMA 依赖）。

## B. 编译器/DSL 类

**B1. opus DSL（单头 C++ 微抽象层）** — `csrc/include/opus/opus.hpp`（4099 行）
原理：typed ext_vector_type 包装（:813-825）、static_for（:177-183）、gmem 描述符（make_buffer_rsrc :1759、OOB 硬件语义 README:76）、MFMA/WMMA 模板分发（:3080-3360，scaled f8f6f4 :3146-3151）、DPP（:1687-1734）、TDM（gfx1250，clang≥22 门 :2411）、免 HIP-runtime 编译（`--genco -D__HIPCC_RTC__`，预处理 190K→11K 行 README:186-265）。
demo：候选（单头 GEMM 例可独立编译）。

**B2. 编译器 hazard 工程实录** — `opus.hpp:1917-1924`、`aiter_opus_plus.h:862-865`、`mha_v4_quant.cu:98-101`
原理：clang≤22 把 uniform voffset 经 readfirstlane 沉入 b128 buffer_store 基址（gfx1250 OOB fault）→ `asm volatile("" : "+v"(vo_))` 保不透明；buffer_store 后 `s_nop 0` 防 WAR；fp6 asm 早熔（early-clobber）防 7.2 结果重叠。**编译器行为必须以产物验证的范例**。demo：候选（compiler 类代表：hazard 复现 + IR/ISA 产物对照）。

**B3. CK 实例化式 JIT** — `csrc/ck_*/gen_instances.py` + `optCompilerConfig.json blob_gen_cmd` + `core.py:1084-1101`
原理：Python f-string 代码生成逐 kernel 实例 .cu → jit 系统按 `--offload-arch` 编译；形状启发式选实例（gemm_a8w8.cu:27-50）；tuned CSV libtype 列驱动后端选择（tuned_gemm.py:448-464）。demo：候选（runtime 类）。

**B4. cpp_itfs：jinja→hipcc→ctypes 微框架** — `csrc/cpp_itfs/utils.py:256-430`
原理：jinja 渲染 → Makefile（hipcc, `-mllvm -amdgpu-early-inline-all=true` 等）→ make → ctypes.CDLL；md5 函数名做缓存键；Triton→HSACO 桥（:439-486）。demo：候选（runtime/JIT 类代表）。

**B5. 类型分发的 torch-free 形式** — `aiter_dispatch.h:104-200`
原理：AT_DISPATCH 的无 torch 版（_rmTorch 宏族）+ ctypes ABI（dtype→C 表 core.py:1970-2105）；rocm_ops.hpp 109 个 PYBIND 组合块。demo：已具雏形（design/dispatch）。

**B6. 内建函数/内联汇编清单**（分组，全部 file:line 见考古②§8）
- MFMA/WMMA：`__builtin_amdgcn_mfma_f32_32x32x8bf16_1k` 等 30+ 形态（全部经 opus 分发）
- 调度：`sched_barrier`(794 处)/`sched_group_barrier`(153)/`s_setprio`(461)
- 数据搬运：`make_buffer_rsrc`(11)、raw_buffer_load/store_b8-b128、`raw_ptr_buffer_load_lds`(7)、gfx1250 `global_load_async_to_lds`
- DS/shuffle：`ds_bpermute`(28)、`mov_dpp`(50)、`readfirstlane`(355)、`ds_read_b64_tr_b16`
- 等待：`s_waitcnt` builtin 41 + 裸 asm 120 处；gfx1250 分计数器 `s_wait_{load,async,tensor}cnt`
- 转换：`cvt_pk_fp8_f32`(22)、`cvt_scalef32_pk_fp4_*`(28)、gfx1250 `pk8`(批量 8)
demo：compiler 类（builtin 单元驱动，每个 20 行 --genco TU 可独立编译）。

**B7. 软件流水三范式** — 见 §9 案例
(a) mha_native `LdsSeq` LDS 旋转；(b) mhc TDM `KEEP/DRAIN` 计数器类（:51-65，KEEP 留 1 在飞 ≤3 预算）；(c) mla_v41 opus 纯手排（K_DEPTH=4，sched_group_barrier 指令类分组 :639-644）。demo：emulation/compiler 类（配合 --save-temps 展示 KEEP/DRAIN ISA 结构）。

## C. 硬件机制类（aiter 视角的使用证据；gfx1030 可用性以我们的探针为准）

**C1. MFMA 矩阵核**：bf16 32x32x8/16x16x16、fp8 32x32x16、scaled f8f6f4 32x32x64/16x16x128、fp4 32x32x64——CDNA(gfx90a-950)；RDNA 无（我们的 PROFILE：无 mai-insts）。gfx12 WMMA wave32 对应物。
**C2. DPP/shuffle**：mov_dpp/upd_dpp 蝶形（Hadamard、scan）、ds_bpermute（NV lane→byte×4）。
**C3. buffer/LDS 直通**：`raw_ptr_buffer_load_lds`（aiter 仅 gfx942 用；gfx1030 硬件有通道但 builtin 错位——我们的实证）；gfx1250 `global_load_async_to_lds`。
**C4. TDM（gfx1250 tensor DMA）**：tdm_desc 位级描述符（opus.hpp:2635-2648 对拍 MLIR）、ring 深度 3/wave（:2946）、`s_wait_tensorcnt`。
**C5. 波长双态**：wave64(CDNA) vs wave32(RDNA/gfx12)；`opus::get_warp_size()` 运行期探测（:1573-1596，`__has_builtin` 代理）；WARP_SIZE 非 const 的 host 回退教训（dsv4:445）。
**C6. packed math**：`v_pk_mul_f32`（CDNA）RDNA 标量回退（activation:106）；`v_pk_fma_f32`、`v_dot2_f32_bf16`、`v_fma_mix_f32_bf16`。
**C7. MX 转换指令**：gfx950 `cvt_scalef32_pk_fp4_*`、`2xpk16_fp6`、scaled MFMA；gfx1250 `pk8` 批量。
**C8. s_waitcnt 家族**：gfx10.3 vmcnt 分裂域（vmcnt=[3:0]+[15:14]，llvm-mc 30+ 探针实证——我们 gfx1030.md L3）；gfx1250 拆分 loadcnt/asynccnt/tensorcnt（aiter_opus_plus.h:924-936）。
**C9. 钉 VGPR 编程**（HipKittens）：`__attribute__((amdgpu_num_vgpr(72)))` + split_many_t range clobber（hk mi3xx:94-105）。

## D. 软件模拟/Fallback 类 → 详见 EMULATION_CATALOG.md（22 案例分级）

## E. 存量 demo 迁移与验证等级（M1 标注）

| rocm-demo 现有模块 | 类别 | 验证等级 |
|---|---|---|
| core/moe_fused_gate, moe_align, topk_softmax | 算法 | REFERENCE_PASS（host 独立参考）|
| core/sample, rope, kv_cache, group_quant, hadamard_quant, gdn_state | 算法/模拟混合 | REFERENCE_PASS |
| core/fp8 | 模拟（codec） | REFERENCE_PASS |
| design/jit_cache, dispatch | 运行时 | REFERENCE_PASS（双进程并发实证）|
| gpu/soft_fp8, soft_fp4 | 模拟 | HARDWARE_PASS（gfx1030 真机）+ 界内数值验证 |
| gpu/soft_tma(.s) + toolchain | 模拟/编译器/硬件 | HARDWARE_PASS；toolchain 含 miscompile 实证（STATIC_ANALYSIS 层证据）|

待 M2 升格到 demos/ 统一标准（per-demo CMake/README/results/inspection）。
