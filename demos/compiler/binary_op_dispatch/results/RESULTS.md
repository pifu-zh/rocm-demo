# RESULTS — binary_op_dispatch

## 执行记录
- 日期：2026-11-14；容器 gfx-m1（rocm10-dev:10.1.0，g++ -std=c++20 -O2；纯 CPU）
- 结果：**19 checks, 0 failures**（4 组全 PASS）

```
1. CONTIGUOUS (2-D, 1-D mod-128 alignment, element_size variants): PASS
2. broadcast family (b0/1/2/3/4 + unsupported shapes): PASS
3. non-3-D middle-dim broadcast fallback (BROADCAST_1): PASS
4. instantiation-matrix ladder emitter (2 ops x 3 dtype pairs): PASS
binary_op_dispatch: 19 checks, 0 failures -> PASS
```

## 调试链（三次测试期望修正 = 三次对上游级联的精读）

1. BROADCAST_3 的 order 方向（input 3-D → true）
2. BROADCAST_1/2 的 order（broadcast 侧在 input → false）
3. 2-D (m,n)+(1,n) 实际不被支持——BROADCAST_1 回退的
   `bcast_dims[0] != 0 && != dim-1` 条件在 2-D 下永不成立；≥4-D 才触发。
   同时确认：1-D 对齐是元素计数（numel % 128），element_size 只影响
   1-D 广播的尺寸对齐（128/element_size）。

## 钉死的契约

- 分类器是 aiter 快路径的门：7 模式覆盖 + 回退，order_flag 钉死
  broadcast 侧永远非 primary。
- 实例化矩阵 = (op × dtype-pair) 的编译成本前移（运行时 JIT → 构建期）。
- 梯子结构契约：首 if、后续 else-if、每分支精确调用名、末端 return false。
