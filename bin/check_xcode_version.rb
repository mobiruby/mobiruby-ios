#!/usr/bin/env ruby

XCODE_VERSION = /Xcode\s+(\d+\.\d+)/.match(`xcodebuild -version`).to_a[1].to_f
OSX_VERSION = /(\d+\.\d+)/.match(`uname -r`).to_a[1].to_f

if XCODE_VERSION < 4.6 || OSX_VERSION < 12.2
  puts "MobiRuby required Mountain Lion / Xcode 4.6 and newer version."
  exit 1
end
