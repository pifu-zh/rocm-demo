# dsv4_dequant_gather_k — DSV4 分页 K 记录的反量化 gather 主机参考

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/kernels/dsv4_dequant_gather_k.cu` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT）——DSV4 KV 故事的 READ 侧（WRITE 侧 = M4-#3 的 dsv4_hadamard_rotate_quant）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 779 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 / ROCm 10.1 内 g++）

## 一、原理说明

### 设计 [1]：分页记录布局（DeepSeek V4 K record）

```
k_cache 字节布局（每 paged block）:
  [0, block_size·576)   token 数据，576 B/token
    token: [0, 448)     fp8-e4m3 NoPE 维（每维 1 B）
           [448, 576)   64 个 bf16 RoPE 维
  [block_size·576, ...) UE8M0 scales，8 B/token（7 用 + 1 pad）
```

gather 把逻辑位置（seq_len − gather_len + i）经 `block_table[batch][pos /
block_size]` 映射到物理块，再在块内 `pos % block_size` 读 token 记录——
**分页间接是技术本体**（token 跨块、表为置换）。

### 设计 [2]：可配置 bias 的分支无 fp8-e4m3 解码

```
normal  = bit-cast((rest << 20) + ((127 − bias) << 23))
rest < 8（subnormal）= mantissa × 2^(1 − bias − 3)
```
bias 7 = OCP e4m3（max 448）、bias 8 = fnuz（max 240）；NaN 编码在 cache
记录中不可达（V4 编码器钳到 FP8_MAX）——两个解码器都把全部 256 字节当
有限值处理，编解码器交叉验证因此穷举干净。与**算术解码器**（ldexp/乘法
形式——独立计划）逐位对撞，并与 soft_fp8 的 E4M3FN 语义（bias 7）呼应。

### 设计 [3]：lane 分解

64 lane 恰好覆盖 512 输出维：lane 0..55 各 8 个 fp8 维（8 B 载荷），
lane 56..63 各 8 个 bf16 RoPE 维（16 B 载荷，**逐字节透传无反量化**）；
scale_idx = (lane·8)/64。

## 二、测试清单（779 checks）

| # | 内容 | 判据 |
|---|---|---|
| 1 | fp8-e4m3：分支无 vs 算术解码，全 256 字节 × bias 7/8 + 四个锚点（1.0 / OCP 448 / fnuz 240 / subnormal 2^-9） | f32 位级 |
| 2 | e8m0 解码 256 字节 + 锚点（byte 127 = 1.0） | f32 位级 |
| 3 | 分页 gather：置换 block_table + 跨块 token + gather 窗口/offset | bf16 位级 vs 朴素（朴素 = 逻辑记录重构 + 逐维算术反量化） |
| 4 | fnuz 变体（bias 8）端到端 | 位级 + 240 上限 |

## 三、章程对照（10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | README §一 + 源文件头注释 |
| 上游出处 + commit | dsv4_dequant_gather_k.cu @ 1eab5ae12，MIT |
| 独立实现 | 单 TU ~330 行：lane 忠实仿真 + 逻辑重构朴素参考 |
| 最小依赖 | C++20；CPU-only |
| Reference | dsv4_hadamard_rotate_quant（WRITE 侧）；e8m0/e4m3 编解码归 soft_fp4/soft_fp8 |
| Correctness Test | 4 组 779 checks |
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | 256 字节穷举编解码器对撞 + 分页置换间接 + 窗口/offset 定位 |
| Hardware Matrix | 上游目标 gfx10/9 系；本 demo CPU 主机参考 |
| Execution Result | `results/execution.log`：779 checks, 0 failures |

## 四、复现

```bash
cd demos/algorithm/dsv4_dequant_gather_k && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
