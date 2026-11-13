# frozen_string_literal: true

require "test_helper"

class TestAmqpMessageClient < Minitest::Test
  def test_initialize_with_default_config
    # Stub the create_amqp_connection method to avoid real connection
    Agent99::AmqpMessageClient.class_eval do
      alias_method :original_create_amqp_connection, :create_amqp_connection
      
      def create_amqp_connection
        mock_connection = Object.new
        def mock_connection.create_channel
          mock_channel = Object.new
          def mock_channel.default_exchange
            Object.new
          end
          mock_channel
        end
        mock_connection
      end
    end
    
    client = Agent99::AmqpMessageClient.new(logger: @logger)
    
    config = client.instance_variable_get(:@config)
    assert_equal "127.0.0.1", config[:host]
    assert_equal 5672, config[:port]
    assert_equal false, config[:ssl]
    
    # Restore original method
    Agent99::AmqpMessageClient.class_eval do
      alias_method :create_amqp_connection, :original_create_amqp_connection
      remove_method :original_create_amqp_connection
    end
  end

  def test_setup_uses_the_given_logger_afterwards
    Agent99::AmqpMessageClient.class_eval do
      alias_method :original_create_amqp_connection, :create_amqp_connection

      def create_amqp_connection
        mock_connection = Object.new
        def mock_connection.create_channel
          mock_channel = Object.new
          def mock_channel.default_exchange = Object.new
          def mock_channel.queue(name, **) = name
          mock_channel
        end
        mock_connection
      end
    end

    client_log = StringIO.new
    agent_log  = StringIO.new
    client = Agent99::AmqpMessageClient.new(logger: Logger.new(client_log))

    client.setup(agent_id: "agent-1", logger: Logger.new(agent_log))
    client.delete_queue(nil)

    assert_includes agent_log.string, "Attempted to delete queue with nil name"
    refute_includes client_log.string, "Attempted to delete queue with nil name"
  ensure
    Agent99::AmqpMessageClient.class_eval do
      alias_method :create_amqp_connection, :original_create_amqp_connection
      remove_method :original_create_amqp_connection
    end
  end

  # Bunny-free stand-ins for the connection, channel, exchange and queue the
  # real client gets from create_amqp_connection.
  class FakeExchange
    attr_reader :published
    attr_accessor :error

    def initialize = @published = []

    def publish(payload, routing_key:)
      raise error if error

      @published << [payload, routing_key]
    end
  end

  class FakeQueue
    attr_reader :name, :subscribe_options

    def initialize(name) = @name = name
    def deleted? = !!@deleted
    def delete = @deleted = true

    def subscribe(**options, &block)
      @subscribe_options = options
      @on_delivery = block
    end

    def deliver(body) = @on_delivery.call(nil, nil, body)
  end

  class FakeChannel
    attr_reader :default_exchange, :declared, :queues
    attr_accessor :passive_error

    def initialize
      @default_exchange = FakeExchange.new
      @declared = []
      @queues = {}
    end

    def queue(name, **options)
      @declared << [name, options]
      raise passive_error if options[:passive] && passive_error

      @queues[name] ||= FakeQueue.new(name)
    end
  end

  FakeConnection = Struct.new(:channel) do
    def create_channel = channel
  end

  # A real AmqpMessageClient wired to a FakeChannel through its
  # create_amqp_connection seam.
  def build_client(config: Agent99::AmqpMessageClient::CONFIG, log: StringIO.new)
    channel = FakeChannel.new
    client = Agent99::AmqpMessageClient.allocate
    client.define_singleton_method(:create_amqp_connection) { FakeConnection.new(channel) }
    client.send(:initialize, config: config, logger: Logger.new(log))
    [client, channel]
  end

  def message_to(to_uuid, type: "request")
    {
      header: { from_uuid: "sender", to_uuid: to_uuid, event_uuid: "event-1", type: type, timestamp: 1 },
      payload: { action: "test" }
    }
  end

  def test_initialize_with_custom_config
    custom_config = { host: "10.0.0.1", port: 5673, user: "testuser", pass: "testpass" }
    client, channel = build_client(config: custom_config)

    assert_equal custom_config, client.instance_variable_get(:@config)
    assert_same channel, client.channel
    assert_same channel.default_exchange, client.exchange
  end

  def test_setup_creates_queue
    client, channel = build_client
    queue = client.setup(agent_id: "agent-1", logger: @logger)

    assert_equal "agent-1", queue.name
    assert_same channel.queues["agent-1"], queue
  end

  def test_create_queue
    client, channel = build_client
    queue = client.create_queue("agent-2")

    assert_equal "agent-2", queue.name
    assert_equal ["agent-2"], channel.declared.map(&:first)
  end

  def test_publish_message_success
    client, channel = build_client
    message = message_to("agent-9")

    result = client.publish(message)

    assert_equal({ success: true, message: "Message published successfully" }, result)
    payload, routing_key = channel.default_exchange.published.first
    assert_equal "agent-9", routing_key
    assert_equal message, JSON.parse(payload, symbolize_names: true)
  end

  def test_publish_message_with_invalid_json
    client, channel = build_client
    message = message_to("agent-9").merge(payload: { value: Float::NAN })

    result = client.publish(message)

    refute result[:success]
    assert_match(/\AJSON conversion error: /, result[:error])
    assert_empty channel.default_exchange.published
  end

  def test_publish_on_closed_connection_reports_publishing_error
    client, channel = build_client
    channel.default_exchange.error = Bunny::ConnectionClosedError.new("frame")

    result = client.publish(message_to("agent-9"))

    refute result[:success]
    assert_match(/\APublishing error: /, result[:error])
  end

  def test_publish_unexpected_error_is_reported
    client, channel = build_client
    channel.default_exchange.error = RuntimeError.new("boom")

    result = client.publish(message_to("agent-9"))

    assert_equal({ success: false, error: "Unexpected error: boom" }, result)
  end

  def test_listen_for_messages_subscribes_blocking
    client, channel = build_client
    queue = channel.queue("agent-1")
    noop = ->(_msg) {}

    client.listen_for_messages(queue, request_handler: noop, response_handler: noop, control_handler: noop)

    assert_equal({ block: true }, queue.subscribe_options)
  end

  def test_message_routing
    client, channel = build_client
    queue = channel.queue("agent-1")
    received = Hash.new { |hash, key| hash[key] = [] }

    client.listen_for_messages(
      queue,
      request_handler: ->(msg) { received[:request] << msg },
      response_handler: ->(msg) { received[:response] << msg },
      control_handler: ->(msg) { received[:control] << msg }
    )

    %w[request response control].each do |type|
      queue.deliver(JSON.generate(message_to("agent-1", type: type)))
    end

    %i[request response control].each do |type|
      assert_equal [message_to("agent-1", type: type.to_s)], received[type], "#{type} handler"
    end
  end

  def test_message_with_unknown_type_raises
    client, channel = build_client
    queue = channel.queue("agent-1")
    noop = ->(_msg) { flunk "no handler should run" }
    client.listen_for_messages(queue, request_handler: noop, response_handler: noop, control_handler: noop)

    error = assert_raises(NotImplementedError) do
      queue.deliver(JSON.generate(message_to("agent-1", type: "bogus")))
    end
    assert_equal "Unsupported message type: bogus", error.message
  end

  def test_delete_queue
    client, channel = build_client
    queue = channel.queue("agent-1")

    client.delete_queue("agent-1")

    assert queue.deleted?
    assert_equal ["agent-1", { passive: true }], channel.declared.last
  end

  def test_delete_nonexistent_queue
    log = StringIO.new
    client, channel = build_client(log: log)
    channel.passive_error = Bunny::NotFound.new("NOT_FOUND", nil, nil)

    client.delete_queue("nonexistent")

    assert_includes log.string, "Queue nonexistent not found"
  end

  def test_delete_queue_unexpected_error_is_logged
    log = StringIO.new
    client, channel = build_client(log: log)
    channel.passive_error = RuntimeError.new("boom")

    client.delete_queue("agent-1")

    assert_includes log.string, "Error deleting queue agent-1: boom"
  end

  def test_delete_queue_with_nil_name
    log = StringIO.new
    client, channel = build_client(log: log)

    client.delete_queue(nil)

    assert_empty channel.declared
    assert_includes log.string, "Attempted to delete queue with nil name"
  end

  def test_singleton_instance
    # Stub the create_amqp_connection method to avoid real connection
    Agent99::AmqpMessageClient.class_eval do
      alias_method :original_create_amqp_connection, :create_amqp_connection
      
      def create_amqp_connection
        mock_connection = Object.new
        def mock_connection.create_channel
          mock_channel = Object.new
          def mock_channel.default_exchange
            Object.new
          end
          mock_channel
        end
        mock_connection
      end
    end
    
    # Clear any existing instance to ensure we test the singleton pattern
    Agent99::AmqpMessageClient.instance_variable_set(:@instance, nil)
    
    instance1 = Agent99::AmqpMessageClient.instance
    instance2 = Agent99::AmqpMessageClient.instance
    
    assert_same instance1, instance2
    
    # Restore original method
    Agent99::AmqpMessageClient.class_eval do
      alias_method :create_amqp_connection, :original_create_amqp_connection
      remove_method :original_create_amqp_connection
    end
    
    # Clean up singleton instance for other tests
    Agent99::AmqpMessageClient.instance_variable_set(:@instance, nil)
  end
end