# RESULTS — gdn_prefill_fwd_h

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（rocm10-dev:10.1.0，g++ -std=c++20 -O2；纯 CPU）
- 命令：`scripts/build_run.sh`
- 结果：**49,157 checks, 0 failures**（4 组全 PASS）

```
1. chunk recurrence (matrix emu vs per-pair naive, 3 chunks x 2 heads): PASS
2. snapshot chain (h[c] = entering state, bf16): PASS
3. tail chunk (actual_bt=2, zero-filled rows 2..63): PASS
4. state slots (h0 indirection + zero sentinel): PASS
gdn_prefill_fwd_h: 49157 checks, 0 failures -> PASS
```

## 调试链

1. **测试 3 的手工参考把衰减乘错侧**：`Hm = (Σ k·gated) · full`——kernel 的
   `full`（exp(g_last)·gk）只乘旧状态；per-token gated 已自带
   exp(g_last − g_t)。值比对（emu -0.867 vs manual -0.596）抓出。
2. 首版测试 1/2 曾在 emu 之后 seed naive（拿到调用后的状态）——seed 必须
   取调用前快照。

## 钉死的契约

- **g 的 chunk 内重置**：kernel 的 exp(g_last) 状态衰减在"g 按 chunk 边界
  累计重置"的契约下才正确——上游 w/u/g 生产 kernel 的职责边界由此钉死。
- **快照 = 进入状态**：h[c] 存于更新前（测试 2 逐位）。
- **尾部零填充**：actual_bt 之外的行为零贡献（g_scale = 0 + 零填充行）。
- **终态单独输出 ht**（快照不含终态）。
