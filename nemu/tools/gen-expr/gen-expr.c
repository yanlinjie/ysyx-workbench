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

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>
#include <time.h>

// ----------------------- 常量/全局变量 -----------------------

typedef uint32_t word_t;

// 用于存储最终生成的随机表达式
static char buf[65536] = {0};
// 用于拼装最终 C 代码
static char code_buf[65536 + 128] = {0};

// C 代码模板，将会把生成的表达式插入到 %s 位置
static const char *code_format =
"#include <stdio.h>\n"
"int main() {\n"
"  unsigned result = %s;\n"
"  printf(\"%%u\", result);\n"
"  return 0;\n"
"}\n";

// 指向 buf 中当前写入位置的指针，避免频繁使用 strcat/strlen
static char *buf_ptr = buf;

// ----------------------- 工具函数 -----------------------

// 在 0 ~ (n-1) 内随机返回一个整数
static word_t choose(word_t n) {
  return rand() % n;
}

// 安全追加单个字符到 buf
static inline void append_char(char c) {
  // 检查缓冲区剩余空间
  if ((size_t)(buf_ptr - buf) < sizeof(buf) - 1) {
    *buf_ptr++ = c;
    *buf_ptr = '\0';
  }
}

// 安全追加字符串到 buf
static inline void append_str(const char *str) {
  while (*str) {
    append_char(*str);
    str++;
  }
}

// 便捷函数：获取 buf 中最后一个字符（若 buf 为空则返回 '\0'）
static inline char last_char() {
  if (buf_ptr == buf) return '\0';     // buf 为空
  return *(buf_ptr - 1);
}

// ----------------------- 表达式生成核心 -----------------------

// 生成一个随机数字 (原逻辑: 1~9)，并追加到 buf 中
static void gen_num() {
  // 生成 1~9 之间的随机数
  word_t num = (rand() % 9) + 1;
  char num_str[4];
  snprintf(num_str, sizeof(num_str), "%u", num); // 转为字符串
  append_str(num_str);
}

// 生成一个随机操作符 (+, -, *, /)，并追加到 buf 中
static void gen_rand_op() {
  static const char ops[] = {'+', '-', '*', '/'};
  word_t idx = choose(4);
  append_char(ops[idx]);
}

// 递归生成随机表达式
static void gen_rand_expr() {
  switch (choose(3)) {
    case 0: {
      // case 0: 生成一个数字
      // 原代码里如果上一个字符是 ')' 则改为递归，否则生成数字
      if (last_char() == ')') {
        // 避免形如 ")3" 这样的非法拼接
        // 做法1: 补个操作符再生成数字
        // append_char('*'); // 或其他操作符
        // gen_num();

        // 做法2: 直接改为生成完整子表达式
        gen_rand_expr();
      } else {
        gen_num();
      }
      break;
    }
    case 1: {
      // case 1: 生成带括号的子表达式
      // “只有在操作符后面才插入括号” 的原思路：如果最后一个字符是操作符
      // 或 buf 还空着，才添加 '('
      char c = last_char();
      if (c == '+' || c == '-' || c == '*' || c == '/' || c == '\0') {
        append_char('(');
        gen_rand_expr();
        append_char(')');
      } else {
        // 否则就再生成一个随机表达式
        gen_rand_expr();
      }
      break;
    }
    default: {
      // case 2: 生成“expr op expr”
      gen_rand_expr();
      gen_rand_op();
      gen_rand_expr();
      break;
    }
  }
}

// 检查表达式中是否含有除零 “/0”
static int has_div_by_zero() {
  // 简易检索：找"/0"子串
  const char *p = strstr(buf, "/0");
  // 如果真的只生成 1~9 的数字，这里或许不会出除0，但还是保留检查
  return (p != NULL);
}

// ----------------------- main: 测试入口 -----------------------

int main(int argc, char *argv[]) {
  // 用当前时间做随机种子
  srand((unsigned)time(NULL));

  // 默认生成1个表达式；可通过命令行参数调整
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }

  for (int i = 0; i < loop; i++) {
    // 先清空 buf，并重置 buf_ptr
    memset(buf, 0, sizeof(buf));
    buf_ptr = buf;

    // 生成随机表达式
    gen_rand_expr();

    // 如果检测到除零，则重新来一轮
    if (has_div_by_zero()) {
      i--;
      continue;
    }

    // 拼装可执行C代码
    snprintf(code_buf, sizeof(code_buf), code_format, buf);

    // 将生成的C代码写入临时文件
    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    // 尝试编译
    int ret = system("gcc /tmp/.code.c -o /tmp/.expr");
    if (ret != 0) {
      // 若编译失败, 跳过
      continue;
    }

    // 运行编译出的程序, 获取输出
    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    unsigned result = 0;
    ret = fscanf(fp, "%u", &result);
    pclose(fp);

    // 打印运算结果和表达式
    printf("%u %s\n", result, buf);
  }

  return 0;
}
