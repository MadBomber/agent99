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

  # Records what the agent publishes, in place of a message broker.
  class RecordingPublisher
    attr_reader :published

    def initialize
      @published = []
    end

    def publish(message)
      @published << message
    end
  end


  def test_pause_sets_paused_and_replies
    agent, publisher = control_agent(action: 'pause')
    agent.send(:receive_control)

    assert agent.send(:paused?)
    assert_equal ['Paused'], reply_data(publisher)
  end


  def test_resume_clears_paused_and_replies
    agent, publisher = control_agent(action: 'resume')
    agent.instance_variable_set(:@paused, true)
    agent.send(:receive_control)

    refute agent.send(:paused?)
    assert_equal ['Resumed'], reply_data(publisher)
  end


  def test_update_config_stores_config_and_replies
    agent, publisher = control_agent(action: 'update_config', config: { level: 3 })
    agent.send(:receive_control)

    assert_equal({ level: 3 }, agent.instance_variable_get(:@config))
    assert_equal ['Configuration updated'], reply_data(publisher)
  end


  def test_status_replies_with_agent_state
    agent, publisher = control_agent(action: 'status')
    agent.instance_variable_set(:@config, { level: 3 })
    agent.instance_variable_set(:@start_time, Time.now - 5)
    agent.send(:receive_control)

    status = reply_data(publisher).first
    assert_equal 'status', status[:type]
    assert_equal 'agent-1', status[:id]
    assert_equal 'ControlAgent', status[:name]
    assert_equal false, status[:paused]
    assert_equal({ level: 3 }, status[:config])
    assert_operator status[:uptime], :>=, 5
  end


  def test_control_reply_is_addressed_to_the_sender
    agent, publisher = control_agent(action: 'pause')
    agent.send(:receive_control)

    reply = publisher.published.first
    assert_equal 'response', reply[:action]
    assert_equal 'control', reply[:header][:type]
    assert_equal 'controller', reply[:header][:to_uuid]
    assert_equal 'agent-1', reply[:header][:from_uuid]
  end


  def test_handler_error_replies_with_error
    agent, publisher = control_agent(action: 'status')
    # @start_time is nil, so the uptime calculation raises.
    agent.send(:receive_control)

    assert_equal 1, publisher.published.size
    assert_kind_of String, reply_data(publisher).first[:error]
  end


  def test_unknown_action_runs_no_handler
    agent, _publisher = control_agent(action: 'no_such_action')
    agent.send(:receive_control)

    refute agent.send(:paused?)
    assert_nil agent.instance_variable_get(:@config)
  end

  private

  def run_script(script)
    lib = File.expand_path('../../lib', __dir__)
    Open3.capture2e(RbConfig.ruby, '-I', lib, '-e', script)
  end


  # An agent built without initialize (no registry, no broker), holding a
  # control message from 'controller'.
  def control_agent(**control)
    publisher = RecordingPublisher.new
    agent = Agent99::Base.allocate
    agent.instance_variable_set(:@id, 'agent-1')
    agent.instance_variable_set(:@name, 'ControlAgent')
    agent.instance_variable_set(:@paused, false)
    agent.instance_variable_set(:@logger, @logger)
    agent.instance_variable_set(:@message_client, publisher)
    agent.instance_variable_set(
      :@payload,
      { header: { type: 'control', from_uuid: 'controller', to_uuid: 'agent-1' } }.merge(control)
    )
    [agent, publisher]
  end


  def reply_data(publisher)
    publisher.published.map { |message| message[:data] }
  end
end
