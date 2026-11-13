# Results — warp_sync (2026-11-13)

环境：容器 gfx-m1（ROCm 7.2.4），GPU RX 6950 XT（gfx1030），hipcc -O3，
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
