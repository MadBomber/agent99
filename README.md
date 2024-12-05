# AiAgent Framework

**Under Development**  Initial release has no AI components - its just a generic client-server / request-response micro-services system using a peer-to-peer messaging broker and a centralized agent registry.

AiAgent is a Ruby-based framework for building and managing AI agents in a distributed system. It provides a robust foundation for creating intelligent agents that can communicate, discover each other, and perform various tasks.

## Features

- Agent Lifecycle Management: Easy setup and teardown of agents
- Message Processing: Handle requests, responses, and control messages
- Agent Discovery: Find other agents based on capabilities
- Flexible Communication: Support for both AMQP and NATS messaging systems
- Registry Integration: Register and discover agents through a central registry
- Error Handling and Logging: Built-in error management and logging capabilities
- Control Actions: Pause, resume, update configuration, and request status of agents

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ai_agent'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install ai_agent
```

## Usage

Here's a basic example of how to create an AI agent:

```ruby
require 'ai_agent'

class MyAgentRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: AiAgent::HeaderSchema

    # Define your agents parameters ....
    string :greeting, required: false,  examples: ["Hello"]
    string :name,     required: true,   examples: ["World"]
  end
end

class MyAgent < AiAgent::Base
  REQUEST_SCHEMA  = MyAgentRequest.schema

  def capabilities
    ['text_processing', 'sentiment_analysis']
    # TODO: make up mind on keyword or unstructured text
  end

  def receive_request
    # Handle the validated incoming requests
    response = { result: "Processed request" }

    # Not every request needs a response
    send_response(response)
  end

  def receive_response
    # You sent a request to another agent
    # now handle the response.
  end
end

agent = MyAgent.new
agent.run
```

## Configuration

The framework can be configured through environment variables:

- `REGISTRY_BASE_URL`: URL of the agent registry service (default: 'http://localhost:4567')  See the default registry service in the examples folder.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MadBomber/ai_agent.

## Short-term Roadmap

- In the example registry, replace the Array(Hash) datastore with sqlite3 with a vector table to support discovery using semantic search.
- Treat the agent like a Tool w/r/t RAG for prompts.
- Add AgentRequest schema to agent's info in the registry.
- Add AgentResponse schema to define the `result` element in the response JSON payload

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).