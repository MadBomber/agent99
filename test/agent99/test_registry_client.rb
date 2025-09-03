# frozen_string_literal: true

require "test_helper"

class TestRegistryClient < Minitest::Test
  def test_initialize_with_defaults
    client = Agent99::RegistryClient.new(logger: @logger)
    assert_equal 'http://localhost:4567', client.instance_variable_get(:@base_url)
  end

  def test_initialize_with_custom_url
    custom_url = "http://test-registry:8080"
    client = Agent99::RegistryClient.new(base_url: custom_url, logger: @logger)
    assert_equal custom_url, client.instance_variable_get(:@base_url)
  end

  def test_register_agent
    client = Agent99::RegistryClient.new(base_url: registry_url, logger: @logger)
    
    agent_info = {
      name: "TestAgent",
      capabilities: ["test", "demo"]
    }
    
    agent_id = client.register(info: agent_info)
    
    refute_nil agent_id
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, agent_id)
    
    # Verify the agent is registered in our mock server
    agents = @registry_server.agents
    assert_includes agents.keys, agent_id
    assert_equal agent_info[:name], agents[agent_id][:name]
    assert_equal agent_info[:capabilities], agents[agent_id][:capabilities]
  end

  def test_withdraw_agent
    client = Agent99::RegistryClient.new(base_url: registry_url, logger: @logger)
    
    # First register an agent
    agent_info = { name: "TestAgent", capabilities: ["test"] }
    agent_id = client.register(info: agent_info)
    
    # Verify it's registered
    assert_includes @registry_server.agents.keys, agent_id
    
    # Now withdraw it
    result = client.withdraw(agent_id)
    
    # Give a moment for the request to process
    sleep 0.1
    
    # Verify it's gone
    refute_includes @registry_server.agents.keys, agent_id
  end

  def test_withdraw_nonexistent_agent
    client = Agent99::RegistryClient.new(base_url: registry_url, logger: @logger)
    
    # Should handle gracefully
    result = client.withdraw("nonexistent-id")
    assert_nil result
  end

  def test_withdraw_without_id
    client = Agent99::RegistryClient.new(base_url: registry_url, logger: @logger)
    
    # Should log warning and return the result of logger.warn (which is typically truthy)
    result = client.withdraw(nil)
    # The logger.warn method returns truthy value, so we just check it's not an error
    refute_nil result
  end

  def test_discover_agents_by_capability
    client = Agent99::RegistryClient.new(base_url: registry_url, logger: @logger)
    
    # Register multiple agents
    agent1_info = { name: "Agent1", capabilities: ["math", "calculation"] }
    agent2_info = { name: "Agent2", capabilities: ["text", "processing"] }
    agent3_info = { name: "Agent3", capabilities: ["math", "geometry"] }
    
    id1 = client.register(info: agent1_info)
    id2 = client.register(info: agent2_info)
    id3 = client.register(info: agent3_info)
    
    # Discover agents with 'math' capability
    math_agents = client.discover(capability: "math")
    
    assert_equal 2, math_agents.size
    agent_names = math_agents.map { |agent| agent[:name] }
    assert_includes agent_names, "Agent1"
    assert_includes agent_names, "Agent3"
    refute_includes agent_names, "Agent2"
  end

  def test_discover_capability_not_found
    client = Agent99::RegistryClient.new(base_url: registry_url, logger: @logger)
    
    # Register an agent without the capability we're looking for
    agent_info = { name: "TestAgent", capabilities: ["other"] }
    client.register(info: agent_info)
    
    # Search for a capability that doesn't exist
    result = client.discover(capability: "nonexistent")
    
    assert_empty result
  end

  def test_fetch_all_agents
    client = Agent99::RegistryClient.new(base_url: registry_url, logger: @logger)
    
    # Initially should be empty
    agents = client.fetch_all_agents
    assert_empty agents
    
    # Register some agents
    agent1_info = { name: "Agent1", capabilities: ["test1"] }
    agent2_info = { name: "Agent2", capabilities: ["test2"] }
    
    id1 = client.register(info: agent1_info)
    id2 = client.register(info: agent2_info)
    
    # Fetch all
    agents = client.fetch_all_agents
    assert_equal 2, agents.size
    
    agent_names = agents.map { |agent| agent[:name] }
    assert_includes agent_names, "Agent1"
    assert_includes agent_names, "Agent2"
    
    # Check that UUIDs are included
    agent_uuids = agents.map { |agent| agent[:uuid] }
    assert_includes agent_uuids, id1
    assert_includes agent_uuids, id2
  end

  def test_handle_server_errors
    # Test with invalid URL to trigger connection errors
    client = Agent99::RegistryClient.new(
      base_url: "http://nonexistent-server:9999",
      logger: @logger
    )
    
    agent_info = { name: "TestAgent", capabilities: ["test"] }
    result = client.register(info: agent_info)
    
    # Should handle connection errors gracefully
    assert_nil result
  end
end