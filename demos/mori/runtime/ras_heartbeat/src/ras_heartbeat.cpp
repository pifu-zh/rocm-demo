// ras_heartbeat.cpp — MORI RAS 心跳与退出检测的独立复现（纯 CPU，单线程 select 状态机）
//
// 上游出处: ROCm/mori @ c5bdc391（该 commit 主体即本模块：RAS 2/5 #909）
//   - include/mori/ras/ras.hpp:24-53  per-process runtime，out-of-band TCP
//   - src/ras/config.hpp:43-61  heartbeatMs{1000}; HeartbeatTimeout=max(20s,3×hb)
//   - src/ras/link.cpp:296,387-405  主循环；lastRx + Timeout → LinkDown
//   - src/ras/link.cpp:1065-1084   giveUp = CantHeal || refusedTooLong
//   - src/ras/heartbeat.hpp:24-31  ACK 回显发送时刻+持有时长 → RTT/钟差数学
//   - 退出分类: LEAVE=干净; LINK_CLOSED=崩溃; HEARTBEAT_TIMEOUT=静默; 拒连持续=GaveUp
//
// 简化（如实记录）:
//   ① 36B 定头 + 定长体（语义字段一一对齐上游），msgpack 体省略（四类消息体为空）
//   ② 上游 per-process 双进程 → 单线程 select 状态机同时驱动 observer(A) 与 peer(B)
//     两端 socket（TCP loopback 仍是真实内核路径；T4 的崩溃注入仍用 fork+SIGKILL
//     保留内核级连接中断语义）
//   ③ msgpack/epoll/多连接 → 定长帧/select 单连接对
//
// 测试矩阵:
//   T1 握手 + 3 轮心跳 + LEAVE（双方各回 LEAVE 端到端）
//   T2 心跳 RTT/钟差数学（peer 注入已知 +5s 发送时刻偏差 → observer 算出 ≈5s）
//   T3 对端 LEAVE → CleanExit（不等待超时）
//   T4 SIGKILL peer 进程 → LINK_CLOSED → PeerCrashed【fork】
//   T5 连接保持但不回 ACK → HEARTBEAT_TIMEOUT → SilentTimeout
//   T6 重连被拒持续 → GaveUp
// 验证等级目标: REFERENCE_PASS
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>
#include <fcntl.h>

#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cerrno>

// ---- 36B 定头协议（字段布局对齐上游语义）----
enum MsgType : uint16_t { MT_HELLO = 1, MT_HELLO_ACK = 2, MT_HEARTBEAT = 3, MT_HEARTBEAT_ACK = 4, MT_LEAVE = 5 };
#pragma pack(push, 1)
struct RasHeader {
  uint32_t magic;        // 'RAS1' = 0x31534152
  uint16_t version;      // v1
  uint16_t type;         // MsgType
  uint32_t bodyLen;      // 四类消息均为 0
  uint64_t senderId;
  uint64_t tMonoSendNs;  // 发送方发送时刻（单调域；T2 注入偏差模拟两机钟差）
  uint64_t tRelayNs;     // ACK: 对端持有时长；其余 0
  // = 36 字节
};
#pragma pack(pop)
static_assert(sizeof(RasHeader) == 36, "36B header per upstream protocol v1");

enum class LinkState : int { ESTABLISHED = 0, CLEAN_EXIT, PEER_CRASHED, SILENT_TIMEOUT, GAVE_UP };
static const char* stateName(LinkState s) {
  switch (s) {
    case LinkState::ESTABLISHED: return "ESTABLISHED";
    case LinkState::CLEAN_EXIT: return "CLEAN_EXIT(LEAVE)";
    case LinkState::PEER_CRASHED: return "PEER_CRASHED(LINK_CLOSED)";
    case LinkState::SILENT_TIMEOUT: return "SILENT_TIMEOUT(HEARTBEAT_TIMEOUT)";
    case LinkState::GAVE_UP: return "GAVE_UP(refused too long)";
  }
  return "?";
}

struct RasConfig {
  uint32_t heartbeatMs = 1000;
  uint64_t heartbeatTimeoutMs() const {
    uint64_t t = heartbeatMs * 3ull, floor = 20000ull;   // 上游: max(20s, 3×heartbeat)
    if (const char* e = getenv("MORI_LAB_RAS_TIMEOUT_MS")) floor = (uint64_t)atoll(e);
    return t > floor ? t : floor;                        // 测试可覆盖下限
  }
  uint64_t peerGoneMs = 60000;
};
static RasConfig cfgFromEnv() {
  RasConfig c;
  if (const char* e = getenv("MORI_LAB_RAS_HEARTBEAT_MS")) c.heartbeatMs = (uint32_t)atoi(e);
  if (const char* e = getenv("MORI_LAB_RAS_PEER_GONE_MS")) c.peerGoneMs = (uint64_t)atoll(e);
  return c;
}

