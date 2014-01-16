#!/usr/bin/env ruby

XCODE_VERSION = /Xcode\s+(\d+\.\d+)/.match(`xcodebuild -version`).to_a[1].to_f
OSX_VERSION = /(\d+\.\d+)/.match(`uname -r`).to_a[1].to_f

if XCODE_VERSION < 5.0 || OSX_VERSION < 13.0
  puts "MobiRuby required Mavericks or newer version and Xcode 5.0 or newer version."
  exit 1
end
