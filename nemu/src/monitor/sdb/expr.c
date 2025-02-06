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

#include <isa.h>
#include <memory/paddr.h>
#include <math.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum {
  TK_NOTYPE = 256, TK_EQ,

  /* TODO: Add more token types */
  NUM = 1,
  REG = 2,
  HEX = 3,
  EQ = 4,
  NOTEQ = 5,
  OR = 6,
  AND = 7,
  LEFT = 8,
  RIGHT = 9,
  LEQ = 10,
  DEREF

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"\\+", '+'},         // plus
  {"\\-", '-'},         // sub
  {"\\*", '*'},         // mul
  {"\\/", '/'},         // div

  {"\\(", LEFT},
  {"\\)", RIGHT},
  {"<=", LEQ},            // leq
  {"\\=\\=", EQ},        // equal
  {"\\!\\=", NOTEQ},

  {"\\|\\|", OR},       // Opetor
  {"\\&\\&", AND},
  {"\\!", '!'},

  {"\\$[a-zA-Z]*[0-9]*", REG},
  {"0[xX][0-9a-fA-F]+", HEX},
  {"[0-9]*", NUM},

};

#define NR_REGEX ARRLEN(rules)  //// calculate the length of an array

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[10000];
} Token;

static Token tokens[10000] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

int len = 0; // Record the struct tokens length.
// bool division_zero;

static bool make_token(char *e) {
char hex_str[20];
char reg_str[20];
bool reg_str_flag = false;
  // printf("Evaluating: %s\n", e);//detect expression
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    // printf("Character at position %d: %c\n", position, e[position]);
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) { //遍历所有rule
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        // char *substr_start = e + position;
        int substr_len = pmatch.rm_eo ;//- pmatch.rm_so;
        position += substr_len;


         
        Token tmp_token;
        switch (rules[i].token_type) {
            case '+': tmp_token.type = '+'; tokens[nr_token ++] = tmp_token; break;
            case '-': tmp_token.type = '-'; tokens[nr_token ++] = tmp_token; break;
            case '*': tmp_token.type = '*'; tokens[nr_token ++] = tmp_token;break;
            case '/': tmp_token.type = '/'; tokens[nr_token ++] = tmp_token;break;
            case 256:break;
            case '!': tmp_token.type = '!'; tokens[nr_token ++] = tmp_token;break;
            case 9: tmp_token.type = ')'; tokens[nr_token ++] = tmp_token;break;
            case 8: tmp_token.type = '('; tokens[nr_token ++] = tmp_token;break;
            case 1: // number
                tokens[nr_token].type = 1;
                strncpy(tokens[nr_token].str, &e[position - substr_len], substr_len);
                // printf("tokens[nr_token].str:%s ,nr_token=%d\n",tokens[nr_token].str ,nr_token);
                nr_token ++;
                break;
            case 2: // reg
                tokens[nr_token].type = 2;
                strncpy(reg_str, &e[position - substr_len+1], substr_len-1);//起始位置+1，消除$
                word_t reg_value = isa_reg_str2val(reg_str, &reg_str_flag);
                // printf("reg_str:%s ,reg_value=%d\n",reg_str ,reg_value);
                snprintf(tokens[nr_token].str, sizeof(tokens[nr_token].str), "%d", reg_value);
                // printf("tokens[nr_token].str:%s ,reg_value=%d\n",tokens[nr_token].str ,reg_value);
                nr_token ++;
                reg_str_flag = false;
                break;
            case 3: // HEX
                tokens[nr_token].type = 3;
                strncpy(hex_str, &e[position - substr_len], substr_len);
                // printf("tokens[nr_token].str:%s ,nr_token=%d\n",hex_str ,nr_token);
                int hextonum = strtol(hex_str,NULL,16);//进制转换
                snprintf(tokens[nr_token].str, sizeof(tokens[nr_token].str), "%d", hextonum);
                nr_token ++;
                break;
            case 4:
                tokens[nr_token].type = 4;
                strcpy(tokens[nr_token].str, "==");
                nr_token++;
                break;
            case 5:
                tokens[nr_token].type = 5;
                strcpy(tokens[nr_token].str, "!=");
                nr_token++;
                break;
            case 6:
                //  printf("HELLO");
                tokens[nr_token].type = 6;
                strcpy(tokens[nr_token].str, "||");
                nr_token++;
                break;
            case 7:
                tokens[nr_token].type = 7;
                strcpy(tokens[nr_token].str, "&&");
                nr_token++;
                break;
            case 10:
                tokens[nr_token].type = 10;
                strcpy(tokens[nr_token].str, "<=");
                nr_token++;
                break;
            default:
                printf("i = %d and No rules is com.\n", i);
                break;
        }
          len = nr_token;
        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}


