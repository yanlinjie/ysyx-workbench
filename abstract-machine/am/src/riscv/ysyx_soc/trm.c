#include <am.h>
#include <npc.h>
//这里直接调用了c的标准库，不知道会不会对后续有什么影响
#include <stdint.h>
#include <string.h>


#define UART_BASE     0x10000000L

#define UART_RBR_THR  (*(volatile uint8_t *)(UART_BASE + 0x00)) // 接收/发送寄存器
#define UART_IER      (*(volatile uint8_t *)(UART_BASE + 0x01))
#define UART_LCR      (*(volatile uint8_t *)(UART_BASE + 0x03))
#define UART_LSR      (*(volatile uint8_t *)(UART_BASE + 0x05))
#define UART_DLL      (*(volatile uint8_t *)(UART_BASE + 0x00)) // 波特率除数低
#define UART_DLM      (*(volatile uint8_t *)(UART_BASE + 0x01)) // 波特率除数高
#define UART_FCR      (*(volatile uint8_t *)(UART_BASE + 0x02))


extern uint8_t _data_lma[];
extern uint8_t _data_start[];
extern uint8_t _data_end[];

extern uint8_t _bss_start[];
extern uint8_t _bss_end[];
extern uint8_t _sdata_lma[], _sdata_start[], _sdata_end[];


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


void bootloader() {
    // 拷贝 .data 段到 SRAM
    memcpy(_data_start, _data_lma, _data_end - _data_start);
    memcpy(_sdata_start, _sdata_lma, _sdata_end - _sdata_start);
    // 清零 .bss 段
    memset(_bss_start, 0, _bss_end - _bss_start);
}



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

void _trm_init() {

  bootloader();
  uart_init();
  int ret = main(mainargs);

  halt(ret);
}