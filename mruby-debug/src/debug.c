#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <unistd.h>//for close() for socket

#include "mruby.h"
#include "mruby/irep.h"

#include "mruby_debug.h"


static struct debug_hook *saved_hooks = NULL;
static int mrb_count = 0;

static void
wait_command(mrb_state *mrb, struct debug_hook *hook, const char* command)
{
  if(hook->step_exec) {
    pthread_mutex_lock(&hook->step_exec_mutex);
  }
}

struct debug_hook* mrb_mruby_debug_gem_hook(struct mrb_state* mrb) {
  int i;
  for(i = 0; i < mrb_count; ++i) {
    if(saved_hooks[i].mrb == mrb) {
      return &saved_hooks[i];
    }
  }
  return NULL;
}

void hook_vm_fetch_code(struct mrb_state *mrb, mrb_irep *irep, mrb_code *pc, mrb_value *regs) {
  struct debug_hook *hook = mrb_mruby_debug_gem_hook(mrb);

  size_t offset = (pc - irep->iseq);
  if(irep->filename && irep->lines) {
    int lineno = irep->lines[offset];
    if(hook->lineno != lineno || hook->filename != irep->filename) {
      hook->lineno = lineno;
      hook->filename = irep->filename;

      if(hook->debug_conn > 0) {
        char buf[512];
        snprintf(buf, sizeof(buf), "TRACE\t%s\t%d\r\n", irep->filename, lineno);
        send(hook->debug_conn, buf, strlen(buf), 0);
        wait_command(mrb, hook, "RESUME");

      }
    }
  }

  if(hook->saved_code_fetch_hook) {
    hook->saved_code_fetch_hook(mrb, irep, pc, regs);
  }
}

void mrb_mruby_debug_gem_init(mrb_state* mrb) {
  /* saved original hooks */
  ++mrb_count;
  saved_hooks = mrb_realloc(mrb, saved_hooks, sizeof(struct debug_hook) * mrb_count);
  struct debug_hook *hook = &saved_hooks[mrb_count - 1];
  bzero(hook, sizeof(struct debug_hook));
  hook->mrb = mrb;
  hook->saved_code_fetch_hook = mrb->code_fetch_hook;
  mrb->code_fetch_hook = hook_vm_fetch_code;

  mrb_mruby_debug_gem_client_init(mrb, hook);
}

void mrb_mruby_debug_gem_final(mrb_state* mrb) {
  int i;
  for(i = 0; i < mrb_count; ++i) {
    if(saved_hooks[i].mrb == mrb) {
      mrb_mruby_debug_gem_client_final(mrb, &saved_hooks[i]);
      mrb->code_fetch_hook = saved_hooks[i].saved_code_fetch_hook;
      --mrb_count;
      memcpy(&saved_hooks[i], &saved_hooks[i+1], (mrb_count - i));
      saved_hooks = mrb_realloc(mrb, saved_hooks, sizeof(struct debug_hook) * mrb_count);
      return;
    }
  }
}
