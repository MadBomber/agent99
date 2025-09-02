# Basic Example: Building a Calculator Service

This detailed example walks you through creating a complete calculator service using Agent99, demonstrating key concepts like schema validation, error handling, and agent discovery.

## What We'll Build

A distributed calculator system with:
- **Calculator Agent**: Performs arithmetic operations
- **Client Agent**: Sends calculation requests
- **Request/Response Schemas**: Validates input and output
- **Error Handling**: Graceful error management

## Step 1: Define the Request Schema

Create `calculator_schemas.rb`:

```ruby
require 'simple_json_schema_builder'

# Request schema for calculator operations
class CalculatorRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    string :operation, enum: %w[add subtract multiply divide], required: true,
           description: "The arithmetic operation to perform"
    number :a, required: true, description: "First operand"
    number :b, required: true, description: "Second operand"
  end
end

# Response schema for calculator results
class CalculatorResponse < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    number :result, required: true, description: "The calculation result"
    string :operation, required: true, description: "The operation performed"
    object :operands do
      number :a, required: true
      number :b, required: true
    end
    string :timestamp, required: true, description: "When the calculation was performed"
  end
end
```

## Step 2: Create the Calculator Agent

Create `calculator_agent.rb`:

```ruby
require 'agent99'
require_relative 'calculator_schemas'

class CalculatorAgent < Agent99::Base
  def info
    {
      name:             self.class.to_s,
      type:             :server,
      capabilities:     ['calculator', 'math', 'arithmetic'],
      description:      'Performs basic arithmetic operations',
      request_schema:   CalculatorRequest.schema,
      response_schema:  CalculatorResponse.schema
    }
  end

  def process_request(payload)
    logger.info "Received calculation request: #{payload}"
    
    # Extract and validate inputs
    operation = payload.dig(:operation)
    a = payload.dig(:a).to_f
    b = payload.dig(:b).to_f

    # Perform calculation
    result = perform_calculation(operation, a, b)
    
    if result.is_a?(Hash) && result[:error]
      # Send error response
      send_error(result[:error], result[:code] || 'CALCULATION_ERROR')
    else
      # Send successful response
      response = {
        result: result,
        operation: operation,
        operands: { a: a, b: b },
        timestamp: Time.now.iso8601
      }
      
      send_response(response)
    end
  end

  private

  def perform_calculation(operation, a, b)
    case operation
    when 'add'
      a + b
    when 'subtract'
      a - b
    when 'multiply'
      a * b
    when 'divide'
      return { error: "Division by zero is not allowed", code: 'DIVISION_BY_ZERO' } if b == 0
      a / b
    else
      { error: "Unknown operation: #{operation}", code: 'INVALID_OPERATION' }
    end
  end
end

# Run the agent if this file is executed directly
if __FILE__ == $0
  puts "🧮 Starting Calculator Agent..."
  agent = CalculatorAgent.new
  
  # Handle graceful shutdown
  trap('INT') do
    puts "\n👋 Shutting down Calculator Agent..."
    agent.shutdown
    exit
  end
  
  agent.run
end
```

## Step 3: Create a Client Agent

Create `calculator_client.rb`:

