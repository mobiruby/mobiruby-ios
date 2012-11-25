//
//  main.m
//  mobiruby-ios
//
//  Created by Yuichiro MASUI on 9/10/12.
//  Copyright (c) 2012 MobiRuby Developers. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "cocoa.h"
#include "mobiruby_common.h"

#include <mruby/proc.h>
#include <mruby/dump.h>


extern const char mruby_data_app[];

void init_cocoa_bridgesupport(mrb_state *mrb);

struct mrb_state_ud {
    struct cfunc_state cfunc_state;
    struct cocoa_state cocoa_state;
};

static
void mrb_state_init(mrb_state *mrb)
{
    mrb->ud = malloc(sizeof(struct mrb_state_ud));
    init_cfunc_module(mrb, mrb_state_init);
    init_cocoa_module(mrb);
    
    init_cocoa_bridgesupport(mrb);
    init_mobiruby_common_module(mrb);
}

int main(int argc, char *argv[])
{
    @autoreleasepool {
        cfunc_state_offset = cfunc_offsetof(struct mrb_state_ud, cfunc_state);
        cocoa_state_offset = cocoa_offsetof(struct mrb_state_ud, cocoa_state);
        
        mrb_state *mrb = mrb_open();
        mrb_state_init(mrb);
        
        int n = mrb_read_irep(mrb, mruby_data_app);
        if (n >= 0) {
            mrb_irep *irep = mrb->irep[n];
            struct RProc *proc = mrb_proc_new(mrb, irep);
            proc->target_class = mrb->object_class;
            mrb_run(mrb, proc, mrb_nil_value());
        }
        else if (mrb->exc) {
            // fail to load.
            longjmp(*(jmp_buf*)mrb->jmp, 1);
        }
        
        if (mrb->exc) {
            mrb_p(mrb, mrb_obj_value(mrb->exc));
        }
        
        return UIApplicationMain(argc, argv, nil, @"GHUnitIOSAppDelegate");
    }
}
