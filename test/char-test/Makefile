# 工具链前缀
CROSS_PREFIX = riscv64-linux-gnu-

# 工具命令
CC      = $(CROSS_PREFIX)gcc
LD      = $(CROSS_PREFIX)ld
OBJCOPY = $(CROSS_PREFIX)objcopy
OBJDUMP = $(CROSS_PREFIX)objdump

# 编译参数
CFLAGS  = -march=rv32ima -mabi=ilp32 -ffreestanding -nostdlib -O2 -g
LDFLAGS = -T linker.ld -m elf32lriscv

# 源文件和目标文件
SRC      = char-test.c
BUILD    = build
OBJ      = $(BUILD)/uart_test.o
ELF      = $(BUILD)/uart_test.elf
BIN      = $(BUILD)/uart_test.bin
DISASM   = $(BUILD)/uart_test.S

# 默认目标
all: $(BIN)

# 创建 build 目录
$(BUILD):
	mkdir -p $(BUILD)

# 编译 C -> obj
$(OBJ): $(SRC) | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

# 链接 obj -> elf
$(ELF): $(OBJ) linker.ld
	$(LD) $(LDFLAGS) -o $@ $<

# elf -> bin
$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

# elf -> 反汇编
disasm: $(ELF)
	$(OBJDUMP) -d -S $< > $(DISASM)
	@echo "Disassembly saved to $(DISASM)"

# 清理所有生成文件
clean:
	rm -rf $(BUILD)

.PHONY: all clean disasm
