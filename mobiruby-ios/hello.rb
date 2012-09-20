class Cocoa::MyAlertView < Cocoa::UIAlertView
  define C::Void, :didPresentAlertView, C::Pointer do
    p "MyAlertView::didPresentAlertView"
  end

  define C::Void, :alertView, C::Pointer, :clickedButtonAtIndex, C::SInt32 do |me, index|
    if index.to_i == 1
        app = Cocoa::UIApplication._sharedApplication
        url = Cocoa::NSURL._URLWithString("http://mobiruby.org")
        app._openURL url
    end
  end
end

alert = Cocoa::MyAlertView._alloc._initWithTitle "Hello",
  :message, "I am MobiRuby",
  :delegate, nil,
  :cancelButtonTitle, "I know!",
  :otherButtonTitles, "What's?", nil
alert._setDelegate alert
alert._show
