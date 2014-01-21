require 'mobiruby'
require 'tableview_menu'

class Cocoa::AppDelegate < Cocoa::UIResponder
    define C::Int, :application, Cocoa::Object, :didFinishLaunchingWithOptions, Cocoa::Object do |application, launchOptions|
        screen_rect = Cocoa::UIScreen._mainScreen._bounds
        @window = Cocoa::UIWindow._alloc._initWithFrame screen_rect
        @navi = Cocoa::UINavigationController._alloc._initWithNibName nil, :bundle, nil
        @window._makeKeyAndVisible
        @window._setRootViewController(@navi)
        show_tableview_menu(@navi)
        # show_samegame(@navi)
    end
    
    define C::Void, :applicationWillResignActive, Cocoa::Object do |application|
        # Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        # Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    end

    define C::Void, :applicationDidEnterBackground, Cocoa::Object do |application|
        # Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        # If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    end

    define C::Void, :applicationWillEnterForeground, Cocoa::Object do |application|
        # Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    end

    define C::Void, :applicationDidBecomeActive, Cocoa::Object do |application|
        # Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    end

    define C::Void, :applicationWillTerminate, Cocoa::Object do |application|
        # Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    end
end
Cocoa::AppDelegate.register
