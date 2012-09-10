#!/bin/sh

cd modules/mruby
make clean
make
cp bin/mrbc ../../bin/
