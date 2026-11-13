# Results — inline_asm_waitcnt (2026-11-14)

环境：容器 gfx-m1（ROCm 7.2.4），GPU RX 6950 XT（gfx1030），hipcc -O3。

1. 真机正确性：partial-drain probe PASS（位级，B=4 对齐形状）。
2. IR/ISA 证据（results/）：
   - `main-hip-amdgcn-amd-amdhsa-gfx1030.s`：最终设备 ISA，含 **30 处
     s_waitcnt**（含本 demo 注入的 `s_waitcnt vmcnt(4)`）——显式内联 asm
     在 -O3 全管线后存活。
   - `vmcnt_encoding.txt`：llvm-mc 确认 gfx10.3 编码
     `s_waitcnt vmcnt(4) = [0x74,0x3f,0x8c,0xbf]`（vmcnt 域分裂 [3:0]+[15:14]）。
3. 负对照结论（架构性）：删掉 asm 后"全排空"语义仍使正确性通过（全排空是
   部分排空的超集）——因此 ISA 产物中的 vmcnt 指令是**该 asm 必要且存活**
   的证据，而非装饰。部分排空本身的必要性由 soft_tma 的分级吞吐背书。

开发中修正的两个测试自伤：host 期望曾写成链式前缀和 / 分量独立累加的
混合错误——位级对比的期望必须逐分量镜像 kernel 的真实累加序。
