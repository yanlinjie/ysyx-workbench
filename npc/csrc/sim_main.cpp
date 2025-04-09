#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vtop.h"
#include "Vtop__Syms.h"
#include <iostream>
#include <iomanip>
#include <fstream>
#include <cstdint>
#include <cstring>
#include <dlfcn.h>
#include <assert.h>
//time
#include <time.h>
#include <stdint.h>

// NEMU头文件
extern "C" {
  #include <common.h>
  #include <memory/vaddr.h>
  #include <cpu/cpu.h>
  #include <difftest-def.h>
}

#define RESET_VECTOR 0x80000000
#define ROM_SIZE     40960000
#define PC_START     0x80000000



// VerilatedVcdC *tfp = nullptr;   // 2. 声明全局 tfp
vluint64_t main_time = 0;       // 3. 声明主时间变量
double sc_time_stamp() { return main_time; }

Vtop* top = new Vtop();
VerilatedVcdC* tfp = new VerilatedVcdC();  // VCD 波形对象

uint32_t rom_mem[ROM_SIZE] = {0};

typedef struct {
  word_t gpr[32];
  vaddr_t pc;
} CPU_state;

CPU_state cpu;
CPU_state ref;


uint64_t get_time() {
  static uint64_t start_us = 0;  // 初始时间
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);  // 获取当前时间
  uint64_t now_us = (uint64_t)ts.tv_sec * 1000000 + ts.tv_nsec / 1000;

  if (start_us == 0) start_us = now_us;  // 第一次调用时记录起点

  return now_us - start_us;  // 返回相对时间
}


extern "C" int pmem_read(uint32_t raddr) {
  // 总是读取地址为`raddr & ~0x3u`的4字节并返回
  uint64_t us = get_time();
  // printf("Start time: %lu us\n", us);
  if (raddr == 0x28000012)    return (uint32_t)us;//{ 返回当前时间 };
  else if(raddr == 0x28000013 ) return us >> 32;
  return 0;
}

extern "C" void monitor_mem_read(uint32_t addr, uint32_t data) {
    // printf("[MEM READ] PC = 0x%08x,  address = 0x%08x, data = 0x%08x\n",cpu.pc, addr, data);
    // if (addr == 0xa000048) ;
}

extern "C" void monitor_mem_write(uint32_t addr, uint32_t data, uint32_t wtype) {
    // const char* type_str = (wtype == 1) ? "WORD" : (wtype == 2) ? "HALF" : "BYTE";
    // printf("[MEM WRITE] PC = 0x%08x, type = %s, address = 0x%08x, data = 0x%08x\n",top->rootp->top__DOT__u_riscv32__DOT__pc , type_str, addr, data);
    uint32_t oaddr = addr;
    uint32_t odata = data;
    if (oaddr == (0xa00003f8/4)) 
    {
      // printf("[MEM WRITE] \n");
      printf("%c", odata);//直接使用printf 打印出数据
      // exit(0);
    }
}
// ========= Ring Buffer =========
typedef struct {
  uint32_t pc;
  uint32_t inst;
} InstrRecord;

#define RING_BUF_SIZE 40
InstrRecord ring_buf[RING_BUF_SIZE];
int ring_pos = 0;

void ring_buffer_push(uint32_t pc, uint32_t inst) {
  ring_buf[ring_pos].pc = pc;
  ring_buf[ring_pos].inst = inst;
  ring_pos = (ring_pos + 1) % RING_BUF_SIZE;
}

void ring_buffer_print() {
  printf("\n--- Last %d Instructions ---\n", RING_BUF_SIZE);
  for (int i = 0; i < RING_BUF_SIZE; ++i) {
    int index = (ring_pos + i) % RING_BUF_SIZE;
    printf("#%02d PC = 0x%08x  INST = 0x%08x\n", i, ring_buf[index].pc, ring_buf[index].inst);
  }
  printf("------------------------------\n\n");
}

