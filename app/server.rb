require "socket"

class YourRedisServer
  def initialize(port)
    @port = port
  end

  def start
    server = TCPServer.new(@port)
    client = server.accept
    
    client.puts "+PONG\r\n"
    client.close
  end
end

YourRedisServer.new(6379).start
