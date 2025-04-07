/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include "local-include/reg.h"  // 包含寄存器相关的头文件
#include <cpu/cpu.h>             // CPU 相关的定义和函数
#include <cpu/ifetch.h>          // 指令获取（Instruction Fetch）的函数
#include <cpu/decode.h>          // 指令解码（Instruction Decode）的函数
#include <limits.h>
#include <isa.h>

// 定义寄存器访问、内存读写的简写宏
#define R(i) gpr(i)       // 访问通用寄存器（GPR，General Purpose Register）
#define Mr vaddr_read      // 读取虚拟地址的数据
#define Mw vaddr_write     // 向虚拟地址写入数据

static vaddr_t *csr_register(word_t imm) {
  switch (imm)
  {
  case 0x341: return &(cpu.csr.mepc);
  case 0x342: return &(cpu.csr.mcause);
  case 0x300: return &(cpu.csr.mstatus);
  case 0x305: return &(cpu.csr.mtvec);
  default: 
    printf("csr imm = 0x%03x" , imm);
    panic("Unknown csr ");
  }
}
//如果nemu使用riscv32e ,则需要将参数该为a5 
#define ECALL(dnpc) { bool success; dnpc = (isa_raise_intr(isa_reg_str2val("a5", &success), s->pc)); }
#define CSR(i) *csr_register(i)

//R I S B U J
enum {
  TYPE_I, 
  TYPE_U, 
  TYPE_S,
  TYPE_N, // none
  TYPE_J,
  TYPE_B,
  TYPE_R,
};//I型指令，U型指令，S型指令，无类型指令

#define src1R() do { *src1 = R(rs1); } while (0) //// 读取源操作数 1（rs1）
#define src2R() do { *src2 = R(rs2); } while (0) //// 读取源操作数 2（rs2）
#define RING_BUFFER_SIZE 10  // 环形缓冲区大小
// int cnt = 1;
// 初始化环形缓冲区
void ring_buffer_init(RingBuffer *rb) {
    rb->head = 0;
    rb->tail = 0;
    rb->full = 0;
}

// 写入指令到环形缓冲区
void ring_buffer_write(RingBuffer *rb, uint32_t address, uint32_t instruction) {
    rb->buffer[rb->head].address = address;
    rb->buffer[rb->head].instruction = instruction;

    if (rb->full) {
        rb->tail = (rb->tail + 1) % RING_BUFFER_SIZE;  // 覆盖最早的指令
    }

    rb->head = (rb->head + 1) % RING_BUFFER_SIZE;
    if (rb->head == rb->tail) {
        rb->full = 1;  // 缓冲区满
    }
}

void ring_buffer_print(RingBuffer *rb, uint32_t error_address) {
  if (rb->head == rb->tail && !rb->full) {
      // 缓冲区为空，直接退出
      printf("Ring buffer is empty.\n");
      return;
  }

  int i = rb->tail;
  char disassembled_str[256];

  do {
    void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
      // 调用 disassemble 反汇编指令
      disassemble(disassembled_str, sizeof(disassembled_str), rb->buffer[i].address,
                  (uint8_t *)&rb->buffer[i].instruction, sizeof(rb->buffer[i].instruction));

      printf("0x%x: %08x\t%s", rb->buffer[i].address, rb->buffer[i].instruction, disassembled_str);

      // 标注出错位置
      if (rb->buffer[i].address == error_address) {
          printf("  <-- Error occurred here");
      }
      printf("\n");

      // 更新读取位置
      i = (i + 1) % RING_BUFFER_SIZE;

  } while (i != rb->head);

  // 如果缓冲区满，读出一次后就重置
  rb->full = 0;
  rb->tail = i; // 更新tail指向新位置
}





//// 解析立即数（Immediate Value）的宏
#define immI() do { *imm = SEXT(BITS(i, 31, 20), 12); } while(0)  // 提取 I 型立即数
#define immU() do { *imm = SEXT(BITS(i, 31, 12), 20) << 12; } while(0)  // 提取 U 型立即数
#define immS() do { *imm = (SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7); } while(0)  // 提取 S 型立即数
#define immJ() do { *imm = SEXT( (BITS(i, 31, 31) << 20) |(BITS(i, 19, 12) << 12) |(BITS(i, 20, 20) << 11) |(BITS(i, 30, 21) << 1),21); } while(0)  
// #define immB() do { *imm = SEXT(BITS(i, 31, 20), 12); } while(0)  // 提取 B 型立即数
#define immB() do { \
  *imm = SEXT( \
    (BITS(i, 31, 31) << 12) |  /* 提取 imm[12] (最高位符号位) */ \
    (BITS(i, 7, 7) << 11) |    /* 提取 imm[11] */ \
    (BITS(i, 30, 25) << 5) |   /* 提取 imm[10:5] */ \
    (BITS(i, 11, 8) << 1), 13); /* 提取 imm[4:1] (注意单位是字节) */ \
} while(0)

