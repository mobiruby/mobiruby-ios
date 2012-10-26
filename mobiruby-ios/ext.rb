class AudioPlayer
    attr_reader :avap

    def initialize(name, ext)
        path = Cocoa::NSBundle._mainBundle._pathForResource name, :ofType, ext
        url = Cocoa::NSURL._fileURLWithPath path
        @avap = Cocoa::AVAudioPlayer._alloc._initWithContentsOfURL url, :error, nil
    end

    def loops=(num)
        @avap._setNumberOfLoops num
    end

    def volume=(num)
        @avap._setVolume num
    end

    def play
        @avap._play
    end
end

class Mutex
    def initialize(&block)
        @lock = false
    end

    def block(&block)
        return false if @lock
        @lock = true
        block.call
        @lock = false
    end
end

def CGRectMake(x,y,w,h)
    rect = Cocoa::Struct::CGRect.new
    rect[:origin][:x] = x.to_f
    rect[:origin][:y] = y.to_f
    rect[:size][:width] = w.to_f
    rect[:size][:height] = h.to_f
    rect
end

def selector(name)
    CFunc.call(CFunc::Pointer, "sel_registerName", name.to_s)
end

def rand
    C::call(C::Int, "rand").value
end

def srand(s)
    C::call(C::Void, "srand", C::Int(s))
end
