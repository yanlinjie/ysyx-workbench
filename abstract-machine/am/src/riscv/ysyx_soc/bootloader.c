#include <stdint.h>
#include <string.h>

extern uint8_t _data_lma[];
extern uint8_t _data_start[];
extern uint8_t _data_end[];

extern uint8_t _bss_start[];
extern uint8_t _bss_end[];

void bootloader() {
    // 拷贝 .data 段到 SRAM
    memcpy(_data_start, _data_lma, _data_end - _data_start);

    // 清零 .bss 段
    memset(_bss_start, 0, _bss_end - _bss_start);
}
