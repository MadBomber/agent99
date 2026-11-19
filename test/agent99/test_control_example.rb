# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"

# Issue #98: examples/control.rb must not send control messages to itself,
# and must leave fini to the framework's at_exit hook.
class TestControlExample < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  # Runs the example's menu loop in a child process with stub clients:
  # the registry lists Control itself plus one other agent.
  SCRIPT = <<~'RUBY'
    require 'agent99'

    class Agent99::RegistryClient
      attr_accessor :logger

      def initialize(*) = nil
      def register(info:) = 'control-uuid'
      def withdraw(id) = $stdout.puts("withdraw #{id}")
      def fetch_all_agents = [{ uuid: 'control-uuid', name: 'Control' }, { uuid: 'max-uuid', name: 'Max' }]
    end

    class Agent99::AmqpMessageClient
      def initialize(*) = nil
      def setup(agent_id:, logger:) = agent_id
      def listen_for_messages(*, **) = sleep
      def delete_queue(name) = $stdout.puts("delete_queue #{name}")

      def publish(message)
        $stdout.puts("#{message[:action]} -> #{message[:header][:to_uuid]}")
        { success: true }
      end
    end

    $PROGRAM_NAME = File.expand_path('examples/control.rb')
    load $PROGRAM_NAME
  RUBY

  def run_control(choices)
    Open3.capture2e(RbConfig.ruby, "-Ilib", "-e", SCRIPT, stdin_data: choices, chdir: ROOT)
  end

  def test_stop_all_skips_the_controller
    output, status = run_control("3\n5\n")

    assert status.success?, output
    assert_includes output, "shutdown -> max-uuid"
    refute_includes output, "shutdown -> control-uuid"
  end

  def test_exit_runs_fini_once
    output, status = run_control("5\n")

    assert status.success?, output
    assert_equal 1, output.scan("withdraw control-uuid").size, output
    refute_includes output, "fini called with a nil id"
  end
end
