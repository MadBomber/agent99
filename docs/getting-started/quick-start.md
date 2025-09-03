# Quick Start

Get up and running with Agent99 in just a few minutes! This guide assumes you have Ruby 3.3.0+ installed.

## Step 1: Install Agent99

```bash
gem install agent99
```

## Step 2: Start a Message Broker

Agent99 needs a message broker for agent communication. Choose one:

=== "NATS (Recommended)"
    ```bash
    # Install NATS server
    brew install nats-server  # macOS
    # OR download from https://nats.io/download/

    # Start NATS
    nats-server
    ```

=== "RabbitMQ"
    ```bash
    # Install RabbitMQ
    brew install rabbitmq  # macOS

    # Start RabbitMQ
    brew services start rabbitmq
    ```

## Step 3: Start the Registry

The registry helps agents discover each other:

```bash
# Clone the repository for examples
git clone https://github.com/MadBomber/agent99.git
cd agent99

# Start the registry
ruby examples/registry.rb
```

## Step 4: Create Your First Agent

Create a file called `my_first_agent.rb`:

```ruby
require 'agent99'

class MyFirstAgent < Agent99::Base
  def info
    {
      name: self.class.to_s,
      type: :server,
      capabilities: ['greeting', 'hello']
    }
  end

  def process_request(payload)
    name = payload.dig(:name) || "World"
    logger.info "Processing greeting request for: #{name}"

    response = {
      message: "Hello, #{name}! Welcome to Agent99!",
      timestamp: Time.now.iso8601
    }

    send_response(response)
  end
end

# Run the agent
if __FILE__ == $0
  puts "🤖 Starting My First Agent..."
  agent = MyFirstAgent.new
  agent.run
end
```

## Step 5: Run Your Agent

```bash
ruby my_first_agent.rb
```

You should see output like:
```
🤖 Starting My First Agent...
INFO -- Agent MyFirstAgent registered successfully
INFO -- Agent listening for messages...
```

## Step 6: Test Your Agent

Create a simple client to test your agent (`test_client.rb`):

```ruby
require 'agent99'

class TestClient < Agent99::Base
  def info
    {
      name: self.class.to_s,
      type: :client,
      capabilities: ['testing']
    }
  end

  def test_greeting
    # Discover greeting agents
    agents = discover_agents(['greeting'])

    if agents.any?
      target_agent = agents.first
      puts "📡 Found agent: #{target_agent[:name]}"

      # Send a request
      request = { name: "Agent99 User" }
      response = send_request(target_agent[:name], request)

      puts "✅ Response: #{response[:message]}"
    else
      puts "❌ No greeting agents found"
    end
  end
end

# Run the test
if __FILE__ == $0
  client = TestClient.new
  client.test_greeting
end
```

Run the test client:
```bash
ruby test_client.rb
```

Expected output:
```
📡 Found agent: MyFirstAgent
✅ Response: Hello, Agent99 User! Welcome to Agent99!
```

## 🎉 Success!

You've successfully:

- ✅ Installed Agent99
- ✅ Started a message broker and registry
- ✅ Created and ran your first agent
- ✅ Tested agent communication

## What's Next?

- **[Basic Example](basic-example.md)** - More detailed walkthrough
- **[Core Concepts](../core-concepts/what-is-an-agent.md)** - Understand how agents work
- **[Examples](../examples/basic-examples.md)** - More agent patterns
- **[Agent Development](../agent-development/custom-agent-implementation.md)** - Build complex agents

## Troubleshooting

**Agent not starting?**
- Make sure NATS or RabbitMQ is running
- Check that Ruby 3.3.0+ is installed: `ruby --version`
- Verify the registry is running on port 4567

**Can't find agents?**
- Ensure all components (registry, broker, agents) are running
- Check that agents are registering: visit http://localhost:4567/agents

**Need help?**
- Check the [Troubleshooting Guide](../operations/troubleshooting.md)
- Visit the [GitHub repository](https://github.com/MadBomber/agent99) for issues and discussions
