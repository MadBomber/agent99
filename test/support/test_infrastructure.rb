# frozen_string_literal: true

require 'socket'
require 'webrick'
require 'json'

module TestInfrastructure
  class MockRegistryServer
    attr_reader :agents, :port, :thread, :server

    def initialize(port = 0)
      @agents = {}
      @server = WEBrick::HTTPServer.new(
        Port: port,
        Logger: WEBrick::Log.new('/dev/null'),
        AccessLog: []
      )
      @port = @server.config[:Port]
      setup_routes
    end

    def start
      @thread = Thread.new { @server.start }
      # Give more time for server to start up
      sleep 0.5
      # Wait until server is actually listening
      10.times do
        begin
          TCPSocket.new('127.0.0.1', @port).close
          break
        rescue Errno::ECONNREFUSED
          sleep 0.1
        end
      end
      self
    end

    def stop
      @server.shutdown if @server
      @thread&.join(2)
      @agents.clear
    end

    def reset
      @agents.clear
    end

    private

    def setup_routes
      # Create a custom servlet that handles all HTTP methods
      servlet = Class.new(WEBrick::HTTPServlet::AbstractServlet) do
        def initialize(server, mock_server)
          super(server)
          @mock_server = mock_server
        end

        # Handle all HTTP methods by delegating to do_METHOD
        %w[GET POST PUT DELETE PATCH HEAD OPTIONS].each do |method|
          define_method("do_#{method}") do |req, res|
            handle_request(req, res)
          end
        end

        private

        def handle_request(req, res)
          puts "DEBUG: Request: #{req.request_method} #{req.path}" if ENV['DEBUG']
          puts "DEBUG: Request headers: #{req.header}" if ENV['DEBUG']
          
          case req.path
          when '/register'
            @mock_server.send(:handle_register, req, res)
          when %r{^/withdraw}
            @mock_server.send(:handle_withdraw, req, res)
          when '/discover'
            @mock_server.send(:handle_discover, req, res)
          when '/'
            @mock_server.send(:handle_list_all, req, res)
          else
            puts "DEBUG: 404 for path: #{req.path}" if ENV['DEBUG']
            res.status = 404
            res['Content-Type'] = 'application/json'
            res.body = { error: "Not found: #{req.path}" }.to_json
          end
        end
      end

      @server.mount('/', servlet, self)
    end

    def handle_register(req, res)
      if req.request_method == 'POST'
        agent_info = JSON.parse(req.body, symbolize_names: true)
        agent_id = SecureRandom.uuid
        @agents[agent_id] = agent_info
        
        res.status = 201
        res['Content-Type'] = 'application/json'
        res.body = { uuid: agent_id }.to_json
      else
        res.status = 405
      end
    end

    def handle_withdraw(req, res)
      if req.request_method == 'DELETE'
        # Handle both /withdraw/id and /withdraw?id=xyz patterns
        agent_id = nil
        if req.path =~ %r{/withdraw/([^/?]+)}
          agent_id = $1
        elsif req.query_string && req.query_string.include?('id=')
          agent_id = req.query['id']
        end
        
        # Debug output
        puts "DEBUG: Withdraw request for agent_id: #{agent_id}, path: #{req.path}" if ENV['DEBUG']
        puts "DEBUG: Available agents: #{@agents.keys}" if ENV['DEBUG']
        
        if agent_id && @agents.delete(agent_id)
          puts "DEBUG: Successfully deleted agent #{agent_id}" if ENV['DEBUG']
          res.status = 204
        else
          puts "DEBUG: Agent #{agent_id} not found" if ENV['DEBUG']
          res.status = 404
          res['Content-Type'] = 'application/json'
          res.body = { error: 'Agent not found' }.to_json
        end
      else
        res.status = 405
      end
    end

    def handle_discover(req, res)
      if req.request_method == 'GET'
        capability = req.query['capability']
        matching_agents = @agents.select do |id, info|
          info[:capabilities]&.include?(capability)
        end
        
        result = matching_agents.map do |id, info|
          info.merge(uuid: id)
        end
        
        res.status = 200
        res['Content-Type'] = 'application/json'
        res.body = result.to_json
      else
        res.status = 405
      end
    end

    def handle_list_all(req, res)
      if req.request_method == 'GET'
        result = @agents.map do |id, info|
          info.merge(uuid: id)
        end
        
        res.status = 200
        res['Content-Type'] = 'application/json'
        res.body = result.to_json
      else
        res.status = 405
      end
    end
  end

  class MockAmqpMessageClient
    attr_accessor :logger, :channel, :exchange
    attr_reader :queues, :published_messages

    def initialize(config: {}, logger: Logger.new('/dev/null'))
      @config = config
      @logger = logger
      @queues = {}
      @published_messages = []
      @message_handlers = {}
    end

    def setup(agent_id:, logger:)
      queue_name = agent_id
      @queues[queue_name] = MockQueue.new(queue_name)
      @queues[queue_name]
    end

    def create_queue(agent_id)
      queue_name = agent_id
      @queues[queue_name] = MockQueue.new(queue_name)
    end

    def listen_for_messages(queue, request_handler:, response_handler:, control_handler:)
      @message_handlers[queue.name] = {
        request: request_handler,
        response: response_handler,
        control: control_handler
      }
      
      # In a real implementation, this would block. For testing, we'll simulate it.
      queue.set_handlers(@message_handlers[queue.name])
    end

    def publish(message)
      @published_messages << message
      
      # Auto-deliver to target queue if it exists
      target_queue = message.dig(:header, :to_uuid)
      if target_queue && @queues[target_queue]
        deliver_message_to_queue(target_queue, message)
      end
      
      { success: true, message: "Message published successfully" }
    end

    def delete_queue(queue_name)
      @queues.delete(queue_name)
    end

    def deliver_message_to_queue(queue_name, message)
      queue = @queues[queue_name]
      return false unless queue
      
      queue.deliver_message(message)
      true
    end
  end

  class MockQueue
    attr_reader :name, :messages
    
    def initialize(name)
      @name = name
      @messages = []
      @handlers = {}
    end

    def set_handlers(handlers)
      @handlers = handlers
    end

    def deliver_message(message)
      @messages << message
      
      # Simulate message processing
      type = message.dig(:header, :type)&.to_sym
      handler = @handlers[type]
      handler&.call(message)
    end

    def clear
      @messages.clear
    end
  end

  class TestAgent < Agent99::Base
    attr_reader :received_requests, :received_responses, :received_controls

    def initialize(name:, capabilities:, **options)
      @test_name = name
      @test_capabilities = capabilities
      @received_requests = []
      @received_responses = []
      @received_controls = []
      super(**options)
      @capabilities = @test_capabilities  # Set the capabilities instance variable
      @name = @test_name  # Set the name instance variable
      setup_message_handlers  # Set up the message handlers
    end

    def info
      {
        name: @test_name,
        capabilities: @test_capabilities
      }
    end

    def receive_request(payload, header)
      @received_requests << { payload: payload, header: header }
      { status: 'processed', response: 'test response' }
    end

    def receive_response(payload, header)
      @received_responses << { payload: payload, header: header }
    end

    def receive_control(payload, header)
      @received_controls << { payload: payload, header: header }
    end

    # Override the initialize to set up proper message handlers
    def setup_message_handlers
      return unless @queue && @message_client
      
      @message_client.listen_for_messages(
        @queue,
        request_handler: ->(message) { 
          process_request(message)
        },
        response_handler: ->(message) { 
          process_response(message)
        },
        control_handler: ->(message) { 
          process_control(message)
        }
      )
    end

    # Override the message processing methods to work with TestAgent
    def process_request(message)
      @payload = message
      @header = message[:header]
      # Skip schema validation for tests
      receive_request(message[:payload], message[:header])
    end

    def process_response(message)
      @payload = message
      receive_response(message[:payload], message[:header])
    end

    def process_control(message)
      @payload = message
      receive_control(message[:payload], message[:header])
    end

    # Add missing methods that tests expect
    def send_request(to_uuid:, payload:)
      header = {
        from_uuid: id,
        to_uuid: to_uuid,
        event_uuid: SecureRandom.uuid,
        type: "request",
        timestamp: Time.now.to_i
      }
      
      message = { header: header, payload: payload }
      message_client.publish(message)
      message
    end

    def send_response(payload:, to_uuid: nil)
      target_uuid = to_uuid || @payload&.dig(:header, :from_uuid)
      return unless target_uuid

      header = {
        from_uuid: id,
        to_uuid: target_uuid,
        event_uuid: SecureRandom.uuid,
        type: "response", 
        timestamp: Time.now.to_i
      }
      
      message = { header: header, payload: payload }
      message_client.publish(message)
      message
    end

    def discover_agents(capability:)
      registry_client.discover(capability: capability)
    end

    def get_all_agents
      registry_client.fetch_all_agents
    end

    def create_header(type:, to_uuid:)
      {
        from_uuid: id,
        to_uuid: to_uuid,
        event_uuid: SecureRandom.uuid,
        type: type,
        timestamp: Time.now.to_i
      }
    end

    def validate_header(header)
      required_keys = [:from_uuid, :to_uuid, :event_uuid, :type, :timestamp]
      required_keys.all? { |key| header.key?(key) }
    end

    def clear_received_messages
      @received_requests.clear
      @received_responses.clear
      @received_controls.clear
    end
  end
end