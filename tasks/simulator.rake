if ENV['TRAVIS']
  IOS_SIM = '/usr/local/bin/ios-sim'
else
  IOS_SIM = './bin/ios-sim'
end

file IOS_SIM do
  if ENV['TRAVIS']
    sh %Q{brew install ios-sim}
  else
    sh %Q{cd ./submodules/ios-sim; rake install prefix=../../}
  end
end

desc 'Run your app on iOS simulator'
task :run => [IOS_SIM, DEBUG_APP_DIR] do
  sh %Q{#{IOS_SIM} launch "#{DEBUG_APP_DIR}" 2>&1}
end

desc 'Run your app on iOS simulator with LLDB'
task :debug => [IOS_SIM, DEBUG_APP_DIR] do
  sh %Q{#{IOS_SIM} launch "#{DEBUG_APP_DIR}" --debug 2>&1}
end

