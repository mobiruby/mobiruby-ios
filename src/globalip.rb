begin
	# Code from https://github.com/matsumoto-r/ 
	# License: MIT / MATSUMOTO Ryosuke 
	class SimpleHttp
  DEFAULTPORT = 80
  HTTP_VERSION = "HTTP/1.0"
  DEFAULT_ACCEPT = "*/*"
  SEP = "\r\n"

  def initialize(address, port = DEFAULTPORT)
    @uri = {}
    ip = ""
    UV::getaddrinfo(address, "http") do |x, info|
      if info 
        ip = info.addr
      end
    end
    UV::run()
    @uri[:address] = address
    @uri[:ip] = ip
    @uri[:port] = port ? port.to_i : DEFAULTPORT
    self
  end

  def address; @uri[:address]; end
  def port; @uri[:port]; end

  def get(path = "/", request = nil)
    request("GET", path, request)
  end

  def post(path = "/", request = nil)
    request("POST", path, request)
  end

  # private
  def request(method, path, req)
    @uri[:path] = path
    if @uri[:path].nil?
      @uri[:path] = "/"
    elsif @uri[:path][0] != "/"
      @uri[:path] = "/" + @uri[:path]
    end
    request_header = create_request_header(method.upcase.to_s, req)
    response_text = send_request(request_header)
    SimpleHttpResponse.new(response_text)
  end
  def send_request(request_header)
    socket = UV::TCP.new
    response_text = ""
    socket.connect(UV.ip4_addr(@uri[:ip].sin_addr, @uri[:port])) do |x|
      if x == 0
        socket.write(request_header) do |x|
          socket.read_start do |b|
            response_text += b.to_s 
          end
        end
      else
        socket.close()
      end
    end
    
    UV::run()
    response_text
  end

  def create_request_header(method, req)
    req = {}  unless req
    str = ""
    body   = ""
    str += sprintf("%s %s %s", method, @uri[:path], HTTP_VERSION) + SEP
    header = {}
    req.each do |key,value|
      header[key.capitalize] = value
    end
    header["Host"] = @uri[:address]  unless header.keys.include?("Host")
    header["Accept"] = DEFAULT_ACCEPT  unless header.keys.include?("Accept")
    header["Connection"] = "close"
    if header["Body"]
      body = header["Body"]
      header.delete("Body")
    end
    if method == "POST" && (not header.keys.include?("content-length".capitalize))
        header["Content-Length"] = (body || '').length
    end
    header.keys.sort.each do |key|
      str += sprintf("%s: %s", key, header[key]) + SEP
    end
    str + SEP + body
  end

  class SimpleHttpResponse
    SEP = SimpleHttp::SEP
    def initialize(response_text)
      @response = {}
      if response_text.include?(SEP + SEP)
        @response["header"], @response["body"] = response_text.split(SEP + SEP)
      else
        @response["header"] = response_text
      end
      parse_header
      self
    end

    def [](key); @response[key]; end
    def []=(key, value);  @response[key] = value; end

    def header; @response['header']; end
    def body; @response['body']; end
    def status; @response['status']; end
    def code; @response['code']; end
    def date; @response['date']; end
    def content_type; @response['content-type']; end
    def content_length; @response['content-length']; end

    def each(&block)
      if block
        @response.each do |k,v| block.call(k,v) end
      end
    end
    def each_name(&block)
      if block
        @response.each do |k,v| block.call(k) end
      end
    end

    # private
    def parse_header
      return unless @response["header"]
      h = @response["header"].split(SEP)
      if h[0].include?("HTTP/1")
        @response["status"] = h[0].split(" ", 2).last
        @response["code"]   = h[0].split(" ", 3)[1].to_i
      end
      h.each do |line|
        if line.include?(": ")
          k,v = line.split(": ")
          @response[k.downcase] = v
        end
      end
    end
  end
end

class HttpRequest

  def get(url, body = nil, headers = {})
    request("GET", url, body, headers)
  end

  def head(url, headers = {})
    request("HEAD", url, nil, headers)
  end

  def post(url, body = nil, headers = {})
    request("POST", url, body, headers)
  end

  def put(url, body = nil, headers = {})
    request("PUT", url, body, headers)
  end

  def delete(url, headers = {})
    request("DELETE", url, nil, headers)
  end

  def request(method, url, body, headers)
    parser = HTTP::Parser.new()
    url = parser.parse_url(url)
    request = create_http_request(method, body, headers)
    host = url.host.to_sym.to_s
    if url.query
        request_uri = url.path + "?" + url.query
    else
        request_uri = url.path
    end
    SimpleHttp.new(host, url.port).request(method, request_uri, request)
  end

  def encode_parameters(params, delimiter = '&', quote = nil)
    if params.is_a?(Hash)
      params = params.map do |key, value|
        sprintf("%s=%s%s%s", escape(key), quote, escape(value), quote)
      end
    else
      params = params.map { |value| escape(value) }
    end
    delimiter ? params.join(delimiter) : params
  end

  def create_http_request(method, body, headers)
    method = method.upcase.to_s
    request = {}
    request = headers
    if method == "POST" || method == "PUT" || method == "GET"
      #if request["Content-Type"]
      #  request["Content-Type"] = 'application/x-www-form-urlencoded'
      #end
      if body
        request["body"] = body.is_a?(Hash) ? encode_parameters(body) : body.to_s
        request["Content-Length"] = (request["body"] || '').length
      end
    end
    request
  end
  #def escape(str, unsafe = nil)
  def escape(str)
    reserved_str = [
      "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "n", "m", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", 
      "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
      "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
      "-", ".", "_", "~"
    ]
    tmp = ''
    str = str.to_s
    str.size.times do |idx|
      chr = str[idx]
      if reserved_str.include?(chr)
        tmp += chr
      else
        tmp += "%" + chr.unpack("H*").first.upcase
      end
    end
    #puts "#{str}: #{tmp}"
    tmp
  end
end

rescue => e
	p e
end

def show_globalip(navi)
	res = HttpRequest.new.get("http://httpbin.org/ip")
	origin_ip = JSON.parse(res.body)['origin']
  Cocoa::SVProgressHUD._dismiss

  alert = Cocoa::HelloAlertView._alloc._initWithTitle "Your global IP is",
    :message, origin_ip,
    :delegate, nil,
    :cancelButtonTitle, "OK",
    :otherButtonTitles, nil
  alert._show
end
