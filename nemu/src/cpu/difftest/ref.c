/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if (direction == DIFFTEST_TO_REF) {
    // printf("[DIFFTEST_MEMCPY] TO REF: addr = 0x%08x, size = %lu\n", addr, n);
    // for (size_t i = 0; i < n; i += 4) {
    //   uint32_t val = *(uint32_t *)((uint8_t *)buf + i);
    //   printf("  write addr = 0x%08x, data = 0x%08x\n", (uint32_t)(addr + i), val);

    // }
    memcpy(guest_to_host(addr), buf, n);
  } else {
    // printf("[DIFFTEST_MEMCPY] TO DUT: addr = 0x%08x, size = %lu\n", addr, n);
    // for (size_t i = 0; i < n; i += 4) {
    //   uint32_t val = *(uint32_t *)(guest_to_host(addr + i));
    //   printf("  read  addr = 0x%08x, data = 0x%08x\n", addr + i, val);
    // }
    memcpy(buf, guest_to_host(addr), n);
  }
}


__EXPORT void difftest_regcpy(void *dut, bool direction) {
  if (direction == DIFFTEST_TO_REF) {
    memcpy(&cpu, dut, sizeof(CPU_state));
  } else {
    memcpy(dut, &cpu, sizeof(CPU_state));
  }
  // assert(0);
}

__EXPORT void difftest_exec(uint64_t n) {
  while (n--) {
    cpu_exec(1);  // REF 执行一条指令
  }
  // assert(0);
}

//中断，暂时不用管
__EXPORT void difftest_raise_intr(word_t NO) {
  assert(0);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  init_mem();
  /* Perform ISA dependent initialization. */
  init_isa();
}
