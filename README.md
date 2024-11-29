# AiAgent

**Under development. Looking for collaborators.**

`AiAgent` implements an agent framework for AI workflows. It posits the availability of a centralized registry where agents can announce their capabilities, making it easier to discover agents that perform specific tasks. The registry supports three main processes: **register**, **discover**, and **withdraw**, with a potential fourth process—**control**—to manage all registered agents collectively.

Agents communicate with each other via a peer-to-peer messaging network, leveraging modern message queue systems.

This project serves as a simple playground for testing and experimenting with AI agent concepts in Ruby.

## Installation

To install the gem and add it to your application's Gemfile, run:

```bash
bundle add ai_agent
```

If you're not using Bundler to manage dependencies, install the gem manually:

```bash
gem install ai_agent
```

## Architecture

The intent is to experiment with Ruby as a reference implementation; however, the API and underlying concepts are designed to support a mixture of programming languages.

This project is inspired by a previous collaboration on the Integrated System Environment (ISE) project, aiming to breathe new life into those old concepts.

### Identification

Each instance of an AiAgent is uniquely identified via a UUID within the registry. This UUID serves both the registry and the peer-to-peer messaging network, establishing channels for communication between agents.

### Registry

The centralized registry is implemented as a Sinatra web application, facilitating agent registration and discovery.

### Peer-to-Peer Messaging

Communication between agents is managed through AMQP, using RabbitMQ as the message broker.

## Usage

Here’s an example of how to create and run your own agent:

```ruby
class MyAgentRequest < SimpleJsonSchemaBuilder
  object do
    object :header, schema: HeaderSchema
    # Additional request fields can be defined here
  end
end

class MyAgent < AiAgent::Base
  REQUEST_SCHEMA = MyAgentRequest.schema

  def receive_request(request)
    # Handle incoming requests
    from_uuit = request.dig('header', 'from_uuid')
    event_id  = request.dig('header', 'event_id')

    logger.info "Received request from #{from_uuid} with event_id: #{event_id}"
    # TODO: Implement request processing logic
  end

  def receive_response(response)
    # Handle responses from other agents
    from_uuid = response.dig('header', 'from_uuid')
    event_id  = response.dig('header', 'event_id')

    logger.info "Received response with event_id: #{event_id}"
    # TODO: Implement response processing logic
  end
end

MyAgent.run
```

## Contributing

All contributions are welcome! To get involved, please clone the repository, make your changes, and submit a pull request.

Have an idea but lack the time to implement it? Please create an issue, and maybe someone else can help bring it to life.

## License

This gem is open source and available under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Acknowledgments

This library builds upon foundational concepts in AI and distributed systems. Special thanks to the community and all collaborators who have contributed to this project and the broader field.
