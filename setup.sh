#!/bin/sh

git pull origin master
git submodule init
(cd modules/mruby/ && git checkout include/mrbconf.h)
git submodule foreach 'git pull origin master'
git submodule update
sed -i -e s/typedef\ int\ mrb_int/typedef\ long\ mrb_int/g modules/mruby/include/mrbconf.h
sed -i -e s/define\ MRB_INT_MIN\ INT_MIN/define\ MRB_INT_MIN\ LONG_MIN/g modules/mruby/include/mrbconf.h
sed -i -e s/define\ MRB_INT_MAX\ INT_MAX/define\ MRB_INT_MAX\ LONG_MAX/g modules/mruby/include/mrbconf.h

sh ./bin/build-libffi.sh
sh ./bin/build-mrbc.sh
