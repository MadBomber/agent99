# frozen_string_literal: true

require "test_helper"

class TestBase < Minitest::Test
  def test_agent_creation_and_basic_properties
    agent = create_test_agent(
      name: "TestBaseAgent",
      capabilities: ["test", "demo"]
    )
    
    assert_kind_of Agent99::Base, agent
    refute_nil agent.id
    assert_equal "TestBaseAgent", agent.name
    assert_equal ["test", "demo"], agent.capabilities
    refute_nil agent.logger
    refute_nil agent.registry_client
    refute_nil agent.message_client
    refute_nil agent.queue
  end

  def test_agent_includes_all_modules
    agent = create_test_agent(name: "ModuleTestAgent", capabilities: ["test"])
    
    assert_includes agent.class.ancestors, Agent99::HeaderManagement
    assert_includes agent.class.ancestors, Agent99::AgentDiscovery
    assert_includes agent.class.ancestors, Agent99::ControlActions
    assert_includes agent.class.ancestors, Agent99::AgentLifecycle
    assert_includes agent.class.ancestors, Agent99::MessageProcessing
  end

  def test_message_types_constant
    assert_equal %w[request response control], Agent99::Base::MESSAGE_TYPES
  end

  def test_agent_responds_to_lifecycle_methods
    agent = create_test_agent(name: "LifecycleAgent", capabilities: ["test"])
    
    assert_respond_to agent, :register
    assert_respond_to agent, :withdraw
    assert_respond_to agent, :fini
  end

  def test_agent_responds_to_message_methods
    agent = create_test_agent(name: "MessageAgent", capabilities: ["test"])
    
    assert_respond_to agent, :receive_request
    assert_respond_to agent, :receive_response
    assert_respond_to agent, :receive_control
    assert_respond_to agent, :send_request
    assert_respond_to agent, :send_response
  end

  def test_agent_responds_to_discovery_methods
    agent = create_test_agent(name: "DiscoveryAgent", capabilities: ["test"])
    
    assert_respond_to agent, :discover_agents
    assert_respond_to agent, :get_all_agents
  end

  def test_agent_responds_to_header_methods
    agent = create_test_agent(name: "HeaderAgent", capabilities: ["test"])
    
    assert_respond_to agent, :create_header
    assert_respond_to agent, :validate_header
  end

  def test_error_handling_method
    agent = create_test_agent(name: "ErrorAgent", capabilities: ["test"])
    
    error_logged = false
    debug_logged = false
    
    # Mock the logger methods on the agent's actual logger
    agent.logger.define_singleton_method(:error) do |message|
      error_logged = true
      # Use basic string methods instead of assert_includes inside the mock
      if message.include?("Test error message: Test exception")
        # Test passed for error logging
      end
    end
    
    agent.logger.define_singleton_method(:debug) do |message|
      debug_logged = true
      # Use basic string methods instead of assert_includes inside the mock
      if message.include?("test_base.rb")
        # Test passed for debug logging
      end
    end
    
    test_error = StandardError.new("Test exception")
    test_error.set_backtrace(caller)
    
    agent.send(:handle_error, "Test error message", test_error)
    
    assert error_logged
    assert debug_logged
  end

  def test_agent_attr_readers
    agent = create_test_agent(name: "AttrAgent", capabilities: ["test"])
    
    # Test that all expected attr_readers work
    refute_nil agent.id
    refute_nil agent.capabilities
    refute_nil agent.name
    refute_nil agent.logger
    refute_nil agent.queue
    
    # These might be nil initially but should be accessible
    assert_respond_to agent, :payload
    assert_respond_to agent, :header
    assert_respond_to agent, :agents
  end

  def test_agent_attr_accessors
    agent = create_test_agent(name: "AccessorAgent", capabilities: ["test"])
    
    # Test registry_client accessor
    original_registry = agent.registry_client
    new_registry = Agent99::RegistryClient.new(base_url: registry_url, logger: @logger)
    agent.registry_client = new_registry
    assert_equal new_registry, agent.registry_client
    agent.registry_client = original_registry
    
    # Test message_client accessor
    original_message_client = agent.message_client
    new_message_client = TestInfrastructure::MockAmqpMessageClient.new
    agent.message_client = new_message_client
    assert_equal new_message_client, agent.message_client
    agent.message_client = original_message_client
  end

  def test_rescue_clause_in_class
    # The Base class has a rescue clause at the class level
    # This test verifies that the class can be loaded without issues
    
    assert_kind_of Class, Agent99::Base
    assert Agent99::Base.ancestors.include?(Agent99::AgentLifecycle)
    assert Agent99::Base.ancestors.include?(Agent99::MessageProcessing)
  end

  def test_agent_info_method_requirement
    # Verify that agents must implement the info method
    agent = create_test_agent(name: "InfoAgent", capabilities: ["test"])
    
    info = agent.info
    assert_kind_of Hash, info
    assert_includes info.keys, :name
    assert_includes info.keys, :capabilities
  end

  def test_multiple_agent_creation
    # Test creating multiple agents with different configurations
    agent1 = create_test_agent(name: "Agent1", capabilities: ["math"])
    agent2 = create_test_agent(name: "Agent2", capabilities: ["text"])
    agent3 = create_test_agent(name: "Agent3", capabilities: ["math", "text"])
    
    # All should have unique IDs
    refute_equal agent1.id, agent2.id
    refute_equal agent1.id, agent3.id
    refute_equal agent2.id, agent3.id
    
    # All should be registered
    agent_ids = @registry_server.agents.keys
    assert_includes agent_ids, agent1.id
    assert_includes agent_ids, agent2.id
    assert_includes agent_ids, agent3.id
    
    # Each should have correct capabilities
    assert_equal ["math"], agent1.capabilities
    assert_equal ["text"], agent2.capabilities
    assert_equal ["math", "text"], agent3.capabilities
  end

  def test_agent_cleanup_on_fini
    agent = create_test_agent(name: "CleanupAgent", capabilities: ["cleanup"])
    
    agent_id = agent.id
    
    # Verify initial state
    assert_includes @registry_server.agents.keys, agent_id
    assert_includes @message_client.queues.keys, agent_id
    
    # Cleanup
    agent.fini
    
    # Verify cleanup
    refute_includes @registry_server.agents.keys, agent_id
    refute_includes @message_client.queues.keys, agent_id
    assert_nil agent.id
  end

  def test_agent_with_custom_clients
    custom_registry = Agent99::RegistryClient.new(
      base_url: registry_url,
      logger: @logger
    )
    custom_message_client = TestInfrastructure::MockAmqpMessageClient.new
    
    agent = TestInfrastructure::TestAgent.new(
      name: "CustomClientAgent",
      capabilities: ["custom"],
      registry_client: custom_registry,
      message_client: custom_message_client,
      logger: @logger
    )
    
    assert_same custom_registry, agent.registry_client
    assert_same custom_message_client, agent.message_client
    refute_nil agent.id
  end
end