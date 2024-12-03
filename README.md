# AiAgent

**Under development. Looking for collaborators.**

`AiAgent` implements an agent framework for AI workflows. It posits the availability of a centralized registry where agents can announce their capabilities, making it easier to discover agents that perform specific tasks. The registry supports three main processes: **register**, **discover**, and **withdraw**, with a potential fourth process—**control**—to manage all registered agents collectively.

Agents communicate with each other via a peer-to-peer messaging network, leveraging modern message queue systems.

This project serves as a simple playground for testing and experimenting with AI agent concepts in Ruby.

## Installation

**NOTE:** This code has not yet been published as a gem.  If you want to try it out you must clone the repo and do a local install from your clone.

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

## "AMQP?  Dude that is so like last century!"

According to the `cool kids` NATS is where its at.  See https:hats.io

```
brew install nats-server nats-streaming-server
gem install nats-pure

require 'nats/client'

nats = NATS.connect("demo.nats.io")
puts "Connected to #{nats.connected_server}"

# Simple subscriber
nats.subscribe("foo.>") { |msg, reply, subject| puts "Received on '#{subject}': '#{msg}'" }

# Simple Publisher
nats.publish('foo.bar.baz', 'Hello World!')

# Unsubscribing
sub = nats.subscribe('bar') { |msg| puts "Received : '#{msg}'" }
sub.unsubscribe()

# Requests with a block handles replies asynchronously
nats.request('help', 'please', max: 5) { |response| puts "Got a response: '#{response}'" }

# Replies
sub = nats.subscribe('help') do |msg|
  puts "Received on '#{msg.subject}': '#{msg.data}' with headers: #{msg.header}"
  msg.respond("I'll help!")
end

# Request without a block waits for response or timeout
begin
  msg = nats.request('help', 'please', timeout: 0.5)
  puts "Received on '#{msg.subject}': #{msg.data}"
rescue NATS::Timeout
  puts "nats: request timed out"
end

# Request using a message with headers
begin
  msg = NATS::Msg.new(subject: "help", headers: {foo: 'bar'})
  resp = nats.request_msg(msg)
  puts "Received on '#{resp.subject}': #{resp.data}"
rescue NATS::Timeout => e
  puts "nats: request timed out: #{e}"
end

# Server roundtrip which fails if it does not happen within 500ms
begin
  nats.flush(0.5)
rescue NATS::Timeout
  puts "nats: flush timeout"
end

# Closes connection to NATS
nats.close
```

Kinda looks like a topic queue organization to me.

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
