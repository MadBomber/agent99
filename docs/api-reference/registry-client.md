# Registry Client API

The Registry Client provides programmatic access to the Agent99 registry service for agent registration, discovery, and management operations.

## Overview

The registry client is built into `Agent99::Base` but can also be used independently for advanced registry operations.

## Basic Usage

### Auto-Registration (Built-in)

Most agents use automatic registration through the base class:

```ruby
class MyAgent < Agent99::Base
  def info
    {
      name: self.class.to_s,
      type: :server,
      capabilities: ['example', 'demo']
    }
  end
  
  def process_request(payload)
    # Agent automatically registers on startup
    send_response(message: "Hello from registered agent!")
  end
end
```

### Manual Registration

For advanced use cases, you can manually register agents:

```ruby
registry = Agent99::RegistryClient.new
agent_info = {
  name: "CustomAgent",
  type: "server",
  capabilities: ["custom", "manual"],
  host: "localhost",
  port: 5000
}

# Register the agent
registry.register_agent(agent_info)
```

## Registry Client Methods

### `#register_agent(agent_info)`

Registers an agent with the registry.

```ruby
def register_agent(agent_info)
  # POST /agents
end
```

**Parameters:**
- `agent_info` (Hash) - Agent information

**Required Fields:**
- `name` (String) - Unique agent name
- `type` (String) - Agent type (`"server"`, `"client"`, `"hybrid"`)
- `capabilities` (Array) - List of capabilities

**Optional Fields:**
- `host` (String) - Agent host (default: detected)
- `port` (Integer) - Agent port (default: auto-assigned)
- `metadata` (Hash) - Additional metadata
- `schema` (Hash) - Request/response schemas

**Example:**
```ruby
registry.register_agent({
  name: "WeatherService",
  type: "server", 
  capabilities: ["weather", "forecast", "temperature"],
  host: "weather.example.com",
  port: 8080,
  metadata: {
    version: "1.2.3",
    region: "us-west"
  }
})
```

### `#unregister_agent(agent_name)`

Removes an agent from the registry.

```ruby
def unregister_agent(agent_name)
  # DELETE /agents/:name
end
```

**Parameters:**
- `agent_name` (String) - Name of agent to remove

**Example:**
```ruby
registry.unregister_agent("WeatherService")
```

### `#discover_agents(capabilities = [])`

Finds agents that match specified capabilities.

```ruby
def discover_agents(capabilities = [])
  # GET /agents/discover?capabilities=cap1,cap2
end
```

**Parameters:**
- `capabilities` (Array) - Required capabilities (empty array returns all)

**Returns:** Array of agent information hashes

**Example:**
```ruby
# Find all weather agents
weather_agents = registry.discover_agents(["weather"])

# Find agents with multiple capabilities  
calc_agents = registry.discover_agents(["calculator", "math"])

# Find all agents
all_agents = registry.discover_agents([])
```

### `#get_agent(agent_name)`

Retrieves detailed information about a specific agent.

```ruby
def get_agent(agent_name)
  # GET /agents/:name
end
```

**Parameters:**
- `agent_name` (String) - Agent name

**Returns:** Agent information hash or nil if not found

**Example:**
```ruby
agent_info = registry.get_agent("WeatherService")
if agent_info
  puts "Agent capabilities: #{agent_info[:capabilities]}"
else
  puts "Agent not found"
end
```

### `#list_agents`

Lists all registered agents.

```ruby
def list_agents
  # GET /agents
end
```

**Returns:** Array of all registered agent information

**Example:**
```ruby
all_agents = registry.list_agents
puts "Total agents: #{all_agents.size}"

all_agents.each do |agent|
  puts "#{agent[:name]} (#{agent[:type]}) - #{agent[:capabilities].join(', ')}"
end
```

### `#health_check`

Checks registry service health.

```ruby
def health_check
  # GET /health
end
```

**Returns:** Health status hash

**Example:**
```ruby
health = registry.health_check
puts "Registry status: #{health[:status]}"
puts "Uptime: #{health[:uptime]}"
```

## Advanced Usage

### Custom Registry Client

For applications that need to interact with multiple registries or require custom configuration:

```ruby
require 'agent99/registry_client'

# Custom registry client
registry = Agent99::RegistryClient.new(
  base_url: 'http://registry.example.com:8080',
  timeout: 15,
  retry_attempts: 5
)

# Use custom client
agents = registry.discover_agents(['database'])
```

### Registry Client Configuration

```ruby
class Agent99::RegistryClient
  def initialize(options = {})
    @base_url = options[:base_url] || ENV['AGENT99_REGISTRY_URL'] || 'http://localhost:4567'
    @timeout = options[:timeout] || 30
    @retry_attempts = options[:retry_attempts] || 3
    @retry_delay = options[:retry_delay] || 1
  end
end
```

**Configuration Options:**
- `base_url` - Registry service URL
- `timeout` - HTTP timeout in seconds
- `retry_attempts` - Number of retry attempts
- `retry_delay` - Delay between retries in seconds

## Error Handling

The registry client raises specific exceptions for different error conditions:

```ruby
begin
  registry.register_agent(agent_info)
rescue Agent99::RegistryError => e
  case e.code
  when 'AGENT_EXISTS'
    puts "Agent already registered"
  when 'VALIDATION_ERROR'
    puts "Invalid agent info: #{e.message}"
  when 'REGISTRY_UNAVAILABLE'
    puts "Registry service unavailable"
  else
    puts "Registration failed: #{e.message}"
  end
end
```