```ruby
require 'agent99'

class CalculatorClient < Agent99::Base
  def info
    {
      name: self.class.to_s,
      type: :client,
      capabilities: ['calculator_client', 'testing']
    }
  end

  def perform_calculations
    # Find calculator agents
    calculators = discover_agents(['calculator'])
    
    if calculators.empty?
      puts "❌ No calculator agents found!"
      return
    end

    calculator = calculators.first
    puts "🎯 Found calculator: #{calculator[:name]}"

    # Test calculations
    test_cases = [
      { operation: 'add', a: 10, b: 5, expected: 15 },
      { operation: 'subtract', a: 10, b: 3, expected: 7 },
      { operation: 'multiply', a: 4, b: 7, expected: 28 },
      { operation: 'divide', a: 20, b: 4, expected: 5 },
      { operation: 'divide', a: 10, b: 0, expected: 'ERROR' }  # This should error
    ]

    test_cases.each_with_index do |test_case, index|
      puts "\n📋 Test #{index + 1}: #{test_case[:a]} #{test_case[:operation]} #{test_case[:b]}"
      
      begin
        response = send_request(calculator[:name], test_case.reject { |k, _| k == :expected })
        
        if response[:error]
          puts "⚠️  Error: #{response[:error]} (#{response[:code]})"
          puts "✅ Expected error!" if test_case[:expected] == 'ERROR'
        else
          result = response[:result]
          puts "📊 Result: #{result}"
          
          if test_case[:expected] != 'ERROR'
            if (result - test_case[:expected]).abs < 0.001  # Handle floating point comparison
              puts "✅ Test passed!"
            else
              puts "❌ Test failed! Expected #{test_case[:expected]}, got #{result}"
            end
          end
        end
      rescue => e
        puts "💥 Request failed: #{e.message}"
      end
    end
  end
end

# Run the client if this file is executed directly
if __FILE__ == $0
  puts "📱 Starting Calculator Client..."
  client = CalculatorClient.new
  client.perform_calculations
end
```

## Step 4: Run the Complete Example

### Terminal 1: Start the Registry
```bash
# From the agent99 repository
ruby examples/registry.rb
```

### Terminal 2: Start NATS (or RabbitMQ)
```bash
nats-server
```

### Terminal 3: Start the Calculator Agent
```bash
ruby calculator_agent.rb
```

Expected output:
```
🧮 Starting Calculator Agent...
INFO -- Agent CalculatorAgent registered successfully
INFO -- Agent listening for messages...
```

### Terminal 4: Run the Client
```bash
ruby calculator_client.rb
```

Expected output:
```
📱 Starting Calculator Client...
🎯 Found calculator: CalculatorAgent

📋 Test 1: 10 add 5
📊 Result: 15.0
✅ Test passed!

📋 Test 2: 10 subtract 3
📊 Result: 7.0
✅ Test passed!

📋 Test 3: 4 multiply 7
📊 Result: 28.0
✅ Test passed!

📋 Test 4: 20 divide 4
📊 Result: 5.0
✅ Test passed!

📋 Test 5: 10 divide 0
⚠️  Error: Division by zero is not allowed (DIVISION_BY_ZERO)
✅ Expected error!
```

## Step 5: Explore the Registry

While everything is running, visit http://localhost:4567/agents in your browser to see registered agents, or use curl:

```bash
# List all agents
curl http://localhost:4567/agents | jq

# Find calculator agents
curl http://localhost:4567/agents/discover/calculator | jq
```

## Key Concepts Demonstrated

### 🏗️ **Agent Architecture**
- **Server Agent**: Waits for and processes requests
- **Client Agent**: Discovers and communicates with other agents
- **Registry**: Central discovery service

### 📝 **Schema Validation**
- **Request Schema**: Validates incoming requests
- **Response Schema**: Defines response structure
- **Type Safety**: Ensures data integrity

### 🛡️ **Error Handling**
- **Validation Errors**: Invalid input handling
- **Business Logic Errors**: Division by zero, invalid operations
- **Network Errors**: Communication failures

### 🔍 **Agent Discovery**
- **Capability-based**: Find agents by what they can do
- **Dynamic**: Agents can join and leave at runtime
- **Fault-tolerant**: Graceful handling of missing agents

## What's Next?

- **[Core Concepts](../core-concepts/what-is-an-agent.md)** - Deep dive into agent theory
- **[Schema Definition](../agent-development/schema-definition.md)** - Advanced schema patterns
- **[Advanced Examples](../examples/advanced-examples.md)** - Complex multi-agent scenarios
- **[Error Handling](../agent-development/error-handling-and-logging.md)** - Comprehensive error strategies

## Exercises

Try extending this example:

1. **Add more operations**: power, square root, factorial
2. **Add validation**: check for reasonable input ranges
3. **Add persistence**: log all calculations to a file
4. **Add monitoring**: track success/failure rates
5. **Add authentication**: require API keys for requests