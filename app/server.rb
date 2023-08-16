require "socket"

class YourRedisServer
  def initialize(port)
    @port = port
  end

  def start
    puts 'Redis da deep web on'
    server = TCPServer.new(@port)

    loop do
      Thread.start(server.accept) do |client| 
       
        loop do
            client.recv 4096
            client.write "+PONG\r\n"
        end
      
        client.close 

      end
    end
    
  end
end

YourRedisServer.new(6379).start
