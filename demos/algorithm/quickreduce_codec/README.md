# quickreduce_codec — aiter QuickReduce 通信压缩编解码器的主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/include/quick_all_reduce.cuh`（CodecQ4/CodecQ3/CodecQ6）+ `csrc/include/quick_all_reduce_base.h` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT, © AMD）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 56,855 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 内 g++）
**范围排除（NOT_EXTRACTED）**: IPC/多卡 communicator 机制（buffer 注册、flag 同步 two-shot 协议、PullQ4 布局）——本 demo 只提取 codec 层（主机可验证部分）。

## 一、原理说明

QuickReduce 是 aiter 的自定义 all-reduce：把 FP16/BF16 激活按块对称量化成
int4/int3/int6 再走 P2P 传输，用带宽换精度。三个 codec 共享一个骨架，本
demo 逐条提取：

### 设计 [1]：符号翻转的块对称量化（核心设计点）

每个量化组 = 8 线程 × 8 个 bf16 lane = 64 值；**偶/奇 lane 位置各自独立
持 scale**（packed f16x2 的两个半区）：

```
decoding_scale = bf16(absmax) × (−1/2^(b−1))      # b = 4/3/6
encoding_scale = rcp(decoding_scale + 1e-7)
w              = clip(v × encoding_scale, [−2^(b−1), +2^(b−1)−1])
q              = rint(w) + 2^(b−1)                # 无符号 [0, 2^b − 1]
```

**为什么要负 scale（不是常规的正对称量化）**：负 encoding_scale 把正数
翻到负 w 侧。无符号码域 [0, 2^b−1] 映回有符号后范围是 [−2^(b−1), +2^(b−1)−1]
——两端不对称，宽端多一个码点。正 absmax 恰好落在宽端（−2^(b−1)）**永不
clip**，而负 absmax 落在 +2^(b−1)−1 端会 clip 掉 ≤1 LSB。即：**把"保证
出现的极值"分配给保证精确的那一端**。测试 A 钉死：正 absmax → 无符号码 0
（宽端）且解码误差 ≤ bf16 scale 精度；负 absmax → clip 端误差 ≤ 1.3 LSB
（见 RESULTS.md 的推导）。

`kScaleEpsilon`（bf16 0x33D7 ≈ 1.0007e-7）加在 rcp 之前：全零块的 scale=0
→ rcp(eps) → w=0 → 码 0 → 解码 0×0 = 0，无 NaN/Inf（测试 B）。

### 设计 [2]：位级打包（整数域精确环回）

| codec | 每线程 8 值 → | recv 重建 |
|---|---|---|
| Q4 | 1×u32（4-bit 场 ×8） | fp16 mantissa 技巧：`(q&0xF) \| 0x6400` = f16(1024+q)，+= −1032 → q−8；bf16 路径显式 int→bf16 后 + kRangeMin |
| Q3 | u16（低 2 bit×8）+ u8（高 1 bit×8） | low2 \| (high1<<2) 重组 + kRangeMin |
| Q6 | u32（低 4 bit×8）+ u16（高 2 bit×8, 场 i·2） | q6 = q4 \| (q2<<4)；fp16 路径 mantissa 技巧 1024/−1056 |

测试 C 穷举全部码点 × lane 顺序，环回逐位相等。

### 设计 [3]：tile 几何（真实字节布局）

| codec | kRankTileStride | 区域 |
|---|---|---|
| Q4 | 1152 B | payload 1024 B（256 线程×4B）+ scale 128 B @1024（32 组×4B） |
| Q3 | 896 B | q2 512 B + q1 256 B @512 + scale @768 |
| Q6 | 1664 B | q4 1024 B + q2 512 B @1024 + scale @1536 |

scale 由组 leader（thread/8·8）写在 `thread/8` 索引处（packed bf16x2：低半
= 偶 lane，高半 = 奇 lane）。测试 D 让 256 线程的完整 tile 走真实偏移的
send→recv 环回。

