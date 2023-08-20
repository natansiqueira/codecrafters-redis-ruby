require "socket"

class RedisDaDeepWeb
  def initialize(port)
    @port = port
  end

  def handle_request(request)
    params = request
      .split
      .select { |element| not(element =~ /[*$]\d+/)  }

    command = params.shift(1).first

    case command
    when "ECHO", "echo"
      case params.size
      when 0
        "$0\r\n\r\n"
      when 1
        param = params.first
        "+#{param}\r\n"
      else
        size = params.size
        params = params
          .map { |element| "$#{element.size}\r\n#{element}\r\n" }
          .join

        "*#{size}\r\n#{params}"
      end
    when "PING", "ping"
      "+PONG\r\n"
    else
      "-ERR unknown command '#{command}'\r\n"
    end
  end

  def start
    puts 'Redis da deep web on'
    server = TCPServer.new(@port)

    loop do
      Thread.start(server.accept) do |client|
        begin
          loop do
            request = client.recv 4096
            response = handle_request request
            client.write response
          end
        rescue Errno::ECONNRESET, Errno::EPIPE
          puts 'client foi de F'
        end
      end
    end

  end
end

RedisDaDeepWeb.new(6379).start
