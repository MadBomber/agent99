# frozen_string_literal: true

require_relative '../test_helper'
require 'open3'
require 'rbconfig'

class TestControlActions < Minitest::Test
  # Runs in a child process so the real exit and at_exit hooks fire.
  SHUTDOWN_SCRIPT = <<~'RUBY'
    require 'agent99'

    class StubRegistry
      attr_accessor :logger

      def register(info:) = 'agent-1'
      def withdraw(id) = $stdout.puts("withdraw #{id}")
    end

    class StubMessenger
      def setup(agent_id:, logger:) = agent_id
      def publish(_message) = nil
      def delete_queue(name) = $stdout.puts("delete_queue #{name}")
    end

    class ShutdownAgent < Agent99::Base
      def info = { name: 'ShutdownAgent', capabilities: ['test'] }
    end

    agent = ShutdownAgent.new(
      registry_client: StubRegistry.new,
      message_client: StubMessenger.new,
      logger: Logger.new($stdout)
    )
    agent.instance_variable_set(:@payload, { header: { from_uuid: 'sender', to_uuid: 'agent-1' } })
    agent.send(:handle_shutdown)
  RUBY

  def test_shutdown_cleans_up_once
    lib = File.expand_path('../../lib', __dir__)
    out, status = Open3.capture2e(RbConfig.ruby, '-I', lib, '-e', SHUTDOWN_SCRIPT)

    assert status.success?, out
    assert_equal 1, out.scan('withdraw agent-1').size, out
    assert_equal 1, out.scan('delete_queue agent-1').size, out
    refute_includes out, 'fini called with a nil id'
  end
end
