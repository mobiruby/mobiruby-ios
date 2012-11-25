//
//  gh_unit_helper.m
//  mobiruby-ios
//
//  Created by Yuichiro MASUI on 11/26/12.
//  Copyright (c) 2012 MobiRuby Developers. All rights reserved.
//

#include <Foundation/Foundation.h>
#import <GHUnitIOS/GHUnit.h>
#import <GHUnitIOS/NSException+GHTestFailureExceptions.h>

id gh_assert(const char* desc)
{
   NSException *exp = [NSException exceptionWithName:GHTestFailureException reason:[NSString stringWithUTF8String:desc] userInfo:@{}];
   NSLog(@"exp=%@,%@",exp,[exp class]);
   return exp;
}

id test123(const char* desc){
   return [NSException exceptionWithName:GHTestFailureException reason:@"test" userInfo:@{}];
}