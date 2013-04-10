TEST_SIMULATOR_VERSION = ENV['TEST_SIMULATOR_VERSION']

desc 'Run test on iOS simulator'
task :sim_test => [IOS_SIM, File.expand_path('lib/libmruby.a'), File.expand_path('submodules/mruby/build/i386/test/mrbtest.a')] do
  sh %Q{osascript -e 'tell app "iPhone Simulator" to quit'}
  sleep 2
  sh %Q{xcodebuild -configuration Debug -sdk iphonesimulator -target mrbtest clean build}
  sleep 2
  sh %Q{rm -f test.log}
  sh %Q{#{IOS_SIM} launch build/Debug-iphonesimulator/mrbtest.app --stdout test.log #{TEST_SIMULATOR_VERSION ? "--sdk #{TEST_SIMULATOR_VERSION}" : ''} || true}
  sh %Q{cat test.log}
  sh %Q{osascript -e 'tell app "iPhone Simulator" to quit'}
  raise "Tests failed" unless `tail -n 1 test.log`.chomp == 'PASSED'
end