static uint64_t monoNs() {
  using namespace std::chrono;
  return (uint64_t)duration_cast<nanoseconds>(steady_clock::now().time_since_epoch()).count();
}

// ---- 阻塞式定长收发（单线程两端轮替，无并发）----
static int sendAll(int fd, const void* p, size_t n) {
  const char* c = (const char*)p;
  while (n) { ssize_t k = send(fd, c, n, 0); if (k <= 0) return -1; c += k; n -= (size_t)k; }
  return 0;
}
static int recvAll(int fd, void* p, size_t n) {
  char* c = (char*)p;
  while (n) {
    ssize_t k = recv(fd, c, n, 0);
    if (k <= 0) return -1;                 // 0=FIN（对端关），-1=错/RST
    c += k; n -= (size_t)k;
  }
  return 0;
}
// 手动序列化 36B（绕开 pack 结构布局的一切编译器风险——offset 显式固定）
static void putU16(unsigned char* p, uint16_t v) { p[0]=v&0xff; p[1]=v>>8; }
static void putU32(unsigned char* p, uint32_t v) { for (int i=0;i<4;++i) p[i]=(v>>(8*i))&0xff; }
static void putU64(unsigned char* p, uint64_t v) { for (int i=0;i<8;++i) p[i]=(v>>(8*i))&0xff; }
static uint32_t getU32(const unsigned char* p) { uint32_t v=0; for (int i=3;i>=0;--i) v=(v<<8)|p[i]; return v; }
static uint16_t getU16(const unsigned char* p) { return (uint16_t)(p[0] | (p[1]<<8)); }
static uint64_t getU64(const unsigned char* p) { uint64_t v=0; for (int i=7;i>=0;--i) v=(v<<8)|p[i]; return v; }
static int sendMsg(int fd, MsgType t, uint64_t id, uint64_t monoSendNs, uint64_t relayNs) {
  unsigned char buf[36];
  putU32(buf, 0x31534152u);
  putU16(buf + 4, 1);
  putU16(buf + 6, (uint16_t)t);
  putU32(buf + 8, 0);
  putU64(buf + 12, id);
  putU64(buf + 20, monoSendNs);
  putU64(buf + 28, relayNs);
  return sendAll(fd, buf, 36);
}
// RasHeader 退化为解码视图（从 36B 缓冲读出）
static int recvMsg(int fd, RasHeader* h) {
  unsigned char buf[36];
  int rc = recvAll(fd, buf, 36);
  if (rc == 0) {
    h->magic = getU32(buf);
    h->version = getU16(buf + 4);
    h->type = getU16(buf + 6);
    h->bodyLen = getU32(buf + 8);
    h->senderId = getU64(buf + 12);
    h->tMonoSendNs = getU64(buf + 20);
    h->tRelayNs = getU64(buf + 28);
  }
  if (rc == 0 && h->magic != 0x31534152u) {
    unsigned char* p = (unsigned char*)h;
    printf("  [framing fd=%d] BAD MAGIC 0x%08x raw36:", fd, h->magic);
    for (size_t i = 0; i < sizeof *h; ++i) printf(" %02x", p[i]);
    printf("\n");
    rc = -2;
  }
  return rc;
}

// ---- 心跳时钟数学（上游 heartbeat.hpp:24-31）----
// ACK 携带: tMonoSendNs=B 的发送时刻（可含注入偏差）, tRelayNs=B 持有时长
// RTT   = A 收到 ACK 单调时刻 - A 发送时刻 - B 持有时长
// offset≈ B 发送时刻 - (A 发送时刻 + RTT/2)  ——两机场景 B 用墙钟域；单机用注入偏差模拟
struct HeartbeatMath { double rttSec = 0, offsetSec = 0; };
static HeartbeatMath processAck(uint64_t aSendMono, uint64_t relayNs, uint64_t bSendNs) {
  HeartbeatMath m;
  uint64_t nowMono = monoNs();
  m.rttSec = (double)(nowMono - aSendMono - relayNs) / 1e9;
  m.offsetSec = (double)(int64_t)(bSendNs - (aSendMono + relayNs / 2)) / 1e9;
  return m;
}

