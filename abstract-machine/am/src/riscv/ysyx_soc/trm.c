#include <am.h>
#include <npc.h>
#include <klib.h>
#include <klib-macros.h>

#define UART_BASE     0x10000000L

#define UART_RBR_THR  (*(volatile uint8_t *)(UART_BASE + 0x00)) // 接收/发送寄存器
#define UART_IER      (*(volatile uint8_t *)(UART_BASE + 0x01))
#define UART_LCR      (*(volatile uint8_t *)(UART_BASE + 0x03))
#define UART_LSR      (*(volatile uint8_t *)(UART_BASE + 0x05))
#define UART_DLL      (*(volatile uint8_t *)(UART_BASE + 0x00)) // 波特率除数低
#define UART_DLM      (*(volatile uint8_t *)(UART_BASE + 0x01)) // 波特率除数高
#define UART_FCR      (*(volatile uint8_t *)(UART_BASE + 0x02))


extern uint8_t _data_lma[];
extern uint8_t _data_end[];

extern uint8_t _bss_start[];
extern uint8_t _bss_end[];

extern uint8_t _heap_start[];
extern uint8_t _heap_end[];




extern uint8_t _main_lma[];
extern uint8_t _main_start[];
extern uint8_t _main_end[];

extern uint8_t _rodata_lma[];
extern uint8_t _rodata_start[];
extern uint8_t _rodata_end[];


extern uint8_t _bss_start[];

extern uint8_t _trm_init_lma[];
extern uint8_t sram_trm_init_start[];
extern uint8_t sram_bootloader_end[];


void uart_init() {
  // 1. 设置DLAB=1，准备设置波特率除数
  UART_LCR = 0x80; // DLAB=1

  // 2. 设置波特率除数 (例如：50MHz / (16 * 27) ≈ 115200)
  UART_DLL = 1;   // 除数低字节
  UART_DLM = 0;    // 除数高字节

  // 3. 清除DLAB，配置为 8位数据，无校验，1停止位
  UART_LCR = 0x03; // 8-bit, no parity, 1 stop bit, DLAB=0

  // 4. 打开 FIFO
  UART_FCR = 0x07; // Enable FIFO, clear TX & RX

  // 5. （可选）关闭所有中断
  UART_IER = 0x00;
}


__attribute__((section(".sram_first_bootloader")))
void first_bootloader() {

      uint32_t *src, *dst;

      src = (uint32_t *)_trm_init_lma;
      dst = (uint32_t *)sram_trm_init_start;
      while (dst < (uint32_t *)sram_bootloader_end) {
          *dst++ = *src++;
      }
}

__attribute__((section(".sram_bootloader")))
void bootloader() {
    // 手动拷贝 .data 段到 SRAM
    //手动拷贝，不要调用函数
    uint32_t *src, *dst;
    src = (uint32_t *)_main_lma;
    dst = (uint32_t *)_main_start;
    while (dst < (uint32_t *)_bss_start) {
        *dst++ = *src++;
    }

    // src = (uint32_t *)_rodata_lma;
    // dst = (uint32_t *)_rodata_start;
    // while (dst < (uint32_t *)_rodata_end) {
    //     *dst++ = *src++;
    // }

    // src = (uint32_t *)_data_lma;
    // dst = (uint32_t *)_rodata_end;
    // while (dst < (uint32_t *)_bss_start) {
    //     *dst++ = *src++;
    // }


    // 手动清零 .bss 段
    dst = (uint32_t *)_bss_start;
    while (dst < (uint32_t *)_bss_end) {
        *dst++ = 0;
    }



}

Area heap = RANGE(&_heap_start, &_heap_end);

static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

void putch(char ch) {
  // 等待发送器空闲（LSR[5] = 1）

  while ((UART_LSR & (1 << 5)) == 0);  // 等待发送器准备好
  UART_RBR_THR = ch;
}


void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : : "r"(code));
  while (1);
}

int main(const char *args);  
__attribute__((section(".sram_trm_init")))
void _trm_init() {


  bootloader();

  uart_init();
  
  // printf("_main_lma: 0x%x \n", _main_lma);
  // printf("_main_start: 0x%x \n", _main_start);
  // printf("_main_end: 0x%x \n", _main_end);
  // printf("_rodata_lma: 0x%x \n", _rodata_lma);
  // printf("_rodata_start: 0x%x \n", _rodata_start);
  // printf("_rodata_end: 0x%x \n", _rodata_end);
  // printf("_data_lma: 0x%x \n", _data_lma);
  // printf("_rodata_end: 0x%x \n", _rodata_end);
  // printf("_bss_start: 0x%x \n", _bss_start);

  uint32_t vendor_id, arch_id;

  // 读取 mvendorid 和 marchid
  asm volatile("csrr %0, mvendorid" : "=r"(vendor_id));
  asm volatile("csrr %0, marchid" : "=r"(arch_id));
  printf("vendor_id: 0x%x \n arch_id: 0x%d \n", vendor_id ,arch_id);


  int ret =  main(mainargs);

  halt(ret);
}