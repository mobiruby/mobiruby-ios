#!/usr/bin/env ruby

require 'fileutils'
unless File.exists?('mruby/build/libffi')
  system 'sh ./bin/build-libffi.sh'
end

MRuby::Build.new do |conf|
  toolchain :clang

  conf.build_mrbtest_lib_only
  conf.bins = %w(mrbc)
  # [conf.cc, conf.cxx, conf.objc].each do |cc|
  #   cc.defines << %w()
  # end
end

SDK_IOS_VERSION="6.1"
MIN_IOS_VERSION="5.0"
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

      conf.build_mrbtest_lib_only

      conf.bins = %w()
      [conf.cc, conf.cxx, conf.objc].each do |cc|
        cc.command = `xcode-select -print-path`.chomp+'/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang'
        cc.defines << %w(MRB_INT64)
        cc.include_paths << File.join(File.dirname(__FILE__), 'mruby/build/libffi/include')
        cc.flags << %Q[-miphoneos-version-min=#{MIN_IOS_VERSION}] if target == :dev
        cc.flags << %Q[-mios-simulator-version-min=#{MIN_IOS_VERSION}] if target == :sim
        cc.flags << %Q[-arch #{conf.name} -isysroot "#{sdk}" -D__IPHONE_OS_VERSION_MIN_REQUIRED=50100]
        cc.flags << %Q[-fmessage-length=0 -std=gnu99 -fpascal-strings -fexceptions -fasm-blocks -gdwarf-2]
        cc.flags << %Q[-fobjc-abi-version=2]
      end
      conf.linker.library_paths << File.join(File.dirname(__FILE__), 'mruby/build/libffi')

      conf.gem File.join(File.dirname(__FILE__), 'mruby-cfunc')
      conf.gem File.join(File.dirname(__FILE__), 'mruby-cocoa')
      conf.gem File.join(File.dirname(__FILE__), 'mobiruby-common')
    end
  end
end

LIBMRUBY = 'mruby/build/libmruby.a'
task 'libmruby' => LIBMRUBY

file LIBMRUBY => MRuby.targets.values.map { |t| t.libfile("#{t.build_dir}/lib/libmruby") } do |t|
  sh %Q[cp "#{MRUBY_ROOT}/bin/mrbc" "bin/mrbc" ]
  sh %Q[lipo -create #{t.prerequisites.map{|s| '"%s"' % s}.join(' ')} -output "#{t.name}"]
end
