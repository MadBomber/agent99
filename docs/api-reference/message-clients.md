# Message Clients API

Agent99 supports multiple message broker clients for different messaging protocols. This document covers the APIs and configuration for each supported client type.

## Overview

Agent99 currently supports three message client types:

- **NATS** - High-performance, cloud-native messaging (recommended)
- **AMQP** - Advanced Message Queuing Protocol via RabbitMQ
- **TCP** - Simple TCP-based messaging for testing

## Client Selection

The message client is automatically selected based on configuration:

```ruby
# Environment variable
ENV['AGENT99_MESSAGE_CLIENT'] = 'nats'  # or 'amqp', 'tcp'

# Or via agent initialization
agent = MyAgent.new(message_client: 'nats')
```

## NATS Client

### Configuration

```ruby
# Environment variables
ENV['NATS_URL'] = 'nats://localhost:4222'
ENV['NATS_USERNAME'] = 'agent99'      # optional
ENV['NATS_PASSWORD'] = 'secret'       # optional

# Or programmatically
nats_config = {
  servers: ['nats://localhost:4222'],
  username: 'agent99',
  password: 'secret',
  timeout: 30,
  reconnect_attempts: 10
}

client = Agent99::MessageClients::NatsClient.new(nats_config)
```

### Connection Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `servers` | Array | `['nats://localhost:4222']` | NATS server URLs |
| `username` | String | `nil` | Authentication username |
| `password` | String | `nil` | Authentication password |
| `timeout` | Integer | 30 | Connection timeout (seconds) |
| `reconnect_attempts` | Integer | 10 | Reconnection attempts |
| `max_reconnect_attempts` | Integer | -1 | Max reconnection attempts (-1 = unlimited) |

### Usage Example

```ruby
class NatsAgent < Agent99::Base
  def initialize
    super(message_client: 'nats')
  end

  def info
    {
      name: self.class.to_s,
      type: :server,
      capabilities: ['nats_example']
    }
  end

  def process_request(payload)
    # NATS-specific features can be accessed via client
    subject = current_message_subject
    reply_to = current_reply_subject
    
    logger.info "Received on subject: #{subject}"
    
    send_response(
      message: "Processed via NATS",
      subject: subject,
      timestamp: Time.now.iso8601
    )
  end
end
```

## AMQP Client (RabbitMQ)

### Configuration

```ruby
# Environment variables
ENV['RABBITMQ_URL'] = 'amqp://localhost:5672'
ENV['RABBITMQ_USERNAME'] = 'guest'    # optional
ENV['RABBITMQ_PASSWORD'] = 'guest'    # optional

# Or programmatically
amqp_config = {
  url: 'amqp://localhost:5672',
  username: 'agent99',
  password: 'secret',
  vhost: '/',
  timeout: 30,
  heartbeat: 30
}

client = Agent99::MessageClients::AmqpClient.new(amqp_config)
```

### Connection Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url` | String | `amqp://localhost:5672` | RabbitMQ connection URL |
| `username` | String | `guest` | Authentication username |
| `password` | String | `guest` | Authentication password |
| `vhost` | String | `/` | Virtual host |
| `timeout` | Integer | 30 | Connection timeout (seconds) |
| `heartbeat` | Integer | 30 | Heartbeat interval (seconds) |
| `exchange` | String | `agent99` | Default exchange name |
| `exchange_type` | String | `topic` | Exchange type |

### Exchange and Routing

```ruby
class AmqpAgent < Agent99::Base
  def initialize
    super(
      message_client: 'amqp',
      exchange: 'agent99.services',
      routing_key: 'services.calculator'
    )
  end

  def process_request(payload)
    # AMQP-specific features
    routing_key = current_routing_key
    exchange = current_exchange
    
    logger.info "Message from: #{routing_key} on #{exchange}"
    
    # Can publish to specific routing keys
    publish_to_routing_key('notifications.processed', {
      agent: info[:name],
      processed_at: Time.now.iso8601
    })
    
    send_response(
      message: "Processed via AMQP",
      routing_key: routing_key
    )
  end
end
```

## TCP Client

### Configuration

The TCP client is primarily for testing and simple setups:

```ruby
# Environment variables
ENV['TCP_HOST'] = 'localhost'
ENV['TCP_PORT'] = '9999'

# Or programmatically
tcp_config = {
  host: 'localhost',
  port: 9999,
  timeout: 30
}

client = Agent99::MessageClients::TcpClient.new(tcp_config)
```

### Usage Example

```ruby
class TcpAgent < Agent99::Base
  def initialize
    super(message_client: 'tcp')
  end

  def process_request(payload)
    client_address = current_client_address
    
    logger.info "Request from: #{client_address}"
    
    send_response(
      message: "Processed via TCP",
      client: client_address
    )
  end
end
```

## Message Client API

### Common Interface

All message clients implement a common interface:

```ruby
class MessageClientBase
  def initialize(config = {})
    # Initialize connection with config
  end

  def connect
    # Establish connection to message broker
  end

  def disconnect
    # Close connection
  end

  def subscribe(subject, &block)
    # Subscribe to messages on subject/queue
  end

  def publish(subject, message, options = {})
    # Publish message to subject/exchange
  end

  def request(subject, message, options = {})
    # Send request and wait for response
  end

  def connected?
    # Check connection status
  end
end
```

