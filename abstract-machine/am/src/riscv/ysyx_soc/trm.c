#include <am.h>
#include <string.h>  // for memcpy, memset
#include <npc.h>
extern char _data_start[];
extern char _data_end[];
extern char _data_load[];

extern char _bss_start[];
extern char _bss_end[];

extern char _heap_start[];
extern char _pmem_start;

#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

Area heap = RANGE(&_heap_start, PMEM_END);
static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

void putch(char ch) {
  outb(SERIAL_PORT, ch);
}

void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : : "r"(code));
  while (1);
}

int main(const char *args);  // forward declaration

void _trm_init() {
  // 🟡 1. 拷贝 .data 段：从 MROM (_data_load) → SRAM (_data_start)
  size_t data_size = _data_end - _data_start;
  memcpy(_data_start, _data_load, data_size);

  // 🟡 2. 清零 .bss 段
  size_t bss_size = _bss_end - _bss_start;
  memset(_bss_start, 0, bss_size);

  // 🟡 3. 调用 C 程序入口
  int ret = main(mainargs);

  // 🟡 4. 退出模拟器（或挂起）
  halt(ret);
}