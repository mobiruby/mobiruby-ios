#!/bin/sh

git pull origin master
git submodule init
git submodule update
(cd modules/mruby/ && git checkout include/mrbconf.h)
git submodule foreach 'git pull origin master'
sed -i -e "s/typedef int mrb_int/typedef int64_t mrb_int/g" modules/mruby/include/mrbconf.h
sed -i -e "s/define MRB_INT_MIN INT_MIN/define MRB_INT_MIN INT64_MIN/g" modules/mruby/include/mrbconf.h
sed -i -e "s/define MRB_INT_MAX INT_MAX/define MRB_INT_MAX INT64_MAX/g" modules/mruby/include/mrbconf.h

sh ./bin/build-libffi.sh
sh ./bin/build-mrbc.sh

echo "Installing RubyGems. please input your password"
GEM_HOME= GEM_PATH= sudo /usr/bin/gem install xcodeproj nokogiri --no-rdoc --no-ri
