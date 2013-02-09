def show_globalip(navi)
  url = Cocoa::NSURL._URLWithString "http://httpbin.org/ip"
	request = Cocoa::NSURLRequest._requestWithURL url

	Cocoa::SVProgressHUD._showWithStatus "Loading..."
	operation = Cocoa::AFJSONRequestOperation._JSONRequestOperationWithRequest request, :success, Cocoa::Block.new(CFunc::Void, [Cocoa::NSURLRequest, Cocoa::NSHTTPURLResponse, Cocoa::Object]) { |req, res, json|
		Cocoa::SVProgressHUD._dismiss
	    alert = Cocoa::HelloAlertView._alloc._initWithTitle "Your global IP is",
		    :message, (json._valueForKeyPath "origin"),
		    :delegate, nil,
		    :cancelButtonTitle, "OK",
		    :otherButtonTitles, nil
	    alert._show
	}, :failure, Cocoa::Block.new(CFunc::Void, [Cocoa::NSURLRequest, Cocoa::NSHTTPURLResponse, Cocoa::NSError, Cocoa::Object]) { |req, res, error, json|
		Cocoa::SVProgressHUD._dismiss
		Cocoa::SVProgressHUD._showErrorWithStatus "Network Error"
	}
	operation._start 
end
