# RESULTS — topk_plain_strategies

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（rocm10-dev:10.1.0，g++ -std=c++20 -O2；纯 CPU；7.2.4 首测结果一致）
- 命令：`scripts/build_run.sh`
- 结果：`execution.log` — **116 checks, 0 failures**（6 组全 PASS）

```
1. WaveTopkFilter: ballot/staging/integrate/overflow vs naive (6 cfgs): PASS
2. WaveTopkSort: chunked sort/merge vs naive: PASS
3. Block-wide reduce (wave ranges + halving merge tree): PASS
4. threshold contract (monotone; final == true k-th best): PASS
5. dispatch: should_use_topk_radix formula + calc_capacity: PASS
6. tie behavior (value multiset pinned; index order free): PASS
topk_plain_strategies: 116 checks, 0 failures -> PASS
```

## 排错链（三个真实发现）

1. **测试数据踩中平局**：初版用 `uniform()` 造值——Lcg 网格
   （步长 1e-6/1e-5）在 n=3000 时期望 ~4.5 次碰撞，n=8192 更多。碰撞
   落在 top-k 边界时，设备压缩顺序与朴素参考选出**不同索引的同值副本**
   → 集合比较失败（阈值"虚高"其实是平局副本占位）。第一次修复
   （+p·1e-9）无效——1e-9 低于 float 在量级 10 处的 ulp(~1e-6)。
   最终修复：**构造性 distinct**——单调铺开 + Fisher-Yates 洗牌
   （`make_distinct_values`），保分布形状、保无平局。教训：浮点测试
   数据的"distinct"必须按 ulp 论证，不能拍脑袋加小 epsilon。
2. **真 bug：finalize 的哨兵填充是死代码**：初版 finalize 构造了补哨兵
   的局部数组 `v`/`p`，但 `integrate()` 直接读原始 `stage_v`——slots
   [staging_count, 64) 里是**早前 integrate 已消费的陈旧候选**。陈旧项
   重入并集 → 多重集里出现重复 rank → 把真实 top-k 成员挤出缓冲
   （实测：threshold 9.81167 > 真实第 64 大 9.78833）。上游 finalize
   是逐 lane 读时补哨兵（真代码），仿真必须同样让补哨兵生效。修复后
   顺带在每个 mid-stream integrate 后显式清扫消费过的 slots（硬化，
   语义无变化——上游靠"integrate 触发时 staging 必然被完全覆盖"的
   覆盖论证）。
3. **阈值不变量错标**：初版断言"阈值 == 已见前缀的第 k 大"——错。阈值
   是**已 integrate 子集**的第 k 大，合法滞后于前缀（staging 里有未
   integrate 候选）。正确且足够的契约：阈值单调不减 + finalize 后等于
   全量第 k 大 + 过滤安全性论证（≤ 阈值者永不可能进最终 top-k，因为
   缓冲已有 ≥ k 个更好元素）。端到端正确性由测试 1 的集合相等兜底。

## 契约记录

- **输出顺序不是契约**（上游测试自身先排序再比较——
  `test_topk_plain.py:52,71`）；集合才是。rank↔(lane,slot) 分布式布局
  是内部不变量（承重：阈值与最弱 slot 读都依赖它），但对外只以集合
  形式可观测。
- 过滤安全性论证（阈值滞后是安全的）写进了 README §一——这是 Filter
  策略存在的前提，值得从代码里显式提炼。
- radix 决策公式与 capacity 公式为**精确复制**（测试 5 六个精确点钉死）；
  公式的 TODO 注释（"n ≤ 2048 时小分母下 radix 是否最优待确认"）原样
  记录，不做评判。
