.section entry, "ax"
.globl _start
.type _start, @function

_start:

  mv s0, zero

  # 设置栈指针
  la sp, _stack_pointer
  call first_bootloader
  # 进入程序主流程
  call _trm_init
