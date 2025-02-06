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

#include <cpu/cpu.h>
#include <cpu/decode.h>
#include <cpu/difftest.h>
#include <locale.h>

/* The assembly code of instructions executed is only output to the screen
 * when the number of instructions executed is less than this value.
 * This is useful when you use the `si' command.
 * You can modify this value as you want.
  当执行的指令数小于该值时，指令的汇编代码会被打印到屏幕上。
 * 主要用于 `si` (单步执行) 调试命令，可以根据需求修改该值。

 */
#define MAX_INST_TO_PRINT 10 //这是一个常量，定义了当执行的指令数小于该值时，指令的汇编代码会被打印到屏幕上。通常用于调试时逐步执行
#define CONFIG_WATCHPOINT   //监视点开关
CPU_state cpu = {};          //代表当前 CPU 状态的结构体
uint64_t g_nr_guest_inst = 0;//跟踪执行的总指令数
static uint64_t g_timer = 0; // unit: us  // 记录仿真所用时间（单位：微秒）
static bool g_print_step = false;  // 是否打印单步执行信息

void device_update();
void scan_watchpoint();

/* 进行指令执行跟踪和差分测试 */
static void trace_and_difftest(Decode *_this, vaddr_t dnpc) {
#ifdef CONFIG_ITRACE_COND
  if (ITRACE_COND) { log_write("%s\n", _this->logbuf); }  // 条件触发时，记录指令信息
#endif
  if (g_print_step) { IFDEF(CONFIG_ITRACE, puts(_this->logbuf)); }  //是否打印指令信息
  IFDEF(CONFIG_DIFFTEST, difftest_step(_this->pc, dnpc));           //进行差分测试
#ifdef CONFIG_WATCHPOINT
  scan_watchpoint();
#endif
}

/* 执行单条指令 */
static void exec_once(Decode *s, vaddr_t pc) {
  s->pc = pc;       ///设置当前指令
  s->snpc = pc;     //设置下一条指令
  isa_exec_once(s); //进行指令执行
  cpu.pc = s->dnpc; //更新cpu的pc
#ifdef CONFIG_ITRACE
//记录执行日志
  char *p = s->logbuf;
  p += snprintf(p, sizeof(s->logbuf), FMT_WORD ":", s->pc);
  int ilen = s->snpc - s->pc;
  int i;
  uint8_t *inst = (uint8_t *)&s->isa.inst;
#ifdef CONFIG_ISA_x86
  for (i = 0; i < ilen; i ++) {       // x86指令从低字节到高字节打印
#else
  for (i = ilen - 1; i >= 0; i --) {   // 其他 ISA 指令从高字节到低字节打印
#endif
    p += snprintf(p, 4, " %02x", inst[i]); // 记录指令的二进制代码
  }
  //对齐格式，使指令显示更加美观
  int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
  int space_len = ilen_max - ilen;
  if (space_len < 0) space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

//进行反汇编，获取指令的汇编代码
  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(p, s->logbuf + sizeof(s->logbuf) - p,
      MUXDEF(CONFIG_ISA_x86, s->snpc, s->pc), (uint8_t *)&s->isa.inst, ilen);
#endif
}

/* 执行 n 条指令 */
static void execute(uint64_t n) {
  Decode s;
  for (;n > 0; n --) {
    exec_once(&s, cpu.pc); //执行单条指令
    g_nr_guest_inst ++;    //指令计数器+1
    trace_and_difftest(&s, cpu.pc); //记录跟踪信息并进行差分测试
    if (nemu_state.state != NEMU_RUNNING) break;
    IFDEF(CONFIG_DEVICE, device_update());
  }
}

static void statistic() {
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
}

void assert_fail_msg() {
  isa_reg_display();
  statistic();
}

/* Simulate how the CPU works. */
void cpu_exec(uint64_t n) {
  g_print_step = (n < MAX_INST_TO_PRINT);
  switch (nemu_state.state) {
    case NEMU_END: case NEMU_ABORT: case NEMU_QUIT:
      printf("Program execution has ended. To restart the program, exit NEMU and run again.\n");
      return;
    default: nemu_state.state = NEMU_RUNNING;
  }

  uint64_t timer_start = get_time();

  execute(n);

  uint64_t timer_end = get_time();
  g_timer += timer_end - timer_start;

  switch (nemu_state.state) {
    case NEMU_RUNNING: nemu_state.state = NEMU_STOP; break;

    case NEMU_END: case NEMU_ABORT:
      Log("nemu: %s at pc = " FMT_WORD,
          (nemu_state.state == NEMU_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
           (nemu_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
            ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
          nemu_state.halt_pc);
      // fall through
    case NEMU_QUIT: statistic();
  }
}
