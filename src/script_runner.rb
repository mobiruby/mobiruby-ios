module Kernel
  def __printstr__(str)
    if $console_view
      $console_view[:text] = _S($console_view._text._UTF8String.to_s + str)
    else
      CFunc::call CFunc::Void, "NSLog", _S("%s"), str
    end
  end
end

def run_console(viewController_p, script)
  viewController = Cocoa::Object.new(viewController_p)
  viewController._runScript _S(script)
end
