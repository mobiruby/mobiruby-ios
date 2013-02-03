#!/bin/sh

git submodule init
git submodule update

ruby build-libmruby.rb clean libmruby #test
