# Agent99::Base

The `Agent99::Base` class is the foundation of all agents in the Agent99 framework. It provides core functionality for agent lifecycle, messaging, discovery, and error handling.

## Class Overview

```ruby
class Agent99::Base
  include Agent99::HeaderManagement
  include Agent99::AgentDiscovery  
  include Agent99::ControlActions
  include Agent99::AgentLifecycle
  include Agent99::MessageProcessing
end
```

## Instance Methods

### Core Lifecycle

#### `#run`

Starts the agent and begins listening for messages.

```ruby
def run
```

**Example:**
```ruby
agent = MyAgent.new
agent.run  # Blocks until shutdown
```

#### `#shutdown`

Gracefully shuts down the agent.

```ruby
def shutdown
```

**Example:**
```ruby
agent.shutdown
```

#### `#info`

Abstract method that must be implemented by subclasses. Returns agent metadata.

```ruby
def info
  # Must return hash with:
  # - :name (String)
  # - :type (Symbol: :server, :client, or :hybrid)  
  # - :capabilities (Array of Strings)
end
```

**Example:**
```ruby
def info
  {
    name: self.class.to_s,
    type: :server,
    capabilities: ['calculator', 'math']
  }
end
```

### Message Processing

#### `#process_request(payload)`

Abstract method for handling incoming requests. Only called for server and hybrid agents.

```ruby
def process_request(payload)
  # Process the payload and call send_response or send_error
end
```

**Parameters:**
- `payload` (Hash) - The request data

**Example:**
```ruby
def process_request(payload)
  name = payload.dig(:name) || "World"
  send_response(message: "Hello, #{name}!")
end
```

#### `#send_response(data)`

Sends a successful response back to the requester.

```ruby
def send_response(data)
```

**Parameters:**
- `data` (Hash) - Response data

**Example:**
```ruby
send_response(
  result: 42,
  status: "success",
  timestamp: Time.now.iso8601
)
```

#### `#send_error(message, code = nil, details = nil)`

Sends an error response back to the requester.

```ruby
def send_error(message, code = nil, details = nil)
```

**Parameters:**
- `message` (String) - Error message
- `code` (String, optional) - Error code
- `details` (Hash, optional) - Additional error details

**Example:**
```ruby
send_error(
  "Invalid input data", 
  "VALIDATION_ERROR",
  { field: "email", expected: "valid email address" }
)
```

#### `#send_request(agent_name, payload, options = {})`

Sends a request to another agent. Only available for client and hybrid agents.

```ruby
def send_request(agent_name, payload, options = {})
```

**Parameters:**
- `agent_name` (String) - Target agent name
- `payload` (Hash) - Request data
- `options` (Hash, optional) - Request options (timeout, etc.)

**Returns:** Response hash or nil if failed

**Example:**
```ruby
response = send_request(
  "CalculatorAgent", 
  { operation: "add", a: 5, b: 3 },
  { timeout: 30 }
)
```

### Agent Discovery

#### `#discover_agents(capabilities = [])`

Finds agents that match the specified capabilities.

```ruby
def discover_agents(capabilities = [])
```

**Parameters:**
- `capabilities` (Array) - List of required capabilities

**Returns:** Array of agent info hashes

**Example:**
```ruby
calculators = discover_agents(['calculator'])
weather_agents = discover_agents(['weather', 'forecast'])
```

#### `#register_agent`

Registers this agent with the registry.

```ruby
def register_agent
```

**Example:**
```ruby
register_agent
```

#### `#unregister_agent`

Removes this agent from the registry.

```ruby
def unregister_agent
```

### Header Management

#### `#header_value(key)`

Gets a header value from the current request.

```ruby
def header_value(key)
```

**Parameters:**
- `key` (String) - Header key

**Returns:** Header value or nil

**Example:**
```ruby
user_id = header_value('user_id')
correlation_id = header_value('correlation_id')
```

#### `#set_header(key, value)`

Sets a header value for the current response.

```ruby
def set_header(key, value)
```

**Parameters:**
- `key` (String) - Header key  
- `value` (String) - Header value

**Example:**
```ruby
set_header('processing_time', '150ms')
set_header('cache_status', 'hit')
```

### Control Actions

#### `#pause`

Pauses the agent (stops processing new requests).

```ruby
def pause
```

