# Results — soft_fp4 (2026-11-13)

环境：容器 gfx-m1（ROCm 10.1 / HIP 7.16 / clang-24；7.2.4 首测），GPU RX 6950 XT（gfx1030），hipcc -O3。

| 检查族 | 项数 | 结果 |
|---|---|---|
| E2M1 标量解码 16 + packed 512 | 528 | PASS |
| E2M1 packed 往返 256 | 256 | PASS |
| E2M1 编码 sweep 108（RNE ties/satfinite/NaN） | 108 | PASS |
| UE8M0 解码 256 + 往返 256 | 512 | PASS |
| MXFP4 组 scale 点积 32×64×128 | 2048 | PASS（worst err/bound = 0.000） |

吞吐（64 Mi pairs，9 B/pair 口径）：decode_e2m1x2 482.7 GB/s | quantize_e2m1x2 545.0 GB/s
——软转换隐藏在内存带宽后（完美替代档，与 soft_fp8 同结论）。

开发中抓到的 bug：UE8M0 解码 byte=0（2^-127 subnormal 被指数域组装 flush 到 0）、
UE8M0 ceil 对 f32 subnormal 输入错位（2^-127 幂二但 mantissa≠0）——双侧同步修复。