### Common Exceptions

- `Agent99::RegistryError` - Base registry exception
- `Agent99::RegistryConnectionError` - Network/connection issues  
- `Agent99::RegistryValidationError` - Invalid agent data
- `Agent99::RegistryNotFoundError` - Agent/resource not found

## Response Formats

### Agent Information Structure

```json
{
  "name": "WeatherService",
  "type": "server",
  "capabilities": ["weather", "forecast"],
  "host": "localhost", 
  "port": 8080,
  "registered_at": "2024-12-12T10:30:00Z",
  "last_seen": "2024-12-12T10:35:00Z",
  "metadata": {
    "version": "1.2.3",
    "region": "us-west"
  },
  "schema": {
    "request": { /* JSON Schema */ },
    "response": { /* JSON Schema */ }
  }
}
```

### Discovery Response

```json
{
  "agents": [
    {
      "name": "WeatherService",
      "type": "server", 
      "capabilities": ["weather", "forecast"],
      "host": "localhost",
      "port": 8080
    }
  ],
  "total_count": 1,
  "matching_capabilities": ["weather"]
}
```

## Registry HTTP API

The registry exposes a REST API that the client uses:

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/agents` | Register new agent |
| `GET` | `/agents` | List all agents |
| `GET` | `/agents/:name` | Get specific agent |
| `DELETE` | `/agents/:name` | Unregister agent |
| `GET` | `/agents/discover` | Discover agents by capabilities |
| `GET` | `/health` | Registry health check |

### Query Parameters

**Discovery endpoint (`/agents/discover`):**
- `capabilities` - Comma-separated list of required capabilities
- `type` - Filter by agent type (`server`, `client`, `hybrid`)
- `limit` - Maximum number of results
- `offset` - Pagination offset

**Example requests:**
```bash
# Find weather agents
GET /agents/discover?capabilities=weather

# Find server agents with math capability
GET /agents/discover?capabilities=math&type=server

# Paginated results
GET /agents/discover?limit=10&offset=20
```

## Testing Registry Operations

### Unit Tests

```ruby
require 'minitest/autorun'
require 'webmock/minitest'

class TestRegistryClient < Minitest::Test
  def setup
    @registry = Agent99::RegistryClient.new(
      base_url: 'http://test-registry:4567'
    )
  end

  def test_agent_registration
    agent_info = {
      name: "TestAgent",
      type: "server",
      capabilities: ["test"]
    }

    # Mock the HTTP request
    stub_request(:post, "http://test-registry:4567/agents")
      .with(body: agent_info.to_json)
      .to_return(status: 201, body: '{"status": "registered"}')

    result = @registry.register_agent(agent_info)
    assert_equal "registered", result["status"]
  end

  def test_agent_discovery
    # Mock discovery response
    response_body = {
      agents: [
        { name: "TestAgent", capabilities: ["test"] }
      ]
    }.to_json

    stub_request(:get, "http://test-registry:4567/agents/discover")
      .with(query: { capabilities: "test" })
      .to_return(status: 200, body: response_body)

    agents = @registry.discover_agents(["test"])
    assert_equal 1, agents.size
    assert_equal "TestAgent", agents.first["name"]
  end
end
```

### Integration Tests

```ruby
class TestRegistryIntegration < Minitest::Test
  def setup
    # Start test registry server
    @registry_server = start_test_registry
    @registry = Agent99::RegistryClient.new(
      base_url: 'http://localhost:4567'
    )
  end

  def teardown
    @registry_server.stop
  end

  def test_full_agent_lifecycle
    agent_info = {
      name: "IntegrationTestAgent", 
      type: "server",
      capabilities: ["integration", "test"]
    }

    # Register agent
    @registry.register_agent(agent_info)

    # Verify registration
    found_agents = @registry.discover_agents(["integration"])
    assert_equal 1, found_agents.size

    # Get agent details
    agent_details = @registry.get_agent("IntegrationTestAgent")
    assert_equal "server", agent_details["type"]

    # Unregister agent
    @registry.unregister_agent("IntegrationTestAgent")

    # Verify removal
    found_agents = @registry.discover_agents(["integration"])
    assert_empty found_agents
  end
end
```

## Best Practices

### 1. Registration
- **Use descriptive names**: Include service purpose and instance info
- **Provide rich metadata**: Version, region, capabilities
- **Handle registration failures**: Retry with backoff
- **Clean up on shutdown**: Always unregister agents

### 2. Discovery
- **Cache results**: Don't discover on every request
- **Handle empty results**: Plan for no matching agents
- **Use specific capabilities**: More specific = better matches
- **Implement fallbacks**: Have backup discovery strategies

### 3. Error Handling  
- **Catch specific exceptions**: Handle different error types appropriately
- **Implement retries**: With exponential backoff
- **Monitor registry health**: Check before critical operations
- **Log registry operations**: For debugging and monitoring

### 4. Performance
- **Batch operations**: When possible, batch registry calls
- **Use connection pooling**: For high-frequency operations
- **Monitor response times**: Track registry performance
- **Implement circuit breakers**: Protect against registry failures

## Next Steps

- **[Message Clients](message-clients.md)** - Message broker client APIs
- **[Agent99::Base](agent99-base.md)** - Core agent class reference  
- **[Configuration](../operations/configuration.md)** - Registry configuration options