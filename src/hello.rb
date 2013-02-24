class Cocoa::HelloAlertView < Cocoa::UIAlertView
    define C::Void, :alertView, C::Pointer, :clickedButtonAtIndex, C::SInt32 do |me, index|
        if index.to_i == 1
            app = Cocoa::UIApplication._sharedApplication
            url = Cocoa::NSURL._URLWithString("http://mobiruby.org")
            app._openURL url
        end
    end
end
Cocoa::HelloAlertView.register

class Cocoa::HelloViewController < Cocoa::UIViewController
    define C::Void, :loadView do
        _super :_loadView
        self[:view]._setBackgroundColor Cocoa::UIColor._whiteColor
   end

    define C::Void, :viewDidAppear, C::Int do |animated|
        alert = Cocoa::HelloAlertView._alloc._initWithTitle "Hello",
          :message, "I am MobiRuby",
          :delegate, nil,
          :cancelButtonTitle, "I know!",
          :otherButtonTitles, "What's?", nil
        alert._setDelegate alert
        alert._show
    end
end
Cocoa::HelloViewController.register

def show_hello(navi)
    viewController = Cocoa::HelloViewController._alloc._init
    viewController[:title] = "Hello world"
    navi._pushViewController viewController, :animated, C::SInt8(1)
end
