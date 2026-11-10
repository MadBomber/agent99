# frozen_string_literal: true

require "test_helper"
require "stringio"

class TestNatsMessageClient < Minitest::Test
  def test_initialize_logs_and_raises_when_nats_connect_fails
    log = StringIO.new

    error = with_failing_nats_connect("connection refused") do
      assert_raises(RuntimeError) do
        Agent99::NatsMessageClient.new(logger: Logger.new(log))
      end
    end

    assert_match "NATS Connection Error: connection refused", error.message
    assert_match "Failed to connect to NATS: connection refused", log.string
  end

  private

  def with_failing_nats_connect(message)
    original = NATS.method(:connect)
    NATS.define_singleton_method(:connect) { |*| raise NATS::IO::ConnectError, message }
    yield
  ensure
    NATS.define_singleton_method(:connect, original)
  end
end
