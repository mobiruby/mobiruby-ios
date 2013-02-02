#!/bin/sh

git submodule init
git submodule update
sh ./bin/build-libffi.sh

ruby build-libmruby.rb clean libmruby test