### group_abs_max

设备端是 shfl_down 链（掩码 1/2/4）+ leader 广播；每半区独立求 max/min 再
packed_abs_max。仿真用纯折叠（leader 语义等价， Pollution lane 被广播丢弃
——与上游一致）。

## 二、常量表（packed hex → bf16 标量，测试 0 交叉核对）

| 常量 | packed hex (bf16) | 标量 |
|---|---|---|
| Q4 kScaleFactor | 0xBE00BE00 | −0.125 |
| Q4 kRangeMin/Max | 0xC100 / 0x40E0 | −8 / +7 |
| Q3 kScaleFactor | 0xBE80BE80 | −0.25 |
| Q3 kRangeMin/Max | 0xC080 / 0x4040 | −4 / +3 |
| Q6 kScaleFactor | 0xBD00BD00 | −1/32 |
| Q6 kRangeMin/Max | 0xC200 / 0x41F8 | −32 / +31 |
| kScaleEpsilon | 0x33D733D7 | ≈1.0007e-7 |

## 三、已文档化的替代与误差界

- 设备 `h2rcp` 是近似倒数（~1 ulp）；主机参考用精确 1/x。误差界容忍
  该差异（eps 与 rint 吸收）。
- 设备 packed_mul/add 在 bf16 域内舍入；仿真逐步 bf16_round 对齐。
- **误差界（测试 A/D 实证）**：内部元素 ≤ 1.05 LSB；clip 端 ≤ 1.3 LSB。
  1.3 的依据：clip 贡献 1 LSB + scale 链双重 bf16 舍入（amax→bf16 与
  ÷2^(b−1)→bf16，各 ≤ 2^-9 相对误差）可再贡献 ~0.7%（实测 Q6 7.515625
  RNE-tie 舍到 7.5 → 1.066 LSB）。
- 压缩比（每 256 线程 atom tile 4096 B raw）：Q4 3.556×、Q3 4.571×、
  Q6 2.462×（测试 6 钉死 = tile_stride 比）。

## 四、文件与验证对照（章程 10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | 本 README §一 + 源文件头注释 |
| 上游出处 + commit | quick_all_reduce.cuh / quick_all_reduce_base.h @ 1eab5ae12，MIT |
| 独立实现 | 单 TU ~600 行：标量语义仿真（每步 bf16 舍入对齐 packed op），不链接 aiter_ref |
| 最小依赖 | C++20；CPU-only |
| Reference | 通信/同步机制归 hardware 类（custom_all_reduce）；fp8 codec 归 soft_fp8 |
| Correctness Test | 6 组 56,855 checks（见 §五） |
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 位布局穷举环回（C）+ 常量表 hex↔标量交叉核对（0）|
| Hardware Matrix | 上游目标 MI300（gfx950 系）+ gfx1250 分支；本 demo CPU 主机参考，未声明任何 HIP 执行 |
| Execution Result | `results/execution.log`：56,855 checks, 0 failures |

## 五、测试清单

| # | 内容 | 判据 |
|---|---|---|
| 0 | packed-hex 常量 → bf16 标量交叉核对 | 10 项逐值 |
| A | 编码/解码环回（256 组随机，log-uniform 幅值） | 逐元素 1.05 LSB / clip 端 1.3 LSB；正 absmax → 码 0 且解码 ≤1% 相对；负 absmax clip ≤ 1.3 LSB |
| B | 全零块 | 解码恰为 0（eps 守卫 rcp） |
| C | 位布局整数环回 | 全码点 × lane 顺序逐位 |
| D | 256 线程 tile send/recv（真实偏移） | tile 大小 = stride；逐元素 ≤ 1.3 LSB（组界） |
| 6 | 压缩比 | 3.556×/4.571×/2.462× 逐值 |

## 六、复现

```bash
cd demos/algorithm/quickreduce_codec && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
