# frozen_string_literal: true

require "test_helper"

class TestMessageProcessing < Minitest::Test
  def build_agent(klass, payload)
    agent = klass.allocate
    agent.instance_variable_set(:@payload, payload)
    agent
  end

  def test_get_returns_nil_for_missing_field_without_request_schema
    klass = Class.new(Agent99::Base)
    agent = build_agent(klass, { name: "World" })

    assert_equal "World", agent.send(:get, :name)
    assert_nil agent.send(:get, :greeting)
  end

  def test_get_falls_back_to_request_schema_example
    klass = Class.new(Agent99::Base) do
      const_set(:REQUEST_SCHEMA, { properties: { greeting: { examples: ["Hello"] } } })
    end
    agent = build_agent(klass, {})

    assert_equal "Hello", agent.send(:get, :greeting)
  end

  def test_get_uses_request_schema_inherited_from_parent_agent
    parent = Class.new(Agent99::Base) do
      const_set(:REQUEST_SCHEMA, { properties: { greeting: { examples: ["Hi"] } } })
    end
    agent = build_agent(Class.new(parent), {})

    assert_equal "Hi", agent.send(:get, :greeting)
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

  def test_unknown_control_action_replies_with_error
    publisher = RecordingPublisher.new
    agent = build_agent(
      Class.new(Agent99::Base),
      { header: { type: "control", from_uuid: "controller", to_uuid: "agent-1" }, action: "restart" }
    )
    agent.instance_variable_set(:@logger, Logger.new(nil))
    agent.instance_variable_set(:@message_client, publisher)

    agent.send(:receive_control)

    assert_equal 1, publisher.published.size
    reply = publisher.published.first
    assert_equal "response", reply[:action]
    assert_equal "controller", reply[:header][:to_uuid]
    assert_equal({ error: "Unknown control action: restart" }, reply[:data])
  end
end
