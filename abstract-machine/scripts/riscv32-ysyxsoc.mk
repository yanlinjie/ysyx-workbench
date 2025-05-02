include $(AM_HOME)/scripts/isa/riscv.mk
include $(AM_HOME)/scripts/platform/ysyxsoc.mk
CFLAGS  += -DISA_H=\"riscv/riscv.h\"
COMMON_CFLAGS += -march=rv32e_zicsr -mabi=ilp32e -Os -malign-data=xlen # overwrite
LDFLAGS       += -melf32lriscv                    # overwrite


