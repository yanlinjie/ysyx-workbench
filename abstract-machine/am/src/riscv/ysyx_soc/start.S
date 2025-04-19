.section entry, "ax"
.globl _start
.type _start, @function

_start:
  # 清空 s0（可以用于调试）
  mv s0, zero

  # 设置栈指针
  la sp, _stack_pointer

  # # 调用 bootloader 执行 .data 拷贝与 .bss 清零
  # call bootloader

  # 进入程序主流程
  call _trm_init
