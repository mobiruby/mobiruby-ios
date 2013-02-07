SIMULATOR_VERSION=5.0

all:
	ruby build-libmruby.rb libmruby test

test: all
	xcodebuild -configuration Debug -sdk iphonesimulator$(SIMULATOR_VERSION) -target mrbtest clean build
	sleep 5
	ios-sim launch build/Debug-iphonesimulator/mrbtest.app --sdk $(SIMULATOR_VERSION)

setup:
	git submodule init
	git submodule update
	make all

clean:
	ruby build-libmruby.rb clean
