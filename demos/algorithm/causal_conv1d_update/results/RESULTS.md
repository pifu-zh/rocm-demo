# RESULTS — causal_conv1d_update

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（rocm10-dev:10.1.0，g++ -std=c++20 -O2；纯 CPU，未触碰 GPU）
- 命令：`scripts/build_run.sh`
- 结果：**377 checks, 0 failures**（4 组全 PASS）

```
1. non-circular two-pass shift + conv vs naive (w2/3/4 x 2 geom x silu): PASS
2. circular ring buffer (w2/3/4, 16 calls, wrapping cursor): PASS
3. continuous batching (indirection + pad skip + shared slot): PASS
4. large-seqlen state hygiene (outputs AND state correct for all seqlen): PASS
causal_conv1d_update: 377 checks, 0 failures -> PASS
```

## 调试链（两个真实 bug + 一个被证伪的假设）

1. **emu 的 x_vals 种子拆出了 pass-2 循环**：kernel 的 pass-2 是
   "读 state[len-2+i] → 写 state[len-seqlen-2+i] → x_vals[i] = 读值"
   三合一——x_vals 捕获**写前**的尾部。emu 把种子拆成独立循环放在
   pass-2 之后 → 读到搬移后的 state（末 token 被复制进卷积窗口）→
   call-1 输出错（got=-0/want=18.375 的零窗口指纹）。
   **教训：kernel 的读写交织顺序是承重结构，仿真必须逐语句对齐。**
2. **校验表达式对源模式不成立**：期望写成 `src[i%32]` 而实际拷贝是
   `src[i]`——demo 的 src 以 37 取模回绕，i ≥ 37 后两者不同。
   （最小复现 sm2 PASS 是其 src 恰为 32 周期的巧合。）
3. **"seqlen > width-1 时状态中段腐坏"假设被证伪**：手写追踪认为
   pass-2 只搬 width-1 个值、大 seqlen 会丢中段——检查显示大 seqlen 的
   输出与状态**均与朴素一致**（pass-2 的守卫钳制 + token 写入的组合对
   任意 seqlen 正确）。假设撤回，检查保留为回归钉子。

## 钉死的契约

- 非循环模式：两遍守卫式搬移 + 尾部 token 写入，任意 seqlen 下状态与
  输出均正确（含 seqlen > state_len 的越界推进，守卫负位截断）。
- 循环模式：游标 = cache_seqlens % len；卷积读游标后方 width-1 个环绕值。
- 连续批处理：pad_slot_id 行的 CTA 早退（状态/输出均不触碰）；
  槽可被两行共享（宿主确定性下最后写者胜）。
