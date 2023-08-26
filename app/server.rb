# frozen_string_literal: true

require 'socket'
require 'time'

# Redis
class Redis
  def initialize(port)
    @port = port
    @entries = {}
  end

  def pong
    "+PONG\r\n"
  end

  def echo(param)
    "$#{param.size}\r\n#{param}\r\n"
  end

  def get(param)
    entry = @entries[param]

    return "$-1\r\n" if entry.nil?
    return "$-1\r\n" if entry[:expiry] && entry[:expiry] < (Time.now.to_f * 1000).to_i

    value = entry[:value]
    "$#{value.size}\r\n#{value}\r\n"
  end

  def set(params)
    key, value = params.shift(3)
    expiry = params.at(0)

    @entries[key] = {
      value:,
      expiry: expiry.nil? ? nil : (Time.now.to_f * 1000).to_i + expiry.to_i
    }

    "+OK\r\n"
  end

  def handle_message(params)
    command = params.shift

    case command
    when 'ping', 'PING' then pong
    when 'echo', 'ECHO' then echo params.at(0)
    when 'get', 'GET' then get params.at(0)
    when 'set', 'SET' then set params
    else
      "-ERR unknown command '#{command}'\r\n"
    end
  end

  def parse_message(message)
    message.split.reject { |element| (element =~ /[*$]\d+/) }
  end

  def handle_client(client)
    loop do
      message = client.recv 4096
      params = parse_message message
      response = handle_message params
      client.write response
    end
  end

  def start
    puts 'redis has been started'
    server = TCPServer.new(@port)

    loop do
      Thread.start(server.accept) do |client|
        handle_client client
      rescue Errno::ECONNRESET, Errno::EPIPE
        puts 'client disconnected'
      end
    end
  end
end

begin
  Redis.new(6379).start
rescue SystemExit, Interrupt
  puts "\nserver has been shutdown"
end