#### `#resume`

Resumes the agent after being paused.

```ruby
def resume
```

#### `#status`

Returns the current agent status.

```ruby
def status
```

**Returns:** Symbol (`:running`, `:paused`, `:stopped`)

### Configuration

#### `#logger`

Returns the logger instance for this agent.

```ruby
def logger
```

**Example:**
```ruby
logger.info "Processing request"
logger.error "Something went wrong: #{error.message}"
```

#### `#config`

Returns the configuration hash for this agent.

```ruby
def config
```

**Example:**
```ruby
timeout = config[:timeout] || 30
registry_url = config[:registry_url]
```

## Class Methods

### `Agent99::Base.create(type:, **options)`

Factory method for creating agents.

```ruby
Agent99::Base.create(type: :server, name: 'TestAgent')
```

**Parameters:**
- `type` (Symbol) - Agent type (`:server`, `:client`, `:hybrid`)
- `options` (Hash) - Configuration options

## Configuration Options

When creating agents, you can pass configuration options:

```ruby
class MyAgent < Agent99::Base
  def initialize(options = {})
    super(options)
  end
end

agent = MyAgent.new(
  registry_url: 'http://localhost:4567',
  message_client: 'nats',
  timeout: 30,
  log_level: :info
)
```

### Available Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `registry_url` | String | `http://localhost:4567` | Registry service URL |
| `message_client` | String | `nats` | Message broker type (`nats`, `amqp`, `tcp`) |
| `timeout` | Integer | 30 | Default request timeout (seconds) |
| `log_level` | Symbol | `:info` | Logging level |
| `retry_attempts` | Integer | 3 | Request retry attempts |
| `retry_delay` | Integer | 1 | Delay between retries (seconds) |

## Examples

### Simple Server Agent

```ruby
class GreeterAgent < Agent99::Base
  def info
    {
      name: self.class.to_s,
      type: :server,
      capabilities: ['greeting', 'hello']
    }
  end

  def process_request(payload)
    name = payload.dig(:name) || "World"
    logger.info "Greeting #{name}"
    
    send_response(
      message: "Hello, #{name}!",
      timestamp: Time.now.iso8601
    )
  end
end
```

### Client Agent with Error Handling

```ruby
class ClientAgent < Agent99::Base
  def info
    {
      name: self.class.to_s,
      type: :client,
      capabilities: ['client_operations']
    }
  end

  def make_greeting_request(name)
    greeters = discover_agents(['greeting'])
    
    if greeters.empty?
      logger.warn "No greeting agents available"
      return nil
    end

    begin
      response = send_request(
        greeters.first[:name], 
        { name: name },
        { timeout: 10 }
      )
      
      logger.info "Received: #{response[:message]}"
      response
    rescue => e
      logger.error "Request failed: #{e.message}"
      nil
    end
  end
end
```

### Hybrid Agent with State

```ruby
class StatefulAgent < Agent99::Base
  def initialize(options = {})
    super(options)
    @request_count = 0
    @mutex = Mutex.new
  end

  def info
    {
      name: self.class.to_s,
      type: :hybrid,
      capabilities: ['stateful', 'counter']
    }
  end

  def process_request(payload)
    @mutex.synchronize do
      @request_count += 1
      
      if payload[:operation] == 'get_count'
        send_response(count: @request_count)
      elsif payload[:operation] == 'reset_count'
        @request_count = 0
        send_response(count: 0, status: 'reset')
      else
        send_error('Unknown operation', 'INVALID_OPERATION')
      end
    end
  end
end
```

## Thread Safety

The `Agent99::Base` class is designed to be thread-safe for concurrent request processing. However:

- **Subclass implementations** should ensure thread safety in their `process_request` methods
- **Shared state** should be protected with mutexes or other synchronization primitives  
- **Instance variables** may be accessed concurrently during request processing

## Error Handling

The base class provides automatic error handling for:

- **Network failures** during agent registration and discovery
- **Message broker disconnections** with automatic retry
- **Invalid message formats** with appropriate error responses
- **Unhandled exceptions** in `process_request` (converted to error responses)

## Next Steps

- **[Registry Client](registry-client.md)** - Registry service API
- **[Message Clients](message-clients.md)** - Message broker clients
- **[Schemas](schemas.md)** - Schema validation system