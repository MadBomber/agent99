# frozen_string_literal: true

require "test_helper"

class TestAgentCommunication < Minitest::Test
  def test_agent_to_agent_request_response
    # Create two agents
    server_agent = create_test_agent(
      name: "ServerAgent",
      capabilities: ["math", "calculation"]
    )
    
    client_agent = create_test_agent(
      name: "ClientAgent", 
      capabilities: ["client", "requester"]
    )
    
    # Override server agent to handle specific requests
    original_receive_request = server_agent.method(:receive_request)
    def server_agent.receive_request(payload, header)
      # Call original to add to received_requests array
      original_result = @original_receive_request.call(payload, header) if @original_receive_request
      
      # Add specific test behavior
      case payload[:operation]
      when "add"
        result = payload[:a] + payload[:b]
        { result: result, operation: "add" }
      when "multiply"
        result = payload[:a] * payload[:b]
        { result: result, operation: "multiply" }
      else
        { error: "Unknown operation: #{payload[:operation]}" }
      end
    end
    server_agent.instance_variable_set(:@original_receive_request, original_receive_request)
    
    # Test addition request
    request_payload = {
      operation: "add",
      a: 5,
      b: 3
    }
    
    response = client_agent.send_request(
      to_uuid: server_agent.id,
      payload: request_payload
    )
    
    # Simulate message delivery and processing
    request_message = @message_client.published_messages.last
    assert_equal server_agent.id, request_message.dig(:header, :to_uuid)
    assert_equal client_agent.id, request_message.dig(:header, :from_uuid)
    assert_equal "request", request_message.dig(:header, :type)
    assert_equal request_payload, request_message[:payload]
    
    # Auto-delivery should have already delivered the message
    # (No need to manually deliver since we fixed auto-delivery)
    
    # Verify server received the request
    assert_equal 1, server_agent.received_requests.size
    received_request = server_agent.received_requests.first
    assert_equal request_payload, received_request[:payload]
    
    # Test multiplication request
    multiply_payload = {
      operation: "multiply",
      a: 4,
      b: 7
    }
    
    client_agent.send_request(
      to_uuid: server_agent.id,
      payload: multiply_payload
    )
    
    multiply_message = @message_client.published_messages.last
    # Auto-delivery should have already delivered this message too
    
    assert_equal 2, server_agent.received_requests.size
    assert_equal multiply_payload, server_agent.received_requests.last[:payload]
  end

  def test_agent_discovery_and_communication
    # Create several specialized agents
    math_agent1 = create_test_agent(name: "MathAgent1", capabilities: ["math", "algebra"])
    math_agent2 = create_test_agent(name: "MathAgent2", capabilities: ["math", "geometry"])  
    text_agent = create_test_agent(name: "TextAgent", capabilities: ["text", "processing"])
    
    # Test discovering math agents
    client_agent = create_test_agent(name: "ClientAgent", capabilities: ["client"])
    
    math_agents = client_agent.discover_agents(capability: "math")
    
    assert_equal 2, math_agents.size
    agent_names = math_agents.map { |agent| agent[:name] }
    assert_includes agent_names, "MathAgent1"
    assert_includes agent_names, "MathAgent2"
    refute_includes agent_names, "TextAgent"
    
    # Test discovering text agents
    text_agents = client_agent.discover_agents(capability: "text")
    
    assert_equal 1, text_agents.size
    assert_equal "TextAgent", text_agents.first[:name]
    
    # Test discovering non-existent capability
    missing_agents = client_agent.discover_agents(capability: "nonexistent")
    assert_empty missing_agents
    
    # Test getting all agents
    all_agents = client_agent.get_all_agents
    assert_equal 4, all_agents.size  # Including the client_agent itself
    
    all_names = all_agents.map { |agent| agent[:name] }
    assert_includes all_names, "MathAgent1"
    assert_includes all_names, "MathAgent2" 
    assert_includes all_names, "TextAgent"
    assert_includes all_names, "ClientAgent"
  end

  def test_multi_agent_workflow
    # Create a workflow with multiple agents
    coordinator = create_test_agent(name: "Coordinator", capabilities: ["coordination"])
    data_processor = create_test_agent(name: "DataProcessor", capabilities: ["data", "processing"])
    validator = create_test_agent(name: "Validator", capabilities: ["validation"])
    reporter = create_test_agent(name: "Reporter", capabilities: ["reporting"])
    
    # Define agent behaviors
    original_data_processor_receive_request = data_processor.method(:receive_request)
    def data_processor.receive_request(payload, header)
      # Call original to add to received_requests array
      original_result = @original_receive_request.call(payload, header) if @original_receive_request
      
      # Add specific test behavior
      if payload[:action] == "process"
        {
          status: "processed",
          data: payload[:raw_data].upcase,
          processed_at: Time.now.to_i
        }
      else
        { error: "Unknown action: #{payload[:action]}" }
      end
    end
    data_processor.instance_variable_set(:@original_receive_request, original_data_processor_receive_request)
    
    original_validator_receive_request = validator.method(:receive_request)
    def validator.receive_request(payload, header)
      # Call original to add to received_requests array
      original_result = @original_receive_request.call(payload, header) if @original_receive_request
      
      # Add specific test behavior
      if payload[:action] == "validate"
        valid = payload[:data] && payload[:data].length > 0
        {
          status: valid ? "valid" : "invalid",
          data: payload[:data],
          validated_at: Time.now.to_i
        }
      else
        { error: "Unknown action: #{payload[:action]}" }
      end
    end
    validator.instance_variable_set(:@original_receive_request, original_validator_receive_request)
    
    original_reporter_receive_request = reporter.method(:receive_request)
    def reporter.receive_request(payload, header)
      # Call original to add to received_requests array
      original_result = @original_receive_request.call(payload, header) if @original_receive_request
      
      # Add specific test behavior
      if payload[:action] == "report"
        {
          report: "Data: #{payload[:data]}, Status: #{payload[:status]}",
          generated_at: Time.now.to_i
        }
      else
        { error: "Unknown action: #{payload[:action]}" }
      end
    end
    reporter.instance_variable_set(:@original_receive_request, original_reporter_receive_request)
    
    # Simulate workflow: Coordinator -> DataProcessor -> Validator -> Reporter
    
    # Step 1: Coordinator requests data processing
    raw_data = "hello world"
    processing_request = {
      action: "process",
      raw_data: raw_data
    }
    
    coordinator.send_request(
      to_uuid: data_processor.id,
      payload: processing_request
    )
    
    # Auto-delivery should have already delivered the message
    
    assert_equal 1, data_processor.received_requests.size
    
    # Step 2: Send processed data to validator
    processed_data = "HELLO WORLD"  # Simulated processing result
    validation_request = {
      action: "validate",
      data: processed_data
    }
    
    coordinator.send_request(
      to_uuid: validator.id,
      payload: validation_request
    )
    
    # Auto-delivery should have already delivered this message
    
    assert_equal 1, validator.received_requests.size
    
    # Step 3: Send validated data to reporter
    reporting_request = {
      action: "report",
      data: processed_data,
      status: "valid"
    }
    
    coordinator.send_request(
      to_uuid: reporter.id,
      payload: reporting_request
    )
    
    # Auto-delivery should have already delivered this message
    
    assert_equal 1, reporter.received_requests.size
    
    # Verify all agents received their expected messages
    assert_equal processing_request, data_processor.received_requests.first[:payload]
    assert_equal validation_request, validator.received_requests.first[:payload]
    assert_equal reporting_request, reporter.received_requests.first[:payload]
  end

  def test_control_message_handling
    # Create agents for control message testing
    supervisor = create_test_agent(name: "Supervisor", capabilities: ["supervision"])
    worker = create_test_agent(name: "Worker", capabilities: ["work"])
    
    # Override worker to handle control messages
    original_receive_control = worker.method(:receive_control)
    def worker.receive_control(payload, header)
      # Call original to add to received_controls array
      original_result = @original_receive_control.call(payload, header) if @original_receive_control
      
      # Add specific test behavior
      case payload[:command]
      when "pause"
        @paused = true
        { status: "paused" }
      when "resume"
        @paused = false
        { status: "resumed" }
      when "status"
        { status: @paused ? "paused" : "running" }
      else
        { error: "Unknown command: #{payload[:command]}" }
      end
    end
    worker.instance_variable_set(:@original_receive_control, original_receive_control)
    
    # Test pause command
    pause_message = {
      header: {
        from_uuid: supervisor.id,
        to_uuid: worker.id,
        event_uuid: SecureRandom.uuid,
        type: "control",
        timestamp: Time.now.to_i
      },
      payload: { command: "pause" }
    }
    
    @message_client.deliver_message_to_queue(worker.id, pause_message)
    
    assert_equal 1, worker.received_controls.size
    assert_equal "pause", worker.received_controls.first[:payload][:command]
    
    # Test resume command
    resume_message = {
      header: {
        from_uuid: supervisor.id,
        to_uuid: worker.id,
        event_uuid: SecureRandom.uuid,
        type: "control",
        timestamp: Time.now.to_i
      },
      payload: { command: "resume" }
    }
    
    @message_client.deliver_message_to_queue(worker.id, resume_message)
    
    assert_equal 2, worker.received_controls.size
    assert_equal "resume", worker.received_controls.last[:payload][:command]
    
    # Test status command
    status_message = {
      header: {
        from_uuid: supervisor.id,
        to_uuid: worker.id,
        event_uuid: SecureRandom.uuid,
        type: "control",
        timestamp: Time.now.to_i
      },
      payload: { command: "status" }
    }
    
    @message_client.deliver_message_to_queue(worker.id, status_message)
    
    assert_equal 3, worker.received_controls.size
    assert_equal "status", worker.received_controls.last[:payload][:command]
  end

  def test_response_message_handling
    # Create agents for response testing
    client = create_test_agent(name: "ClientAgent", capabilities: ["client"])
    server = create_test_agent(name: "ServerAgent", capabilities: ["server"])
    
    # Send a request and simulate a response
    original_request_id = SecureRandom.uuid
    
    # Simulate receiving a response
    response_message = {
      header: {
        from_uuid: server.id,
        to_uuid: client.id,
        event_uuid: original_request_id,  # Links back to original request
        type: "response",
        timestamp: Time.now.to_i
      },
      payload: {
        status: "success",
        data: "processed result",
        original_request: original_request_id
      }
    }
    
    @message_client.deliver_message_to_queue(client.id, response_message)
    
    assert_equal 1, client.received_responses.size
    response = client.received_responses.first
    assert_equal "success", response[:payload][:status]
    assert_equal "processed result", response[:payload][:data]
    assert_equal server.id, response[:header][:from_uuid]
    assert_equal client.id, response[:header][:to_uuid]
  end

  def test_error_handling_in_communication
    # Create agents for error testing
    client = create_test_agent(name: "ErrorClient", capabilities: ["client"])
    problematic_server = create_test_agent(name: "ProblematicServer", capabilities: ["server"])
    
    # Override server to simulate errors
    def problematic_server.receive_request(payload, header)
      case payload[:action]
      when "cause_error"
        raise StandardError, "Simulated processing error"
      when "return_error"
        { error: "Intentional error response", code: 500 }
      else
        { status: "ok" }
      end
    end
    
    # Test error response
    error_request = {
      action: "return_error",
      data: "test"
    }
    
    client.send_request(
      to_uuid: problematic_server.id,
      payload: error_request
    )
    
    error_message = @message_client.published_messages.last
    
    # This would normally be handled by the server's message processing
    # but we're testing that the message structure is correct
    assert_equal "request", error_message.dig(:header, :type)
    assert_equal error_request, error_message[:payload]
    assert_equal problematic_server.id, error_message.dig(:header, :to_uuid)
    assert_equal client.id, error_message.dig(:header, :from_uuid)
  end
end