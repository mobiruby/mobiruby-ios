#!/bin/sh

cd modules/mruby
./minirake clean
./minirake all
cp bin/mrbc ../../bin/
