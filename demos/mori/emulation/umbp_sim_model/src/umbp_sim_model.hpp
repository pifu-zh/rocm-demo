// umbp_sim_model.hpp — UMBP sim 模式核心的独立复现（纯 CPU）
//
// 上游出处: ROCm/mori @ c5bdc391
//   - src/umbp/sim/sim.h:60-146（SimTransferEngine：控制面真实+传输虚拟化，
//     kModelCount=16 路径模型）
//   - docs/umbp-simulation.md:106-114（官方公式——本文件的实现依据）:
//       size_term = log2(max(1, bytes / copies / 4096))
//       overhead  = latency_ns[p] + copies*copy_latency_ns[p]
//                 + size_term*(copies*log_size_latency_ns + batch_log_size_latency_ns)
//       private_ns = overhead + bytes*1e9/bandwidth[p]
//       service_ns = overhead + bytes*1e9/channel_capacity
//       channel_available = max(submitted, channel_available) + service_ns
//       finish = max(submitted + private_ns, channel_available)
//   - :41-58（"serialize_latency=false 的 SSD 读：service 只含字节成本，请求延迟可
//     overlap"——T5 验证点）
//
// 与 io_sim_model（MORI-IO sim）的区别: UMBP 模型多了 ①多线程拷贝曲线（copies 参与两处）
// ②size_term 对数项 ③channel_capacity 独立于单调用 bandwidth（容量=多调用方共享的实测
// 上限）④SSD 读的半服务语义。
#ifndef MORI_LAB_UMBP_SIM_MODEL_HPP
#define MORI_LAB_UMBP_SIM_MODEL_HPP
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <mutex>
#include <string>
#include <vector>

namespace mori_lab_umbp {

// 单条路径模型（sim.h:89-103 Path 的标量字段；cpu_cpu 型曲线用标量近似并如实标注）
struct Path {
  std::string name;
  double latency_ns;             // 固定起点延迟
  double copy_latency_ns;        // 每份拷贝的启动延迟
  double log_size_latency_ns;    // 每拷贝 × log2(size/4K) 的对数项
  double batch_log_size_latency_ns;
  double bandwidth;              // **bytes/秒**（单调用实测带宽——上游公式 bytes*1e9/bw
                                 //  的单位约定；30GB/s 存 3e10）
  double channel_capacity;       // bytes/秒（通道共享容量——独立调用方可超线程限）
  bool serialize_latency = true; // false: SSD 读 service 只含字节成本
};

// 通道: per-direction FIFO（available 时间点；ReserveLink 的 UMBP 版）
class Channel {
 public:
  explicit Channel(double capacityBytesPerNs) : capacity_(capacityBytesPerNs) {}
  double reserve(double submittedNs, double serviceNs) {
    std::lock_guard<std::mutex> lk(mu_);
    available_ = std::max(submittedNs, available_) + serviceNs;
    return available_;
  }
  double available() const { return available_; }
 private:
  double capacity_;
  double available_ = 0.0;
  std::mutex mu_;
};

// 单次传输的模型计算（公式逐项对应 docs:106-114；全部纯函数便于对照）
struct ModelResult { double sizeTerm, overheadNs, privateNs, serviceNs, finishNs; };
static ModelResult modelTransfer(const Path& p, Channel& ch, double bytes, int copies,
                                 double submittedNs) {
  ModelResult r;
  r.sizeTerm = std::log2(std::max(1.0, bytes / copies / 4096.0));
  r.overheadNs = p.latency_ns + copies * p.copy_latency_ns
               + r.sizeTerm * (copies * p.log_size_latency_ns + p.batch_log_size_latency_ns);
  r.privateNs = r.overheadNs + bytes * 1e9 / p.bandwidth;
  double serviceNs = r.overheadNs + bytes * 1e9 / p.channel_capacity;
  if (!p.serialize_latency) serviceNs = bytes * 1e9 / p.channel_capacity;  // SSD 读半服务
  r.serviceNs = serviceNs;
  double chAvail = ch.reserve(submittedNs, serviceNs);
  r.finishNs = std::max(submittedNs + r.privateNs, chAvail);
  return r;
}

}  // namespace mori_lab_umbp
#endif
