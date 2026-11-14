# cpp_itfs_microframe — aiter cpp_itfs 运行时微框架的主机参考

**类目**: runtime · **验证级别**: SOURCE_VERIFIED + REFERENCE_PASS（纯 CPU 主机参考，无 GPU 执行声明）
**上游**: `aiter/csrc/cpp_itfs/{lru_cache.h, utils.h, utils.py}` @ `1eab5ae12c93af3c8c660202d9a413f637c2f011`（MIT, © AMD）
**依赖**: C++20 + POSIX dlopen（链接 dl/pthread）；无 ROCm / 无 torch / 无 jinja / 无 OpenSSL
**结果**: 21 checks, 0 failures（`results/execution.log`，2026-11-14 容器 gfx-m1 内 g++）
**范围锚点**: `opus --genco`（`csrc/opus_gemm/gen_co/build_co.py`）是这对组合的 compiler 半区——opus 是 aiter 的单头文件 C++ DSL，`--genco` 把 opus DSL 编译成 clang offload bundle。提取它需要完整 opus 工具链构建，归 compiler 线（本仓库 compiler 类 demo 已锚定）；本 demo 锚定 runtime 半区。hsaco launcher / HsacoKernel triton 缓存层同样未提取（设备线）。

## 一、原理说明

cpp_itfs 是 aiter 的"按需编译 + 内容寻址加载"运行时：Python 侧用 jinja
把 kernel 入口模板渲染成 `.cpp`（函数名由配置元组内容寻址），hipcc 编成
`~/.aiter/build/<folder>/lib.so`，再用 ctypes/C++ dlopen 调用。四个可提取
设计：

### 设计 [1]：LRUCache（`lru_cache.h` 逐语义移植）

`std::mutex + std::list + unordered_map<key, list-iterator>` 的 O(1) LRU：
get 把节点 splice 到表首；put 就地更新或驱逐表尾；**capacity −1 = 无界**
（`AITER_MAX_CACHE_SIZE` 缺省）。缓存两类对象：已加载的 SharedLibrary
（C++ 侧，按 func_name 键）与已算出的函数名（防重复 hash）。

### 设计 [2]：内容寻址的 kernel 身份

```
func_name = "<module>_<md5(join(args, '_').lower())>"
```

同一配置元组**永远**映射到同一构建目录 + 同一导出符号；不同配置不碰撞
（md5）；参数小写归一（"Gfx950" 与 "gfx950" 共享构建）。C++ 侧
（utils.h）用 OpenSSL EVP-MD5，Python 侧（utils.py）用 hashlib——本
demo 自带紧凑 RFC-1321 MD5（公开域参考实现），零依赖且**契约精确**
（三个 RFC 官方测试向量钉死：""、"abc"、quick-fox）。

### 设计 [3]：SharedLibrary RAII（`utils.h` 移植）

dlopen(RTLD_LAZY) → dlsym（先 dlerror() 清错、调用后再查错的协议）→
dlclose。模板 `call<ReturnType>(name, args...)` 把 dlsym 指针重解释为
函数指针直接调用。

### 设计 [4]：双边 build-if-missing 流水线

Python 侧：`compile_template_op` →（未构建才）渲染源码 → `compile_lib`
（拷贝头文件、生成 Makefile：`hipcc -shared`、版本相关 cxxflags、
`--offload-arch` 校验、`hip_flag_checker` 逐 flag 探测、FileBaton 多进程
锁）→ `run_lib`（ctypes.CDLL，lru_cache）。C++ 侧镜像：`not_built() →
run_lib()`（dlopen + LRUCache）。本 demo 用**stub builder**（写标记文件）
替代 hipcc 步骤、libm 替代生成的 lib.so，验证编排逻辑本身：未构建 →
构建一次 → 缓存命中 → 二次调用零构建。

## 二、被测试钉死的约定

- LRU 语义：get 触碰改变驱逐序、put 就地更新 + 移前、−1 无界（测试 1/5）。
- 命名：确定性、大小写归一、配置区分、32-hex 格式、MD5 官方向量（测试 2）。
- dlopen 协议：成功路径 + 缺符号抛错路径（测试 3）。
- 编排：首调恰一次构建、同配置二调零构建、异配置独立构建（测试 4）。
- 并发：3 线程 × 20k put/get 无损坏、size 上界（测试 5）。

## 三、文件与验证对照（章程 10 项）

| 章程项 | 本 demo |
|---|---|
| 原理说明 | 本 README §一 + 源文件头注释 |
| 上游出处 + commit | csrc/cpp_itfs/{lru_cache.h, utils.h, utils.py} @ 1eab5ae12，MIT |
| 独立实现 | 单 TU ~560 行：LRUCache/SharedLibrary 逐语义移植 + 紧凑 MD5 + stub 编排 |
| 最小依赖 | C++20 + libdl + pthread；CPU-only |
| Reference | opus/--genco = compiler 半区（范围锚点）；jit_cache demo 是 Python 侧同族设计 |
| Correctness Test | 5 组 21 checks |
| Build Script | `scripts/build_run.sh`；CMakeLists 亦可 ctest |
| Inspection | MD5 RFC 官方向量 = 哈希层的外部基准；编排测试断言构建计数器 |
| Hardware Matrix | 上游目标：主机侧运行时（所有 GPU 型号共享）；CPU-only，未声明任何 HIP 执行 |
| Execution Result | `results/execution.log`：21 checks, 0 failures |

## 四、复现

```bash
cd demos/runtime/cpp_itfs_microframe && ./scripts/build_run.sh
# 或 CMake + ctest
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && ctest --test-dir build
```
