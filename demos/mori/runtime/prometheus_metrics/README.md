# prometheus_metrics — mori 内嵌 Prometheus 指标服务复现（D-07，纯 CPU）

**类目**: runtime ｜ **验证等级**: `REFERENCE_PASS`（8/8 语义测试，纯 CPU 无 HIP）
**上游对应**: `src/metrics/prometheus_metrics_server.cpp`（456 行）+
`include/mori/metrics/prometheus_metrics_server.hpp`（API 面）@ `c5bdc391`

## 1. 原理说明

MORI-IO/UMBP 的 master/standalone 进程内嵌一个**零依赖 Prometheus 指标服务**：
accept loop + 每连接线程 + GET /metrics 输出 Prometheus 文本格式。API 面
（`prometheus_metrics_server.hpp:101-141`）：
- `setGauge`（覆盖）/ `addCounter`（累加，delta 用 double——注释解释秒累计不能被
  uint64 截断）/ `observe`（histogram，bounds 累积计数）+ labeled 变体
- histogram 语义（`prometheus_metrics_server.cpp:162-166`）：
  `value <= bounds[i]` 逐桶 `++` —— **累积桶**（上桶含下桶观测），`+Inf` 桶 ==
  总观测数，`_sum` 全量精度累加
- `SanitizeName`（hpp:95-98）：名字外字符 [a-zA-Z0-9_] → '_'
- 文本渲染（`SerializeMaps`，cpp:305-372）：`# HELP`/`# TYPE` 头、labeled family
  的 `{k="v",...}` 标签串、`FormatValue` = max_digits10

**实测矩阵（8/8 PASS）**：T1a gauge HELP/TYPE/value 行序；T1b counter 累加；
T2a 累积桶（obs {0.02,0.4,0.7,3.0} → 桶计数 1/2/3/4）；T2b `le="+Inf"`==count、
`_sum`=4.12；T4 SanitizeName；**T5 8 线程 ×5000 次 addCounter 无丢更新**（互斥锁
正确性压力）；T6 真 HTTP GET /metrics 端到端（socket 解析 200/text/plain/TYPE 行）。

## 2. 上游出处

- `src/metrics/prometheus_metrics_server.cpp:305-372`（SerializeMaps 渲染）、
  `:152-166`（observe 累积桶）、`:252-258`（FormatLabels）、`:277`（FormatValue）
- `include/mori/metrics/prometheus_metrics_server.hpp:95-101`（SanitizeName/API）
- 消费方：UMBP master（9091）、standalone server（9092）
- 考古报告：`docs/archaeology/04-io-umbp-ras.md` §6

## 3. 独立实现说明

单文件 C++20，零第三方依赖（上游也是零依赖自渲染）。HTTP accept loop + 每连接
detached 线程（上游同构）；serialize 与上游 SerializeMaps 逐行对应。

## 4. Reference / Correctness Test

期望文本逐字符串比对（HELP/TYPE/value 全行）；桶计数与 sum 由 host 独立计算；
T5 压力计数期望 = 8×5000 精确等于。测试解析本身曾踩"HELP 行含同前缀"的匹配坑
（find→行首 find 修复）——测试代码的解析也要精确。

## 5. 构建

```bash
demos/runtime/prometheus_metrics/scripts/build_run.sh   # 容器内（纯 CPU）
```

## 6. Inspection

`results/run_cpu.log`（8 测试）；`results/metrics_sample.txt`（/metrics 全文样例）。

## 7. Hardware Matrix

纯 CPU——任何机器可跑。真 Prometheus server 抓取本端点的联邦验证未做（格式
与 Prometheus 文本格式 0.0.4 约定一致）。

## 8. Execution Result

ALL PASS（2026-11-23）。未验证事项：observeAggregated（预聚合桶合并）、
labeled histogram 的 bucket_prefix 拼接（上游 cpp:360-370，demo 未含 labeled 变体）、
高并发 HTTP 压力。
