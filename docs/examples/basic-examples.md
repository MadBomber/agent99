# Basic Examples

This section contains basic examples to help you get started with Agent99.

## Simple Greeter Agent

Here's a basic server agent that responds to greeting requests:

```ruby
require 'agent99'
require 'simple_json_schema_builder'

# Define the request schema
class GreeterRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    string :name, required: true, examples: ["World"]
  end
end

# Create the agent
class GreeterAgent < Agent99::Base
  def info
    {
      name:             self.class.to_s,
      type:             :server,
      capabilities:     ['greeter', 'hello_world'],
      request_schema:   GreeterRequest.schema
    }
  end

  def process_request(payload)
    name = payload.dig(:name) || "World"
    response = { result: "Hello, #{name}!" }
    send_response(response)
  end
end

# Run the agent
if __FILE__ == $0
  agent = GreeterAgent.new
  puts "Starting Greeter Agent..."
  agent.run
end
```

## Echo Agent

An agent that echoes back whatever message it receives:

```ruby
require 'agent99'

class EchoAgent < Agent99::Base
  def info
    {
      name:           self.class.to_s,
      type:           :server,
      capabilities:   ['echo', 'mirror']
    }
  end

  def process_request(payload)
    logger.info "Echo agent received: #{payload}"
    send_response(message: "You said: #{payload}")
  end
end

# Run the agent
if __FILE__ == $0
  agent = EchoAgent.new
  puts "Starting Echo Agent..."
  agent.run
end
```

## Calculator Agent

A more complex agent that performs basic arithmetic operations:

```ruby
require 'agent99'
require 'simple_json_schema_builder'

class CalculatorRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    string :operation, enum: %w[add subtract multiply divide], required: true
    number :a, required: true
    number :b, required: true
  end
end

class CalculatorAgent < Agent99::Base
  def info
    {
      name:             self.class.to_s,
      type:             :server,
      capabilities:     ['calculator', 'math', 'arithmetic'],
      request_schema:   CalculatorRequest.schema
    }
  end

  def process_request(payload)
    operation = payload.dig(:operation)
    a = payload.dig(:a).to_f
    b = payload.dig(:b).to_f

    result = case operation
    when 'add'
      a + b
    when 'subtract'
      a - b
    when 'multiply'
      a * b
    when 'divide'
      return send_error("Division by zero") if b == 0
      a / b
    else
      return send_error("Unknown operation: #{operation}")
    end

    send_response(result: result, operation: operation, inputs: { a: a, b: b })
  end
end

# Run the agent
if __FILE__ == $0
  agent = CalculatorAgent.new
  puts "Starting Calculator Agent..."
  agent.run
end
```

## Client Agent Example

An agent that makes requests to other agents:

```ruby
require 'agent99'

class ClientAgent < Agent99::Base
  def info
    {
      name:           self.class.to_s,
      type:           :client,
      capabilities:   ['client', 'requester']
    }
  end

  def start
    # Find available agents
    agents = discover_agents(['greeter'])
    
    if agents.any?
      greeter = agents.first
      logger.info "Found greeter agent: #{greeter[:name]}"
      
      # Send a request
      request = {
        name: "Agent99 Client"
      }
      
      response = send_request(greeter[:name], request)
      logger.info "Received response: #{response}"
    else
      logger.warn "No greeter agents found"
    end
  end
end

# Run the client
if __FILE__ == $0
  client = ClientAgent.new
  puts "Starting Client Agent..."
  
  # Run once and exit
  client.start
end
```

## Hybrid Agent Example

An agent that can both serve requests and make requests to other agents:

```ruby
require 'agent99'

class HybridAgent < Agent99::Base
  def info
    {
      name:           self.class.to_s,
      type:           :hybrid,
      capabilities:   ['proxy', 'forwarder']
    }
  end

  def process_request(payload)
    # This agent forwards requests to other agents
    target_capability = payload.dig(:forward_to)
    message = payload.dig(:message)

    if target_capability && message
      # Find agents with the target capability
      agents = discover_agents([target_capability])
      
      if agents.any?
        target_agent = agents.first
        
        # Forward the message
        response = send_request(target_agent[:name], { name: message })
        send_response(forwarded_response: response, target_agent: target_agent[:name])
      else
        send_error("No agents found with capability: #{target_capability}")
      end
    else
      send_error("Missing 'forward_to' or 'message' in request")
    end
  end
end

# Run the agent
if __FILE__ == $0
  agent = HybridAgent.new
  puts "Starting Hybrid Agent..."
  agent.run
end
```

## Running the Examples

1. **Start the Registry**: 
   ```bash
   ruby examples/registry.rb
   ```

2. **Start a Message Broker** (NATS or RabbitMQ):
   ```bash
   nats-server
   # OR
   rabbitmq-server
   ```

3. **Run the Agents**:
   ```bash
   # In separate terminals
   ruby greeter_agent.rb
   ruby calculator_agent.rb
   ruby client_agent.rb
   ```

## Testing Agent Communication

You can test agent communication using the client example or by sending HTTP requests to the registry:

```bash
# List all registered agents
curl http://localhost:4567/agents

# Find agents by capability
curl http://localhost:4567/agents/discover/greeter
```

## Next Steps

- [Advanced Examples](advanced-examples.md) - More complex agent patterns
- [Schema Definition](../agent-development/schema-definition.md) - Learn about request/response schemas
- [Message Processing](../framework-components/message-processing.md) - Understand message handling