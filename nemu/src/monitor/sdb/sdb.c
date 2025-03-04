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
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <stdio.h>
#include <string.h>
#include "sdb.h"
#include "common.h"
#include <memory/vaddr.h>

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_help(char *args);

static int cmd_si(char* args){
  int n = args == NULL ? 1 : atoi(args);
  cpu_exec(n);
  return 0;
}

static int cmd_info(char *args){
  if(args == NULL || args[0]=='r')
    isa_reg_display(&cpu);
  else if(args[0] == 'w')
    print_wp();
  return 0;
}

static int cmd_x(char* args){
  char* arg1 = strtok(args, " ");
  char* arg2 = args + strlen(arg1) + 1;
  int n = atoi(arg1);
  vaddr_t addr;
  sscanf(arg2, "%x", &addr);
  for(int i = 0; i<n; i++){
    printf("(0x%x) = 0x%x\n", addr+i*4, vaddr_read(addr+i*4, 4));
  }
  return 0;
}

static int cmd_p(char* args){
  bool success;
  word_t result = expr(args, &success);
  if(success) printf("%s = 0x%x\n", args, result);
  else printf("Invalid expression\n");
  return 0;
}

static int cmd_w(char* args){
  WP* wp = new_wp();
  bool success;
  wp->value = expr(args, &success);
  strcpy(wp->expression, args);
  printf("Watchpoint %d\n", wp->NO);
  return 0;
}

static int cmd_d(char* args){
  free_wp(get_wp(atoi(args)));
  return 0;
}

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  { "si", "Single execute", cmd_si},
  { "info", "NEMU information", cmd_info},
  { "x", "Print memory", cmd_x},
  { "p", "Expression value", cmd_p},
  { "w", "Add watchpoint", cmd_w},
  { "d", "Delete watchpoint", cmd_d},
  
  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }
  /*FILE *fp = fopen("/home/mland/ysyx-workbench/nemu/tools/gen-expr/input", "r");
  char line[1000];
  int n = 0;
  while (fgets(line, sizeof(line), fp)) {
    line[strcspn(line, "\n")] = 0;
    char *space_pos = strchr(line, ' ');
    char result[34];
    strncpy(result, line, space_pos - line);
    result[space_pos - line] = '\0';  // 添加字符串结束符
    char *expression = space_pos + 1;
    bool success;
    word_t r1 = expr(expression, &success);
    word_t r2;
    sscanf(result, "%u", &r2);
    if(r1 != r2)
    {
      printf("r1 = %d, r2 = %d\nexpression = %s\n", r1, r2, expression);
      exit(0);
    }
    else {
      printf("%d: %s = %d\n", n, expression, r1);
      n++;
    }
    
  }
  fclose(fp);
  */

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
