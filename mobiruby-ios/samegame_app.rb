require 'samegame'
require 'ext'

bgm = AudioPlayer.new("bgm_00", "aif")
bgm.loops = -1
bgm.volume = 0.25
bgm.play

soundPath = Cocoa::NSBundle._mainBundle._pathForResource _S("tap_se_00"), :ofType, _S("wav")
soundURL = Cocoa::NSURL._fileURLWithPath soundPath
$tap_se = C::Int(0)
C::call C::Void, "AudioServicesCreateSystemSoundID", soundURL, $tap_se.to_pointer

class Cocoa::StageView < Cocoa::UIView
    attr_accessor :score
    
    COLORS = ['red', 'green', 'yellow', 'blue']
    ICON_SIZE = 22
    STAGE_SIZE = {:width => 14, :height => 18}
    
    def self.size
        {:width => STAGE_SIZE[:width] * ICON_SIZE, :height => STAGE_SIZE[:height] * ICON_SIZE}
    end

    def reset
        new_stage = Stage.new(STAGE_SIZE[:width], STAGE_SIZE[:height])
        new_stage.each do |item, x, y|
            item[:color] = COLORS[rand % COLORS.size]
        end
        setStage new_stage
        GC.start
    end

    # callback for updated score
    def updated_score(&block)
        @updated_score_block = block
    end

    # callback for game is over
    def gameover(&block)
        @gameover_block = block
    end

    def setStage(stage)
        @stage.each do |item|
            item[:view]._removeFromSuperview if item[:view]
        end if @stage
        
        @stage = stage
        @stage.each do |item, x, y|
            img = Cocoa::UIImage._imageNamed("square-#{item[:color]}-24-ns.png")
            item_view = Cocoa::UIImageView._alloc._initWithImage(img)
            item_view._setFrame itemFrame(x, y)
            self._addSubview item_view
            item[:view] = item_view
        end
        
        @score = 0
        @updated_score_block.call(@score) if @updated_score_block
    end

    def itemFrame(x, y)
        CGRectMake(ICON_SIZE * x, ICON_SIZE * (@stage.height - 1 - y), ICON_SIZE, ICON_SIZE)
    end

    def calcPosition(touches)
        touch = touches._anyObject
        x = (touch._locationInView(self)[:x] / ICON_SIZE).to_i
        y = (@stage.height - 1) - (touch._locationInView(self)[:y] / ICON_SIZE).to_i
        [x, y]
    end

    define C::Void, :touchesBegan, Cocoa::Object, :withEvent, Cocoa::Object do |touches, event|
        (@touchesBeganLock ||= Mutex.new).block do
            x, y = calcPosition(touches)
            checked = @stage.check(x, y)
            
            if checked.size > 1
                @cursor = [x, y]
                @stage.each do |item, x, y|
                    if item[:view]
                        item[:view]._setAlpha(checked.include?([x, y]) ? 0.4 : 1.0)
                    end
                end
                else
                @cursor = nil
            end
        end
    end

    define C::Void, :touchesCancelled, Cocoa::Object, :withEvent, Cocoa::Object do |touches, event|
        (@touchesCancelledLock ||= Mutex.new).block do
            @cursor = nil
            @stage.each do |item, x, y|
                item[:view]._setAlpha(1.0) if item[:view]
            end
        end
    end

    define C::Void, :touchesMoved, Cocoa::Object, :withEvent, Cocoa::Object do |touches, event|
        (@touchesMovedLock ||= Mutex.new).block do
            if @cursor
                cur_x, cur_y = @cursor
                x, y = calcPosition(touches)
                if (cur_x - x).abs > 5 || (cur_y - y).abs > 5
                    @cursor = nil
                    @stage.each do |item, x, y|
                        item[:view]._setAlpha(1.0) if item[:view]
                    end
                end
            end
        end
    end

    define C::Void, :touchesEnded, Cocoa::Object, :withEvent, Cocoa::Object do |touches, event|
        (@touchesEndedLock ||= Mutex.new).block do
            if @cursor
                x, y = @cursor
                
                removed = @stage.remove(x, y) do |item, x, y|
                    item[:view]._removeFromSuperview if item[:view]
                    item[:view] = item[:color] = nil
                end
                
                @stage.fall do |item, x, y, steps|
                    context = C::call(C::Pointer, "UIGraphicsGetCurrentContext")
                    Cocoa::UIView._beginAnimations nil, :context, context
                    Cocoa::UIView._setAnimationDuration C::Double(0.05*steps)
                    Cocoa::UIView._setAnimationCurve Cocoa::Const::UIViewAnimationCurveEaseIn
                    item[:view]._setFrame itemFrame(x, y - steps)
                    Cocoa::UIView._commitAnimations
                end
                
                @stage.compact do |x, steps|
                    context = C::call(C::Pointer, "UIGraphicsGetCurrentContext")
                    Cocoa::UIView._beginAnimations nil, :context, context
                    Cocoa::UIView._setAnimationDuration C::Double(0.1*steps)
                    Cocoa::UIView._setAnimationCurve Cocoa::Const::UIViewAnimationCurveLinear
                    
                    @stage.height.times do |y|
                        item = @stage[x, y]
                        if item && item[:view]
                            item[:view]._setFrame itemFrame(x - steps, y)
                        end
                    end
                    
                    Cocoa::UIView._commitAnimations
                end
                
                @score += (removed.size - 2) ** 2
                @updated_score_block.call(@score) if @updated_score_block
                
                if @stage.is_cleared?
                    @gameover_block.call(true)
                    elsif @stage.is_gameover?
                    @gameover_block.call(false)
                end
            end
        end
    end
