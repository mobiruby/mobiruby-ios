#!/usr/bin/env ruby
require 'fileutils'

MRuby::Build.new do |conf|
  toolchain :clang
  conf.build_mrbtest_lib_only
  conf.bins = %w(mrbc)
end

GEMS = %w(mruby-cfunc mruby-cocoa mobiruby-common mruby-json mruby-digest mruby-pack)
# GEMS += %w(mruby-uv mruby-sqlite3)
BASEDIR = File.dirname(__FILE__)
SDK_IOS_VERSION=`awk -F '=' '$1 ~/^SDK_IOS_VERSION/{  print $2   }' #{BASEDIR}/bin/build-config.sh|sed 's/\"//g'`.chomp
MIN_IOS_VERSION=`awk -F '=' '$1 ~/^MIN_IOS_VERSION/{  print $2   }' #{BASEDIR}/bin/build-config.sh|sed 's/\"//g'`.chomp
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
        #cc.defines << %w(MRB_INT64)
        cc.include_paths << "#{BASEDIR}/include"
        cc.flags << %Q[-miphoneos-version-min=#{MIN_IOS_VERSION}] if target == :dev
        cc.flags << %Q[-mios-simulator-version-min=#{MIN_IOS_VERSION}] if target == :sim
        cc.flags << %Q[-arch #{conf.name} -isysroot "#{sdk}" -D__IPHONE_OS_VERSION_MIN_REQUIRED=50100]
        cc.flags << %Q[-fmessage-length=0 -std=gnu99 -fpascal-strings -fexceptions -fasm-blocks -gdwarf-2]
        cc.flags << %Q[-fobjc-abi-version=2]
      end
      conf.linker.library_paths << %W(#{BASEDIR}/lib #{sdk}/usr/lib)

      conf.gem "#{root}/mrbgems/mruby-print"
      conf.gem "#{root}/mrbgems/mruby-sprintf"
      conf.gem "#{root}/mrbgems/mruby-math"
      conf.gem "#{root}/mrbgems/mruby-time"
      conf.gem "#{root}/mrbgems/mruby-struct"
      conf.gem "#{root}/mrbgems/mruby-enum-ext"
      conf.gem "#{root}/mrbgems/mruby-string-ext"
      conf.gem "#{root}/mrbgems/mruby-numeric-ext"
      conf.gem "#{root}/mrbgems/mruby-array-ext"
      conf.gem "#{root}/mrbgems/mruby-hash-ext"
      conf.gem "#{root}/mrbgems/mruby-random"

      conf.gem "#{root}/mrbgems/mruby-eval"

      conf.gem "#{BASEDIR}/submodules/mruby-cfunc"
      conf.gem "#{BASEDIR}/submodules/mruby-cocoa"
      conf.gem "#{BASEDIR}/submodules/mobiruby-common"

      conf.gem "#{BASEDIR}/submodules/mruby-json"
      conf.gem "#{BASEDIR}/submodules/mruby-digest"
      conf.gem "#{BASEDIR}/submodules/mruby-pack"
      conf.gem "#{BASEDIR}/submodules/mruby-sqlite3"

      conf.gem "#{BASEDIR}/submodules/mruby-uv"
      conf.gem "#{BASEDIR}/submodules/mruby-http"
    end
  end
end

LIBMRUBY = File.expand_path('lib/libmruby.a')
#task 'libmruby' => LIBMRUBY

file LIBMRUBY => MRuby.targets.values.map { |t| t.libfile("#{t.build_dir}/lib/libmruby") } do |t|
  sh %Q[cp "#{MRUBY_ROOT}/build/host/bin/mrbc" "bin/mrbc" ]
  #t.prerequisites.map do |lib|
  #  sh %Q[ar d "#{lib}" LEGAL]
  #end
  sh %Q[lipo -create #{t.prerequisites.map{|s| '"%s"' % s}.join(' ')} -output "#{t.name}"]

  # copy include files
  dest_dir = File.expand_path('include')
  current_dir = Dir.pwd
  MRuby.targets['i386'].cc.include_paths.each do |dir|
    unless File.expand_path(dir) == dest_dir
      begin
        if File.directory?(dir)
          Dir.chdir dir
          Dir.glob("**/*").each do |file|
            if File.file?(file)
              dir = File.dirname(file)
              FileUtils.mkdir_p File.join(dest_dir, dir)
              FileUtils.cp file, File.join(dest_dir, file)
              mtime = File.mtime(file)
              File.utime mtime, mtime, File.join(dest_dir, file)
            end
          end
        end
      ensure
        Dir.chdir current_dir
      end
    end
  end
end

file 'bin/mrbc' => "#{BASEDIR}/submodules/mruby/bin/mrbc" do |t|
  FileUtils.cp t.prerequisites.first t.name
end

system %Q[./bin/build-libffi.sh] unless File.exists?('lib/libffi.a')
system %Q[./bin/build-libuv.sh] unless File.exists?('lib/libuv.a')
