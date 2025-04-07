#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>
/*
user_handler 是一个函数指针

它指向的函数的参数有两个：

第一个参数类型是 Event

第二个参数类型是 Context*
*/
static Context* (*user_handler)(Event, Context*) = NULL;
//中断函数 __am_asm_trap 最终会调用 __am_irq_handle
/*
__am_asm_trap 是在 trap.S 文件中定义的中断入口汇编函数。它做的事情大致是：

保存所有寄存器（形成 Context）；

将 sp（即 Context*）传给 __am_irq_handle：
*/
//是在 trap 异常发生后，被中断入口的汇编代码主动调用的，并且参数 c 就是当时保存下来的上下文。
Context* __am_irq_handle(Context *c) {

  // printf("=== Trap Context ===\n");
  // printf("mepc    = 0x%08x\n", c->mepc);
  // printf("mcause  = 0x%08x\n", c->mcause);
  // printf("mstatus = 0x%08x\n", c->mstatus);

  // for (int i = 0; i < NR_REGS; i++) {
  //   printf("gpr[%d] = 0x%08x\n", i, c->gpr[i]);
  // }

  // // printf("pdir    = %p\n", c->pdir);
  // printf("====================\n");

  if (user_handler) {
    Event ev = {0};
    printf("%d\n", c->mcause);
    switch (c->mcause) {
      case -1:  ev.event = EVENT_YIELD;break;
      default: ev.event = EVENT_ERROR; break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));//设置 mtvec 寄存器为 __am_asm_trap 的地址 —— 也就是设置中断入口地址。

  // register event handler
  //user_handler 代表的是**“用户注册的中断处理函数”**
  user_handler = handler;

  return true;
}
/*
kstack 表示这个线程栈的起始红终止地址
void (*entry)(void *)：一个函数指针，表示这个线程将要运行的函数。
void *arg：传给 entry 函数的参数
*/
Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  Context *ctx = (Context *)((uintptr_t)kstack.end - sizeof(Context));
  memset(ctx, 0, sizeof(Context));  //把这块内存清零，防止出现未定义行为。
  ctx->mepc = (uintptr_t)entry;     // 设置程序计数器为线程入口
  ctx->gpr[10] = (uintptr_t)arg;    // a0 = arg
  ctx->mstatus = 0x1800;            // 设置 MIE=1, MPIE=1
  return ctx;
}

void yield() {
#ifdef __riscv_e
  asm volatile("li a5, -1; ecall");
#else
  asm volatile("li a7, -1; ecall");
#endif
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
}