// ========= DiffTest API =========
typedef void (*difftest_memcpy_t)(paddr_t, void*, size_t, bool);
typedef void (*difftest_regcpy_t)(void*, bool);
typedef void (*difftest_exec_t)(uint64_t);
typedef void (*difftest_raise_intr_t)(uint64_t);
typedef void (*difftest_init_t)(int);

static difftest_memcpy_t difftest_memcpy;
static difftest_regcpy_t difftest_regcpy;
static difftest_exec_t difftest_exec;
static difftest_raise_intr_t difftest_raise_intr;
static difftest_init_t difftest_init;

void* guest_to_host(uint32_t paddr) {
  return (void*)&rom_mem[(paddr - RESET_VECTOR) / 4];
}

bool isa_difftest_checkregs(CPU_state *ref_r, CPU_state *dut) {
  int reg_num = 32;
  bool ok = true;

  for (int i = 0; i < reg_num; i++) {
    if (ref_r->gpr[i] != dut->gpr[i]) {
      ok = false;
      break;
    }
  }
  if (ref_r->pc != dut->pc) ok = false;

  if (!ok) {
    printf("\n========== \033[1;31m[DIFFTEST FAIL]\033[0m ==========\n");
    printf("Mismatch detected at PC = 0x%08x\n\n", dut->pc);
    printf("%-8s%-18s%-18s\n", "Reg", "REF", "DUT");
    printf("---------------------------------------------\n");
    for (int i = 0; i < reg_num; i++) {
      printf("x%-7d0x%08x       0x%08x", i, ref_r->gpr[i], dut->gpr[i]);
      if (ref_r->gpr[i] != dut->gpr[i]) printf("   <--- ❌");
      printf("\n");
    }
    printf("\nPC        : REF = 0x%08x, DUT = 0x%08x", ref_r->pc, dut->pc);
    if (ref_r->pc != dut->pc) printf("   <--- ❌");
    printf("\n==========================================\n");
  }

  return ok;
}

static void single_cycle() {
  top->clk = 1; top->eval();tfp->dump(main_time++);
  top->clk = 0; top->eval();tfp->dump(main_time++);

}

static void rst(int n) {
  top->rst = 1;
  while (n--) single_cycle();
  top->rst = 0;
}

uint32_t fetch_instruction(uint32_t pc) {
  uint32_t index = ((pc - PC_START) >> 2);
  
  return rom_mem[index];
}

int load_program(const char* filename) {
  std::ifstream file(filename, std::ios::binary);
  if (!file) {
    std::cerr << "Error: Failed to open file " << filename << "\n";
    exit(-1);
  }

  uint32_t instruction;
  int index = 0;
  while (file.read(reinterpret_cast<char*>(&instruction), sizeof(instruction))) {
    if (index < ROM_SIZE) {
      rom_mem[index++] = instruction;
    } else {
      std::cerr << "Error: ROM overflow!\n";
      break;
    }
  }

  file.close();
  std::cout << "Loaded " << index << " instructions from " << filename << "\n";
  return index * 4;
}

void load_bin_to_data_mem(const char* bin_file_path) {
  std::ifstream file(bin_file_path, std::ios::binary);
  if (!file) {
      std::cerr << "Failed to open .bin file: " << bin_file_path << std::endl;
      exit(1);
  }

  int idx = 0;
  char byte;
  while (file.get(byte)) {
      if (idx >= 163840000) {
          std::cerr << "Error: .bin file too large for data memory!" << std::endl;
          break;
      }
      // top->rootp->top__DOT__DATA_MEM__DOT__data[idx] = static_cast<uint8_t>(byte);
      idx++;
  }

  std::cout << "Loaded " << idx << " bytes into DATA_MEM.data[]" << std::endl;
}

