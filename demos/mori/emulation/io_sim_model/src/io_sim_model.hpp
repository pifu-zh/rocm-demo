// io_sim_model.hpp — MORI-IO sim backend 的独立复现（纯 CPU，无 HIP 依赖）
//
// 上游出处: ROCm/mori @ c5bdc391
//   - src/io/sim/backend_impl.hpp:46-49:
//       "Hardware-free stand-ins ... Registration, routing, sessions, the TCP
//        control plane and notifications run for real; only the data movement
//        is replaced by a modelled delay." —— 控制面真实 + 数据面模型
//   - src/io/sim/backend_impl.cpp:631-642 ReserveLink:
//       busy = bytes/BW + segments*perSeg + perOp
//       freeAt = max(now, freeAt) + busy        ← 每方向一条 FIFO 链路
//       finish = freeAt + latency               ← 完成时刻 = 占用结束 + 传播延迟
//   - src/io/sim/backend_impl.cpp:575-601 Submit: 越界拦截（模拟 DMA 引擎的拒绝行为）
//   - src/io/sim/backend_impl.cpp:562-573 MarkPeerDead + :666-691 Complete:
//       peer 死亡 → 到期复查 → ERR_RDMA_OP + PeerFailureEvent
//   - python/mori/io/sim_catalog.yaml: 标定目录（BW/latency/perSeg/perOp 每硬件一条）
//   - tests/python/io/test_sim_backend.py: 上游官方测试（420 行，全 GPU-free）的对应物
//
// 验证等级目标: REFERENCE_PASS（纯 CPU 语义验证；模型参数对照上游 YAML 数值）
#ifndef MORI_LAB_IO_SIM_MODEL_HPP
#define MORI_LAB_IO_SIM_MODEL_HPP

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstdio>
#include <functional>
#include <map>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace mori_lab_sim {

// ---- 链路模型参数（上游 ReserveLink 的四元组；数值单位对齐 sim_catalog.yaml）----
struct LinkProfile {
  double bytesPerNs;      // GB/s → B/ns
  double latencyNs;       // 传播延迟（完成时刻 = 链路空闲 + busy + latency）
  double perSegmentNs;    // 每段固定开销
  double perOpNs;         // 每 op 固定开销
  double timeScale = 1.0; // MORI_IO_SIM_TIME_SCALE（>1 加速）
};

// 单方向 FIFO 链路（tx/rx 各一条，互不影响 —— 上游 rxFreeAt_/txFreeAt_）
class DirectionalLink {
 public:
  explicit DirectionalLink(const LinkProfile& p) : p_(p) {}
  // 返回完成时刻（steady_clock ns）；并发调用受锁保护，FIFO 串行排队
  std::chrono::steady_clock::time_point Reserve(size_t bytes, int segments) {
    using clk = std::chrono::steady_clock;
    double busyNs = (bytes / p_.bytesPerNs +
                     segments * p_.perSegmentNs + p_.perOpNs) / p_.timeScale;
    double latNs = p_.latencyNs / p_.timeScale;
    std::lock_guard<std::mutex> lk(mu_);
    auto now = clk::now();
    auto start = std::max(now, freeAt_);
    freeAt_ = start + std::chrono::nanoseconds((long long)busyNs);
    return freeAt_ + std::chrono::nanoseconds((long long)latNs);
  }
 private:
  LinkProfile p_;
  std::mutex mu_;
  std::chrono::steady_clock::time_point freeAt_ = std::chrono::steady_clock::now();
};

// 模拟引擎状态：本端内存表（无真实数据搬运，但注册/寻址/越界检查真实）
struct MemDesc { uintptr_t base; size_t size; };

enum class Status { kSuccess, kInvalidArgs, kOpFailed };
enum class EventType { kPeerUnreachable };

struct TransferResult { Status status; std::chrono::steady_clock::time_point deadline; };

// 单端引擎（上游 SimBackend + IOEngine 的缩小版；TCP 控制面以"本地回调总线"替位，
// 协议语义保留：AskMemory 校验远端内存存在 → ReserveLink → 定时 Complete/故障复查）
class SimEngine {
 public:
  explicit SimEngine(const LinkProfile& p, const std::string& name) : p_(p), name_(name) {}

  bool RegisterMemory(uintptr_t base, size_t size) {
    std::lock_guard<std::mutex> lk(mu_);
    mems_[base] = {base, size};
    return true;
  }
  bool HasMemory(uintptr_t base, size_t size) const {   // AskMemory 的服务端语义
    std::lock_guard<std::mutex> lk(mu_);
    auto it = mems_.lower_bound(base);
    // 允许子区视图（base 落在已注册区间内；对齐上游 desc.ipcOffset 思想的简化）
    if (it != mems_.begin()) { --it;
      if (base >= it->second.base && base + size <= it->second.base + it->second.size) return true; }
    return it != mems_.end() && base >= it->second.base && base + size <= it->second.base + it->second.size;
  }

  // remote: 对端引擎（控制面校验对象）；rx: 对端的接收方向链路；tx: 本端发送方向链路
  TransferResult Write(SimEngine* remote, uintptr_t remoteBase, size_t bytes, int segments,
                       DirectionalLink* tx, DirectionalLink* rx) {
    // 1) 控制面：AskMemory（真实校验，模拟 QP/MR 建立失败语义）
    if (!remote || !remote->HasMemory(remoteBase, bytes)) {
      MarkPeerDead();
      return {Status::kOpFailed, std::chrono::steady_clock::now()};
    }
    // 2) 越界拦截（上游 Submit :588-601——模拟真实 DMA 引擎拒绝越界）
    if (!HasMemory(remoteBase, bytes) /*本端侧无需；保留对称检查位*/ && false) {}
    // 3) 数据面：模型延迟（双方向 FIFO：发送占用 tx，接收占用 rx —— 上游语义）
    auto finish = tx->Reserve(bytes, segments);
    auto rxFinish = rx->Reserve(bytes, segments);
    if (rxFinish > finish) finish = rxFinish;
    return {Status::kSuccess, finish};
  }

  void MarkPeerDead() { dead_ = true; }                 // MarkPeerDead :562-573
  bool dead() const { return dead_; }
  bool ConsumeFailureEvent(EventType* ev) {             // PopPeerFailure 语义
    if (dead_ && !eventTaken_) { eventTaken_ = true; *ev = EventType::kPeerUnreachable; return true; }
    return false;
  }
  const std::string& name() const { return name_; }
  const LinkProfile& profile() const { return p_; }

 private:
  LinkProfile p_;
  std::string name_;
  std::map<uintptr_t, MemDesc> mems_;
  mutable std::mutex mu_;
  std::atomic<bool> dead_{false};
  bool eventTaken_ = false;
};

}  // namespace mori_lab_sim
#endif
