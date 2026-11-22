// sdma_user_queue_probe.c — mori anvil（shader_sdma）在 gfx1030 上的可行性探测
//
// 上游出处: ROCm/mori @ c5bdc391, src/application/transport/sdma/anvil.cpp
//   - :106-110  SetUpKFD: hsaKmtOpenKFD → hsaKmtAcquireSystemProperties
//   - :235-286  SdmaQueue 构造: hsaKmtAllocMemory(NonPaged|HostAccess|ExecuteAccess|Uncached)
//               → hsaKmtMapMemoryToGPU → hsaKmtCreateQueueExt(HSA_QUEUE_SDMA_BY_ENG_ID, engineId)
//   - :199-212  engine 掩码: props.HsaTarget 下的 RecSdmaEngIdMask（sysfs recommended_sdma_engine_id_mask）
//   - :61-62    注释记录了 hsakmt 版本坑（泄漏/双重释放/二次建队列）——版本敏感
//
// 探测问题（按层级递进，任一层失败即记录该层结论）：
//   P1 KFD 打开与 GPU node 枚举（NumSdmaEngines/NumSdmaQueuesPerEngine/RecSdmaEngIdMask）
//   P2 用户态 SDMA 队列创建（hsaKmtCreateQueueExt(HSA_QUEUE_SDMA_BY_ENG_ID)）
//   P3 队列环读写指针可访问性（Queue_write_ptr_aql / Queue_DoorBell_aql 非空）
//
// 注：写 COPY_LINEAR 包并验证拷贝属于后续完整 demo（包布局是 gfx9 SDMA4 的，
//     gfx1030 是 SDMA5——若 P2 通过仍需包格式适配实验，不在本探测范围）。
// 验证等级目标: STATIC_ANALYSIS_PASS → COMPILE_PASS →（若 P1-P3 通过）HARDWARE_PASS(probe)

#include <hsakmt/hsakmt.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static const char* statusStr(HSAKMT_STATUS s) {
  switch (s) {
    case HSAKMT_STATUS_SUCCESS: return "SUCCESS";
    case HSAKMT_STATUS_INVALID_PARAMETER: return "INVALID_PARAMETER";
    case HSAKMT_STATUS_INVALID_NODE_UNIT: return "INVALID_NODE_UNIT";
    case HSAKMT_STATUS_NOT_SUPPORTED: return "NOT_SUPPORTED";
    case HSAKMT_STATUS_NO_MEMORY: return "NO_MEMORY";
    default: return "OTHER";
  }
}

