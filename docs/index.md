# Agent99 Framework Documentation

Welcome to the comprehensive documentation for Agent99 - a Ruby framework for building distributed AI agents with peer-to-peer messaging capabilities.

## 🚀 Getting Started

New to Agent99? Start here to get up and running quickly:

- **[Overview](getting-started/overview.md)** - What is Agent99 and what can it do?
- **[Installation](getting-started/installation.md)** - Get Agent99 installed and configured
- **[Quick Start](getting-started/quick-start.md)** - Build your first agent in minutes  
- **[Basic Example](getting-started/basic-example.md)** - Detailed walkthrough of a complete system

## 🧠 Core Concepts

Understand the fundamental concepts behind Agent99:

- **[What is an Agent?](core-concepts/what-is-an-agent.md)** - Basic agent concepts and philosophy
- **[Agent Types](core-concepts/agent-types.md)** - Server, Client, and Hybrid agents explained
- **[Agent Lifecycle](core-concepts/agent-lifecycle.md)** - How agents start, run, and stop
- **[Architecture Overview](core-concepts/architecture.md)** - System design and component interaction

## 🔧 Framework Components

Deep dive into the Agent99 system components:

- **[Agent Registry](framework-components/agent-registry.md)** - Central agent discovery service
- **[Agent Discovery](framework-components/agent-discovery.md)** - How agents find each other
- **[Messaging System](framework-components/messaging-system.md)** - AMQP, NATS, and TCP messaging
- **[Message Processing](framework-components/message-processing.md)** - Request/response handling

## 💻 Agent Development

Build your own agents with these guides:

- **[Custom Agent Implementation](agent-development/custom-agent-implementation.md)** - Create custom agents
- **[Schema Definition](agent-development/schema-definition.md)** - Request/response validation  
- **[Request & Response Handling](agent-development/request-response-handling.md)** - Message processing patterns
- **[Error Handling & Logging](agent-development/error-handling-and-logging.md)** - Robust error strategies

## 🎯 Advanced Topics

Advanced features and integration patterns:

- **[Control Actions](advanced-topics/control-actions.md)** - Agent control and management
- **[Advanced Features](advanced-topics/advanced-features.md)** - Dynamic loading and multi-agent processing
- **[A2A Protocol](advanced-topics/a2a-protocol.md)** - Agent-to-Agent communication protocol  
- **[Model Context Protocol](advanced-topics/model-context-protocol.md)** - AI model integration
- **[Extending the Framework](advanced-topics/extending-the-framework.md)** - Custom modules and extensions

## 📚 API Reference

Detailed API documentation:

- **[Agent99::Base](api-reference/agent99-base.md)** - Core agent class reference
- **[Registry Client](api-reference/registry-client.md)** - Registry service API  
- **[Message Clients](api-reference/message-clients.md)** - Messaging client APIs
- **[Schemas](api-reference/schemas.md)** - Schema validation system

## ⚙️ Operations

Deploy and maintain Agent99 in production:

- **[Configuration](operations/configuration.md)** - Environment and runtime configuration
- **[Security](operations/security.md)** - Security best practices and implementation
- **[Performance Considerations](operations/performance-considerations.md)** - Optimization and scaling
- **[Troubleshooting](operations/troubleshooting.md)** - Common issues and solutions
- **[Breaking Changes](operations/breaking-changes.md)** - Version upgrade guide

## 💡 Examples

Working examples and tutorials:

- **[Basic Examples](examples/basic-examples.md)** - Simple agent patterns and use cases
- **[Advanced Examples](examples/advanced-examples.md)** - Complex multi-agent scenarios

## 🔄 Recent Updates

### 2024-12-12 - Version 0.0.4 Release
- Breaking changes in agent registration and discovery
- Improved message processing performance
- Enhanced error handling and logging

### 2025-04-09 - A2A Protocol Integration
Google announced its Agent-to-Agent public protocol called A2A. Agent99 is designed to integrate with this protocol. For additional information see [A2A Protocol Documentation](advanced-topics/a2a-protocol.md).

## 🤝 Contributing

Agent99 is an open-source project and welcomes contributions:

- **GitHub Repository**: [https://github.com/MadBomber/agent99](https://github.com/MadBomber/agent99)
- **RubyGems Package**: [https://rubygems.org/gems/agent99](https://rubygems.org/gems/agent99)
- **Issue Tracker**: Report bugs and request features on GitHub

---

*Ready to build distributed agent systems? Start with the [Getting Started](getting-started/overview.md) guide!*
