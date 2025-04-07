TOPNAME = top
INC_PATH := ./vsrc \
            /home/ylj/ysyx-workbench/nemu/include


VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert  -Wno-UNOPTFLAT  \
				--trace \
				--Wno-LATCH

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

# 指定程序路径
PROGRAM_BIN ?= ./program.bin

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

$(BIN): $(VSRCS) $(CSRCS) 
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(INCFLAGS) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all: default

# ✅ 运行仿真器，并传入 .bin 文件路径
run: $(BIN)
	@echo "Running simulation with $(PROGRAM_BIN)..."
	@$(BIN) $(PROGRAM_BIN)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: default all clean run