/**
 * @brief 解析指令的操作数
 * 
 * @param s    指令解码结构体
 * @param rd   目标寄存器
 * @param src1 源操作数 1
 * @param src2 源操作数 2
 * @param imm  立即数
 * @param type 指令类型（I/U/S/J等）
 */
static void decode_operand(Decode *s, int *rd, word_t *src1, word_t *src2, word_t *imm, int type) {
  uint32_t i = s->isa.inst;   // 取出当前指令
  int rs1 = BITS(i, 19, 15);  // 提取 rs1 寄存器编号
  int rs2 = BITS(i, 24, 20);  // 提取 rs2 寄存器编号
  *rd     = BITS(i, 11, 7);   // 提取 rd 目标寄存器编号
  // printf("rs1 = %d, src1 = %d, rs2 = %d, src2 = %d\n", rs1, R(rs1), rs2, R(rs2));
  // 根据指令类型解析相应的操作数
  switch (type) {
    case TYPE_R: src1R(); src2R(); break;  // R 型指令需要解析两个寄存器 rs1 和 rs2
    case TYPE_I: src1R();          immI(); break;
    case TYPE_U:                   immU(); break;
    case TYPE_S: src1R(); src2R(); immS(); break;
    case TYPE_J:                   immJ(); break;
    case TYPE_N:                           break;
    case TYPE_B: src1R(); src2R(); immB(); break;  // 使用 immB() 解析分支指令

    default: panic("unsupported type = %d", type);
  }
}

/**
 * @brief 解析并执行一条指令
 * 
 * @param s  指令解码结构体
 * @return int  返回 0，表示正常执行
 */

static int decode_exec(Decode *s) {
  s->dnpc = s->snpc;// 设定默认的下一条指令地址

//// 宏：获取当前指令
#define INSTPAT_INST(s) ((s)->isa.inst)
//// 宏：匹配指令模板，解析操作数，并执行指令
#define INSTPAT_MATCH(s, name, type, ... /* execute body */ ) { \
  int rd = 0; \
  word_t src1 = 0, src2 = 0, imm = 0; \
  decode_operand(s, &rd, &src1, &src2, &imm, concat(TYPE_, type)); \
  __VA_ARGS__ ; \
}

  INSTPAT_START();
