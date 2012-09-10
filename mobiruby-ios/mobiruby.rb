module MobiRuby
end

C = CFunc

def _S(str)
    Cocoa::NSString._stringWithUTF8String(str)
end
