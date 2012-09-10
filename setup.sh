#!/bin/sh

git submodule init
git submodule update
sh ./bin/build-libffi.sh
sh ./bin/build-mrbc.sh
