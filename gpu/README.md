# rocm-demo / gpu — HIP 工艺 demo（gfx1030 / RDNA2）

本目录的 demo 不进 CMake：它们需要 GPU 与 ROCm 工具链，走独立构建脚本，
与 core（纯 CPU 参考库）分开。宿主机无 ROCm，全部在容器内构建运行
（镜像 `rocm10-dev:10.1.0` =
`docker.m.daocloud.io/rocm/dev-ubuntu-24.04:10.1.0-full`，GPU RX 6950 XT
直通；M2 时代的 7.2.4 镜像与 gfx-m1 实例 2026-11-14 退役，各 demo
RESULTS 中的 gfx-m1 字样为当时的测量环境记录）。

```bash
docker run --rm --device=/dev/kfd --device=/dev/dri --group-add 44 --group-add 989 \
    -v /home/zhuo:/home/zhuo rocm10-dev:10.1.0 \
    bash /home/zhuo/workspace/src/rocm-demo/gpu/run_gfx1030.sh
```

## Demo 一览

原单文件 demo（`soft_fp8.hip` / `soft_fp4.hip` / `soft_tma.hip`）已迁往
`demos/emulation/<name>/`（per-demo CMake / scripts / results）；本目录只保留
下表两件，构建走 `run_gfx1030.sh`。

| Demo | 展示的设计 | 验证方式 |
|---|---|---|
| `soft_tma_pipeline.s` | **手写 ISA 参照实现**（soft-TMA 软件流水：prologue 预取 4×dwordx4 + `vmcnt(4)` 部分排空 + `ds_write_b128` 进 LDS 双缓冲（s16 XOR 换相）+ 消费）；clang 汇编 → `hipModuleLoadData` → 启动 | 32768 lane 逐位对拍（max_abs=0）；作为 `demos/emulation/soft_tma` 的校准参照消费 |
| `toolchain.hip` | hipRTC 运行时编译；`__builtin_amdgcn_ds_bpermute`；buffer_load→LDS 直通（ISA 版验证 + builtin 版如实报告错位） | 各子例自检 PASS |

## 谱系与口径

soft_tma 是 cuda-oxide soft-TMA 研究线（2026-11-04 收线）的**教学重写版**，
改编自已验证的 `lds_b4` 微基准 kernel（原工程
`cuda-oxide/scripts/soft_tma_bench/`）。收线数字 553 GB/s = 经验上限
575.5 GB/s 的 96.1% = D2D 参照的 91.4%（完美替代档）来自 8×255MiB 区域
轮转 + 中位数协议；`soft_tma_pipeline.s` 的同族口径复跑（556.9 GB/s，
2026-11-14）与 C++ 版逐级数字见
`demos/emulation/soft_tma/results/RESULTS.md`。同基准复跑请用原工程。

## 实证发现（本轮新增，已写入 kernel 注释）

1. **`__builtin_amdgcn_raw_ptr_buffer_load_lds` 在 gfx1030/ROCm 7.2 上错位**：
   编译器把 shared 数组基址折叠为 `m0=0`，而数组实际位于 LDS 偏移 128 B，
   结果整体 +32 dword 位移（数据本身正确）。信任路径 = 手写 ISA 显式
   `s_mov_b32 m0`。这与 substitution-catalogue §3 的"MUBUF 基址 wrap"同族。
2. **buffer_load→LDS 直通的单波约束**：一个 workgroup 两个 wave 共用 m0
   会触发 unspecified launch failure；demo 钉在 1 wave/workgroup。
3. **`.amdgpu_metadata` YAML note 是 hipModuleLoadData 的硬要求**：只有
   `.amdhsa_kernel` rodata 块而缺 note 时报 "no kernel image"；且
   `clang -c` 产物是 REL 型，必须链接为 ET_DYN（去掉 `-c`）。
4. **MUBUF lds 形式的汇编语法**：`buffer_load_dword <voffset>, s[..], 0
   offen lds` —— 只有 voffset 一个 v 操作数（数据直落 m0+lane*4），
   多写的 dst 寄存器是解析错误；该拼写 llvm-mc/asm 解析器在 gfx1030 上
   接受，但lds 修饰符的更多组合不接受（负探针见 toolchain.hip 注释）。

## License

新代码 Apache-2.0（repo 默认）；改编自 aiter 的部分沿其 MIT 头注明
（见各文件 SPDX 块）。
