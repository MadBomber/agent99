# Agent99 Test Suite

This comprehensive test suite for Agent99 uses Minitest and follows a real-implementation approach without mock objects. All tests use actual Agent99 components with a lightweight mock registry server and message broker.

## Test Structure

### Test Categories

1. **Unit Tests** (`test/agent99/`)
   - Test individual classes and modules
   - Focus on single-responsibility components
   - Use real implementations with controlled dependencies

2. **Integration Tests** (`test/integration/`)
   - Test inter-component communication
   - Verify agent-to-agent messaging
   - Test discovery and workflow coordination

3. **System Tests** (`test/system/`)
   - Test complete workflows and scenarios
   - Simulate real-world usage patterns
   - Validate end-to-end functionality

### Test Infrastructure

#### Mock Registry Server (`test/support/test_infrastructure.rb`)
- **MockRegistryServer**: Lightweight HTTP server for agent registration
- **MockAmqpMessageClient**: Message broker simulation
- **MockQueue**: Queue implementation for message handling
- **TestAgent**: Configurable agent class for testing

#### Test Helper (`test/test_helper.rb`)
- Automatic setup/teardown of mock services
- Helper methods for creating test agents
- Shared test configuration

## Running Tests

### All Tests
```bash
ruby -Ilib -Itest -e "Dir.glob('test/**/*_test.rb') { |f| require f }"
```

### Specific Test Categories
```bash
# Unit tests only
ruby -Ilib -Itest -e "Dir.glob('test/agent99/*_test.rb') { |f| require f }"

# Integration tests only  
ruby -Ilib -Itest -e "Dir.glob('test/integration/*_test.rb') { |f| require f }"

# System tests only
ruby -Ilib -Itest -e "Dir.glob('test/system/*_test.rb') { |f| require f }"
```

### Individual Test Files
```bash
ruby -Ilib test/agent99/test_base.rb
ruby -Ilib test/integration/test_agent_communication.rb
ruby -Ilib test/system/test_full_workflows.rb
```

## Test Philosophy

### No Mock Objects
This test suite deliberately avoids mock objects in favor of:
- Real Agent99 components
- Lightweight mock services (registry, message broker)
- Actual object interactions and state changes

### Real Integration Testing
- Tests use actual networking (localhost)
- Real JSON serialization/deserialization
- Authentic error handling and edge cases
- True asynchronous behavior simulation

## Test Coverage

### Core Components Tested

#### `Agent99::RegistryClient`
- Agent registration and withdrawal
- Service discovery by capability
- Error handling for network failures
- Response parsing and validation

#### `Agent99::AmqpMessageClient` 
- Queue creation and management
- Message publishing and routing
- Handler setup and message delivery
- Singleton pattern implementation

#### `Agent99::Base` and Modules
- **AgentLifecycle**: Initialization, registration, cleanup
- **MessageProcessing**: Request/response/control handling
- **AgentDiscovery**: Service discovery operations
- **HeaderManagement**: Message header creation/validation
- **ControlActions**: Agent control operations

### Workflow Scenarios

#### Document Processing Workflow
- Multi-step document processing pipeline
- Text extraction → Sentiment analysis → Summarization → Reporting
- Workflow ID tracking and data integrity
- Error propagation and handling

#### Distributed Calculation System
- Parallel computation across multiple workers
- Result aggregation and coordination
- Load balancing and worker specialization

#### System Monitoring
- Health check orchestration
- Service status aggregation
- Alert generation and notification
- Degraded service handling

#### Agent Lifecycle Management
- Dynamic agent registration/withdrawal
- Resource cleanup verification
- Workflow continuation after agent departure

## Test Data and Fixtures

### Agent Configurations
```ruby
# Math-capable agent
math_agent = create_test_agent(
  name: "MathAgent",
  capabilities: ["math", "calculation"]
)

# Text processing agent
text_agent = create_test_agent(
  name: "TextProcessor", 
  capabilities: ["text", "nlp", "processing"]
)
```

### Message Structures
```ruby
# Request message
{
  header: {
    from_uuid: "sender-uuid",
    to_uuid: "recipient-uuid", 
    event_uuid: "unique-event-id",
    type: "request",
    timestamp: 1234567890
  },
  payload: {
    action: "process",
    data: "input data"
  }
}
```

## Debugging Tests

### Logging
Tests use silent loggers by default. To enable logging:
```ruby
@logger = Logger.new($stdout)
@logger.level = Logger::DEBUG
```

### Message Inspection
Access published messages:
```ruby
puts @message_client.published_messages.inspect
```

### Registry State
Inspect registered agents:
```ruby
puts @registry_server.agents.inspect
```

### Queue State  
Check message queues:
```ruby
puts @message_client.queues.keys.inspect
```

## Contributing to Tests

### Adding New Tests

1. **Unit Tests**: Create in `test/agent99/test_[component].rb`
2. **Integration Tests**: Create in `test/integration/test_[feature].rb`  
3. **System Tests**: Create in `test/system/test_[workflow].rb`

### Test Naming Conventions

- Test files: `test_[component_name].rb`
- Test methods: `test_[specific_behavior]`
- Test classes: `Test[ComponentName]`

### Test Structure Template

```ruby
require "test_helper"

class TestNewComponent < Minitest::Test
  def test_basic_functionality
    # Arrange
    component = create_test_component
    
    # Act
    result = component.do_something
    
    # Assert
    assert_equal expected_value, result
  end
  
  def test_error_conditions
    # Test error handling
  end
  
  def test_edge_cases
    # Test boundary conditions
  end
end
```

## Known Test Limitations

1. **Concurrency**: Tests simulate async behavior but run synchronously
2. **Network**: Uses localhost only, no remote network testing
3. **Performance**: Not designed for performance benchmarking
4. **External Dependencies**: Requires WEBrick for mock registry server

## Future Test Enhancements

- Performance and load testing
- Real AMQP broker integration tests
- Network failure simulation
- Multi-node deployment testing
- Chaos engineering scenarios