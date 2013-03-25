# Check OS/Xcode version
XCODE_VERSION = /Xcode\s+(\d+\.\d+)/.match(`xcodebuild -version`).to_a[1].to_f
OSX_VERSION = /(\d+\.\d+)/.match(`uname -r`).to_a[1].to_f

if XCODE_VERSION < 4.6 || OSX_VERSION < 11.4
  puts "MobiRuby required Lion or Mountain Lion / Xcode 4.6 or newer version."
  exit 1
end

