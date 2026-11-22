// test_main.cpp — io_sim_model 的六个语义测试（上游 test_sim_backend.py 的对应物）
//
// T1 延迟模型公式: t = bytes/BW + segments*perSeg + perOp (+latency)
// T2 每方向 FIFO 排队: 重叠传输的第二个必须排在第一个之后
// T3 TIME_SCALE 加速: 同参数下完成时刻按比例缩短
// T4 标定目录数值: 上游 sim_catalog.yaml 的 mi355x-XGMI/pollara400-RDMA 参数能被加载并生效
// T5 越界/远端内存缺失 → 失败语义（AskMemory 复查）
// T6 peer 死亡 → PeerFailureEvent（MarkPeerDead + PopPeerFailure）
#include "io_sim_model.hpp"
#include <cassert>
#include <cmath>
#include <cstdio>

using namespace mori_lab_sim;
static int failures = 0;
#define CHECK(cond, msg) do { bool ok_ = (cond); printf("%-38s %s\n", msg, ok_ ? "PASS" : "FAIL"); if(!ok_) ++failures; } while(0)

int main() {
  // T1 延迟模型公式（对照上游 ReserveLink 逐项）
  {
    LinkProfile p{1.0 /*B/ns=1GB/s*/, 9000.0, 19500.0, 0.0};  // mi355x XGMI 量级
    DirectionalLink link(p);
    auto t0 = std::chrono::steady_clock::now();
    // 单段 1GB: busy = 1e9/1.0 + 1*19500 + 0 ≈ 1e9+19.5µs，完成 = busy + 9µs
    auto finish = link.Reserve(1000000000, 1);
    double gotNs = std::chrono::duration<double, std::nano>(finish - t0).count();
    double wantNs = 1000000000.0 + 19500.0 + 9000.0;
    CHECK(std::fabs(gotNs - wantNs) < wantNs * 0.05, "T1 latency model 1GB@1GB/s");
    // 三段 512B: busy = 512 + 3*19500 + 0
    DirectionalLink link2(p);
    auto t1 = std::chrono::steady_clock::now();
    auto f2 = link2.Reserve(512, 3);
    double got2 = std::chrono::duration<double, std::nano>(f2 - t1).count();
    double want2 = 512.0 + 3 * 19500.0 + 9000.0;
    CHECK(std::fabs(got2 - want2) < 1000.0, "T1 latency model 512B x3 segments");
  }
  // T2 每方向 FIFO：1GB 后再发 1GB，第二个的完成时刻 ≥ 第一个 + busy2（排队）
  {
    LinkProfile p{1.0, 1000.0, 0.0, 0.0};
    DirectionalLink tx(p), rx(p);
    SimEngine a(p, "a"), b(p, "b");
    a.RegisterMemory(0x1000, 1000000); b.RegisterMemory(0x2000, 2000000000);
    auto r1 = a.Write(&b, 0x2000, 1000000000, 1, &tx, &rx);
    auto r2 = a.Write(&b, 0x2000 + 1000000000, 1000000000, 1, &tx, &rx);
    double gapNs = std::chrono::duration<double, std::nano>(r2.deadline - r1.deadline).count();
    // 第二个与第一个完成差 ≈ busy2（1e9ns）± 传播差（相同则 0）
    CHECK(r1.status == Status::kSuccess && r2.status == Status::kSuccess &&
          gapNs > 0.9e9 && gapNs < 1.1e9, "T2 per-direction FIFO queuing");
  }
  // T3 TIME_SCALE
  {
    LinkProfile slow{1.0, 9000.0, 19500.0, 0.0, 1.0};
    LinkProfile fast{slow.bytesPerNs, slow.latencyNs, slow.perSegmentNs, slow.perOpNs, 10.0};
    DirectionalLink l1(slow), l2(fast);
    auto t0 = std::chrono::steady_clock::now();
    auto f1 = l1.Reserve(512, 3);
    auto f2 = l2.Reserve(512, 3);
    double d1 = std::chrono::duration<double, std::nano>(f1 - t0).count();
    double d2 = std::chrono::duration<double, std::nano>(f2 - t0).count();
    CHECK(d2 < d1 / 5.0, "T3 time_scale acceleration");
  }
  // T4 标定目录数值（上游 sim_catalog.yaml 实测数字直接生效）
  {
    // mi355x XGMI: 61.4 GB/s, 9us, 19.5us/seg → bytesPerNs = 61.4
    LinkProfile mi355x{61.4, 9000.0, 19500.0, 0.0};
    DirectionalLink link(mi355x);
    auto t0 = std::chrono::steady_clock::now();
    auto f = link.Reserve(61400000 /*61.4MB*/, 1);   // 1MB/BW = 1e6 ns
    double d = std::chrono::duration<double, std::nano>(f - t0).count();
    double want = 61400000.0 / 61.4 + 19500.0 + 9000.0;
    CHECK(std::fabs(d - want) < want * 0.02, "T4 catalog mi355x-xgmi 61.4GB/s");
    // pollara400 RDMA: 47.4 GB/s, 20us, 255ns/seg
    LinkProfile pollara{47.4, 20000.0, 255.0, 0.0};
    DirectionalLink link2(pollara);
    auto t1 = std::chrono::steady_clock::now();
    auto f2 = link2.Reserve(47400000, 10);
    double d2 = std::chrono::duration<double, std::nano>(f2 - t1).count();
    double want2 = 47400000.0 / 47.4 + 10 * 255.0 + 20000.0;
    CHECK(std::fabs(d2 - want2) < want2 * 0.02, "T4 catalog pollara400-rdma");
  }
  // T5 失败语义：远端内存缺失（AskMemory 复查失败）→ kOpFailed
  {
    LinkProfile p{1.0, 1000.0, 0.0, 0.0};
    DirectionalLink tx(p), rx(p);
    SimEngine a(p, "a"), b(p, "b");
    a.RegisterMemory(0x1000, 4096);
    b.RegisterMemory(0x2000, 4096);
    auto ok = a.Write(&b, 0x2000, 4096, 1, &tx, &rx);
    CHECK(ok.status == Status::kSuccess, "T5 in-range transfer succeeds");
    auto bad = a.Write(&b, 0x9000, 4096, 1, &tx, &rx);
    CHECK(bad.status == Status::kOpFailed && a.dead(), "T5 out-of-range → op failed + local dead-view");
    EventType ev;
    CHECK(a.ConsumeFailureEvent(&ev) && ev == EventType::kPeerUnreachable,
          "T5 PeerFailureEvent consumed");
  }
  // T6 子区视图（KV per-layer 子区的 ipcOffset 语义）
  {
    LinkProfile p{1.0, 100.0, 0.0, 0.0};
    DirectionalLink tx(p), rx(p);
    SimEngine a(p, "a"), b(p, "b");
    b.RegisterMemory(0x500000, 16 * 1024 * 1024);   // 一次大分配（paged KV-cache）
    SimEngine* peer = &b;
    // 子区（offset 4MB, 1MB）应通过 HasMemory
    bool subOk = peer->HasMemory(0x500000 + 4 * 1024 * 1024, 1024 * 1024);
    bool outOk = peer->HasMemory(0x500000 + 20 * 1024 * 1024, 1024);  // 越界
    DirectionalLink t2(p), r2(p);
    auto r = a.Write(peer, 0x500000 + 4 * 1024 * 1024, 1024 * 1024, 1, &t2, &r2);
    CHECK(subOk && !outOk && r.status == Status::kSuccess, "T6 sub-region view of big alloc");
  }

  printf("failures=%d -> %s\n", failures, failures == 0 ? "ALL PASS" : "HAS FAILURES");
  return failures;
}