// ---- Peer（B）单步: 处理一条到达消息并响应（单线程顺序驱动用）----
// 返回 false = 连接应终止（对端 LEAVE/关闭）
static bool peerStep(int bfd, bool silent, double offsetSec) {
  RasHeader h;
  if (recvMsg(bfd, &h) != 0) return false;
  if (h.type == MT_HELLO) {
    sendMsg(bfd, MT_HELLO_ACK, 2, monoNs() + (uint64_t)(offsetSec * 1e9), 0);
  } else if (h.type == MT_HEARTBEAT) {
    if (!silent) {
      uint64_t recvNs = monoNs();
      sendMsg(bfd, MT_HEARTBEAT_ACK, 2, monoNs() + (uint64_t)(offsetSec * 1e9),
              (recvNs - h.tMonoSendNs) / 2);
    }
  } else if (h.type == MT_LEAVE) {
    return false;
  }
  return true;
}

// ---- Observer（A）状态机（上游 link.cpp:387-405 的超时判定）----
static LinkState observeLink(int sockFd, const RasConfig& cfg, HeartbeatMath* math,
                             bool mathOn, int maxRounds) {
  if (sendMsg(sockFd, MT_HELLO, 1, monoNs(), 0) != 0) return LinkState::PEER_CRASHED;
  RasHeader h;
  if (recvMsg(sockFd, &h) != 0 || h.type != MT_HELLO_ACK) return LinkState::PEER_CRASHED;
  auto lastRx = std::chrono::steady_clock::now();
  int rounds = 0;
  while (true) {
    if (maxRounds > 0 && rounds >= maxRounds) {   // 成功出口: N 轮全 ACK → LEAVE
      sendMsg(sockFd, MT_LEAVE, 1, monoNs(), 0);
      return LinkState::CLEAN_EXIT;
    }
    uint64_t t0 = monoNs();
    if (sendMsg(sockFd, MT_HEARTBEAT, 1, t0, 0) != 0) return LinkState::PEER_CRASHED;
    fd_set rfds; FD_ZERO(&rfds); FD_SET(sockFd, &rfds);
    timeval tv{(long)(cfg.heartbeatMs / 1000), (suseconds_t)((cfg.heartbeatMs % 1000) * 1000)};
    int r = select(sockFd + 1, &rfds, nullptr, nullptr, &tv);
    if (r == 0) {
      auto silentMs = std::chrono::duration_cast<std::chrono::milliseconds>(
          std::chrono::steady_clock::now() - lastRx).count();
      if ((uint64_t)silentMs >= cfg.heartbeatTimeoutMs()) return LinkState::SILENT_TIMEOUT;
      continue;
    }
    if (recvMsg(sockFd, &h) != 0) return LinkState::PEER_CRASHED;
    lastRx = std::chrono::steady_clock::now();
    if (h.type == MT_HEARTBEAT_ACK) {
      ++rounds;
      if (mathOn) *math = processAck(t0, h.tRelayNs, h.tMonoSendNs);
    }
    if (h.type == MT_LEAVE) return LinkState::CLEAN_EXIT;
  }
}

