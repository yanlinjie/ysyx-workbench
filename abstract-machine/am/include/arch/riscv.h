#ifndef ARCH_H__
#define ARCH_H__

#ifdef __riscv_e
#define NR_REGS 16
#else
#define NR_REGS 32
#endif

struct Context {
  uintptr_t gpr[NR_REGS];  // 先保存所有 GPR
  uintptr_t mcause;        // 然后 mcause
  uintptr_t mstatus;       // 然后 mstatus
  uintptr_t mepc;          // 然后 mepc
  void *pdir;              // 最后是虚表地址（由软件设置）
};


// struct Context {
//   // TODO: fix the order of these members to match trap.S
//   uintptr_t mepc, mcause, gpr[NR_REGS], mstatus;
//   void *pdir;
// };

#ifdef __riscv_e
#define GPR1 gpr[15] // a5
#else
#define GPR1 gpr[17] // a7
#endif

#define GPR2 gpr[0]
#define GPR3 gpr[0]
#define GPR4 gpr[0]
#define GPRx gpr[0]

#endif
