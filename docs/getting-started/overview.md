# Agent99 Framework Overview

Agent99 is a Ruby framework for building distributed AI agents with peer-to-peer messaging capabilities. It provides a robust foundation for creating intelligent agents that can communicate, discover each other, and perform various tasks in a microservices architecture.

## Current Status

**Version**: 0.0.4 (Under Development)

!!! warning "Development Status"
    Agent99 is currently under active development. The initial release has no AI components - it's a generic client-server / request-response microservices system using peer-to-peer messaging brokers and a centralized agent registry.

## Key Features

- **Agent Types**: Support for Server (responds to requests), Client (makes requests), and Hybrid (both) agents
- **Messaging**: Multiple messaging backends including AMQP (via Bunny) and NATS
- **Agent Discovery**: Central registry for finding agents by capabilities
- **Lifecycle Management**: Complete agent registration, message processing, and control actions
- **Dynamic Loading**: Runtime agent deployment via AgentWatcher
- **Multi-threading**: Run multiple agents in the same process with thread isolation

## Architecture Highlights

- **Modular Design**: Built with mixins for HeaderManagement, AgentDiscovery, ControlActions, AgentLifecycle, and MessageProcessing
- **Multiple Message Clients**: AMQP, NATS, and TCP implementations
- **HTTP Registry**: Simple HTTP-based service for agent discovery (default: localhost:4567)
- **Schema Validation**: JSON schema validation for requests and responses

## Future Vision

The framework is designed with AI integration in mind, referencing protocols like:
- **Agent2Agent (A2A)**: Now under the Linux Foundation
- **Model Context Protocol**: For AI model integration

## Quick Example

```ruby
require 'agent99'

class GreeterAgent < Agent99::Base
  def info
    {
      name: self.class.to_s,
      type: :server,
      capabilities: ['greeter', 'hello_world']
    }
  end

  def process_request(payload)
    name = payload.dig(:name)
    response = { result: "Hello, #{name}!" }
    send_response(response)
  end
end

# Create and run the agent
agent = GreeterAgent.new
agent.run
```

## Next Steps

- [Installation](installation.md) - Get Agent99 installed
- [Quick Start](quick-start.md) - Build your first agent
- [Basic Example](basic-example.md) - Detailed walkthrough