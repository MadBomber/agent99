# AiAgent Framework Examples

- TODO
    - Review and edit
    - Add instructions for brew install rabbitmq nats-server boxes
    - review example agents to see code can be tightened

This folder contains example implementations using the AiAgent framework. The framework provides a foundation for building AI agents that can communicate with each other through a message-based system.

## Files

### 1. hello_world.rb

This file demonstrates a basic AI agent implementation using the AiAgent framework.

- Class: `HelloWorld < AiAgent::Base`
- Functionality: Responds to "hello world" requests
- Key methods:
  - `receive_request`: Handles incoming requests
  - `validate_request`: Validates the request against a schema
  - `process`: Generates the response

### 2. hello_world_client.rb

This file shows how to create a client that interacts with the HelloWorld agent.

- Class: `HelloWorldClient < AiAgent::Base`
- Functionality: Sends a request to a HelloWorld agent and processes the response
- Key methods:
  - `init`: Initiates the request sending process
  - `send_request`: Builds and sends the request
  - `receive_response`: Handles the response from the HelloWorld agent

### 3. hello_world_request.rb

This file defines the schema for HelloWorld requests using SimpleJsonSchemaBuilder.

- Class: `HelloWorldRequest < SimpleJsonSchemaBuilder::Base`
- Defines the structure of a valid HelloWorld request

### 4. registry.rb

This file implements a simple registry service for AI agents using Sinatra.

- Functionality: Allows agents to register, discover other agents, and withdraw from the registry
- Endpoints:
  - GET `/healthcheck`: Returns the number of registered agents
  - POST `/register`: Registers a new agent
  - GET `/discover`: Discovers agents by capability
  - DELETE `/withdraw/:uuid`: Withdraws an agent from the registry
  - GET `/`: Lists all registered agents

## Usage

1. Start the registry service:
   ```
   ruby registry.rb
   ```

2. Run the HelloWorld agent:
   ```
   ruby hello_world.rb
   ```

3. Run the HelloWorld client:
   ```
   ruby hello_world_client.rb
   ```

## Dependencies

- Ruby 3.3+
- Gems: json, json_schema, sinatra, bunny, securerandom

## Notes

- The framework uses modern Ruby 3.3 syntax, especially for hashes and method signatures with named parameters.
- The examples demonstrate basic usage of the AiAgent framework, including request/response handling, validation, and agent discovery.
- The registry service uses an in-memory store (AGENT_REGISTRY) for simplicity, but it's recommended to use a more robust solution like SQLite for production use.
