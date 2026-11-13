# demo: jit_cache_minimal — 内容寻址编译缓存 + FileBaton 跨进程锁（Runtime/JIT）

## 验证等级

**REFERENCE_PASS**（host C++17，双进程并发实证；2026-11-13 起 lab 结构落位）

## 原理与上游出处

aiter 的运行时编译系统（aiter @ 1eab5ae12）三个可剥离机制：

1. **内容寻址缓存键**：`FNV-1a(source, flags, toolchain_version)`——任何输入
   变化强制新构建（aiter/jit/core.py:1802-1924 optCompilerConfig + 版本化）。
2. **原子发布**：tmp 文件 + rename(2)——读者永不看到半成品
   （aiter/jit/utils/jit_cache.py `atomic_copy`:516-551）。
3. **FileBaton 跨进程单建造者锁**：O_CREAT|O_EXCL + pid 戳 + 死者检测
   + 破锁重做（aiter/jit/utils/file_baton.py:26-）。

完整实现与测试：`../../design/`（本目录 = lab 结构中的 runtime 类目入口；
实现在 design/jit_cache.{hpp,cpp}，测试 tests/test_jit_cache.cpp）。

## 实测（design/jit_cache，2026-11-13）

- 双进程竞争同一 key：恰好一次编译，败者经 double-check 命中缓存（标记文件计数 = 1）
- 崩溃持有者的锁被 waiter 检测（pid 死亡）→ 破锁 → 重新获取并重做
- 身份 sidecar 篡改 → 重编译
- 30 checks 全绿（ctest: jit_cache）

## 依赖

无（C++17 filesystem；POSIX）。aiter 对应机制的多进程安全扩展
（blob 事务 stage/publish/restore、世代令牌）未移植——见
docs/archaeology/03-python-runtime.md §1.3。

## Build

ctest 顶层构建自动包含（target: test_jit_cache）；或
`cmake --build build --target test_jit_cache && ./build/test_jit_cache`
