require "socket"

class RedisDaDeepWeb
  def initialize(port)
    @port = port
  end

  def start
    puts 'Redis da deep web on'
    server = TCPServer.new(@port)

    loop do
      Thread.start(server.accept) do |client| 
        begin  
          loop do
            client.recv 4096
            client.write "+PONG\r\n"
          end
        rescue Errno::ECONNRESET
          puts 'client foi de F'
        end
      end
    end
    
  end
end

RedisDaDeepWeb.new(6379).start
