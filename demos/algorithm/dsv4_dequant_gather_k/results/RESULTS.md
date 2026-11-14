# RESULTS — dsv4_dequant_gather_k

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（rocm10-dev:10.1.0，g++ -std=c++20 -O2；纯 CPU）
- 命令：`scripts/build_run.sh`
- 结果：**779 checks, 0 failures**（4 组全 PASS）

```
1. fp8-e4m3 branchless decode vs arithmetic (256B x bias 7/8 + spots): PASS
2. e8m0 scale decode (256 bytes + anchor): PASS
3. paged gather (permutation table + block straddle + window/offset): PASS
4. fnuz variant (bias 8) end-to-end: PASS
dsv4_dequant_gather_k: 779 checks, 0 failures -> PASS
```

## 调试链（两个测试侧错误 + gdb 定位法）

1. **block_table 的 2-D 布局误解**：测试建了 1 行（3 项），kernel 按
   `[batch·max_blocks_per_seq + blk]` 索引需要 3 行×3 项——batch 2 读到
   越界垃圾块号 → 巨大块偏移 → 段错误。gdb 铁证：`tok = data + 50,496`
   远超 14,592 B 向量（期望偏移 9,728）。上游 AITER_CHECK
   "block_table must be [num_reqs, max_blocks_per_seq]" 是布局契约。
2. **正则修复破坏了 naive 的 if/else 结构**：fp8 分支内嵌入了 bf16 尾部
   读（负偏移 OOB）覆盖正确值（got 0x4940 = 手算正确值 vs want 0x7372）。
   **教训：正则重构后必须重读结构，不能只看编译通过。**

## 钉死的契约

- 分支无 fp8 解码与算术解码在全部 256 字节 × bias 7/8 逐位一致；
  OCP max 448（0x7E）、fnuz max 240（0x7F bias 8）、subnormal 2^-9 锚点。
- NaN 编码在 cache 记录中不可达（编码器钳位）——两个解码器按有限值处理，
  穷举因此干净。
- bf16 RoPE 尾部逐字节透传（无反量化）。
- 输出行 [512, ...) 尾部由调用方预填（kernel 只写 512 维/行）。
