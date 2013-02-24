IOS_SIM = './bin/ios-sim'

file IOS_SIM do
  sh %Q{cd ios-sim; rake install prefix=../}
end

desc 'Run your app on iOS simulator'
task :run => [IOS_SIM, DEBUG_APP_DIR] do
  sh %Q{#{IOS_SIM} launch "#{DEBUG_APP_DIR}" 2>&1}
end
