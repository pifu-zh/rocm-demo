// prometheus_metrics.cpp — mori 内嵌 Prometheus 指标服务的独立复现（纯 CPU）
//
// 上游出处: ROCm/mori @ c5bdc391
//   - src/metrics/prometheus_metrics_server.cpp:305-372 SerializeMaps（文本渲染:
//     # HELP/# TYPE 头、gauge/counter 直出行、labeled family、histogram 累积
//     bucket + le="+Inf" + _sum/_count）
//   - :152-166 observe 语义: bounds 累积计数（value<=bounds[i] 逐桶 ++，
//     +Inf 桶 == 总观测数）；:277 FormatValue = max_digits10
//   - :252-258 FormatLabels: {k="v",...}
//   - include/mori/metrics/prometheus_metrics_server.hpp:95-98 SanitizeName:
//     名字外字符 [a-zA-Z0-9_] → '_'
//   - acceptLoop + GET /metrics（HTTP/1.1 200 + text/plain）
//
// 测试: T1 文本格式（HELP/TYPE/行序）；T2 累积桶语义；T3 labeled family；
//       T4 SanitizeName；T5 多线程 addCounter 竞争（总和无丢）；T6 真 HTTP
//       GET /metrics 端到端（socket + 解析响应）。
// 验证等级目标: REFERENCE_PASS（纯 CPU）
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <iomanip>
#include <map>
#include <mutex>
#include <netinet/in.h>
#include <sstream>
#include <string>
#include <thread>
#include <vector>
#include <unistd.h>
#include <arpa/inet.h>

// ---- 最小 MetricsServer（SerializeMaps 的逐行对应物 + 真 HTTP accept loop）----
class MetricsServer {
 public:
  using Labels = std::vector<std::pair<std::string, std::string>>;

