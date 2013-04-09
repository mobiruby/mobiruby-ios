## Welcome to MobiRuby for iOS (alpha)

Notice: It's for mruby and iOS hackers

## Current status

- @masuidrive: I'm working hard on [mruby](https://github.com/mruby/mruby) what support debugging feagture now - Mar 3rd, 2013
 
[![Build Status](https://secure.travis-ci.org/mobiruby/mobiruby-ios.png)](http://travis-ci.org/mobiruby/mobiruby-ios)


## Getting started

At first time, you might need to install the below gems:

```
GEM_HOME=/Library/Ruby/Gems/1.8 GEM_PATH=/Library/Ruby/Gems/1.8 sudo /usr/bin/gem install xcodeproj -v=0.3.5
GEM_HOME=/Library/Ruby/Gems/1.8 GEM_PATH=/Library/Ruby/Gems/1.8 sudo /usr/bin/gem install nokogiri rake
```

And then, type the commands in terminal:

```
git clone https://github.com/mobiruby/mobiruby-ios.git
cd mobiruby-ios
rake
```

If you use XCode beta version, you should modify ``bin/build-config.sh`` or set up xcode-select correctly.

It's tested only Mountain Lion and XCode 4.6.x

``src/app.rb`` is MobiRuby starting point. 

run ``rake`` is build and run on iOS simulator.

Let's change and hack it.





## Contributing

Feel free to open tickets or send pull requests with improvements.
Thanks in advance for your help!


## Authors

Original Authors "MobiRuby developers" are [https://github.com/mobiruby/mobiruby-ios/tree/master/AUTHORS](https://github.com/mobiruby/mobiruby-ios/tree/master/AUTHORS)


## License

 "MobiRuby for iOS" is released under the MIT license:

* http://www.opensource.org/licenses/mit-license.php
