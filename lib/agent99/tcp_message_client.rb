require 'socket'
require 'json'
require 'logger'

class Agent99::TcpMessageClient
  def initialize(logger: Logger.new($stdout))
    @logger = logger
    @server_socket = nil
    @client_connections = {}
    @handlers = {}
    @running = false
  end

  def listen_for_messages(queue, request_handler:, response_handler:, control_handler:)
    @handlers = {
      request: request_handler,
      response: response_handler,
      control: control_handler
    }
    
    start_server(queue[:port])
  end

  def publish(message)
    target = message.dig(:header, :to)
    return unless target

    agent_info = discover_agent(target)
    return unless agent_info

    socket = connect_to_agent(agent_info[:ip], agent_info[:port])
    return unless socket

    begin
      socket.puts(message.to_json)
      true
    rescue StandardError => e
      @logger.error("Failed to send message: #{e.message}")
      false
    ensure
      socket.close unless socket.closed?
    end
  end

  def stop
    @running = false
    @server_socket&.close
    @client_connections.each_value(&:close)
    @client_connections.clear
  end

  private

  def start_server(port)
    @server_socket = TCPServer.new(port)
    @running = true

    Thread.new do
      while @running
        begin
          client = @server_socket.accept
          handle_client(client)
        rescue StandardError => e
          @logger.error("Server error: #{e.message}")
        end
      end
    end
  end

  def handle_client(client)
    Thread.new do
      while @running
        begin
          message = client.gets
          break if message.nil?

          parsed_message = JSON.parse(message, symbolize_names: true)
          route_message(parsed_message)
        rescue JSON::ParserError => e
          @logger.error("Invalid JSON received: #{e.message}")
        rescue StandardError => e
          @logger.error("Error handling client: #{e.message}")
          break
        end
      end
      client.close unless client.closed?
    end
  end

  def route_message(message)
    type = message.dig(:header, :type)&.to_sym
    handler = @handlers[type]
    
    if handler
      handler.call(message)
    else
      @logger.warn("No handler for message type: #{type}")
    end
  end

  def discover_agent(agent_name)
    # This would need to be implemented to work with your registry
    # to look up the IP/port for the target agent
    # Return format should be { ip: "1.2.3.4", port: 1234 }
  end

  def connect_to_agent(ip, port)
    TCPSocket.new(ip, port)
  rescue StandardError => e
    @logger.error("Failed to connect to #{ip}:#{port}: #{e.message}")
    nil
  end
end