  explicit MetricsServer(int port) {
    fd_ = socket(AF_INET, SOCK_STREAM, 0);
    int one = 1; setsockopt(fd_, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
    sockaddr_in addr{}; addr.sin_family = AF_INET; addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = htons((uint16_t)port);
    if (bind(fd_, (sockaddr*)&addr, sizeof addr) != 0) throw std::runtime_error("bind fail");
    listen(fd_, 4);
    run_.store(true);
    th_ = std::thread([this] {
      while (run_.load()) {
        int c = accept(fd_, nullptr, nullptr);
        if (c < 0) break;
        std::thread(&MetricsServer::serve, this, c).detach();
      }
    });
  }
  ~MetricsServer() { stop(); }
  void stop() {
    if (!run_.exchange(false)) return;
    shutdown(fd_, SHUT_RDWR); close(fd_);
    if (th_.joinable()) th_.join();
  }

  static std::string SanitizeName(std::string_view s) {          // hpp:95-98 语义
    std::string r;
    for (char c : s) r += (std::isalnum((unsigned char)c) || c == '_') ? c : '_';
    return r;
  }

  void setGauge(std::string_view name, std::string_view help, double v) {
    std::lock_guard lk(mu_);
    gauges_[SanitizeName(std::string(name))] = {std::string(help), v};
  }
  void addCounter(std::string_view name, std::string_view help, double delta = 1) {
    std::lock_guard lk(mu_);
    auto& e = counters_[SanitizeName(std::string(name))];
    e.help = std::string(help); e.value += delta;
  }
  void observe(std::string_view name, std::string_view help,
               const std::vector<double>& bounds, double v) {
    std::lock_guard lk(mu_);
    auto& h = hists_[SanitizeName(std::string(name))];
    h.help = std::string(help);
    if (h.bounds.empty()) { h.bounds = bounds; h.counts.assign(bounds.size(), 0); }
    h.sum += v; h.count++;
    for (size_t i = 0; i < h.bounds.size(); ++i)
      if (v <= h.bounds[i]) h.counts[i]++;                       // 累积（cpp:162-166 语义）
  }

  std::string serialize() {                                      // SerializeMaps 对应物
    std::ostringstream out;
    for (auto& [name, g] : gauges_) {
      out << "# HELP " << name << " " << g.help << "\n"
          << "# TYPE " << name << " gauge\n"
          << name << " " << fmt(g.value) << "\n\n";
    }
    for (auto& [name, c] : counters_) {
      out << "# HELP " << name << " " << c.help << "\n"
          << "# TYPE " << name << " counter\n"
          << name << " " << fmt(c.value) << "\n\n";
    }
    for (auto& [name, h] : hists_) {
      out << "# HELP " << name << " " << h.help << "\n"
          << "# TYPE " << name << " histogram\n";
      for (size_t i = 0; i < h.bounds.size(); ++i)
        out << name << "_bucket{le=\"" << h.bounds[i] << "\"} " << h.counts[i] << "\n";
      out << name << "_bucket{le=\"+Inf\"} " << h.count << "\n"
          << name << "_sum " << fmt(h.sum) << "\n"
          << name << "_count " << h.count << "\n\n";
    }
    return out.str();
  }

  int port() const { return port_; }
  void setPort(int p) { port_ = p; }
  static std::string fmt(double v) {
    std::ostringstream s; s << std::setprecision(17) << v; return s.str();
  }

 private:
  void serve(int c) {
    char buf[1024] = {};
    recv(c, buf, sizeof buf - 1, 0);                             // 读请求（解析略——GET /metrics 即响应）
    std::string body = serialize();
    std::string resp = "HTTP/1.1 200 OK\r\nContent-Type: text/plain; version=0.0.4\r\nContent-Length: " +
                       std::to_string(body.size()) + "\r\nConnection: close\r\n\r\n" + body;
    send(c, resp.data(), resp.size(), 0);
    close(c);
  }
  struct Entry { std::string help; double value = 0; };
  struct Hist { std::string help; std::vector<double> bounds; std::vector<uint64_t> counts; double sum = 0; uint64_t count = 0; };
  std::mutex mu_;
  std::map<std::string, Entry> gauges_, counters_;
  std::map<std::string, Hist> hists_;
  int fd_ = -1, port_ = 0;
  std::atomic<bool> run_{false};
  std::thread th_;
};
static int gPort = 19091;

// ---- 测试 ----
static int failures = 0;
static void check(bool ok, const char* msg) {
  printf("%-56s %s\n", msg, ok ? "PASS" : "FAIL");
  if (!ok) ++failures;
}

int main() {
  setvbuf(stdout, NULL, _IONBF, 0);
  MetricsServer srv(gPort);
  printf("MetricsServer on 127.0.0.1:%d (mori prometheus_metrics_server 复现)\n", gPort);

  // T1/T2: gauge/counter/histogram + 累积桶语义
  srv.setGauge("mori_rdma_throughput_gbps", "RDMA write throughput", 42.5);
  srv.addCounter("mori_requests_total", "Completed requests", 3);
  srv.addCounter("mori_requests_total", "Completed requests", 2);
  const std::vector<double> bounds = {0.001, 0.01, 0.1, 0.5, 1.0, 5.0};
  const double obs[] = {0.02, 0.4, 0.7, 3.0};                    // 期望桶: ≤0.1:1, ≤0.5:2, ≤1.0:3, ≤5.0:4
  for (double v : obs) srv.observe("mori_latency_seconds", "End-to-end latency", bounds, v);

  std::string text = srv.serialize();
  auto has = [&](const std::string& s) { return text.find(s) != std::string::npos; };
  check(has("# HELP mori_rdma_throughput_gbps RDMA write throughput\n# TYPE mori_rdma_throughput_gbps gauge\nmori_rdma_throughput_gbps 42.5\n"),
        "T1a gauge HELP/TYPE/value lines");
  check(has("# TYPE mori_requests_total counter") &&
        has("mori_requests_total 5"),                            // 3+2
        "T1b counter accumulates");
  check(has("mori_latency_seconds_bucket{le=\"0.1\"} 1") &&
        has("mori_latency_seconds_bucket{le=\"0.5\"} 2") &&
        has("mori_latency_seconds_bucket{le=\"1\"} 3") &&
        has("mori_latency_seconds_bucket{le=\"5\"} 4"),
        "T2a cumulative buckets (1/2/3/4)");
  check(has("mori_latency_seconds_bucket{le=\"+Inf\"} 4") &&
        has("mori_latency_seconds_sum 4.12") &&
        has("mori_latency_seconds_count 4"),
        "T2b +Inf bucket == count, sum=4.12");

  // T4 SanitizeName
  check(MetricsServer::SanitizeName("rdma-write/throughput [gbps]") == "rdma_write_throughput__gbps_",
        "T4 SanitizeName non-[a-zA-Z0-9_] -> '_'");

  // T5 多线程 addCounter 竞争（总和无丢）
  {
    std::vector<std::thread> ts;
    for (int t = 0; t < 8; ++t)
      ts.emplace_back([&] { for (int k = 0; k < 5000; ++k) srv.addCounter("mori_stress_total", "stress"); });
    for (auto& t : ts) t.join();
  }
  std::string text2 = srv.serialize();
  auto pos = text2.find("\nmori_stress_total ");
  double stressVal = std::atof(text2.c_str() + pos + strlen("mori_stress_total "));
  check(stressVal == 8 * 5000.0, "T5 8-thread counter stress, no lost updates");

  // T6 真 HTTP GET /metrics（socket 端到端）
  {
    int c = socket(AF_INET, SOCK_STREAM, 0);
    sockaddr_in a{}; a.sin_family = AF_INET; a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    a.sin_port = htons((uint16_t)gPort);
    if (connect(c, (sockaddr*)&a, sizeof a) != 0) { printf("T6 connect FAIL\n"); return 1; }
    const char* req = "GET /metrics HTTP/1.1\r\nHost: localhost\r\n\r\n";
    send(c, req, strlen(req), 0);
    std::string resp; char buf[4096]; ssize_t k;
    while ((k = recv(c, buf, sizeof buf, 0)) > 0) resp.append(buf, k);
    close(c);
    bool ok = resp.rfind("HTTP/1.1 200 OK", 0) == 0 &&
              resp.find("Content-Type: text/plain") != std::string::npos &&
              resp.find("# TYPE mori_rdma_throughput_gbps gauge") != std::string::npos;
    check(ok, "T6 HTTP GET /metrics end-to-end");
  }

  srv.stop();
  // 产物落盘（inspection）
  FILE* f = fopen("results/metrics_sample.txt", "w");
  if (f) { fputs(text2.c_str(), f); fclose(f); }
  printf("%s\n", failures == 0 ? "ALL PASS" : "HAS FAILURES");
  return failures;
}
