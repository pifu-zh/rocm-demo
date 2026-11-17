# opus_mla_decode_splitkv — opus MLA 解码 split-KV 流水线主机参考（ABI + 调度 + 合并数学）

**类目**: algorithm · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考；MFMA 瓦片机制为设备线，预编译 .co）
**上游**: `aiter/csrc/kernels/mla/opus_mla_decode_fwd.cu` + `opus/mla_decode_kargs.h` + `include/mla_reduce_kernels.cuh` + 设备消费侧 `opus/gfx950/mla_decode_a8w8_16mx1_32nx4.hpp` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT；设备端 gfx950-only）
**依赖**: C++20 编译器，无 ROCm / 无 GPU / 无第三方库
**结果**: 32 checks, 0 failures（`results/execution.log`，2026-11-18 容器 gfx-m1 / ROCm 10.1 内 g++；ASAN+UBSAN 零报告）
**关联**: 读侧消费 M6-#2 concat_and_cache_mla_seg 的分段布局家族（本 demo 的 fp8 构建走 page_size 1 的逐 token 记录 + kv_indices 间接）；DSR1 MLA 读写闭环补全

## 一、原理说明

### 设计 [1]：冻结的 kargs ABI——偏移即接口

预编译 .co 对象按字节布局编译，字段变更必须重建。demo 逐字节镜像三套
kargs 并复制上游全部 static_assert：work_info 32 B；merged kargs 136 B
（work_info_set@80、softmax_scale@116、cp_rank@132）；a8w8 扩展 = 136+16
（两个 descale 指针）；mxfp8 176 B（work_info_set@112、softmax_scale@172）。

### 设计 [2]：work 调度器与伪批折叠

一个 work item = {batch_idx, partial_slot, qo_start/end, kv_start/end,
kv_offset}：kv_start/end 索引该批的 kv_indices token 列表；**kv_offset =
原批 KV 末 − 本 split 的 kv_end**——mla.py 把头折叠成伪批，batch_idx 索引
折叠后的 q_indptr 而 kv_indptr 保持按原批，因果对角靠
`qo_start − kv_start + kv_end + kv_offset − q_indptr[batch_idx+1]` 恢复
（demo 手算案例证实其对 split 切分不变）。partial_slot < 0 = 整请求项 →
直接写最终输出、不进 reduce。

### 设计 [3]：per-split 解码数学（设备侧逐条）

- **softmax 不变性的利用**：qk_scale = softmax_scale·descale_q·descale_k
  折进温度——QK descale 只为数值条件，不改变 softmax 权重（softmax 对
  分数整体缩放不变）；**PV MFMA 吃原始 fp8**，descale_k 在成品 O 上一次
  乘完（与归一化合并）：O = (l > 0) ? descale_k·Σexp(s−m)·V8 / l : 0；
  partial LSE = m + log(l)。V8 = 记录前 512 维（merged d=576，rope 是
  +512 切片；O 头维 = 512 而分数维 = 576）。
- l == 0（全掩码）→ O 必须是 0 而非 NaN；因果前缀语义下 token 0 对所有
  行可见 ⇒ 唯一全掩码情形是空批。
- page_size 1：rope DMA 按 16-token 行供给，无法携带 per-lane 页内偏移
  ⇒ fp8 opus 构建只跑逐 token 记录，kv_indices[t] 直接寻址。

### 设计 [4]：split-KV reduce 合并（mla_reduce_v1）

max_lse → sum_lse = Σexp(lse_s − max) → global_lse（sum==0 或 NaN →
INFINITY 守卫）→ lse_scale_s = exp(lse_s − global) → O = Σ w_s·O_s。
**代数只在每 split 的 partial O 于 split 内归一化时闭合**
（O_true = Σ_s exp(m_s)·Õ_s / Σexp(lse_s) = Σ w_s·(Õ_s/l_s)）——这是
partial 布局契约的核心。权重和恒为 1（凸性，demo 以 ulp 量级阈值验证）。

### 设计 [5]：4 GiB 描述符溢出 → 64 位平坦指针回退（charter §4 案例）

buffer descriptor 的 num_records 是 32 位，KV cache ≥ 4 GiB 时越界读**静
默返回零**；page_size 1 使一个 KV tile 的 32 token 落在 per-lane 无关偏移
上，描述符基址是波统一的——无法逐 tile 重定基 → large 路径改用平坦 64 位
指针（global_load_lds），实测代价 ~1-2%，故有门控。

## 二、测试清单（32 checks）

| 组 | 内容 | 结果 |
|---|---|---|
| 0 | ABI 镜像：三套 kargs 的 sizeof/offsetof 全套（32/136/152/176 + 四个偏移） | PASS |
| 1 | 调度器：因果对角公式（split 不变的手算案例）、splits 切分全覆盖 [kv_s, kv_e) | PASS |
| 2 | split 流水线 vs 平坦参考：O（2e-5·max_v 界）与 LSE（1e-4 界）容差比对 + 合并代数恒等式（测试侧按 pipeline 自身几何重组 → 位级）+ lse_scale 凸性（ulp 量级阈值） | PASS |
| 3 | 直接路径与因果：q=1 时 causal 无效果（位级相同，上游 use_causal = causal && q>1 门）；空批全掩码 → O=0、lse=−inf；因果行可见性（同 q 行位级相同、不同前缀行不同） | PASS |
| 4 | 随机主 sweep：5 种子（H 2-3、q 行 1-3、splits 1-4、causal 交替）split 流水线 vs 平坦参考 | PASS |

## 三、发现与教训

1. **"oracle 一致性 ≠ 正确性"第三次活例（最深一次）**：两套调度共享的
   "fp8 解码"把字节当整数（0-255）——流水线与参考**内部完全自洽**（凸组
   合、调度对撞、代数恒等式全绿），只有 O 的界模型（编码真实 fp8 语义：
   |O| ≤ descale_k·max|V8|）抓到 O=3.56 超出 0.075 的矛盾。界模型是把
   语义注入测试的第三种 oracle。
2. **softmax 不变性的语义结论**：QK descale 对注意力权重**语义惰性**
   （softmax(c·s)=softmax(s)），只有 V 的 descale 进输出——设备把
   descale_q·descale_k 折进温度是数值条件选择，不是语义需求。
3. **随机 fp8 测试数据须控值域**：全幅随机字节（值域 ±448）使 576 维点积
   ~1e8、lse ~680，合并权重和的浮点误差达 ulp(680)=6e-5——测试数据应模
   真实量化分布（值域 ≤3.75），阈值按 |gl|·eps 缩放。
4. **测试预期的语义推导要过一遍前缀代数**：2 KV token 时 row 1（q_pos=1）
   可见两个 token——只有 row 0 受前缀限制；位级相同的行还需要 q 数据相同。
5. **ABI 即契约**：kargs 布局冻结意味着 host 端可以在不碰 GPU 的前提下验
   证接口的每一个字节——三套 static_assert 全部可在主机复现。

## 四、规格表

| 项 | 值 |
|---|---|
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | ABI 字节镜像 + 双调度容差/位级对撞 + 合并代数恒等式 + 因果/空批守卫 |
| Hardware Matrix | 设备端 gfx950-only（MFMA 预编译 .co，meta 路由 nhead×max_seqlen_q）；本 demo CPU 主机参考 |
| Execution Result | `results/execution.log`：32 checks, 0 failures |

## 五、复现

```bash
cd demos/algorithm/opus_mla_decode_splitkv && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
