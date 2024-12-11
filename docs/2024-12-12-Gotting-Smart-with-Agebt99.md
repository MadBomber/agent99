---
title: "Getting Smart with Agent99"
categories:
  - Engineering
tags:
  - Agents
  - Tools
---

# Getting Smart with Agent99

Welcome to the first article in a series that introduces the  Ruby gem [**agent99**](https://rubygems.org/gems/agent99), which provides a reference implementation framework for the execution and management of software agents. If you're eager to jump right in, feel free to visit the [software repository](https://github.com/MadBomber/agent99).

## Background

I've been developed software systems since I wrote my first computer program in the fall of 1970.  It was a one-liner in APL - A Programming Langauge.  Of course all programs in APL are essencially one-liners.  I'm very happy that I've been using Ruby since 2005.

With this long history, I've accumulated some references that sometimes puzzle newer developers. For instance, when mention that Agent 99 is smarter than Agent 86.

One of my favorite spy shows from the 1960s is [**Get Smart**](https://www.youtube.com/watch?v=16_6XrPlV-w), a title that resonates with today’s growing interest in integrating artificial intelligence (AI) into every software project, which is not always for the better.

In Get Smart, Agent 99, portrayed by Barbara Feldon, is a skilled and intelligent agent who excels through quick thinking and resourcefulness. In a male-dominated world, she stands as a symbol of capability and independence.

Here’s how the Ruby programming language, like Agent 99, offers unique benefits in a Python-dominated AI landscape:

- **Refreshing Alternative:** Ruby allows developers to create elegant and expressive AI applications.
- **Encourages Innovation:** It promotes paradigm shifts, challenging the Python status quo in AI development.
- **Readable and Maintainable:** Developers who value clarity can find their niche in Ruby’s design.
- **Supports Unique Projects:** Ruby's metaprogramming capabilities pave the way for creative AI solutions.
- **Integration-friendly:** Greater integration of Ruby-based frameworks makes them viable choices in the AI landscape.
- **Object-Oriented Strengths:** Ruby's object-oriented style leads to more modular and testable code.
- **Engaged Community:** Ruby inspires a community that often prefers its syntax over Python's.

Now, let’s dive into the fundamental concepts behind the [Agent99 Framework](https://github.com/MadBomber/agent99) as implemented in the Ruby gem.

### Getting Started with Agent99

To install the Agent99 gem, simply run:

```bash
gem install agent99
```

The [documentation](https://github.com/MadBomber/agent99/blob/main/docs/README.md) provides a comprehensive overview of the framework, but here, we will explore definitions of software agents and the Single Responsibility Principle (SRP), along with how Agent99 distinguishes itself in agent management and description.

## What is a Reference Implementation?

The Agent99 gem implements a protocol in Ruby that can be replicated in other programming languages. This interoperability allows software agents, given they support the Agent99 protocol, to mix and match regardless of the language they were built in.

### Understanding Software Agents and the Single Responsibility Principle

Software agents and the Single Responsibility Principle (SRP) are crucial in contemporary software development. They decompose complex systems into manageable, autonomous components, while SRP promotes the creation of maintainable, testable, and adaptable systems. Utilizing both can boost code quality and nurture agility in development teams, particularly in AI, automation, and microservices contexts.

### What are Software Agents?

In simple terms, a software agent is a designated piece of code that performs a single function effectively. Within the Agent99 framework, agents are instances of subclasses derived from the **Agent99::Base** class. Each subclass is responsible for specific methods that define its unique capabilities, such as the following:

```ruby
def capabilities = %w[ greeter hello_world ]
```

Additionally, methods for handling requests, responses, and control commands are essential, and custom implementations of **init**, **initialize**, or **fini** may be necessary for managing state or resources.

> **Note:** Currently, the Agent99 implementation defines the **capabilities** value as an `Array(String)`, with plans to enhance this functionality into descriptive unstructured text akin to defining tools for functional callbacks in LLM processing.

## The Single Responsibility Principle (SRP)

The Single Responsibility Principle, part of the SOLID principles of object-oriented design, asserts that a class or module should have only one reason to change. This means it should fulfill a single job or responsibility effectively.

### Why SRP Matters

1. **Maintainability:** Code is easier to read and modify, leading to more maintainable systems.
2. **Testability:** Isolated responsibilities facilitate independent unit testing.
3. **Flexibility:** Minimal impact on other parts of the system when modifying one responsibility, reducing the risk of bugs.

### Applying SRP in Software Development

Implementing SRP involves:

- **Identifying Responsibilities:** Break down functionalities into specific tasks; each class or module should focus on a particular duty.
- **Modular Design:** Create a loosely coupled system to enhance separation of concerns.
- **Utilizing Design Patterns:** Harness design patterns like Observer, Strategy, and Factory to ensure clear interfaces and responsibilities.

## Alignment of Agents and SRP

The notion of software agents naturally corresponds with the SRP. Each agent can be a distinct class or module that encapsulates a specific functionality. For instance:

- An order processing agent focuses solely on order management.
- A notification agent manages the sending of alerts or messages without getting involved in order processing logic.

Designing agents with SRP in mind fosters modularity and reusability, allowing changes to one agent without affecting others and supporting more robust architecture.

## Agent99 as a Reference Framework

In its current iteration, the Agent99 Framework does not differ conceptually from other micro-service archecture implementations. It enables centralized registration where agents list their capabilities for other agents or applications to discover. Agent communications occur via a distributed messaging system.  The agent99 Ruby gem currently uses AMQP (via the Bunny gem and the RabbitMQ broker) and the NATS-server.

### Agent Structure

Agents in Agent99 inherit from **Agent99::Base**, which offers core functionality through crucial modules:

- **HeaderManagement:** Handles message header processing.
- **AgentDiscovery:** Facilitates capability advertisement and discovery.
- **ControlActions:** Manages control messages.
- **AgentLifecycle:** Oversees agent startup and shutdown functionality.
- **MessageProcessing:** Manages message dispatch and handling.

Every agent must define its type (server, client, or hybrid) and capabilities. The framework supports three message types: requests, responses, and control messages.

### Centralized Registry

The registry service tracks agent availability and capabilities through a **RegistryClient**. A web-based application serves as the central registry, with a Sinatra implementation found in the `examples/registry.rb` file. Its primary function is to maintain a data store of registered agents.

It supports three core operations:

#### 1. Register

![Central Registry Process](/assets/images/agent_registry_process.png)

Agents register by providing their information (e.g., name and capabilities) to the registry service. Upon successful registration, they receive a universally unique ID (UUID) that identifies them in the system.

#### 2. Discover

Agents can query the registry to discover capabilities. The discovery operation retrieves information about agents offering specific capabilities via an HTTP GET request.

#### 3. Withdraw

When an agent needs to exit the system, it withdraws its registration using its UUID, removing it from the available agents list through an HTTP DELETE request.

### Messaging Network

The Ruby implementation of Agent99 currently focuses on AMQP messaging systems. Messages are formatted as JSON structures that adhere to defined schemas, allowing the **MessageClient** to validate messages effortlessly. Invalidated messages return to the sender without invoking agent-specific processes. 

Message types within the framework include:

#### Request Messages

These messages are validated against an agent-defined schema and include:

- A header with routing information.
- A payload with request details.
- Type-specific validation rules.

Requests are handled by the `receive_request` handler in target agents.

#### Response Messages

Responses are routed back to the requesting agent, including:

- The original message header in reverse.
- The response payload.
- Status information.

Responses are processed by the `receive_response` method.

#### Control Messages

Control messages manage agent lifecycles and configurations and include commands such as:

- **shutdown:** Stop the agent.
- **pause/resume:** Temporarily suspend or resume operations.
- **update_config:** Modify agent configurations.
- **status:** Query agent state.
- **response:** Handle control operation results.

Messages are queued with a 60-second TTL (Time To Live) to prevent buildup from inactive agents.

## Additional Resources

For further exploration, check out the documentation of the current Ruby implementation at [GitHub](https://github.com/MadBomber/agent99).

Contributions to this initial Ruby reference implementation are welcome! It would be exciting to see additional language implementations. Anyone interested in creating APL, PL-1, or Ada versions?
