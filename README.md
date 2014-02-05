## Welcome to MobiRuby for iOS (alpha)

Notice: It's for mruby and iOS hackers

## Current status

- Supporting iOS7, 64bit and Mavericks.


## Getting started

At first time, you might need to install the below system gems:

```
gem install xcodeproj -v=0.3.5
gem install nokogiri
```
If you used rbenv, please run 'rbenv local system' before.


And then, type the commands in terminal:

```
git clone https://github.com/mobiruby/mobiruby-ios.git
cd mobiruby-ios
git checkout develop
rake
```

If you use XCode beta version, you should modify ``bin/build-config.sh`` or set up xcode-select correctly.

Download iOS 7.0 Simulator in Xcode.app, if you use Xcode beta version.

It's tested only Mavericks and XCode 5.0.x

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
