# 
# Build configration for *.sh 
# 

PLATFORM_IOS=`xcode-select -print-path`"/Platforms/iPhoneOS.platform/"
PLATFORM_IOS_SIM=`xcode-select -print-path`"/Platforms/iPhoneSimulator.platform/"
GCC_PLATFORM_IOS=`xcode-select -print-path`
GCC_PLATFORM_IOS_SIM=${PLATFORM_IOS_SIM}"/Developer/"
SDK_IOS_VERSION=`ls "$PLATFORM_IOS/Developer/SDKs/" | ruby -e "p STDIN.read.split(/\s+/).map{|i| /[.\d]+/.match(i.gsub('.sdk', '')).to_a.first.to_f}.max"`
MIN_IOS_VERSION="6.0"
