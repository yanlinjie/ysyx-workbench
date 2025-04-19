AM_SRCS := riscv/ysyx_soc/start.S \
           riscv/ysyx_soc/trm.c \
           riscv/ysyx_soc/ioe.c \
           riscv/ysyx_soc/timer.c \
           riscv/ysyx_soc/input.c \
           riscv/ysyx_soc/cte.c \
           riscv/ysyx_soc/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
CFLAGS    += -I$(AM_HOME)/am/src/riscv/npc/include
LDSCRIPTS += $(AM_HOME)/scripts/linker_ysyxsoc.ld
LDFLAGS   += --defsym=_pmem_start=0x20000000 --defsym=_entry_offset=0x0
LDFLAGS   += --gc-sections -e _start

MAINARGS_MAX_LEN = 64
MAINARGS_PLACEHOLDER = The insert-arg rule in Makefile will insert mainargs here.
CFLAGS += -DMAINARGS_MAX_LEN=$(MAINARGS_MAX_LEN) -DMAINARGS_PLACEHOLDER=\""$(MAINARGS_PLACEHOLDER)"\"
OBJCOPY_FLAGS := -O binary -R .bss -R .sbss.b
insert-arg: image
	@python $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) "$(MAINARGS_PLACEHOLDER)" "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
#	@$(OBJCOPY)  -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

	@$(OBJCOPY) $(OBJCOPY_FLAGS) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: insert-arg
	$(MAKE) -C $(NPC_HOME) run PROGRAM_BIN=$(IMAGE).bin

.PHONY: insert-arg
