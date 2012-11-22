#!/bin/sh

git pull origin master
git submodule init
git submodule update
(cd modules/mruby/ && git checkout include/mrbconf.h)
git submodule foreach 'git pull origin master'
sed -i -e 's/\/\/\#define MRB_INT64/\#define MRB_INT64/' modules/mruby/include/mrbconf.h

sh ./bin/build-libffi.sh
sh ./bin/build-mrbc.sh
