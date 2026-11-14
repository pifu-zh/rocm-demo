# RESULTS — opus_dsl_host

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（rocm10-dev:10.1.0），宿主编译器 = clang-24（**clang-only**：opus.hpp 用 __make_integer_seq/__type_pack_element 内建，g++ 无法解析——本 demo 是实验室唯一 clang 编译的 CPU 件）
- 命令：`scripts/build_run.sh`
- 结果：**52 checks, 0 failures**（8 组全 PASS）

```
1-8（number / seq / ford / array+pack / tuple / layout / finfo / empty-tuple）全 PASS
opus_dsl_host: 52 checks, 0 failures -> PASS
```

## 调试链

1. **CHECK 宏的模板逗号陷阱**：`is_same_v<A, B>` 的逗号在宏参数里劈开
   调用 → 改可变参 `CHECK(...)`。
2. **reduce_seq_sum/mul 返回 seq（number）** 而非标量——类型断言改为
   `seq<9>`/`seq<24>`。
3. **fp4_t 不在切片内**（其 REGISTER_DTYPE 在切片外的设备段）——改用
   切片内的 dpacks 机制本地构造 4-bit pack 类型测试代理 round trip。
4. **static_ford 的 seq 是形状维度**：`seq<0,1,2,3>` 第 0 维大小 0 → 零
   迭代（sum=0 ≠ 6 抓出）；修正为形状语义（1-D <4> 与 2-D <2,2>）。
5. **slice 的 fallback 是 dtype-only**：tuple 不是 dtype → 不匹配 fallback
   重载；改测头文件 NOTE 钉住的空 tuple 契约。
6. **bf16 max 的十进制注释是舍入值**：比较改位模式（0x7F7F0000）。

## 提炼记录

- **切片边界 = 上游 1190 行**（GCN asm 节之前），花括号差 1 = namespace
  opus 开着，切片尾补 `}`。切片内唯一裸 __host__/__device__ = 421 行
  tuple 推导指南（shim 置空解决）。
- 设备无关半的可测性本身就是设计质量的证据：52 个检查无一处需要修改
  上游代码（纯外部单元测试）。
- 消费者映射：12+ kernel 建立在切片抽象之上——剥离 DSL = 理解这批
  kernel 的公共地基。