end


class Cocoa::MyViewController < Cocoa::UIViewController
    
    define C::Void, :loadView do
        screen_rect = Cocoa::UIScreen._mainScreen._bounds
        self[:view] = @view = Cocoa::UIView._alloc._initWithFrame screen_rect
        
        stage_size = Cocoa::StageView::size
        corner = (screen_rect[:size][:width] - stage_size[:width]) / 2
        stage_frame = CGRectMake(corner, corner, stage_size[:width], stage_size[:height])
        @stage_view = Cocoa::StageView._alloc._initWithFrame stage_frame
        @view._addSubview @stage_view
        
        @reset_button = Cocoa::UIButton._buttonWithType(Cocoa::Const::UIButtonTypeRoudedRect)
        @reset_button._setFrame CGRectMake(220, 422, 100, 32)
        @reset_button._setTitle _S("Reset"), :forState, Cocoa::Const::UIControlStateNormal
        @reset_button._titleLabel._setTextColor Cocoa::UIColor._whiteColor
        
        greenButtonImage = Cocoa::UIImage._imageNamed _S("greenButton.png")
        stretchableGreenButton = greenButtonImage._stretchableImageWithLeftCapWidth 12, :topCapHeight, 12
        @reset_button._setBackgroundImage stretchableGreenButton, :forState, Cocoa::Const::UIControlStateNormal
        @reset_button._setTitleColor Cocoa::UIColor._whiteColor, :forState, Cocoa::Const::UIControlStateNormal
        @reset_button._addTarget self, :action, selector(:reset), :forControlEvents, Cocoa::Const::UIControlEventTouchUpInside
        @view._addSubview @reset_button
        
        @score_label = Cocoa::UILabel._alloc._init
        @score_label._setFrame CGRectMake(10, 427, 300, 22)
        @score_label._setTextColor Cocoa::UIColor._whiteColor
        @score_label._setBackgroundColor Cocoa::UIColor._clearColor
        @score_label[:text] = _S("Score: 0")
        @view._addSubview @score_label
        
        @stage_view.updated_score do |score|
            @score_label[:text] = _S("Score: #{score}")
        end

        @stage_view.gameover do |is_cleared|
            if is_cleared
                @stage_view.score += 1000
                @score_label[:text] = _S("Score: #{@stage_view.score}")
            end
        end

        @stage_view.reset
    end

    define C::Void, :viewWillAppear, C::SInt8 do
        self._navigationController._navigationBar._setHidden(-1)
    end

    define C::Void, :reset do
        (@resetLock ||= Mutex.new).block do
            @stage_view.reset
        end
    end
end


Cocoa::UIApplication._sharedApplication[:statusBarHidden] = 0

screen_rect = Cocoa::UIScreen._mainScreen._bounds
window = Cocoa::UIWindow._alloc._initWithFrame screen_rect
viewController = Cocoa::MyViewController._alloc._init

navi = Cocoa::UINavigationController._alloc._initWithNibName nil, :bundle, nil
navi._pushViewController viewController, :animated, C::SInt8(0)
window._addSubview navi._view

window._makeKeyAndVisible
