# frozen_string_literal: true

require "test_helper"

class TestAgentDiscovery < Minitest::Test
  def build_agent(discover_result)
    registry_client = Object.new
    registry_client.define_singleton_method(:discover) { |capability:| discover_result }

    agent = Class.new(Agent99::Base).allocate
    agent.instance_variable_set(:@registry_client, registry_client)
    agent.instance_variable_set(:@logger, @logger)
    agent
  end

  def test_discover_agent_raises_no_agents_available_when_registry_returns_nil
    agent = build_agent(nil)

    error = assert_raises(RuntimeError) { agent.send(:discover_agent, capability: "greeter") }
    assert_equal "No agents available", error.message
  end

  def test_discover_agent_raises_no_agents_available_when_registry_returns_empty
    agent = build_agent([])

    error = assert_raises(RuntimeError) { agent.send(:discover_agent, capability: "greeter") }
    assert_equal "No agents available", error.message
  end
end
