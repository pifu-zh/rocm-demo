# Results — warp_sync (2026-11-13)

环境：容器 gfx-m1（ROCm 10.1 / HIP 7.16 / clang-24；首测 7.2.4），GPU RX 6950 XT（gfx1030），hipcc -O3，
256 线程单 CTA，64 ops/launch，事件计时 best-of-3×10。

正确性：shuffle lane^1 / redux 总和 / 计数屏障（双并发部分组×2 轮 + 跨组
握手）/ 软 mbarrier（3 轮 + 生产者消费者可见性）全 PASS。

延迟（ns/op，native __syncthreads = 141.9）：
counted 624.4（4.4×）/ mbarrier 230.6（1.6×）/ shfl 145.6（1.0×）/ redux 227.5（1.6×）。

设备级发现（解决过程完整记录于 git 历史）：
1. 64 位 LDS atomicCAS 挂死（last-arriver 卡在 CAS 内部，255 spinner 压同地址；
   atomicAdd 同条件可靠）→ 翻转改 atomicAdd parity 技巧，全程零 CAS。
2. SIMT 波陷阱：if(flip) else spin 让编译器把 spin 排在 flip 前，flipper lane
   被困同波 spin PC（32 线程单波即挂）→ flip 前置 + 无分支统一 spin。
3. debug mark 的普通全局 store 会被重排，挂死观测需 atomicExch 或独立流轮询。
4. mbarrier 无需 re-arm：parity 逐轮自动翻转，计数守恒（迟到 +1 归入新轮）。

延迟对比上游 Rust-LLVM 路径：mbarrier 1.6× vs 上游 7.8×（atomicAdd-only flip
+ 退避的组合收益），counted 4.4× vs 上游 8.8×。

## ROCm 10.1 重测与 workaround 撤除（2026-11-14）

环境换到 rocm10-dev:10.1.0（HIP 7.16.26385 / clang 24.0.0git）后的三个撤除实验：

| 实验 | 7.2.4 行为 | 10.1 实测 | 处置 |
|---|---|---|---|
| A. flip 用 64 位 LDS atomicCAS 循环 | 挂死 | **仍挂死**（timeout） | atomicAdd-only flip 保留 |
| B. 发散 `if(flip) else spin` 结构 | 单波即挂 | **仍挂死**（timeout） | flip 前置+统一 spin 保留 |
| C. 去掉 s_sleep(16) 退避 | 确定性活锁（12s 零翻转） | **15/15 全套件干净** | **退避撤除** |

撤除退避后的延迟（同协议）：counted barrier **624.4 → 176.3 ns（4.4× → 1.2× native）**、
soft mbarrier 230.6 → 186.9 ns（1.6× → 1.3×）——退避本身才是延迟开销；7.2.4 的
活锁是 LDS 读饿死 flipper 原子的竞争行为，clang-24 的调度变了不再显现（历史
注释保留在头文件，供 7.x 复现者参考）。

其余数字：native 141.9 ns、shuffle 133.7、redux 141.2——与 7.2.4 一致。
