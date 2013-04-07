#include "mruby.h"
#include "mruby/irep.h"
#include <pthread.h>
#include <stdbool.h>

struct debug_hook {
  mrb_state *mrb;
  
  uint16_t lineno;
  const char *filename;

  int debug_listen;
  int debug_conn;

  void (*saved_code_fetch_hook)(struct mrb_state* mrb, struct mrb_irep *irep, mrb_code *pc, mrb_value *regs);

  pthread_t worker;

  bool step_exec;
  pthread_mutex_t step_exec_mutex;
};

struct debug_hook* mrb_mruby_debug_gem_hook(struct mrb_state* mrb);
void mrb_mruby_debug_gem_client_init(mrb_state*, struct debug_hook*);
void mrb_mruby_debug_gem_client_final(mrb_state*, struct debug_hook*);
