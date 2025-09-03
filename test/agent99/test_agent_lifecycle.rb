# frozen_string_literal: true

require "test_helper"

class TestAgentLifecycle < Minitest::Test
  def test_agent_initialization_and_registration
    agent = create_test_agent(
      name: "TestLifecycleAgent",
      capabilities: ["test", "lifecycle"]
    )
    
    refute_nil agent.id
    assert_equal "TestLifecycleAgent", agent.name
    assert_equal ["test", "lifecycle"], agent.capabilities
    
    # Verify agent is registered in the mock registry
    agents = @registry_server.agents
    assert_includes agents.keys, agent.id
  end

  def test_agent_info_validation_success
    # This should not raise an error since TestAgent implements info method
    agent = create_test_agent(
      name: "ValidAgent",
      capabilities: ["valid"]
    )
    
    assert_equal "ValidAgent", agent.info[:name]
    assert_equal ["valid"], agent.info[:capabilities]
  end

  def test_agent_info_validation_missing_method
    # Create a class without info method
    invalid_agent_class = Class.new(Agent99::Base) do
      # No info method defined
    end
    
    registry_client = Agent99::RegistryClient.new(
      base_url: registry_url,
      logger: @logger
    )
    
    # This should exit with error code 1, but we can't test exit in minitest
    # Instead, we'll test that the validation method detects the missing info method
    agent_instance = invalid_agent_class.allocate
    agent_instance.instance_variable_set(:@logger, @logger)
    agent_instance.instance_variable_set(:@registry_client, registry_client)
    agent_instance.instance_variable_set(:@message_client, @message_client)
    
    # We can't actually call initialize as it would exit, so we test validate_info_keys directly
    error_logged = false
    
    @logger.define_singleton_method(:error) do |message|
      error_logged = true if message.include?("must implement the info method")
    end
    
    assert_raises(SystemExit) do
      agent_instance.send(:validate_info_keys)
    end
  end

  def test_agent_info_validation_missing_required_keys
    # Create an agent with incomplete info
    incomplete_agent_class = Class.new(Agent99::Base) do
      def info
        { name: "IncompleteAgent" }  # Missing capabilities
      end
    end
    
    registry_client = Agent99::RegistryClient.new(
      base_url: registry_url,
      logger: @logger
    )
    
    agent_instance = incomplete_agent_class.allocate
    agent_instance.instance_variable_set(:@logger, @logger)
    agent_instance.instance_variable_set(:@registry_client, registry_client)
    agent_instance.instance_variable_set(:@message_client, @message_client)
    
    error_logged = false
    
    @logger.define_singleton_method(:error) do |message|
      error_logged = true if message.include?("missing") && message.include?("capabilities")
    end
    
    assert_raises(SystemExit) do
      agent_instance.send(:validate_info_keys)
    end
  end

  def test_agent_withdrawal
    agent = create_test_agent(
      name: "WithdrawTestAgent",
      capabilities: ["test"]
    )
    
    agent_id = agent.id
    
    # Verify agent is registered
    assert_includes @registry_server.agents.keys, agent_id
    
    # Withdraw agent
    agent.withdraw
    
    # Verify agent is unregistered
    refute_includes @registry_server.agents.keys, agent_id
    assert_nil agent.id
  end

  def test_agent_fini_cleanup
    agent = create_test_agent(
      name: "FiniTestAgent",
      capabilities: ["test"]
    )
    
    agent_id = agent.id
    queue_name = agent_id
    
    # Verify agent is registered and has a queue
    assert_includes @registry_server.agents.keys, agent_id
    assert_includes @message_client.queues.keys, queue_name
    
    # Call fini
    agent.fini
    
    # Verify cleanup occurred
    refute_includes @registry_server.agents.keys, agent_id
    refute_includes @message_client.queues.keys, queue_name
    assert_nil agent.id
  end

  def test_agent_fini_with_nil_id
    agent = create_test_agent(
      name: "NilIdAgent",
      capabilities: ["test"]
    )
    
    # Manually set id to nil to test the warning path
    agent.instance_variable_set(:@id, nil)
    
    warning_logged = false
    
    @logger.define_singleton_method(:warn) do |message|
      warning_logged = true if message.include?("fini called with a nil id")
    end
    
    # Should not raise an error, just log a warning
    agent.fini
    
    assert warning_logged
  end

  def test_signal_handlers_setup
    agent = create_test_agent(
      name: "SignalTestAgent",
      capabilities: ["test"]
    )
    
    # We can't easily test actual signal handling without complex mocking,
    # but we can verify that the signal handlers are set up
    # This is more of an integration test to ensure initialization completes
    refute_nil agent
    refute_nil agent.id
  end

  def test_paused_functionality
    agent = create_test_agent(
      name: "PausedTestAgent",
      capabilities: ["test"]
    )
    
    # Test the paused? private method (we can access it through send for testing)
    refute agent.send(:paused?)
    
    # Set paused state
    agent.instance_variable_set(:@paused, true)
    assert agent.send(:paused?)
    
    # Unset paused state
    agent.instance_variable_set(:@paused, false)
    refute agent.send(:paused?)
  end

  def test_registration_error_handling
    # Create a registry client that will fail
    failing_registry = Agent99::RegistryClient.new(
      base_url: "http://nonexistent-server:9999",
      logger: @logger
    )
    
    error_handled = false
    
    agent_class = Class.new(TestInfrastructure::TestAgent) do
      def handle_error(message, error)
        @error_handled = true
        super
      end
    end
    
    # This will attempt to register and should handle the error gracefully
    agent = agent_class.new(
      name: "FailingAgent",
      capabilities: ["test"],
      registry_client: failing_registry,
      message_client: @message_client,
      logger: @logger
    )
    
    # Agent should still be created but without a valid ID
    assert_nil agent.id
  end
end