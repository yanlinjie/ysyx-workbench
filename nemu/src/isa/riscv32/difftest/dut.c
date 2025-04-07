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
#include <cpu/difftest.h>
#include "../local-include/reg.h"

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  int reg_num = ARRLEN(cpu.gpr);
  bool ok = true;

  for (int i = 0; i < reg_num; i++) {
    if (ref_r->gpr[i] != cpu.gpr[i]) {
      ok = false;
      break;  // 一旦发现不一致就准备打印全部
    }
  }

  if (ref_r->pc != cpu.pc) {
    ok = false;
  }

  if (!ok) {
    printf("========== [DIFFTEST FAIL] ==========\n");
    ring_buffer_print(&rb, cpu.pc);
    printf("Mismatch detected at PC = 0x%08x\n", cpu.pc);
    printf("\n%-8s%-15s%-15s\n", "Reg", "REF", "DUT");
    for (int i = 0; i < reg_num; i++) {
      printf("x%-7d0x%08x     0x%08x\n", i, ref_r->gpr[i], cpu.gpr[i]);
    }

    printf("PC        : ref = 0x%08x, dut = 0x%08x\n", ref_r->pc, cpu.pc);
    printf("======================================\n");
  }

  return ok;
}


// bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
//   int reg_num = ARRLEN(cpu.gpr);
//   for (int i = 0; i < reg_num; i++) {
//     if (ref_r->gpr[i] != cpu.gpr[i]) {
//       return false;
//     }
//   }
//   if (ref_r->pc != cpu.pc) {
//     return false;
//   }

//   return true;
// }

void isa_difftest_attach() {
}
