# frozen_string_literal: true

require "test_helper"
require "stringio"

class TestNatsMessageClient < Minitest::Test
  # nats-pure re-raises the socket error when no server is listening
  def test_initialize_logs_and_raises_when_nats_server_is_unreachable
    assert_connect_failure_reported(Errno::ECONNREFUSED.new("connect(2)"))
  end

  # nats-pure raises ConnectError for protocol and auth failures
  def test_initialize_logs_and_raises_when_nats_handshake_fails
    assert_connect_failure_reported(NATS::IO::ConnectError.new("INFO not received"))
  end

  # Stands in for a nats-pure connection: records publishes and subscriptions.
  class FakeNats
    attr_reader :published, :subjects
    attr_accessor :error

    def initialize
      @published = []
      @subjects = []
    end

    def publish(subject, data)
      raise error if error

      @published << [subject, data]
    end

    def subscribe(subject, &block)
      @subjects << subject
      @on_message = block
    end

    def deliver(data) = @on_message.call(Struct.new(:data).new(data))
  end

  # A real NatsMessageClient with a FakeNats, built without connecting.
  def build_client(log: StringIO.new)
    nats = FakeNats.new
    client = Agent99::NatsMessageClient.allocate
    client.instance_variable_set(:@nats, nats)
    client.instance_variable_set(:@logger, Logger.new(log))
    [client, nats]
  end

  def message_to(to_uuid, type: "request")
    {
      header: { from_uuid: "sender", to_uuid: to_uuid, event_uuid: "event-1", type: type, timestamp: 1 },
      payload: { action: "test" }
    }
  end

  # listen_for_messages ends in `loop { sleep 1 }` to keep the process alive;
  # an instance-level loop that returns lets the test continue.
  def listen(client, **handlers)
    client.define_singleton_method(:loop) { nil }
    client.listen_for_messages("agent-1", **handlers)
  end

  def test_publish_success
    client, nats = build_client
    message = message_to("agent-9")

    result = client.publish(message)

    assert_equal({ success: true, message: "Message published successfully" }, result)
    subject, data = nats.published.first
    assert_equal "agent-9", subject
    assert_equal message, JSON.parse(data, symbolize_names: true)
  end

  def test_publish_json_error
    client, nats = build_client
    message = message_to("agent-9").merge(payload: { value: Float::NAN })

    result = client.publish(message)

    refute result[:success]
    assert_match(/\AJSON conversion error: /, result[:error])
    assert_empty nats.published
  end

  def test_publish_timeout_reports_publishing_error
    client, nats = build_client
    nats.error = NATS::IO::Timeout.new("timed out")

    result = client.publish(message_to("agent-9"))

    assert_equal({ success: false, error: "Publishing error: timed out" }, result)
  end

  def test_publish_unexpected_error_is_reported
    client, nats = build_client
    nats.error = RuntimeError.new("boom")

    result = client.publish(message_to("agent-9"))

    assert_equal({ success: false, error: "Unexpected error: boom" }, result)
  end

  def test_listen_for_messages_routes_by_type
    client, nats = build_client
    received = Hash.new { |hash, key| hash[key] = [] }

    listen(
      client,
      request_handler: ->(msg) { received[:request] << msg },
      response_handler: ->(msg) { received[:response] << msg },
      control_handler: ->(msg) { received[:control] << msg }
    )
    %w[request response control].each do |type|
      nats.deliver(JSON.generate(message_to("agent-1", type: type)))
    end

    assert_equal ["agent-1"], nats.subjects
    %i[request response control].each do |type|
      assert_equal [message_to("agent-1", type: type.to_s)], received[type], "#{type} handler"
    end
  end

  def test_listen_for_messages_rejects_unknown_type
    client, nats = build_client
    noop = ->(_msg) { flunk "no handler should run" }
    listen(client, request_handler: noop, response_handler: noop, control_handler: noop)

    error = assert_raises(NotImplementedError) do
      nats.deliver(JSON.generate(message_to("agent-1", type: "bogus")))
    end
    assert_equal "Unsupported message type: bogus", error.message
  end

  def test_delete_queue_only_logs
    log = StringIO.new
    client, nats = build_client(log: log)

    client.delete_queue("agent-1")

    assert_includes log.string, "Subject agent-1 will be automatically cleaned up"
    assert_empty nats.published
  end

  private

  def assert_connect_failure_reported(connect_error)
    log = StringIO.new

    error = with_nats_connect_raising(connect_error) do
      assert_raises(RuntimeError) do
        Agent99::NatsMessageClient.new(logger: Logger.new(log))
      end
    end

    assert_match "NATS Connection Error: #{connect_error.message}", error.message
    assert_match "Failed to connect to NATS: #{connect_error.class}: #{connect_error.message}", log.string
    assert_same connect_error, error.cause
  end

  def with_nats_connect_raising(connect_error)
    original = NATS.method(:connect)
    NATS.define_singleton_method(:connect) { |*| raise connect_error }
    begin
      yield
    ensure
      NATS.define_singleton_method(:connect, original)
    end
  end
end
