//
//  AppDelegate.m
//  mobiruby-ios
//
//  Created by Yuichiro MASUI on 9/10/12.
//  Copyright (c) 2012 MobiRuby Developers. All rights reserved.
//

#import "AppDelegate.h"
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
@implementation AppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    mrb_state *mrb = mrb_open();
    mrb->ud = malloc(sizeof(struct mrb_state_ud));
    
    cfunc_state_offset = cfunc_offsetof(struct mrb_state_ud, cfunc_state);
    init_cfunc_module(mrb);
    
    cocoa_state_offset = cocoa_offsetof(struct mrb_state_ud, cocoa_state);
    init_cocoa_module(mrb);
    
    init_cocoa_bridgesupport(mrb);
    init_mobiruby_common_module(mrb);
    
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
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