INSTPAT("??????? ????? ????? ??? ????? 00101 11", auipc  , U, R(rd) = s->pc + imm);
INSTPAT("??????? ????? ????? 100 ????? 00000 11", lbu    , I, R(rd) = Mr(src1 + imm, 1));
INSTPAT("??????? ????? ????? 000 ????? 01000 11", sb     , S, Mw(src1 + imm, 1, src2));
INSTPAT("??????? ????? ????? 010 ????? 01000 11", sw     , S, Mw(src1 + imm, 4, src2));
INSTPAT("??????? ????? ????? 000 ????? 00100 11", addi   , I, R(rd) = src1 + imm);
INSTPAT("??????? ????? ????? ??? ????? 11011 11", jal    , J, R(rd) = s->pc + 4; s->dnpc = s->pc + imm);
INSTPAT("??????? ????? ????? 000 ????? 11001 11", jalr   , I, R(rd) = s->pc + 4; s->dnpc = (src1 + imm) & (~1));
INSTPAT("??????? ????? ????? 010 ????? 00000 11", lw     , I, R(rd) = SEXT(Mr(src1 + imm, 4), 32));
INSTPAT("0000000 ????? ????? 000 ????? 01100 11", add    , R, R(rd) = src1 + src2);
INSTPAT("0100000 ????? ????? 000 ????? 01100 11", sub    , R, R(rd) = src1 - src2);
INSTPAT("??????? ????? ????? 011 ????? 00100 11", sltiu  , I, R(rd) = ((word_t)src1 < (word_t)imm ? 1 : 0));
INSTPAT("??????? ????? ????? 010 ????? 00100 11", slti   , I, R(rd) = ((sword_t)src1 < (sword_t)imm ? 1 : 0));
INSTPAT("??????? ????? ????? 000 ????? 11000 11", beq    , B, if(src1 == src2) s->dnpc = s->pc + imm);
INSTPAT("??????? ????? ????? 001 ????? 11000 11", bne    , B, if(src1 != src2) s->dnpc = s->pc + imm);
INSTPAT("0000000 ????? ????? 011 ????? 01100 11", sltu   , R, R(rd) = ((word_t)src1 < (word_t)src2 ? 1 : 0));
INSTPAT("0000000 ????? ????? 100 ????? 01100 11", xor    , R, R(rd) = src1 ^ src2);
INSTPAT("0000000 ????? ????? 110 ????? 01100 11", or     , R, R(rd) = src1 | src2);
INSTPAT("??????? ????? ????? 001 ????? 01000 11", sh     , S, Mw(src1 + imm, 2, src2));
INSTPAT("0100000 ????? ????? 101 ????? 00100 11", srai   , I, if((imm - 1024) < 32) R(rd) = ((sword_t)src1 >> (imm - 1024)));
INSTPAT("??????? ????? ????? 111 ????? 00100 11", andi   , I, R(rd) = src1 & imm);
INSTPAT("0000000 ????? ????? 001 ????? 01100 11", sll    , R, R(rd) = src1 << (src2 % 32));
INSTPAT("0000000 ????? ????? 111 ????? 01100 11", and    , R, R(rd) = src1 & src2);
INSTPAT("??????? ????? ????? 100 ????? 00100 11", xori   , I, R(rd) = src1 ^ imm);
INSTPAT("??????? ????? ????? 110 ????? 00100 11", ori    , I, R(rd) = src1 | imm);
INSTPAT("??????? ????? ????? 101 ????? 11000 11", bge    , B, if((sword_t)src1 >= (sword_t)src2) s->dnpc = s->pc + imm);
INSTPAT("??????? ????? ????? ??? ????? 01101 11", lui    , U, R(rd) = imm);
INSTPAT("000000? ????? ????? 101 ????? 00100 11", srli   , I, if(imm < 32) R(rd) = (src1 >> imm));
INSTPAT("??????? ????? ????? 111 ????? 11000 11", bgeu   , B, if(src1 >= src2) s->dnpc = s->pc + imm);
INSTPAT("000000? ????? ????? 001 ????? 00100 11", slli   , I, if(imm < 32) R(rd) = (src1 << imm ));
INSTPAT("0000001 ????? ????? 000 ????? 01100 11", mul    , R, R(rd) = src1 * src2);
INSTPAT("0000001 ????? ????? 100 ????? 01100 11", div, R, 
  if ((int32_t)src2 == 0) { 
    if (rd != 0) {
        R(rd) = -1;
    }
  } 
  else {
    // 取符号
    int negative = ((int32_t)src1 < 0) ^ ((int32_t)src2 < 0);

    // printf("src1 = %d, src2 = %d\n", src1, src2);
    // 使用 abs() 取绝对值，防止溢出
    uint32_t dividend = ((int32_t)src1 < 0) ? abs((int32_t)src1) : (uint32_t)src1;
    uint32_t divisor = ((int32_t)src2 < 0) ? abs((int32_t)src2) : (uint32_t)src2;
    // 调试输出，使用 %u 防止格式错误
    // printf("dividend = %u, divisor = %u \n", dividend, divisor);

    // 执行无符号除法
    int32_t quotient = dividend / divisor;

    // 如果 rd = x0，结果丢弃
    if (rd != 0) {
        R(rd) = negative ? -quotient : quotient;
    }
    // printf("src1 = %d, src2 = %d, R(rd) = %d\n", src1, src2, R(rd));
  }
);
INSTPAT("0000001 ????? ????? 110 ????? 01100 11", rem, R,
  if (src2 == 0) {
    // 除数为0，返回被除数
    if (rd != 0) {
        R(rd) = src1;
    }
  } else if (src1 == INT_MIN && src2 == -1) {
    // 最小负数取余-1，结果为 0（避免溢出）
    if (rd != 0) {
        R(rd) = 0;
    }
  } else {
    // 执行带符号的取余运算
    int32_t result = (int32_t)src1 % (int32_t)src2;
    
    // 调试输出
    // printf("src1 = %d, src2 = %d, result = %d\n", (int32_t)src1, (int32_t)src2, result);

    // 存储结果
    if (rd != 0) {
        R(rd) = result;
    }
  }
  // printf("src1 = %d, src2 = %d\n", (int32_t)src1, (int32_t)src2);
);

