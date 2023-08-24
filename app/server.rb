require "socket"
require "time"

class RedisDaDeepWeb
  def initialize(port)
    @port = port
    @entries = {}
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
    when "GET", "get"
      key = params.at(0)
      entry = @entries[key]

      return "$-1\r\n" if entry.nil?
      puts entry[:expiry]
      puts Time.now
      if entry[:expiry] && entry[:expiry] < Time.now
        return "$-1\r\n"
      end

      value = entry[:value]

      "$#{value.size}\r\n#{value}\r\n"
    when "SET", "set"
      key = params.at(0)
      value = params.at(1)
      expiry = params.at(3)

      @entries[key] = {
        value: value,
        expiry: Time.now + (expiry.to_i / 1000)
      }
      "+OK\r\n"
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

begin
  RedisDaDeepWeb.new(6379).start
rescue SystemExit, Interrupt
  puts "\nserver foi de F"
end
