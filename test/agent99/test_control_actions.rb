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

  # nats-pure runs handlers on a concurrent-ruby pool worker, which rescues
  # Exception, so an exit raised on that thread never reaches the main thread.
  SHUTDOWN_FROM_WORKER_SCRIPT = SHUTDOWN_SCRIPT.sub('agent.send(:handle_shutdown)', <<~'RUBY')
    Thread.new do
      agent.send(:handle_shutdown)
    rescue Exception # rubocop:disable Lint/RescueException
      nil
    end
    sleep 5
    $stdout.puts 'still running'
  RUBY

  def test_shutdown_cleans_up_once
    out, status = run_script(SHUTDOWN_SCRIPT)

    assert status.success?, out
    assert_equal 1, out.scan('withdraw agent-1').size, out
    assert_equal 1, out.scan('delete_queue agent-1').size, out
    refute_includes out, 'fini called with a nil id'
  end


  def test_shutdown_from_worker_thread_ends_the_process
    out, status = run_script(SHUTDOWN_FROM_WORKER_SCRIPT)

    assert status.success?, out
    refute_includes out, 'still running'
    assert_equal 1, out.scan('withdraw agent-1').size, out
  end

  private

  def run_script(script)
    lib = File.expand_path('../../lib', __dir__)
    Open3.capture2e(RbConfig.ruby, '-I', lib, '-e', script)
  end
end
