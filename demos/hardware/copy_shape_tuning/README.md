# copy_shape_tuning — float4 拷贝形状扫描（HBM 边界的负结果 + 方法论）

**类目**: hardware · **验证级别**: HARDWARE_PASS + PERFORMANCE_MEASURED（RX 6950 XT / gfx1030，ROCm 10.1，2026-11-14）
**动机**: soft_tma 的 grading 分母（copy_f4 ceiling kernel，b1024 × e1）是继承的形状，从未扫描过。本 demo 在卡上扫描 块大小 × 向量宽 × 每线程元素数。

## 一、结果（L2-defeating 协议：4 × 338 MB 区域轮转）

| 形状 | GB/s | 相对最优 |
|---|---|---|
| **v4 e1（任意块大小 64-1024）** | **494.9–499.5** | 100% |
| v4 e2 | 310–356 | −29~38% |
| v4 e4 | 236–240 | −52% |
| v2 e4 | 183–199 | −60% |
| v1 e8 | 104–119 | −76% |

**结论（阴性 + 阳性）**：
1. **每线程 1 个 float4 时块大小无关**（64-1024 全在 494-500）——shipped 的
   b1024×e1 形状本就最优，无需改动（负结果，但有价值：形状是"继承未验证"
   的，现在有了扫描证据）。
2. **每线程元素数 > 1 塌陷**（e2 −32%、e4 −52%）——多条独立 float4 的展开
   分支 + 守卫降低占用。
3. **窄向量塌陷**（v2 −60%、v1 −76%）——访问宽度是第一序参数。

## 二、方法论教训（两次测量陷阱）

1. **L2 驻留假象**：第一版 sweep 用 2.6 MB 区域 × 8——全塞进 8 MB L2，
   "最优 773.9 GB/s"是 L2 带宽不是 HBM，把形状排序搞错 1.5×。区域必须
   L2-defeating（≥ 数百 MB）。
2. **字节核算单位**：kRegionF4 是 float4 计数——分配用 ×16 B、kernel 的
   n 用 ×4 floats、带宽公式用 ×16×区域数——三处单位不一致曾分别造成
   4× OOB fault 与 4× 低估。
3. 分配单位错误表现为 GPU "Page not present" fault（而非主机段错误）——
   首次 fault 时应在分配/访问两端核对字节单位。

## 三、复现

```bash
cd demos/hardware/copy_shape_tuning && ./scripts/build_run.sh   # 容器内，需真机
```
