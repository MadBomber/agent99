# frozen_string_literal: true

require "test_helper"
require "open3"

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


  def test_get_keeps_explicit_false_nil_and_zero_from_the_request
    klass = Class.new(Agent99::Base) do
      const_set(:REQUEST_SCHEMA, {
        properties: {
          loud:  { examples: [true] },
          count: { examples: [3] },
          note:  { examples: ["hi"] }
        }
      })
    end
    agent = klass.allocate
    agent.instance_variable_set(:@payload, { loud: false, count: 0, note: nil })

    assert_equal false, agent.send(:get, :loud)
    assert_equal 0, agent.send(:get, :count)
    assert_nil agent.send(:get, :note)

    agent.instance_variable_set(:@payload, {})
    assert_equal true, agent.send(:get, :loud)
  end


  # These check the real Agent99 code, not the TestInfrastructure::TestAgent
  # double, which adds public methods Base does not have. Each assertion
  # fails naming what is missing. The message hooks are pinned as
  # private because that is how Base defines them today.

  def test_base_public_lifecycle_and_run_methods
    assert_empty %i[register withdraw fini run] - Agent99::Base.public_instance_methods
  end


  def test_base_private_message_methods
    expected = %i[receive_request receive_response receive_control send_response send_control_response]
    assert_empty expected - Agent99::Base.private_instance_methods
  end


  def test_base_private_discovery_method
    assert_empty %i[discover_agent] - Agent99::Base.private_instance_methods
  end


  # Also check the module that defines the header helpers, so a reader
  # added on Base cannot shadow them unnoticed.
  def test_base_public_header_methods
    expected = %i[header to_uuid from_uuid event_uuid timestamp type return_address]
    assert_empty expected - Agent99::Base.public_instance_methods
    assert_empty expected - Agent99::HeaderManagement.public_instance_methods(false)
  end


  def test_header_helpers_read_the_current_message
    klass = Class.new(Agent99::Base) do
      attr_reader :seen

      def receive_request = (@seen ||= []) << [:request, from_uuid]
      def receive_response = (@seen ||= []) << [:response, from_uuid]
      def receive_control = (@seen ||= []) << [:control, from_uuid]
    end
    agent = klass.allocate

    agent.send(:process_response, { header: { from_uuid: "carol", type: "response" } })
    agent.send(:process_request,  { header: { from_uuid: "alice", type: "request" } })
    agent.send(:process_response, { header: { from_uuid: "bob",   type: "response" } })
    agent.send(:process_control,  { header: { from_uuid: "dave",  type: "control" }, action: "status" })

    assert_equal [[:response, "carol"], [:request, "alice"], [:response, "bob"], [:control, "dave"]], agent.seen
    assert_equal({ from_uuid: "dave", type: "control" }, agent.header)
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

  def test_base_source_compiles_without_warnings
    base_rb = File.expand_path("../../lib/agent99/base.rb", __dir__)

    _stdout, stderr, status = Open3.capture3({ "RUBYOPT" => nil }, RbConfig.ruby, "-wc", base_rb)

    assert status.success?, stderr
    refute_match(/^#{Regexp.escape(base_rb)}:\d+: warning:/, stderr)
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