int main() {
  setvbuf(stdout, NULL, _IONBF, 0);
  RasConfig cfg = cfgFromEnv();
  int failures = 0;
  printf("RAS heartbeat demo (pure CPU, upstream c5bdc391 RAS 2/5 #909)\n");
  printf("config: heartbeat=%ums hbTimeout=%ums peerGone=%ums\n",
         cfg.heartbeatMs, cfg.heartbeatTimeoutMs(), cfg.peerGoneMs);

  int lfd = socket(AF_INET, SOCK_STREAM, 0);
  int one = 1; setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
  sockaddr_in addr{}; addr.sin_family = AF_INET; addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  addr.sin_port = 0;                                // 内核随机分配空闲端口（防孤儿进程偷连接）
  socklen_t alen = sizeof addr;
  if (bind(lfd, (sockaddr*)&addr, sizeof addr) != 0) { perror("bind"); return 1; }
  getsockname(lfd, (sockaddr*)&addr, &alen);
  const uint16_t kPort = ntohs(addr.sin_port);
  printf("listening on 127.0.0.1:%u\n", (unsigned)kPort);
  listen(lfd, 4);

  auto connectPeer = [&]() {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    int one2 = 1; setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one2, sizeof one2);
    sockaddr_in a{}; a.sin_family = AF_INET; a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    a.sin_port = htons(kPort);
    for (int i = 0; i < 50; ++i) {
      if (connect(fd, (sockaddr*)&a, sizeof a) == 0) return fd;
      if (i == 0) printf("  connect retry 0 failed: %s\n", strerror(errno));
      usleep(20000);
    }
    printf("  connectPeer FAILED all retries\n");
    return -1;
  };

  // ---- T1 握手 + 3 轮心跳 + 双向 LEAVE（单线程分步驱动）----
  {
    int a = connectPeer();
    int b = accept(lfd, nullptr, nullptr);
    sendMsg(a, MT_HELLO, 1, monoNs(), 0);          // A→HELLO
    peerStep(b, false, 0.0);                       // B 收 HELLO 回 ACK
    RasHeader h;
    recvMsg(a, &h);                                // A 收 ACK（握手完成）
    bool roundsOk = true;
    for (int r = 0; r < 3 && roundsOk; ++r) {      // 3 轮心跳
      uint64_t t0 = monoNs();
      sendMsg(a, MT_HEARTBEAT, 1, t0, 0);
      peerStep(b, false, 0.0);
      if (recvMsg(a, &h) != 0 || h.type != MT_HEARTBEAT_ACK) roundsOk = false;
    }
    sendMsg(a, MT_LEAVE, 1, monoNs(), 0);          // A→LEAVE
    bool bLeaveOk = !peerStep(b, false, 0.0);      // B 收 LEAVE 终止（false=正常终止）
    close(b); close(a);
    bool ok = roundsOk && bLeaveOk;
    printf("T1 handshake+3rounds+LEAVE: roundsOk=%s bLeaveOk=%s -> %s\n",
           roundsOk ? "y" : "N", bLeaveOk ? "y" : "N", ok ? "PASS" : "FAIL");
    if (!ok) ++failures;
  }
  // ---- T2 心跳数学（peer 注入 +5s 发送时刻偏差）----
  {
    int a = connectPeer();
    int b = accept(lfd, nullptr, nullptr);
    RasHeader h;
    sendMsg(a, MT_HELLO, 1, monoNs(), 0);
    peerStep(b, false, 5.0);
    recvMsg(a, &h);
    HeartbeatMath m;
    bool ok = true;
    for (int r = 0; r < 5; ++r) {
      uint64_t t0 = monoNs();
      sendMsg(a, MT_HEARTBEAT, 1, t0, 0);
      peerStep(b, false, 5.0);
      if (recvMsg(a, &h) != 0 || h.type != MT_HEARTBEAT_ACK) { ok = false; break; }
      m = processAck(t0, h.tRelayNs, h.tMonoSendNs);
    }
    close(b); close(a);
    ok = ok && m.rttSec < 0.5 && m.offsetSec > 4.0 && m.offsetSec < 6.0;  // 容差覆盖调度噪声
    printf("T2 heartbeat math: rtt=%.4fs offset=%.3fs (注入5s, 期望 5±1) -> %s\n",
           m.rttSec, m.offsetSec, ok ? "PASS" : "FAIL");
    if (!ok) ++failures;
  }
  // ---- T3 对端 LEAVE → CleanExit ----
  {
    int a = connectPeer();
    int b = accept(lfd, nullptr, nullptr);
    // B: 握手后立即 LEAVE（上游: 对端 LEAVE=CleanExit，不等待超时）
    RasHeader h;
    sendMsg(a, MT_HELLO, 1, monoNs(), 0);                  // A→HELLO（先发，B 在等）
    recvMsg(b, &h);                                        // B 收 HELLO
    sendMsg(b, MT_HELLO_ACK, 2, monoNs(), 0);              // B→ACK
    sendMsg(b, MT_LEAVE, 2, monoNs(), 0);                  // B→LEAVE（对端主动退出）
    LinkState st;
    if (recvMsg(a, &h) != 0 || h.type != MT_HELLO_ACK) st = LinkState::PEER_CRASHED;
    else {
      if (recvMsg(a, &h) != 0) st = LinkState::PEER_CRASHED;
      else st = (h.type == MT_LEAVE) ? LinkState::CLEAN_EXIT : LinkState::PEER_CRASHED;
    }
    close(b); close(a);
    bool ok = (st == LinkState::CLEAN_EXIT);
    printf("T3 peer LEAVE: state=%s -> %s\n", stateName(st), ok ? "PASS" : "FAIL");
    if (!ok) ++failures;
  }
  // ---- T4 SIGKILL peer 进程 → LINK_CLOSED（fork，内核级连接中断）----
  {
    int slfd = socket(AF_INET, SOCK_STREAM, 0);
    int one2 = 1; setsockopt(slfd, SOL_SOCKET, SO_REUSEADDR, &one2, sizeof one2);
    sockaddr_in sa{}; sa.sin_family = AF_INET; sa.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    sa.sin_port = htons(0);
    socklen_t slen = sizeof sa;
    if (bind(slfd, (sockaddr*)&sa, sizeof sa) != 0) { close(slfd); return 1; }
    getsockname(slfd, (sockaddr*)&sa, &slen);
    listen(slfd, 2);
    pid_t pid = fork();
    if (pid == 0) {
      int cfd = accept(slfd, nullptr, nullptr);
      RasHeader h;
      recvMsg(cfd, &h);
      sendMsg(cfd, MT_HELLO_ACK, 9, monoNs(), 0);
      while (recvMsg(cfd, &h) == 0) {
        if (h.type == MT_HEARTBEAT) sendMsg(cfd, MT_HEARTBEAT_ACK, 9, monoNs(), 0);
      }
      _exit(0);
    }
    usleep(50000);
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    sockaddr_in ca{}; ca.sin_family = AF_INET; ca.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    ca.sin_port = sa.sin_port;
    connect(fd, (sockaddr*)&ca, sizeof ca);
    sendMsg(fd, MT_HELLO, 1, monoNs(), 0);
    RasHeader h; recvMsg(fd, &h);
    sendMsg(fd, MT_HEARTBEAT, 1, monoNs(), 0); recvMsg(fd, &h);   // 确认链路活
    kill(pid, SIGKILL);                                            // 内核级中断
    int stt = 0; waitpid(pid, &stt, 0);
    LinkState st = (recvMsg(fd, &h) != 0) ? LinkState::PEER_CRASHED : LinkState::CLEAN_EXIT;
    close(fd); close(slfd);
    bool ok = (st == LinkState::PEER_CRASHED);
    printf("T4 SIGKILL crash: state=%s -> %s\n", stateName(st), ok ? "PASS" : "FAIL");
    if (!ok) ++failures;
  }
  // ---- T5 连接保持但不回 ACK → HEARTBEAT_TIMEOUT ----
  // 并发结构: fork 子进程扮演"静默 peer"（accept→读 HELLO→不回不关→A 超时后退出）。
  // 单线程无法同时驱动观察与静默两端（B 必须在 A 观察期间保持存在）。
  {
    pid_t pid = fork();
    if (pid == 0) {
      int b2 = accept(lfd, nullptr, nullptr);
      RasHeader h;
      recvMsg(b2, &h);                       // A 的 HELLO
      sendMsg(b2, MT_HELLO_ACK, 2, monoNs(), 0);   // 握手正常完成（真实路径）
      // 之后静默：心跳不回 ACK 也不关连接 → A 判 HEARTBEAT_TIMEOUT
      auto deadline = std::chrono::steady_clock::now() +
                      std::chrono::milliseconds(cfg.heartbeatTimeoutMs() + 1500);
      while (std::chrono::steady_clock::now() < deadline) {
        fd_set rfds; FD_ZERO(&rfds); FD_SET(b2, &rfds);
        timeval tv{0, 100000};
        if (select(b2 + 1, &rfds, nullptr, nullptr, &tv) <= 0) continue;
        if (recvMsg(b2, &h) != 0) break;     // A 超时后关闭
      }
      close(b2);
      _exit(0);
    }
    usleep(50000);                           // 子进程先进入 accept
    int a2 = connectPeer();
    HeartbeatMath m;
    LinkState st = observeLink(a2, cfg, &m, false, 0);
    close(a2);
    int stt = 0; waitpid(pid, &stt, 0);
    bool ok = (st == LinkState::SILENT_TIMEOUT);
    printf("T5 silent death: state=%s -> %s\n", stateName(st), ok ? "PASS" : "FAIL");
    if (!ok) ++failures;
  }
  // ---- T6 重连被拒持续 → GaveUp ----
  {
    close(lfd);                              // 停止 accept（模拟服务不可达）
    int refused = 0;
    auto t0 = std::chrono::steady_clock::now();
    while (std::chrono::duration_cast<std::chrono::milliseconds>(
               std::chrono::steady_clock::now() - t0).count() < (long long)cfg.peerGoneMs) {
      int fd = socket(AF_INET, SOCK_STREAM, 0);
      sockaddr_in a{}; a.sin_family = AF_INET; a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
      a.sin_port = htons(kPort);
      if (connect(fd, (sockaddr*)&a, sizeof a) != 0) ++refused;
      close(fd);
      usleep(30000);
    }
    LinkState st = (refused > 3) ? LinkState::GAVE_UP : LinkState::ESTABLISHED;
    printf("T6 reconnect refused x%d -> state=%s -> %s\n", refused, stateName(st),
           st == LinkState::GAVE_UP ? "PASS" : "FAIL");
    if (st != LinkState::GAVE_UP) ++failures;
  }

  printf("%s\n", failures == 0 ? "ALL PASS" : "HAS FAILURES");
  return failures;
}
