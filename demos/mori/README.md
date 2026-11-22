# demos/mori/ — mori Lab demo 集合（上游：ROCm/mori）

mori 技术解剖与独立复现工程（mori Lab）产出的独立 Demo。上游 pin：
**ROCm/mori @ `c5bdc3913660f6b663ae09ba7c7176291d6f5343`**（2026-11-17，main）。
完整的源码考古（`docs/archaeology/01~05`）、知识地图与验证证据链在独立仓库
`~/workspace/src/mori`（mori Lab 正本）；本目录是该 Demo 集的镜像。

方法论与 AITER Lab 一致：从生产级代码提取技术原理 → 独立最小实现 →
正确性测试 → 编译产物检查 → 验证等级标注（SOURCE_VERIFIED → … → HARDWARE_PASS）。

## 环境

- GPU Demo 在容器 `gfx-m1`（rocm10-dev:10.1.0，ROCm 10.1.0（HIP 子系统串 7.16.26385）.26385，AMD clang 24.0）内构建运行，目标 **gfx1030**（RX 6950 XT，RDNA2，wave32）——注意 mori 官方不支持 gfx1030（构建层只认 gfx942/950/1250），本集合验证的是"提取出的机制"而非 mori 全栈。
- 纯 CPU Demo（ras_heartbeat、io_sim_model）容器内构建，无 GPU 参与。

## Demo 一览（18 个，全部 HARDWARE_PASS / REFERENCE_PASS / STATIC_ANALYSIS_PASS+HW 或更高）

### algorithm/
| Demo | 原理 | 等级 |
|---|---|---|
| `dispatch_merged_reserve` | EPv1 dispatch 合并远端原子预留：O(tokens×topk) RMW → O(blocks×npes)，实测 336× 压缩 | HARDWARE_PASS |
| `load_once_fanout` | Load-once-write-many 扇出 + v_readlane 指针广播 + 寄存器 dedup（IntraNodeLL 核心；含 shfl 收敛性陷阱实录） | HARDWARE_PASS |
| `twoshot_ar_protocol` | twoshot AR 协议模拟（scatter→世代flag→reduce→AG）：2-rank 3 世代全过；位型整数加≠浮点加等四纪律实录 | HARDWARE_PASS |

### compiler/
| Demo | 原理 | 等级 |
|---|---|---|
| `nttp_cfg_specialization` | structural NTTP 配置特化（JIT v2 编译期核心）：Cfg 值编进 mangled name，各特化 ISA 形态差异（slc 位实证） | HARDWARE_PASS + STATIC_ANALYSIS_PASS |
| `shmem_bitcode_pipeline` | shmem 设备 bitcode 流水线（B-08）：emit-llvm→llvm-link→lifetime-strip→符号验证→ISA 逐指令等价；clang24 lifetime 消失/Triton 消费阻断取证 | STATIC_ANALYSIS_PASS + HARDWARE_PASS(源级语义) |

### emulation/
| Demo | 原理 | 等级 |
|---|---|---|
| `p2p_cas_atomic` | P2P 原子的 CAS-loop 软件仿真与硬件原子 6/6 对拍（争用 85,000× 已诚实记录） | HARDWARE_PASS |
| `io_sim_model` | MORI-IO sim 后端复现：控制面真实+数据面模型（t=b/BW+n·seg+op+lat），纯 CPU 10/10 | REFERENCE_PASS |
| `umbp_sim_model` | UMBP 排队模型：channel_capacity FIFO（private 可 overlap）+ size_term 对数项 + SSD 半服务，纯 CPU 13/13 | REFERENCE_PASS |

### hardware/
| Demo | 原理 | 等级 |
|---|---|---|
| `proxy_ring_publish_order` | GPU→CPU 发布协议（payload→threadfence_system→status）：819k 命令零撕裂；RDNA2 fence = `s_waitcnt_vscnt` 实测 | HARDWARE_PASS + STATIC_ANALYSIS_PASS |
| `ipc_symmetric_heap` | 单卡双进程 IPC 对称堆全链路：映射/直写零撕裂/跨进程 CAS/epoch barrier | HARDWARE_PASS |
| `vmm_flat_va_probe` | VMM flat-VA + 跨进程 FD 互映射（CCO LSA 物理前提）；host 裸指针写 VMM 页=SEGV 纪律实证 | HARDWARE_PASS(probe) |
| `lsa_flat_va` | CCO LSA 完整端到端：peer_va 公式寻址双向 put（内核校验 0/4096）+ epoch barrier 双进程 rendezvous；SCM_RIGHTS FD 须显式 import | HARDWARE_PASS |
| `sdma_user_queue_probe` | KFD 用户态 SDMA 队列创建：4 引擎×8 队列全 SUCCESS | HARDWARE_PASS(probe) |
| `sdma5_copy_experiment` | SDMA5 COPY_LINEAR 包执行：gfx9 布局跨代兼容，10/10 NT 校验；**SDMA 写绕过 L2 → NT load 强制**；ATOMIC 不执行/NOP 卡死（诚实记录） | HARDWARE_PASS(COPY) |

### runtime/
| Demo | 原理 | 等级 |
|---|---|---|
| `jit_content_cache` | 内容寻址 JIT 缓存全链路（Cfg→render→sha256→rename 发布→hipModule 实跑）；双进程竞态单发布者 | HARDWARE_PASS + REFERENCE_PASS |
| `graph_gen_counter` | hipGraph 重放陷阱量化：冻结 host token 113/200 踩坑 vs 设备侧 genCounter 0/200 | HARDWARE_PASS |
| `ras_heartbeat` | RAS 心跳/退出检测：注入 5s 偏差→算出 5.000s；LEAVE/崩溃/静默/GaveUp 四分类 | REFERENCE_PASS |
| `shmem_p2p_chain` | SHMEM P2P 全链路：bootstrap→GpuStates→put+signal/get/barrier 4/4；**硬件发现: IPC alias 原子静默失效**（plain store ✓） | HARDWARE_PASS |

### 交叉验证
`~/workspace/src/mori/demos/crossval/run_crossval.sh` + `docs/CROSSVALIDATION.md`：
-O0/-O2/-O3 正确性+ISA 对照（fence 永不消除但形态随优化变；原子寻址 flat→global
晋升）、--genco 与 -c 产物路径对照。

## 构建

各 demo 的 `scripts/build_run.sh` 在 gfx-m1 容器内执行（`docker exec gfx-m1 bash <绝对路径>`）。纯 CPU demo 同样在容器内构建（宿主无编译器）。

## 工程坑沉淀（跨 demo 实测）

fork 必须先于任何 HIP 调用（UB）；hsaKmtOpenKFD 必须晚于 HIP 初始化；SDMA 写绕过 L2——读 SDMA 产物必须 `__builtin_nontemporal_load`；HIP7 的 shfl/ballot mask 需 64 位；hipcc 产物是 CLANG_OFFLOAD_BUNDLE，需 clang-offload-bundler 解包后才能 objdump；协议 wire 格式用显式序列化（pack 结构体聚合直发有字段错位风险）。
