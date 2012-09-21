class Cocoa::TopMenuViewController < Cocoa::UITableViewController
    attr_accessor :data, :navi

    define Cocoa::Object, :tableView, Cocoa::Object, :cellForRowAtIndexPath, Cocoa::Object do |tableView, indexPath|
        @cellIdent ||= _S("Cell")
        cell = tableView._dequeueReusableCellWithIdentifier @cellIdent
        unless cell
            cell = Cocoa::UITableViewCell._alloc._initWithStyle Cocoa::Const::UITableViewCellStyleDefault, :reuseIdentifier, @cellIdent
        end
        cell[:textLabel][:text] = @data[indexPath[:row].to_i][:title]
        cell
    end

    define C::Int, :tableView, Cocoa::Object, :numberOfRowsInSection, C::Int do |tableView, section|
        @data.size
    end

    define C::Void, :tableView, Cocoa::Object, :didSelectRowAtIndexPath, Cocoa::Object do |tableView, indexPath|
        row = indexPath[:row].to_i
        send(@data[indexPath[:row].to_i][:func], self._navigationController)
    end
end

def show_tableview_menu(navi)
    viewController = Cocoa::TopMenuViewController._alloc._initWithStyle Cocoa::Const::UITableViewStylePlain 
    viewController[:title] = "MobiRuby"
    viewController.data = [
        {:title => 'SameGame', :func => 'show_samegame'},
        {:title => 'Hello world', :func => 'show_hello'},
    ]
    viewController[:tableView][:dataSource] = viewController
    viewController[:tableView][:delegate] = viewController
    navi._pushViewController viewController, :animated, C::SInt8(0)
end
