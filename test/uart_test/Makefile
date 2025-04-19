# 工具链前缀
CROSS = riscv64-linux-gnu
CC = $(CROSS)-gcc
LD = $(CC)
OBJCOPY = $(CROSS)-objcopy
OBJDUMP = $(CROSS)-objdump

# 工程结构
AM_DIR = ../am
AM_SRC = $(AM_DIR)/src
AM_INC = $(AM_DIR)/include
LINKER = $(AM_DIR)/linker.ld

# 所有源码文件（包括 UART 用户代码）
SRCS = ../am/src/start.S \
       ../am/src/trm.c \
       uart.c


# 编译器选项（推荐组合）
CFLAGS   = -march=rv32e_zicsr -mabi=ilp32e -Os \
           -ffreestanding -nostdlib \
           -ffunction-sections -fdata-sections \
           -I. -I$(AM_INC) \
		   -fno-pic

# 链接器选项（推荐组合）
LDFLAGS  = -T $(LINKER) -nostdlib -static -nostartfiles \
           -Wl,--gc-sections -Wl,-e,_start -Wl,--build-id=none





# 构建目标
TARGET = image

all: $(TARGET).bin

$(TARGET).elf: $(SRCS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
	$(OBJDUMP) -d $< > $*.txt
	@echo "✅ Build complete: $@"

clean:
	rm -f *.o *.elf *.bin *.txt

.PHONY: all clean
