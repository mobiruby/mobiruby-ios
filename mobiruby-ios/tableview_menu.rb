class Cocoa::TopMenu < Cocoa::NSObject
    attr_accessor :data, :navi

    define Cocoa::Object, :tableView, Cocoa::Object, :cellForRowAtIndexPath, Cocoa::Object do |tableView, indexPath|
        @cellIdent ||= _S("Cell")
        cell = Cocoa::UITableViewCell._alloc._initWithStyle Cocoa::Const::UITableViewCellStyleDefault, :reuseIdentifier, @cellIdent
        cell[:textLabel][:text] = @data[indexPath[:row].to_i][:title]
        cell
    end

    define C::Int, :tableView, Cocoa::Object, :numberOfRowsInSection, C::Int do |tableView, section|
        @data.size
    end

    define C::Void, :tableView, Cocoa::Object, :didSelectRowAtIndexPath, Cocoa::Object do |tableView, indexPath|
        row = indexPath[:row].to_i
        send(@data[indexPath[:row].to_i][:func], @navi)
    end

end

def show_tableview_menu(navi)
    viewController = Cocoa::UITableViewController._alloc._initWithStyle Cocoa::Const::UITableViewStylePlain 
    viewController[:title] = "MobiRuby"

    topMenu = Cocoa::TopMenu._alloc._init
    topMenu.navi = navi
    topMenu.data = [
        {:title => 'SameGame', :func => 'show_samegame'},
        {:title => 'Hello world', :func => 'show_hello'},
    ]
    viewController[:tableView][:dataSource] = topMenu
    viewController[:tableView][:delegate] = topMenu
    navi._pushViewController viewController, :animated, C::SInt8(0)
end
