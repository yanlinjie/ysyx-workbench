include $(AM_HOME)/scripts/isa/riscv.mk
include $(AM_HOME)/scripts/platform/ysyxsoc.mk
CFLAGS  += -DISA_H=\"riscv/riscv.h\"
COMMON_CFLAGS += -march=rv32e_zicsr -mabi=ilp32e  # overwrite
LDFLAGS       += -melf32lriscv                    # overwrite

AM_SRCS += riscv/ysyx_soc/libgcc/div.S \
           riscv/ysyx_soc/libgcc/muldi3.S \
           riscv/ysyx_soc/libgcc/multi3.c \
           riscv/ysyx_soc/libgcc/ashldi3.c \
           riscv/ysyx_soc/libgcc/unused.c