INSTPAT("??????? ????? ????? 100 ????? 11000 11", blt    , B, if((sword_t)src1 < (sword_t)src2) s->dnpc = s->pc + imm);
INSTPAT("0000000 ????? ????? 010 ????? 01100 11", slt    , R, R(rd) = (sword_t)src1 < (sword_t)src2);
INSTPAT("??????? ????? ????? 001 ????? 00000 11", lh     , I, R(rd) = SEXT(Mr(src1 + imm, 2), 16));
INSTPAT("??????? ????? ????? 000 ????? 00000 11", lb     , I, R(rd) = SEXT(Mr(src1 + imm, 2), 8));
INSTPAT("??????? ????? ????? 101 ????? 00000 11", lhu    , I, R(rd) = Mr(src1 + imm, 2));
INSTPAT("0000001 ????? ????? 001 ????? 01100 11", mulh   , R, R(rd) = (((int64_t)(sword_t)src1 * (int64_t)(sword_t)src2) >> 32));
INSTPAT("0000001 ????? ????? 011 ????? 01100 11", mulhu  , R, R(rd) = (((uint64_t)src1 * (uint64_t)src2) >> 32));
INSTPAT("0000001 ????? ????? 111 ????? 01100 11", remu, R,
  if (src2 == 0) {
    // 除数为0，返回被除数
    if (rd != 0) {
        R(rd) = src1;
    }
  } else {
    // 执行无符号取余运算
    uint32_t result = (uint32_t)src1 % (uint32_t)src2;

    // 调试输出
    // printf("src1 = %u, src2 = %u, result = %u\n", (uint32_t)src1, (uint32_t)src2, result);

    // 存储结果
    if (rd != 0) {
        R(rd) = result;
    }
  }
);

INSTPAT("0000001 ????? ????? 101 ????? 01100 11", divu   , R,   if (src2 == 0) { 
  // 除数为 0，返回 -1（RISC-V 规范）
  R(rd) = -1; 
} else { 
  // 向零舍入，C 的整数除法已经是向零舍入
  R(rd) = src1 / src2;
});
INSTPAT("0000001 ????? ????? 010 ????? 01100 11", mulhsu, R, 
  // rs1 是有符号数，rs2 是无符号数
  int64_t result = (int64_t)(int32_t)src1 * (uint64_t)(uint32_t)src2;

  // 调试输出
  // printf("src1 = %d, src2 = %u\n", (int32_t)src1, (uint32_t)src2);
  // printf("64-bit result = 0x%016llx\n", result);
  // printf("High 32-bit result = 0x%08x\n", (int32_t)(result >> 32));

  // 取高位并存储结果
  if (rd != 0) {
      R(rd) = (int32_t)(result >> 32);
  }
);

INSTPAT("0100000 ????? ????? 101 ????? 01100 11", sra    , R, R(rd) = ((sword_t)src1 >> ((sword_t)src2 - 32)));
INSTPAT("0000000 ????? ????? 101 ????? 01100 11", srl    , R, R(rd) = (src1 >> (src2 - 32)));
INSTPAT("??????? ????? ????? 110 ????? 11000 11", bltu   , B, if(src1 < src2) s->dnpc = s->pc + imm);

INSTPAT("??????? ????? ????? 001 ????? 11100 11", csrrw  , I, R(rd) = CSR(imm); CSR(imm) = src1);
INSTPAT("??????? ????? ????? 010 ????? 11100 11", csrrs  , I, R(rd) = CSR(imm); CSR(imm) |= src1);
INSTPAT("0000000 00000 00000 000 00000 11100 11", ecall  , I, ECALL(s->dnpc));
INSTPAT("0011000 00010 00000 000 00000 11100 11", mret, N, s->dnpc = cpu.csr.mepc);

INSTPAT("0000000 00001 00000 000 00000 11100 11", ebreak , N, NEMUTRAP(s->pc, R(10))); // R(10) is $a0
INSTPAT("??????? ????? ????? ??? ????? ????? ??", inv    , N, ring_buffer_print(&rb, s->pc); INV(s->pc) );
// INSTPAT("??????? ????? ????? ??? ????? ????? ??", inv    , N, ring_buffer_print(&rb, s->pc); printf("$a4 = 0x%08x\n", R(14)); INV(s->pc) );

  INSTPAT_END();

  R(0) = 0; // reset $zero to 0

  return 0;
}

int isa_exec_once(Decode *s) {
  s->isa.inst = inst_fetch(&s->snpc, 4);//从pc中取指
  ring_buffer_write(&rb, s->pc, s->isa.inst);  // 写入环形缓冲区：pc 和 指令
  
  return decode_exec(s);
}
