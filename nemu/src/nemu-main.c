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

#include <common.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE_LENGTH 1024
word_t expr(char *e, bool *success);
int result;
 bool flag = false;
void init_monitor(int, char *[]);
void am_init_monitor();
void engine_start();
int is_exit_status_bad();

int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
#ifdef CONFIG_TARGET_AM
  am_init_monitor();
#else
  init_monitor(argc, argv);
#endif


    // FILE *fp = fopen("/home/ylj/gdb_test/gen_expr/input", "r");
    // // FILE *fp = fopen("/home/ylj/ysyx-workbench/nemu/tools/gen-expr/build/input", "r");

    // if (fp == NULL) {
    //     perror("Failed to open file");
    //     return 1;
    // }
    // char line[MAX_LINE_LENGTH];  // 用来存储每一行的表达式
    // while (fgets(line, sizeof(line), fp)) {
    //     // 去除行末的换行符
    //     line[strcspn(line, "\n")] = '\0';  // 去掉 '\n' 字符

    //     // 查找第一个空格，跳过计算结果部分
    //     char *expression = strchr(line, ' ');
    //     if (expression != NULL) {
    //         expression++;
    //         printf("Expression: %s\n", expression);
    //          expr(expression, &flag);

    //   }
    // }


  /* Start engine. */
  engine_start();

  return is_exit_status_bad();
}
