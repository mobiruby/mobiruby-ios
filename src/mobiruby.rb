module MobiRuby
end
require 'ext'

C = CFunc

def _S(str)
    Cocoa::NSString._stringWithUTF8String(str)
end
