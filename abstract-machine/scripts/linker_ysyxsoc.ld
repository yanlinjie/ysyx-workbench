ENTRY(_start)

MEMORY {
  /* MROM (rx)  : ORIGIN = 0x20000000, LENGTH = 4K */
  /* SRAM (xrw) : ORIGIN = 0x0f000000, LENGTH = 8K */

  MROM (rx)  : ORIGIN = 0x30000000, LENGTH = 16M
  SRAM (xrw) : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {

  . = ORIGIN(MROM);

  .text : {
    KEEP(*(.vector_table))
    *(entry)
    *(.text .text.*)
  } > MROM

  .rodata : {
    *(.rodata .rodata.*)
    . = ALIGN(4);
  } > MROM

  /* === .data：运行在 SRAM，加载自 MROM === */
  _data_lma = ALIGN(LOADADDR(.rodata) + SIZEOF(.rodata), 4);

  .data : AT(_data_lma) {
    _data_start = .;
    *(.data .data.*)
    . = ALIGN(4);
    _data_end = .;
  } > SRAM

  _data_load = LOADADDR(.data);
  _sdata_lma = LOADADDR(.sdata);

  .sdata : AT(LOADADDR(.data) + SIZEOF(.data)) {
    _sdata_start = .;
    *(.sdata .sdata.*)
    . = ALIGN(4);
    _sdata_end = .;
  } > SRAM

  .bss : {
    _bss_start = .;
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(4);
    _bss_end = .;
  } > SRAM

  /* === 堆区：.bss之后 2KB === */
  . = ALIGN(4);
  _heap_start = .;
  /* . = . + 0x800;   */
  . = . + 0x2000;  
  _heap_end = .;

  /* === 栈区：SRAM末尾向下分配2KB === */
  _stack_bottom = ORIGIN(SRAM) + LENGTH(SRAM) - 0x200000;
  _stack_pointer = ORIGIN(SRAM) + LENGTH(SRAM);

  _end = .;
}
