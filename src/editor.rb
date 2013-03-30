require 'script_runner'

class Cocoa::ScriptRunnerViewController < Cocoa::UIViewController
  define C::Void, :loadView do
#    _super :_loadView

    self._setTitle "Running"

    navbar = self[:navigationController][:navigationBar] 
    navi_height = navbar._bounds[:size][:height]

    screen_rect = self[:view]._bounds
    @view_frame = CGRectMake(0, 0, screen_rect[:size][:width], self[:view]._bounds[:size][:height] - navi_height)

    self[:view] = @view = Cocoa::UIView._alloc._initWithFrame @view_frame
    
    @console_frame = CGRectMake(0, 0, @view_frame[:size][:width], @view_frame[:size][:height])
    @console_view = Cocoa::UITextView._alloc._initWithFrame @console_frame
    @view._addSubview @console_view
  end

  define C::Void, :runScript, Cocoa::Object do |script|
    $console_view = @console_view
    $console_view[:text] = ''
    begin
      eval script._UTF8String.to_s
    rescue => e
      p e
    ensure
      $console_view = nil
    end
  end
end
Cocoa::ScriptRunnerViewController.register


class Cocoa::EditorViewController < Cocoa::UIViewController
  define C::Void, :loadView do
    _super :_loadView
    self._setTitle "Editor"

    @keyboardFrame = CGRectMake(0, 0, 0, 0)

    run_btn = Cocoa::UIBarButtonItem._alloc._initWithTitle _S("Run"), :style, Cocoa::Const::UIBarButtonItemStylePlain, :target, self, :action, selector("runScript:")
    self._navigationItem._setRightBarButtonItem run_btn

    navbar = self[:navigationController][:navigationBar] 
    navi_height = navbar._bounds[:size][:height]

    screen_rect = self[:view]._bounds
    @view_frame = CGRectMake(0, 0, screen_rect[:size][:width], self[:view]._bounds[:size][:height] - navi_height)

    self[:view] = @view = Cocoa::UIView._alloc._initWithFrame @view_frame
    
    @editor_frame = CGRectMake(0, 0, @view_frame[:size][:width], @view_frame[:size][:height])
    @editor_view = Cocoa::UITextView._alloc._initWithFrame @editor_frame
    # TODO: need to support prop
    @editor_view._setAutocorrectionType Cocoa::Const::UITextAutocorrectionTypeNo
    @editor_view._setAutocapitalizationType Cocoa::Const::UITextAutocapitalizationTypeNone
    @view._addSubview @editor_view
    @editor_view[:text] = "puts 2 * 16\n"
  end

  define C::Void, :viewDidAppear, C::Int do |animated|
    _super :_viewWillAppear, animated
 
    Cocoa::NSNotificationCenter._defaultCenter._addObserver self, :selector, selector("keyboardWillShow:"), :name, Cocoa::Const::UIKeyboardWillShowNotification, :object, nil
    Cocoa::NSNotificationCenter._defaultCenter._addObserver self, :selector, selector("keyboardWillHide:"), :name, Cocoa::Const::UIKeyboardWillHideNotification, :object, nil
  end

  define C::Void, :viewDidDisappear, C::Int do |animated|
    _super :_viewDidDisappear, animated
 
    Cocoa::NSNotificationCenter._defaultCenter._removeObserver self, :name, Cocoa::Const::UIKeyboardWillShowNotification, :object, nil
    Cocoa::NSNotificationCenter._defaultCenter._removeObserver self, :name, Cocoa::Const::UIKeyboardWillHideNotification, :object, nil
  end

  define C::Void, :keyboardWillShow, Cocoa::Object do |notification|
    info = notification._userInfo
    @keyboardFrame = info._objectForKey(Cocoa::Const::UIKeyboardFrameEndUserInfoKey)._CGRectValue
    duration = info._objectForKey(Cocoa::Const::UIKeyboardAnimationDurationUserInfoKey)._doubleValue

    update_layout
  end

  define C::Void, :keyboardWillHide, Cocoa::Object do |notification|
    info = notification._userInfo
    duration = info._objectForKey(Cocoa::Const::UIKeyboardAnimationDurationUserInfoKey)._doubleValue
    @keyboardFrame = CGRectMake(0, 0, 0, 0)

    update_layout
  end

  define C::Void, :runScript, Cocoa::Object do |sender|
    body = @editor_view._text._UTF8String.to_s
    show_script_runner self[:navigationController], body
    # CFunc::call CFunc::Pointer, "eval_mobiruby", body
  end

  def update_layout
    kbd_height = @keyboardFrame[:size][:height]
    @editor_frame = CGRectMake(0, 0, @view_frame[:size][:width], @view_frame[:size][:height]-kbd_height)
    @editor_view._setFrame @editor_frame
  end
end
Cocoa::EditorViewController.register

def show_script_runner(navi, script)
  viewController = Cocoa::ScriptRunnerViewController._alloc._init
  navi._pushViewController viewController, :animated, C::SInt8(1)
  CFunc::call CFunc::Pointer, "eval_mobiruby", script, viewController
end

def show_editor(navi)
    viewController = Cocoa::EditorViewController._alloc._init
    navi._pushViewController viewController, :animated, C::SInt8(1)
end
