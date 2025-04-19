#include "verilated.h"
#include "verilated_vcd_c.h"
#include "VysyxSoCFull.h"
#include "VysyxSoCFull__Syms.h"
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
#include <cstdio> 

// NEMU头文件
extern "C" {
  #include <common.h>
  #include <memory/vaddr.h>
  #include <cpu/cpu.h>
  #include <difftest-def.h>
}

#define WAVE_ON 

#define RESET_VECTOR 0x80000000
#define ROM_SIZE     40960000
#define  MROM_BASE  0x20000000
#define  MROM_SIZE  0x1000        // 4KB
#define  MROM_WORDS  MROM_SIZE / 4 // 1024 words

uint32_t mrom[MROM_WORDS] = {
  // 0x100007b7, 
  // 0x04100713, 
  // 0x00e78023, 
  // 0x00a00713, 
  // 0x00e78023,
  // 0x0000006f,
};

#ifdef WAVE_ON
vluint64_t main_time = 0;       // 3. 声明主时间变量
double sc_time_stamp() { return main_time; }
VerilatedVcdC* tfp = new VerilatedVcdC();  // VCD 波形对象
#endif

VysyxSoCFull* top = new VysyxSoCFull();

FILE* reg_dump = fopen("regdump.txt", "w");  // 打开输出文件（写入模式）
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

extern "C" void flash_read(int32_t addr, int32_t *data) { assert(0); }
extern "C" void mrom_read(int32_t addr, int32_t *data) {
  // 范围检查
  if ((uint32_t)addr < MROM_BASE || (uint32_t)addr >= MROM_BASE + MROM_SIZE) {
      printf("[MROM] Error: Address 0x%08x out of range\n", addr);
      *data = 0;
      assert(0);
  }

  if (addr % 4 != 0) {
      printf("[MROM] Error: Unaligned access at 0x%08x\n", addr);
      *data = 0;
      assert(0);
  }

  uint32_t index = ((uint32_t)addr - MROM_BASE) >> 2;
  *data = (int32_t)mrom[index];
}

extern "C" int pmem_read(uint32_t raddr) {
  // 总是读取地址为`raddr & ~0x3u`的4字节并返回
  uint64_t us = get_time();
  // printf("Start time: %lu us\n", us);//a000_0048
  if (raddr == 0xa0000048)    return (uint32_t)us;//{ 返回当前时间 };
  else if(raddr == 0xa000004c ) return us >> 32;
  return 0;
}

extern "C" void monitor_mem_read(uint32_t addr, uint32_t data) {
    // printf("[MEM READ] PC = 0x%08x,  address = 0x%08x, data = 0x%08x\n",cpu.pc, addr, data);
    // if (addr == 0xa000048) ;
}

extern "C" void monitor_mem_write(uint32_t addr, unsigned char data, uint32_t wtype) {
    const char* type_str = (wtype == 1) ? "WORD" : (wtype == 2) ? "HALF" : "BYTE";
    // printf("[MEM WRITE] PC = 0x%08x,  address = 0x%08x, data = 0x%08x\n",top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_araddr , addr, data);
    uint32_t oaddr = addr;
    uint32_t odata = data;
    if (oaddr == 0xa00003f8) 
    {
      printf("%c", odata);//直接使用printf 打印出数据
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
#ifdef WAVE_ON
  top->clock = 1; top->eval();
  tfp->dump(main_time++);
  top->clock = 0; top->eval();
  tfp->dump(main_time++);

#else 
  top->clock = 1; top->eval();
  top->clock = 0; top->eval();
#endif

}

static void rst(int n) {
  top->reset = 1;
  while (n--) single_cycle();
  top->reset = 0;
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



void load_mrom_bin(const char *filename) {
  FILE *f = fopen(filename, "rb");
  if (!f) {
      perror("[MROM] Failed to open bin file");
      exit(EXIT_FAILURE);
  }

  size_t read_words = fread(mrom, sizeof(uint32_t), MROM_WORDS, f);
  fclose(f);

  printf("[MROM] Loaded %zu words (%zu bytes) from %s\n",
         read_words, read_words * sizeof(uint32_t), filename);
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
  int state = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_reg_file__DOT__regs[10];
    printf("[INFO] ebreak instruction encountered. Ending simulation.");
    if (state)
    printf("\033[1;31mHIT BAD TRAP\033[0m at pc = 0x%08x\n",top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_araddr);  // 红色
  else
    printf("\033[1;32mHIT GOOD TRAP\033[0m at pc = 0x%08x\n", top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_araddr); // 绿色

  printf(" \033[1;32mpromgram stop!\033[0m\n");

#ifdef WAVE_ON
  tfp->close();
  delete tfp;
#endif
  delete top;
  exit(state);
}

static void welcome() {
  printf("\033[1;31mWelcome to -NPC!\033[0m \n");
}

int main(int argc, char** argv) {
  std::setvbuf(stdout, NULL, _IONBF, 0);  // 禁用 stdout 缓冲 打印输出有缓冲区！

#ifdef WAVE_ON
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  top->trace(tfp, 99);      // 99 是层级深度
  tfp->open("wave.vcd");    // 波形文件名
#endif

  // Verilated::commandArgs(argc, argv);

  welcome();
  load_mrom_bin(argv[1]);
  // load_mrom_bin("/home/ylj/ysyx-workbench/test/uart_test/image.bin");


  rst(10);



// // //debug diff
//   uint32_t prev_inst = 0;  // 初始化为0或其他非法指令
//   cpu.pc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_araddr;
//   for (int i = 0; i < 32; ++i)
//     cpu.gpr[i] = top->rootp->top__DOT__u_riscv32__DOT__u_reg_file__DOT__regs[i];
//   long program_size = load_program(argv[1]);
//   init_difftest("/home/ylj/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so", program_size, 0);
 
  int cycle_count = 0;
  while (true) {

 

    single_cycle();
    // printf("cpu.pc = 0x%08x inst = 0x%08x\n", top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_araddr  , top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_rdata);
    // fprintf(reg_dump,"cpu.pc = 0x%08x inst = 0x%08x\n", top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_araddr , top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_rdata);

// //debug diff
// if (top->rootp->top__DOT__u_riscv32__DOT__inst != prev_inst){
//     // fprintf(reg_dump,"cpu.pc = 0x%08x inst = 0x%08x\n", (top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_araddr - 0x80000000)/4 , top->rootp->top__DOT__u_riscv32__DOT__inst);

//     ring_buffer_push(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_araddr, top->rootp->top__DOT__u_riscv32__DOT__inst);  // 👈 加入 ring buffer
//     cpu.pc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_araddr;
//     for (int i = 0; i < 32; ++i)
//       cpu.gpr[i] = top->rootp->top__DOT__u_riscv32__DOT__u_reg_file__DOT__regs[i];
//     difftest_regcpy(&ref, DIFFTEST_TO_DUT);
//     //ref 是正确端 dut是
//     if (!isa_difftest_checkregs(&ref, &cpu)) {
//       ring_buffer_print();  // 👈 打印 ring buffer
//       // printf("cycle_count = %d\n", cycle_count);
//       exit(1);
//     }
//     difftest_exec(1);
// }
// prev_inst = top->rootp->top__DOT__u_riscv32__DOT__inst;
if(++cycle_count == 4000000)
{
#ifdef WAVE_ON
  tfp->close();
  delete tfp;
#endif
  delete top;
  exit(1);
}

  }
#ifdef WAVE_ON
  tfp->close();
  delete tfp;
#endif
  delete top;
  exit(1);

}
