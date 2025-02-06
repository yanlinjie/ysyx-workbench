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

#include "sdb.h"
#include <assert.h>
#include <stdio.h>
#include <regex.h>
#include <stdbool.h>

#define NR_WP 32

typedef struct watchpoint {
  int NO;                       //监视点编号
  struct watchpoint *next;         //指向下一个监视点的指针，用于链表管理

  /* TODO: Add more members if necessary */
  bool flag; // to record used or unused
  char expr[100]; //保存监视的表达式
  int value;  //当前值
char type;
} WP;

// 初始化监视点池，最多支持 NR_WP 个监视点
static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL; // head指向已分配的监视点链表，free_指向空闲监视点链表


//初始化
void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;              // 初始化每个监视点编号
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]); // 设置监视点链表
    wp_pool[i].flag = false;       // 初始化标记为未使用
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */



//断点
bool is_valid_expr(const char *expr) {
    // 定义正则表达式：允许空格的 $寄存器 == ADDR
    const char *pattern = "^\\$[a-zA-Z][a-zA-Z0-9]*\\s*==\\s*0x[0-9a-fA-F]+$";

    // 编译正则表达式
    regex_t regex;
    int ret = regcomp(&regex, pattern, REG_EXTENDED);
    if (ret != 0) {
        printf("Failed to compile regex.\n");
        return false;
    }

    // 匹配表达式
    ret = regexec(&regex, expr, 0, NULL, 0);
    regfree(&regex);

    // 如果匹配成功，返回 true，否则返回 false
    return ret == 0;
}

// 从空闲链表中分配一个监视点
WP* new_wp(){
    for(WP* p = free_ ; p -> next != NULL ; p = p -> next){ //遍历空闲链表
        if( p -> flag == false){    
            p -> flag = true;  //标记
            if(head == NULL){    
            head = p;
            }
            return p;  //
        }
    }
    printf("No unuse point.\n");
    assert(0);
    return NULL;

}

// 将监视点归还到空闲链表
void free_wp(WP *wp){
    if(head -> NO == wp -> NO){  //如果要删除头部监视点
    	head -> flag = false;       //置0
      head = NULL;  //指针置空
      printf("Delete watchpoint  success.\n");
      return ;
    }
    for(WP* p = head ; p -> next != NULL ; p = p -> next){
//	printf("wp -> no = %d , head -> no = %d, p -> no = %d.\n", wp -> NO, p-> NO, head -> NO);
	if(p -> next -> NO  == wp -> NO)
	{
	    p -> next = p -> next -> next;
	    p -> next -> flag = false; // 没有被使用
	    printf("free succes.\n");
	    return ;
	}
    }
}

void sdb_watchpoint_display(){
  // printf("hello\n");
    bool watchpoint_flag = true;
    for(int i = 0 ; i < NR_WP ; i ++){
        // printf("hello\n");
        if(wp_pool[i].flag){
            printf("type: %c  No: %d, expr = \"%s\",  value = 0x%x , flag = %d\n",wp_pool[i].type, wp_pool[i].NO, wp_pool[i].expr, wp_pool[i].value ,wp_pool[i].flag);
            watchpoint_flag = false;
        }
    }
    if(watchpoint_flag) printf("No watchpoint now.\n");
}

//删除
void delete_watchpoint(int no){
    for(int i = 0 ; i < NR_WP ; i ++)
        if(wp_pool[i].NO == no){
            free_wp(&wp_pool[i]);
            return ;
        }
}

//新建
void create_watchpoint(char* args){
    WP* p =  new_wp();
    strcpy(p -> expr, args);//将表达式保存至监视点中
    bool success = false;
    if(is_valid_expr(p -> expr)) p -> type = 'b';//判断是否为断点
    else p->type = 'w';

    int tmp = expr(p -> expr,&success);  //计算表达式
   if(success) p -> value = tmp; //保存计算值
   else printf("expr error\n");
    printf("Create watchpoint No.%d success.\n", p -> NO);
}

// Scan all watchpoint.
void scan_watchpoint(){
    // printf("hello");
    int old_value=0;
    for(int i = 0 ; i < NR_WP; i ++){
        if(wp_pool[i].flag)
        {
            if(wp_pool[i].type=='b')
            {
                bool success = false;
                printf(" expr = \"%s\"\n", wp_pool[i].expr);
                int tmp = expr(wp_pool[i].expr,&success);
                if(success){
                    if(tmp == 1)
                    {
                        old_value = wp_pool[i].value;
                        wp_pool[i].value = tmp;
                        nemu_state.state = NEMU_STOP;
                        printf("Watchpoint triggered: value changed.\n old_value = %d\n new_value = %d\n" , old_value ,wp_pool[i].value );

                        return ;
                    }
                    if(tmp != wp_pool[i].value)
                    {
                        old_value = wp_pool[i].value;
                        wp_pool[i].value = tmp;
                        nemu_state.state = NEMU_STOP;
                        printf("Watchpoint triggered: value changed.\n old_value = %d\n new_value = %d\n" , old_value ,wp_pool[i].value );

                        return ;
                    }
                } 
            } else{
                    bool success = false;
                    printf(" expr = \"%s\"\n", wp_pool[i].expr);
                    int tmp = expr(wp_pool[i].expr,&success);
                    if(success){
                        if(tmp != wp_pool[i].value)
                        {

                            old_value = wp_pool[i].value;
                            wp_pool[i].value = tmp;
                            nemu_state.state = NEMU_STOP;
                            printf("Watchpoint triggered: value changed.\n old_value = %d\n new_value = %d\n" , old_value ,wp_pool[i].value );

                            return ;
                        }
                    } else{
                        printf("expr error.\n");
                        assert(0);
                    }
            }



        }
    }
}