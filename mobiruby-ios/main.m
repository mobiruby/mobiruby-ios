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

#include <mruby.h>
#include <mruby/proc.h>
#include <mruby/dump.h>
#include <mruby/compile.h>
#include <mruby/data.h>

#include "cfunc_pointer.h"

extern const char mruby_data_app[];
@class ScriptRunnerViewController;

void init_cocoa_bridgesupport(mrb_state *mrb);

static
void mrb_state_init(mrb_state *mrb)
{
    init_cocoa_bridgesupport(mrb);
}

mrb_state* open_mobiruby() 
{
    mrb_state *mrb = mrb_open();
    mrb_state_init(mrb);

    return mrb;
}

void eval_mobiruby(const char* str, UIViewController *viewController) 
{
    mrb_state *mrb = open_mobiruby();

    mrb_load_string(mrb, "require 'mobiruby'");
    if (mrb->exc) {
        mrb_p(mrb, mrb_obj_value(mrb->exc));
        exit(0);
    }

    mrb_load_string(mrb, "require 'script_runner'");
    if (mrb->exc) {
        mrb_p(mrb, mrb_obj_value(mrb->exc));
        exit(0);
    }

    mrb_funcall(mrb, mrb_top_self(mrb), "run_console", 2, cfunc_pointer_new_with_pointer(mrb, viewController, false), mrb_str_new_cstr(mrb, str));
    if (mrb->exc) {
        mrb_p(mrb, mrb_obj_value(mrb->exc));
        exit(0);
    }

    mrb_close(mrb);
}


int main(int argc, char *argv[])
{
    @autoreleasepool {
        mrb_state *mrb = open_mobiruby();
                
        mrb_load_irep(mrb, mruby_data_app);
        if (mrb->exc) {
            mrb_p(mrb, mrb_obj_value(mrb->exc));
            exit(0);
        }
        
        return UIApplicationMain(argc, argv, nil, @"AppDelegate");
    }
}
