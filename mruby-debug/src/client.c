#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <unistd.h>//for close() for socket
#include <arpa/inet.h>
#include <netdb.h>

#include "mruby_debug.h"
#include "mruby/hash.h"
#include "mruby/string.h"

//void mrb_mruby_debug_gem_client_init(mrb_state *mrb, struct debug_hook *hook)

static
void* recv_command_thread(void *hook_p)
{
  struct debug_hook *hook = hook_p;
  char buf[512];
  char *cur = buf;
  size_t cur_len = 0;
  int i;
  while(1) {
    int rlen = recv(hook->debug_conn, cur, sizeof(buf) - cur_len - 1, 0);
    cur_len += rlen;
    bool eoc = false;
    buf[cur_len] = '\0';
    for(i = 0; i < rlen; ++i) {
      if(cur[i] == '\r' || cur[i] == '\n') {
        cur[i] = '\0';
        eoc = true;
      }
    }
    cur += rlen;

    if(eoc) {
      if(strcmp("RESUME", buf) == 0) {
        pthread_mutex_unlock(&hook->step_exec_mutex);
      }
      cur = buf;
      cur_len = 0;
    }
  }
}


static mrb_value
mrb_debug_server(mrb_state *mrb, mrb_value klass)
{
  int argc;
  mrb_value options;
  int wait = 0;
  struct sockaddr_in addr;
  int len = sizeof(struct sockaddr_in);

  addr.sin_port = htons(8990);

  argc = mrb_get_args(mrb, "|H", &options);
  if(argc > 0) {
    mrb_value val;
    val = mrb_hash_get(mrb, options, mrb_symbol_value(mrb_intern(mrb, "port")));
    if(!mrb_nil_p(val)) {
      addr.sin_port = htons(mrb_fixnum(val));
    }

    val = mrb_hash_get(mrb, options, mrb_symbol_value(mrb_intern(mrb, "wait")));
    if(!mrb_nil_p(val)) {
      wait = 1;
    }
    printf("wait=%d\n", wait);
  }

  struct debug_hook *hook = mrb_mruby_debug_gem_hook(mrb);

  pthread_mutex_init(&hook->step_exec_mutex, NULL);

  hook->step_exec = true;
  pthread_mutex_lock(&hook->step_exec_mutex);

  if ((hook->debug_listen = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    puts("Debugger error");
    exit(EXIT_FAILURE);
  }

  addr.sin_family = PF_INET;
  addr.sin_addr.s_addr = INADDR_ANY;
  if (bind(hook->debug_listen, (struct sockaddr *)&addr, len) < 0) {
    puts("Bind error");
    exit(EXIT_FAILURE);
  }

  if (listen(hook->debug_listen, SOMAXCONN) < 0) {
    puts("Listen error");
    exit(EXIT_FAILURE);
  }

  struct sockaddr_in caddr;
  if ((hook->debug_conn = accept(hook->debug_listen, (struct sockaddr *)&caddr, &len)) < 0) {
    puts("Accept error");
    exit(EXIT_FAILURE);
  }
 
  if (pthread_create(&hook->worker, NULL, (void *)recv_command_thread, (void *)hook) != 0) {
    puts("pthread_create error");
    exit(EXIT_FAILURE);
  }
  pthread_detach(hook->worker);

  return mrb_nil_value();
}

void
mrb_mruby_debug_gem_client_init(mrb_state *mrb, struct debug_hook *hook)
{
  struct RClass *class_debug;
  class_debug = mrb_define_class(mrb, "Debug", mrb->object_class);

  mrb_define_class_method(mrb, class_debug, "server", mrb_debug_server, ARGS_ANY());
}

void
mrb_mruby_debug_gem_client_final(mrb_state *mrb, struct debug_hook *hook)
{
  pthread_cancel(hook->worker);

  if(hook->debug_conn > 0) {
    close(hook->debug_conn);
  }
  if(hook->debug_listen > 0) {
    close(hook->debug_listen);
  }
}
