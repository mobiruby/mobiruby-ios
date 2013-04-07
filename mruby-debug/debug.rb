#!/usr/bin/ruby
require "socket"

sock = TCPSocket.open("127.0.0.1", 8990)

while true
  while buf = sock.gets
    buf.chomp!
    command, filename, line, = buf.split(/\t/)
    case command
    when 'TRACE'
      sock.write "RESUME\r\n"
      puts "#{filename}(#{line}):"
    end
  end
  puts "close"
  sock.close
end