# frozen_string_literal: true

require "test_helper"
require "stringio"

class TestNatsMessageClient < Minitest::Test
  # nats-pure re-raises the socket error when no server is listening
  def test_initialize_logs_and_raises_when_nats_server_is_unreachable
    assert_connect_failure_reported(Errno::ECONNREFUSED.new("connect(2)"))
  end

  # nats-pure raises ConnectError for protocol, TLS, and auth failures
  def test_initialize_logs_and_raises_when_nats_handshake_fails
    assert_connect_failure_reported(NATS::IO::ConnectError.new("INFO not received"))
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
    assert_match "Failed to connect to NATS: #{connect_error.message}", log.string
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
