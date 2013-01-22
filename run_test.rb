#!/usr/bin/env ruby

if __FILE__ == $PROGRAM_NAME
  require 'fileutils'
  FileUtils.mkdir_p 'tmp'
  unless File.exists?('tmp/mruby')
    system 'git clone https://github.com/mruby/mruby.git tmp/mruby'
  end
  exit system(%Q[cd tmp/mruby; MRUBY_CONFIG=#{File.expand_path __FILE__} rake #{ARGV.join(' ')}])
end

MRuby::Build.new do |conf|
  toolchain :clang

  conf.bins = %w(mrbc)
  [conf.cc, conf.cxx, conf.objc].each do |cc|
    cc.defines << %w(MRB_INT64)
  end
end

SDK_IOS_VERSION="6.0"
MIN_IOS_VERSION="5.1"
PLATFORM_IOS=`xcode-select -print-path`.chomp+'/Platforms/iPhoneOS.platform/'
PLATFORM_IOS_SIM=`xcode-select -print-path`.chomp+'/Platforms/iPhoneSimulator.platform/'
IOS_SDK = "#{PLATFORM_IOS}/Developer/SDKs/iPhoneOS#{SDK_IOS_VERSION}.sdk/"
IOS_SIM_SDK = "#{PLATFORM_IOS_SIM}/Developer/SDKs/iPhoneSimulator#{SDK_IOS_VERSION}.sdk/"

{
  :dev => %w(armv7 armv7s),
  :sim => %w(i386)
}.each do |target, archs|
  if target == :dev
    sdk = IOS_SDK
  else
    sdk = IOS_SIM_SDK
  end
  archs.each do |arch|
    MRuby::CrossBuild.new(arch) do |conf|
      toolchain :clang

      conf.bins = %w()
      [conf.cc, conf.cxx, conf.objc].each do |cc|
        cc.command = `xcode-select -print-path`.chomp+'/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang'
        cc.defines << %w(MRB_INT64)
        cc.flags << %Q[-miphoneos-version-min=#{MIN_IOS_VERSION}] if target == :dev
        cc.flags << %Q[-mios-simulator-version-min=#{MIN_IOS_VERSION}] if target == :sim
        cc.flags << %Q[-arch #{conf.name} -isysroot "#{sdk}" -D__IPHONE_OS_VERSION_MIN_REQUIRED=50100]
        cc.flags << %Q[-fmessage-length=0 -std=gnu99 -fpascal-strings -fexceptions -fasm-blocks -gdwarf-2]
        cc.flags << %Q[-fobjc-abi-version=2]
      end
      conf.gem :github => 'mobiruby/mruby-cfunc'
      conf.gem :github => 'mobiruby/mruby-cocoa'
      conf.gem :github => 'mobiruby/mobiruby-common'
    end
  end
end