void load_bin_to_inst_mem(const char* bin_file_path) {
  std::ifstream file(bin_file_path, std::ios::binary);
  if (!file) {
      std::cerr << "Failed to open .bin file: " << bin_file_path << std::endl;
      exit(1);
  }

  int idx = 0;
  int cnt = 0;
  char bytes[4];
  while (file.read(bytes, 4)) {
      if (idx >= 40960000) {
          std::cerr << "Error: bin file too large for instruction memory!" << std::endl;
          break;
      }

      // Little-endian -> 32-bit word
      uint32_t inst = (uint8_t)bytes[0] |
                      ((uint8_t)bytes[1] << 8) |
                      ((uint8_t)bytes[2] << 16) |
                      ((uint8_t)bytes[3] << 24);
      // printf("%08x\n",inst);
      // 写入 instruction_mem 的 rom_mem
      top->rootp->top__DOT__u_dual_ram_template__DOT__memory[idx] = inst;
      // printf("inst = %08x; addr = %08x ; idx = %d\n",inst , cnt ,idx);
      idx++;
      
      cnt = cnt +4;
  }

  std::cout << "Loaded " << idx << " instructions into INSTRUCTION_MEM.rom_mem[]" << std::endl;
}



void init_difftest(const char* ref_so_file, long img_size, int port) {
  void* handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  difftest_init       = (difftest_init_t)dlsym(handle, "difftest_init");
  difftest_memcpy     = (difftest_memcpy_t)dlsym(handle, "difftest_memcpy");
  difftest_regcpy     = (difftest_regcpy_t)dlsym(handle, "difftest_regcpy");
  difftest_exec       = (difftest_exec_t)dlsym(handle, "difftest_exec");
  difftest_raise_intr = (difftest_raise_intr_t)dlsym(handle, "difftest_raise_intr");

  assert(difftest_init && difftest_memcpy && difftest_regcpy && difftest_exec && difftest_raise_intr);

  difftest_init(port);
  difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

extern "C" void dpi_exit_simulation() {
  int state = top->rootp->top__DOT__u_riscv32__DOT__u_reg_file__DOT__regs[10];
    printf("[INFO] ebreak instruction encountered. Ending simulation.");
    if (state)
    printf("\033[1;31mHIT BAD TRAP\033[0m at pc = 0x%08x\n",top->rootp->top__DOT__u_riscv32__DOT__pc);  // 红色
  else
    printf("\033[1;32mHIT GOOD TRAP\033[0m at pc = 0x%08x\n", top->rootp->top__DOT__u_riscv32__DOT__pc); // 绿色
    delete top;
    delete tfp;
  exit(state);
}

static void welcome() {
  printf("Welcome to -NPC!\n");
}

int main(int argc, char** argv) {

  FILE* reg_dump = fopen("regdump.txt", "w");  // 打开输出文件（写入模式）
  if (reg_dump == nullptr) {
      perror("Failed to open regdump.txt");
      exit(1);
  }
  Verilated::traceEverOn(true);
  // VerilatedVcdC *tfp = new VerilatedVcdC;
  tfp = new VerilatedVcdC;
  top->trace(tfp, 99);      // 99 是层级深度
  tfp->open("wave.vcd");    // 波形文件名
  welcome();
  load_bin_to_inst_mem(argv[1]);  // 在 reset 之后，仿真主循环之前

  rst(10);


  int cycle_count = 0;
  while (true) {


    single_cycle();
    
fprintf(reg_dump, "\n========= Register File =========\n");
fprintf(reg_dump ,"pc = %08x inst = %08x\n", top->rootp->top__DOT__u_riscv32__DOT__pc,top->rootp->top__DOT__u_riscv32__DOT__inst);
for (int i = 0; i < 32; i++) {
    fprintf(reg_dump, "x%-2d = 0x%08x  ", i, top->rootp->top__DOT__u_riscv32__DOT__u_reg_file__DOT__regs[i]);
    if ((i + 1) % 4 == 0) fprintf(reg_dump, "\n");
}
fprintf(reg_dump, "=================================\n\n");
  
    if (++cycle_count > 500000) {
      printf("[ERROR] Timeout: Too many cycles.\n");
      break;
    }
  }
  tfp->close();
  delete top;
  delete tfp;
  return -1;

}