bool check_parentheses(int p, int q){
    int left_cnt=0;
    // int right_cnt=0;
    int count = 0;
    if(tokens[p].type != '('  || tokens[q].type != ')')
        return false;
    for (int i = p; i <= q; i++){
        if (tokens[i].type == '(' ) left_cnt++;
        if (tokens[i].type == ')' ) 
        {
            left_cnt--;
            if (left_cnt == 0) count++;
        }
    } 
       if (count == 1) return true;
        else return false;

}


//计算整个表达式
uint32_t eval(int p, int q) {
    // printf("p: %d\n q: %d\n", p , q);
    if (p > q) {
        // printf("p: %d\n q: %d\n", p , q);
        // 错误的表达式
        assert(0);
        return -1;
    }
    else if (p == q) {
        // 只有一个 token，应该是数字
        // printf("tokens[%d].str:%s\n",p , tokens[p].str);
        return atoi(tokens[p].str);
    }
    else if (check_parentheses(p, q)) {
        // 去掉括号
        return eval(p + 1, q - 1);
    } else {
        int op = -1; // 操作符的下标
        // bool flag = false;
// 优先级：先处理乘除，再处理加减，最后处理关系运算
// int op = -1;
int op_type = -1;
int priority = -1;  // 优先级
int cnt= 0;
int current_priority = -2;

// 扫描操作符，按优先级分层
for (int i = p; i <= q; i++) {
 current_priority = -2;
 //区分指针和乘法
    if  ( tokens[i].type == '*' || tokens[i].type == DEREF ){
        if ( !(i != 0 && (tokens[i - 1].type ==')' || tokens[i - 1].type == NUM)) ) 
        {
            tokens[i].type = DEREF;
            current_priority = 0;
        }
    }
//判断括号
    if (tokens[i].type == '(' ) cnt++;
    if (tokens[i].type == ')' ) cnt--;
//当有括是，不进行（+-*/）
if(cnt == 0){

    if (tokens[i].type == '*' || tokens[i].type == '/') {
        current_priority = 1;  // 乘除运算优先级
    } else if (tokens[i].type == '+' || tokens[i].type == '-') {
        current_priority = 2;  // 加减运算优先级
    } else if (tokens[i].type == EQ || tokens[i].type == NOTEQ || tokens[i].type == LEQ) {
        current_priority = 3;  // 关系运算符优先级
    }

    // //主运算符号,current_priority越大，运算优先级越低，作为主运算符
    if (current_priority >= priority ) {
        op = i;
        op_type = tokens[i].type;
        priority = current_priority;
    }
}
}
        // 如果没有找到任何操作符
        if (op == -1) {
            assert(0);
            return -1;
        }

    int val2 = eval(op + 1, q);  // 计算右边的值
        // printf("val2=%d op_type=%d\n",val2,op_type);
     if(tokens[op].type==DEREF) 
     
     return  paddr_read(val2,4);


    int val1 = eval(p, op - 1);  // 计算左边的值        
        // printf("val1=%d , val2=%d op_type=%d\n",val1,val2,op_type);

        switch (op_type) {
            case '+':return val1 + val2;
            case '-': return val1 - val2;
            case '*':return val1 * val2;
            case '/':
                    if(val2==0) 
                    {
                        printf("error: division by zero");
                        return 0;
                        // assert(0);
                        // return -1;
                    }  else 
                        return val1 / val2;
            case EQ:    return val1 == val2;
            case NOTEQ: return val1 != val2;
            case LEQ:   return val1 <= val2;
            case AND:   return val1 && val2;
            case DEREF: return paddr_read(val2,4);
            default: assert(0);
        }
    }
}



word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }else *success = true;

  /* TODO: Insert codes to evaluate the expression. */
  // TODO();
    // printf("Evaluating: %s\n", e);
    // printf("nr_token: %d\n", nr_token-1);
    word_t result = eval(0, nr_token - 1);//calculate from zero to nr_token-1
    printf("Calculated result: %u\n", result);//输出计算结果
    memset(tokens, 0, sizeof(tokens)); //清零结构体,防止二次计算受影响


    return result;



}
