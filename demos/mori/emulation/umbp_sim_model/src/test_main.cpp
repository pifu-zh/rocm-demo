// test_main.cpp — umbp_sim_model 六项语义测试（对照 docs/umbp-simulation.md 公式）
#include "umbp_sim_model.hpp"
#include <cstdio>
#include <cmath>

using namespace mori_lab_umbp;
static int failures = 0;
#define CHECK(cond, msg) do { bool ok_=(cond); printf("%-52s %s\n", msg, ok_?"PASS":"FAIL"); if(!ok_) ++failures; } while(0)

// 演示系数（自造、量级合理；上游示例 GPU/网络系数未标定——docs 明言）。
// bandwidth/capacity 单位 = **bytes/秒**（上游公式 bytes*1e9/bw 的约定）
static Path gpuPath() {
  return {"gpu_gpu", /*latency*/3000.0, /*copy_latency*/1500.0, /*log_size*/80.0,
          /*batch_log_size*/200.0, /*bw*/30e9 /*30GB/s*/, /*capacity*/45e9};
}
static Path ssdReadPath() {
  Path p{"cpu_file", /*latency*/20000.0, /*copy_latency*/5000.0, /*log_size*/150.0,
         /*batch_log_size*/400.0, /*bw*/3e9, /*capacity*/3.5e9};
  p.serialize_latency = false;
  return p;
}

int main() {
  // T1 公式逐项精确性（独立 host 计算 vs 模型输出）
  {
    Path p = gpuPath(); Channel ch(p.channel_capacity);
    double bytes = 1 << 24; int copies = 1, t0 = 0;   // 16MB
    ModelResult r = modelTransfer(p, ch, bytes, copies, t0);
    double wantSizeTerm = std::log2(bytes / copies / 4096.0);            // log2(4096)=12
    double wantOverhead = 3000.0 + 1500.0 + wantSizeTerm * (80.0 + 200.0);
    double wantPrivate = wantOverhead + bytes * 1e9 / 30e9;
    double wantService = wantOverhead + bytes * 1e9 / 45e9;
    CHECK(std::fabs(r.sizeTerm - 12.0) < 1e-9, "T1 size_term=log2(4096)=12");
    CHECK(std::fabs(r.overheadNs - wantOverhead) < 1e-6, "T1 overhead formula");
    CHECK(std::fabs(r.privateNs - wantPrivate) < 1e-6, "T1 private_ns formula");
    CHECK(std::fabs(r.serviceNs - wantService) < 1e-6, "T1 service_ns formula");
    CHECK(std::fabs(r.finishNs - wantPrivate) < 1e-6, "T1 finish=max(private, channel)");
  }
  // T2 通道排队: 同通道两次同时提交，第二次 finish ≥ 第一次 finish + service₂
  {
    Path p = gpuPath(); Channel ch(p.channel_capacity);
    double bytes = 1 << 24;
    ModelResult r1 = modelTransfer(p, ch, bytes, 1, 0);
    ModelResult r2 = modelTransfer(p, ch, bytes, 1, 0);   // 同时提交
    // 模型语义: 通道服务 FIFO 串行（r2 的通道起点 = serv1），private 可与通道 overlap
    double wantFin2 = std::max(0.0 + r2.privateNs, r1.serviceNs + r2.serviceNs);
    CHECK(std::fabs(r2.finishNs - wantFin2) < 1e-6 && r2.finishNs > r1.serviceNs,
          "T2 channel FIFO: service serialized, private overlapped");
  }
  // T3 通道空闲时的 private-only 语义（finish=max 的另一分支）
  {
    Path p = gpuPath(); Channel ch(p.channel_capacity);
    ModelResult r0 = modelTransfer(p, ch, 1 << 20, 1, 0);    // 先占一次通道
    ModelResult r = modelTransfer(p, ch, 1 << 20, 1, 1e9);   // 1s 后提交，通道早已空闲
    double expect = 1e9 + r.privateNs;
    CHECK(std::fabs(r.finishNs - expect) < 1e-6, "T3 idle channel: finish=private only");
  }
  // T4 copies 缩放: size_term 用 bytes/copies；overhead 的 copies 项线性
  {
    Path p = gpuPath(); Channel ch(p.channel_capacity);
    double bytes = 1 << 24;
    ModelResult r1 = modelTransfer(p, ch, bytes, 1, 0);
    ModelResult r4 = modelTransfer(p, ch, bytes, 4, 0);
    double wantSizeTerm4 = std::log2(bytes / 4 / 4096.0);
    CHECK(std::fabs(wantSizeTerm4 - (r1.sizeTerm - 2.0)) < 1e-9, "T4 size_term uses bytes/copies");
    double wantOverhead4 = 3000.0 + 4 * 1500.0 + wantSizeTerm4 * (4 * 80.0 + 200.0);
    CHECK(std::fabs(r4.overheadNs - wantOverhead4) < 1e-6, "T4 overhead scales with copies");
  }
  // T5 SSD 读半服务: serialize_latency=false → service 只含字节成本（延迟可 overlap）
  {
    Path p = ssdReadPath(); Channel ch(p.channel_capacity);
    double bytes = 1 << 24;
    ModelResult r = modelTransfer(p, ch, bytes, 1, 0);
    double wantService = bytes * 1e9 / p.channel_capacity;
    CHECK(std::fabs(r.serviceNs - wantService) < 1e-6, "T5 unsynced SSD read: service=bytes-only");
    Path pw = ssdReadPath(); pw.serialize_latency = true;    // 写: 全服务对照
    Channel chw(pw.channel_capacity);
    ModelResult rw = modelTransfer(pw, chw, bytes, 1, 0);
    double wantWService = rw.overheadNs + bytes * 1e9 / pw.channel_capacity;
    CHECK(std::fabs(rw.serviceNs - wantWService) < 1e-6 && rw.serviceNs > r.serviceNs,
          "T5 write/mixed keeps full service cost");
  }
  // T6 零字节无字节成本 + 共享路径服务求和
  {
    Path p = gpuPath(); Channel ch(p.channel_capacity);
    ModelResult r0 = modelTransfer(p, ch, 0, 1, 0);
    CHECK(r0.serviceNs > 0 && r0.finishNs <= r0.serviceNs + 1e-6,
          "T6 zero bytes: no byte cost, overhead only");
    Channel ch2(p.channel_capacity);
    ch2.reserve(0, 100.0);
    double b = ch2.reserve(0, 200.0);
    CHECK(std::fabs(b - 300.0) < 1e-9, "T6 shared path sums service costs");
  }

  printf("%s\n", failures == 0 ? "ALL PASS" : "HAS FAILURES");
  return failures;
}