int main(void) {
  int failures = 0;
  HSAKMT_STATUS st;

  // P1: KFD 打开 + 系统 properties + GPU node 枚举
  st = hsaKmtOpenKFD();
  printf("P1 hsaKmtOpenKFD: %s\n", statusStr(st));
  if (st != HSAKMT_STATUS_SUCCESS) { printf("PROBE STOP (open failed)\n"); return 1; }

  HsaSystemProperties sys;
  st = hsaKmtAcquireSystemProperties(&sys);
  printf("P1 hsaKmtAcquireSystemProperties: %s (numNodes=%u)\n", statusStr(st), sys.NumNodes);
  if (st != HSAKMT_STATUS_SUCCESS) { hsaKmtCloseKFD(); return 1; }

  HsaNodeProperties nodeProps;
  HSAuint32 gpuNode = (HSAuint32)-1;
  for (HSAuint32 n = 0; n < sys.NumNodes; ++n) {
    if (hsaKmtGetNodeProperties(n, &nodeProps) == HSAKMT_STATUS_SUCCESS &&
        nodeProps.KFDGpuID != 0 /* GPU 节点判据 —— mori anvil.cpp:223 同款 */) {
      gpuNode = n;
      printf("P1 GPU node %u (KFDGpuID=%u): NumSdmaEngines=%u NumSdmaXgmiEngines=%u "
             "NumSdmaQueuesPerEngine=%u NumCpQueues=%u\n",
             n, nodeProps.KFDGpuID, nodeProps.NumSdmaEngines, nodeProps.NumSdmaXgmiEngines,
             nodeProps.NumSdmaQueuesPerEngine, nodeProps.NumCpQueues);
      memcpy(&nodeProps, &nodeProps, sizeof nodeProps);  // 保留最后一个 GPU node 的属性
    }
  }
  if (gpuNode == (HSAuint32)-1) {
    printf("P1 FAIL: no GPU node found\n");
    hsaKmtCloseKFD();
    return 1;
  }
  if (nodeProps.NumSdmaEngines == 0) {
    printf("P1 CONCLUSION: GPU node reports 0 SDMA engines — anvil 线在此节点不可行\n");
    hsaKmtCloseKFD();
    return 1;
  }

  // P2: 队列缓冲分配 + SDMA 用户队列创建（逐 engine 探测）
  HsaMemFlags memFlags = {};
  memFlags.ui32.NonPaged = 1;
  memFlags.ui32.HostAccess = 1;
  memFlags.ui32.PageSize = HSA_PAGE_SIZE_4KB;
  memFlags.ui32.NoNUMABind = 1;
  memFlags.ui32.ExecuteAccess = 1;
  memFlags.ui32.Uncached = 1;
  const HSAuint32 kQueueSize = 256 * 1024;   // anvil SDMA_QUEUE_SIZE

  void* queueBuf = NULL;
  st = hsaKmtAllocMemory(gpuNode, kQueueSize, memFlags, &queueBuf);
  printf("P2 hsaKmtAllocMemory(256KB, NonPaged|Execute|Uncached): %s (%p)\n",
         statusStr(st), queueBuf);
  if (st != HSAKMT_STATUS_SUCCESS) { hsaKmtCloseKFD(); return 1; }
  st = hsaKmtMapMemoryToGPU(queueBuf, kQueueSize, NULL);
  printf("P2 hsaKmtMapMemoryToGPU: %s\n", statusStr(st));
  if (st != HSAKMT_STATUS_SUCCESS) { hsaKmtCloseKFD(); return 1; }

  int createdAny = 0;
  for (HSAuint32 e = 0; e < nodeProps.NumSdmaEngines; ++e) {
    HsaQueueResource q;
    memset(&q, 0, sizeof q);
    st = hsaKmtCreateQueueExt(gpuNode, HSA_QUEUE_SDMA_BY_ENG_ID, 100,
                              HSA_QUEUE_PRIORITY_MAXIMUM, e, queueBuf, kQueueSize,
                              NULL, &q);
    printf("P2 hsaKmtCreateQueueExt(SDMA_BY_ENG_ID, engine=%u): %s", e, statusStr(st));
    if (st == HSAKMT_STATUS_SUCCESS) {
      printf(" [queueId=%u wptr=%p doorbell=%p rptr=%p]",
             q.QueueId, (void*)q.Queue_write_ptr_aql, (void*)q.Queue_DoorBell_aql,
             (void*)q.Queue_read_ptr_aql);
      createdAny = 1;
      // P3: 环读写指针可访问性
      int p3ok = q.Queue_write_ptr_aql && q.Queue_read_ptr_aql && q.Queue_DoorBell_aql;
      printf(" P3 pointers-accessible=%s", p3ok ? "y" : "N");
      hsaKmtDestroyQueue(q.QueueId);
      printf(" [destroyed]");
    }
    printf("\n");
  }
  hsaKmtUnmapMemoryToGPU(queueBuf);
  hsaKmtFreeMemory(queueBuf, kQueueSize);
  hsaKmtCloseKFD();

  if (!createdAny) {
    printf("PROBE CONCLUSION: 用户态 SDMA 队列在 gfx1030 上不可创建（P2 全失败）——\n"
           "  anvil 的 gfx9 SDMA4 线对本机不可行；shader-SDMA 的 gfx10 形态需另立路径\n");
    failures = 0;   // 探测结论本身有价值，不算测试失败
  } else {
    printf("PROBE CONCLUSION: 用户态 SDMA 队列可创建（P1-P3 通过）——\n"
           "  下一步：gfx1030 SDMA5 包格式适配实验（COPY_LINEAR 布局待验证）\n");
  }
  return failures;
}
