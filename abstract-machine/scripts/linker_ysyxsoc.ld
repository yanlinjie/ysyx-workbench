ENTRY(_start)

MEMORY {
  FLASH (rx)  : ORIGIN = 0x30000000, LENGTH = 16M
  PSRAM (xrw) : ORIGIN = 0x80000000, LENGTH = 4M
  SRAM (xrw) : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {

  . = ORIGIN(FLASH);

_memtest_start = .; /* <<< 加上程序开始标记 */

  .text : {
    *(entry)
  } > FLASH

  .sram_first_bootloader :  {
    *(sram_first_bootloader)
    . = ALIGN(4);
  } > FLASH

  _trm_init_lma = ALIGN(LOADADDR(.sram_first_bootloader) + SIZEOF(.sram_first_bootloader), 4);

  .sram_trm_init :  AT(_trm_init_lma) {
    sram_trm_init_start = .;
    *(sram_trm_init)
    . = ALIGN(4);
  } > SRAM

  sram_bootloader_lma = ALIGN(LOADADDR(.sram_trm_init) + SIZEOF(.sram_trm_init), 4);

  .sram_bootloader :  AT(sram_bootloader_lma)  {
    *(sram_bootloader)
    . = ALIGN(4);
  } > SRAM
    sram_bootloader_end = .;

  _main_lma = ALIGN(LOADADDR(.sram_bootloader) + SIZEOF(.sram_bootloader), 4);
/* . = 0x80000220; */
  .text.startup.main :   AT(_main_lma) {
    _main_start = .;
    /* *(.text.startup.main) */
    *(.text .text.*)
    . = ALIGN(4);
    _main_end = .;
  } > PSRAM

  _rodata_lma = ALIGN(LOADADDR(.text.startup.main) + SIZEOF(.text.startup.main), 4);

  .rodata  _main_end : AT(_rodata_lma){
    _rodata_start = .;
    *(.rodata .rodata.* .srodata.*)
    . = ALIGN(4);
    _rodata_end = .;

  } > PSRAM
 /* _memtest_end = .;  */


_data_lma = ALIGN(LOADADDR(.rodata) + SIZEOF(.rodata), 4);
  /* . = ALIGN(8); */



   .data :  AT(_data_lma){
    *(.data )
  } > PSRAM



  .bss : {
    _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    . = ALIGN(4);
    _bss_end = .;
  } > PSRAM

 
  . = ALIGN(4);
  _heap_start = .;
  . = . + 0x100000;  
  _heap_end = .;

/* 4k */
  _stack_bottom = ORIGIN(SRAM) + LENGTH(SRAM) - 0x1000; 
  _stack_pointer = ORIGIN(SRAM) + LENGTH(SRAM);


  _end = .;
}
