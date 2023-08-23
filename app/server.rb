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
      key = params.first
      entry = @entries[key.to_sym]

      return "_\r\n" if entry.nil? or entry[:values].nil?

      is_expired = !entry[:expires_at].nil? && entry[:expires_at] < Time.now

      if is_expired
        @entries.delete key.to_sym
        return "_\r\n"
      end

      values = entry[:values]
      return "$0\r\n\r\n" if values.size == 0

      if values.size == 1 or values.is_a? String
        return "+#{values}\r\n"
      end

      size = values.size
      values = values
        .map { |value| "$#{value.size}\r\n#{value}\r\n" }
        .join

      "*#{size}\r\n#{values}"
    when "SET", "set"
      px = params.index { |element| element =~ /(PXe|px)/ }
      expiry = nil

      if not px.nil?
        expiry = params.drop(px).last
        key, values = params.shift, params.slice(0, px)
      else
        key, values = params.shift(1)
      end


      @entries[key.to_sym] = {
        :values => values,
        :expires_at => expiry.nil? ? nil : Time.now + (expiry.to_i / 1000)
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