### Connection Management

```ruby
# Check connection status
if client.connected?
  logger.info "Connected to message broker"
else
  logger.warn "Not connected, attempting reconnect..."
  client.connect
end

# Graceful shutdown
Signal.trap('TERM') do
  logger.info "Shutting down..."
  client.disconnect
  exit
end
```

### Error Handling

```ruby
begin
  response = client.request('service.calculate', payload, timeout: 10)
rescue Agent99::MessageClient::TimeoutError
  logger.error "Request timed out"
rescue Agent99::MessageClient::ConnectionError => e
  logger.error "Connection failed: #{e.message}"
  # Attempt reconnection
  client.connect
rescue Agent99::MessageClient::Error => e
  logger.error "Message client error: #{e.message}"
end
```

## Advanced Features

### Message Filtering

```ruby
# NATS subject filtering
client.subscribe('services.calculator.*') do |message|
  # Receives: services.calculator.add, services.calculator.multiply, etc.
end

# AMQP routing key patterns
client.subscribe('services.#') do |message|
  # Receives all messages starting with 'services.'
end
```

### Message Persistence

```ruby
# AMQP persistent messages
client.publish('important.task', payload, persistent: true)

# NATS with JetStream persistence (if available)
client.publish('stream.data', payload, stream: 'EVENTS')
```

### Load Balancing

```ruby
# NATS queue groups for load balancing
client.subscribe('work.queue', queue: 'workers') do |message|
  # Multiple subscribers share the work
end

# AMQP work queues
client.subscribe('task.queue', durable: true, ack: true) do |message|
  process_task(message)
  message.ack # Acknowledge completion
end
```

## Performance Considerations

### Connection Pooling

```ruby
class PooledMessageClient
  def initialize(config = {})
    @pool_size = config[:pool_size] || 10
    @pool = ConnectionPool.new(size: @pool_size) do
      Agent99::MessageClients::NatsClient.new(config)
    end
  end

  def with_connection(&block)
    @pool.with(&block)
  end
end
```

### Batching

```ruby
# Batch messages for better performance
messages = []
(1..100).each do |i|
  messages << { id: i, data: "message #{i}" }
end

# Send in batches
messages.each_slice(10) do |batch|
  batch.each { |msg| client.publish('batch.data', msg) }
  sleep(0.1) # Rate limiting
end
```

### Monitoring

```ruby
class MonitoredClient
  def initialize(base_client)
    @client = base_client
    @metrics = {
      messages_sent: 0,
      messages_received: 0,
      errors: 0
    }
  end

  def publish(subject, message, options = {})
    start_time = Time.now
    
    begin
      @client.publish(subject, message, options)
      @metrics[:messages_sent] += 1
    rescue => e
      @metrics[:errors] += 1
      raise
    ensure
      duration = Time.now - start_time
      logger.debug "Published to #{subject} in #{duration}s"
    end
  end

  def stats
    @metrics.dup
  end
end
```

## Testing Message Clients

### Mock Client for Testing

```ruby
class MockMessageClient
  def initialize
    @messages = []
    @subscriptions = {}
  end

  def publish(subject, message, options = {})
    @messages << {
      subject: subject,
      message: message,
      options: options,
      timestamp: Time.now
    }
    
    # Trigger subscriptions
    @subscriptions[subject]&.each { |block| block.call(message) }
  end

  def subscribe(subject, &block)
    @subscriptions[subject] ||= []
    @subscriptions[subject] << block
  end

  def published_messages
    @messages
  end

  def clear_messages
    @messages.clear
  end
end
```

### Integration Testing

```ruby
require 'minitest/autorun'

class TestMessageClientIntegration < Minitest::Test
  def setup
    @client = Agent99::MessageClients::NatsClient.new
    @client.connect
  end

  def teardown
    @client.disconnect
  end

  def test_request_response
    # Start a responder
    response_thread = Thread.new do
      @client.subscribe('test.echo') do |message|
        @client.publish(message.reply, { echo: message.data })
      end
    end

    # Send request
    response = @client.request('test.echo', { text: 'hello' })
    
    assert_equal 'hello', response[:echo][:text]
    
    response_thread.kill
  end
end
```

## Configuration Examples

### Production NATS Cluster

```yaml
# config/nats.yml
production:
  servers:
    - nats://nats1.example.com:4222
    - nats://nats2.example.com:4222
    - nats://nats3.example.com:4222
  username: <%= ENV['NATS_USERNAME'] %>
  password: <%= ENV['NATS_PASSWORD'] %>
  tls:
    cert_file: /etc/ssl/certs/client.crt
    key_file: /etc/ssl/private/client.key
    ca_file: /etc/ssl/certs/ca.crt
```

### Production RabbitMQ

```yaml
# config/rabbitmq.yml
production:
  url: <%= ENV['RABBITMQ_URL'] %>
  heartbeat: 30
  connection_timeout: 10
  read_timeout: 30
  write_timeout: 30
  ssl:
    enabled: true
    verify: true
    cert_path: /etc/ssl/certs/client.pem
    key_path: /etc/ssl/private/client.key
```

## Next Steps

- **[Agent99::Base](agent99-base.md)** - Core agent class reference
- **[Registry Client](registry-client.md)** - Registry service API
- **[Configuration](../operations/configuration.md)** - Detailed configuration options