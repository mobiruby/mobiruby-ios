#!/bin/sh

ruby run_test.rb clean all
lipo -create tmp/mruby/build/i386/lib/libmruby.a tmp/mruby/build/armv7/lib/libmruby.a tmp/mruby/build/armv7s/lib/libmruby.a -output libmruby.a
