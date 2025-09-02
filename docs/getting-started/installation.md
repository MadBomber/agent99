# Installation

This guide will help you install Agent99 and set up your development environment.

## Prerequisites

Agent99 requires **Ruby 3.3.0** or higher.

Check your Ruby version:

```bash
ruby --version
```

If you need to install or upgrade Ruby, we recommend using [rbenv](https://github.com/rbenv/rbenv) or [RVM](https://rvm.io/).

## Install the Gem

### From RubyGems

```bash
gem install agent99
```

### From Bundler

Add this line to your application's Gemfile:

```ruby
gem 'agent99'
```

And then execute:

```bash
bundle install
```

### From Source

Clone the repository and install:

```bash
git clone https://github.com/MadBomber/agent99.git
cd agent99
bundle install
```

## Dependencies

Agent99 automatically installs the following dependencies:

- **bunny** - AMQP messaging client
- **nats-pure** - NATS messaging client  
- **simple_json_schema_builder** - JSON schema validation
- **sinatra** - For the registry service

## Message Broker Setup

Agent99 supports multiple messaging backends. Choose one:

### Option 1: NATS (Recommended for Development)

Install NATS server:

```bash
# macOS
brew install nats-server

# Ubuntu/Debian
apt-get install nats-server

# Or download from https://nats.io/download/
```

Start NATS server:

```bash
nats-server
```

### Option 2: RabbitMQ (AMQP)

Install RabbitMQ:

```bash
# macOS
brew install rabbitmq

# Ubuntu/Debian  
apt-get install rabbitmq-server

# Or download from https://www.rabbitmq.com/download.html
```

Start RabbitMQ:

```bash
# macOS
brew services start rabbitmq

# Ubuntu/Debian
systemctl start rabbitmq-server
```

## Registry Service

Agent99 uses a central registry for agent discovery. You can use the example registry or create your own.

Start the example registry:

```bash
# From the agent99 source directory
ruby examples/registry.rb
```

The registry will start on http://localhost:4567 by default.

## Environment Variables

Configure Agent99 using environment variables:

```bash
# Registry URL (default: http://localhost:4567)
export AGENT99_REGISTRY_URL=http://localhost:4567

# Message broker settings (see messaging documentation)
export RABBITMQ_URL=amqp://localhost
export NATS_URL=nats://localhost:4222
```

## Verification

Verify your installation by running a simple test:

```ruby
require 'agent99'
puts "Agent99 version: #{Agent99.version}"
```

## Development Dependencies

If you're contributing to Agent99, install development dependencies:

```bash
bundle install --with development
```

This includes:
- **amazing_print** - Pretty printing
- **debug_me** - Debugging utilities
- **hashdiff** - Hash comparison
- **mocha** - Testing framework
- **tocer** - Documentation generation

## Next Steps

- [Quick Start](quick-start.md) - Build your first agent
- [Basic Example](basic-example.md) - Detailed walkthrough
- [Configuration](../operations/configuration.md) - Advanced setup options