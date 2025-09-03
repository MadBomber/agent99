# Agent99 Framework Architecture

## High-Level Architecture Overview

Agent99 is a Ruby-based framework designed for building and managing software agents in a distributed system environment. The architecture follows a service-oriented approach with three main components:

1. **Agents**: Independent services that can register, discover, and communicate with each other
2. **Registry Service**: Central registration and discovery system
3. **Message Broker**: Communication backbone (supports AMQP or NATS)

### System Components Diagram

![Agent99 Architecture](../assets/images/agent99-architecture.svg)

The diagram above illustrates the key components and their interactions:

- **Agents**: Come in three types:
   - Client Agents: Only make requests
   - Server Agents: Only respond to requests
   - Hybrid Agents: Both make and respond to requests

- **Registry Service**: 
   - Maintains agent registrations
   - Handles capability-based discovery
   - Issues unique UUIDs to agents

- **Message Broker**:
   - Supports both AMQP and NATS protocols
   - Handles message routing between agents
   - Provides reliable message delivery

### Communication Patterns

1. **Registration Flow**:
      - New agent instantiated
      - Agent registers with Registry Service
      - Receives unique UUID for identification
      - Sets up message queue/topic

2. **Discovery Flow**:
      - Agent queries Registry for specific capabilities
      - Registry returns matching agent information
      - Requesting agent caches discovery results

3. **Messaging Flow**:
      - Agent creates message with recipient UUID
      - Message routed through Message Broker
      - Recipient processes message based on type:
         - Requests: Handled by receive_request
         - Responses: Handled by receive_response
         - Control: Handled by control handlers

### Message Types

The framework supports three primary message types:

1. **Request Messages**: 
      - Used to request services from other agents
      - Must include capability requirements
      - Can contain arbitrary payload data

2. **Response Messages**:
      - Sent in reply to requests
      - Include original request reference
      - Contain result data or error information

3. **Control Messages**:
      - System-level communication
      - Handle agent lifecycle events
      - Support configuration updates

## Implementation Details

For detailed implementation information, see:
- [API Reference](../api-reference/agent99-base.md) for method specifications
- [Agent Lifecycle](agent-lifecycle.md) for lifecycle management
- [Agent Discovery](../framework-components/agent-discovery.md) for discovery mechanisms
