# RESULTS — cpp_itfs_microframe

## 执行记录

- 日期：2026-11-14
- 环境：容器 gfx-m1（ROCm 7.2.4 镜像，g++ -std=c++20 -O2；纯 CPU，未触碰 GPU）
- 命令：`scripts/build_run.sh`
- 结果：`execution.log` — **21 checks, 0 failures**（5 组全 PASS）

```
1. LRUCache (splice-to-front, update-in-place, evict, unbounded): PASS
2. content-addressed naming (md5 vectors, case-fold, cache): PASS
3. SharedLibrary RAII (dlopen libm, dlsym sqrt, error path): PASS
4. build-if-missing + cached-load orchestration (stub builder): PASS
5. concurrent LRUCache hammering (3 threads x 20k ops): PASS
cpp_itfs_microframe: 21 checks, 0 failures -> PASS
```

## 提取记录

- LRUCache 从 `lru_cache.h` 逐语义移植（仅去掉 aiter_logger 依赖）；
  行为测试覆盖 splice-to-front、就地更新、按容量驱逐、−1 无界、并发。
- 命名契约（`get_default_func_name`）在两侧实现（utils.h C++ / utils.py
  Python）里行为一致；demo 用自带 RFC-1321 MD5（""/abc/quick-fox 三个
  官方向量钉死）替代 OpenSSL/hashlib，保持零外部依赖且契约精确。
- SharedLibrary 的 dlerror 协议（先清错、dlsym 后查错）按原样移植；
  错误路径由测试 3 的"缺符号必须抛错"验证。
- 编排逻辑（not_built → 构建一次 → 缓存命中 → 异配置独立目录）用
  stub builder + libm 替身验证——hipcc/jinja/ctypes 步骤本身不在
  CPU demo 的能力范围内，但其**控制流**（构建计数、缓存键、目录布局
  `<root>/<folder>/lib.so`）被测试 4 断言。

## 调试记录

- 一次测试侧 bug：摘要提取用 `find('_')` 命中模块名里的下划线
  （"top_k_..."）——md5 hex 只含 [0-9a-f] 无下划线，`rfind('_')` 才对。
- 一次编译错：`std::string / std::string`（path 拼接）→ 统一改用
  `std::filesystem::path`。

## 范围锚点

- `opus --genco`（csrc/opus_gemm/gen_co/build_co.py）：opus 单头文件
  C++ DSL → clang offload bundle 的编译模式，需要完整 opus 工具链；
  归 compiler 线。本 demo 只锚定 cpp_itfs 运行时半区。
- `compile_hsaco`/`HsacoKernel`（triton kernel 的 hsaco 缓存路径）、
  `hsaco_launcher.py`：设备线，未提取。
- Python 侧 `compile_lib` 的 hipcc flag 演进矩阵（hip 版本条件 flag、
  `hip_flag_checker` 逐 flag 探测）已读入并记录于本文档，提取归
  compiler 线的构建系统 demo（与 jit_cache demo 互补）。
