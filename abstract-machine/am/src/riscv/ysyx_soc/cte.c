#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  if (user_handler) {
    Event ev = {0};
    //  printf("%d\n", c->mcause);
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
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

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
