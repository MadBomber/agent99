# Agent99 Framework

## Messaging Systems

Agent99 supports both AMQP and NATS messaging systems, allowing you to choose the most appropriate messaging backend for your needs. The framework provides a consistent interface regardless of which messaging system you use.

### Supported Message Brokers

#### AMQP (RabbitMQ)
The AMQP implementation uses RabbitMQ as the message broker and provides:

- **Durability**: Messages can persist across broker restarts
- **Queue TTL**: Queues automatically expire after 60 seconds of inactivity
- **Automatic Reconnection**: Handles connection drops gracefully
- **Default Configuration**:
  ```ruby
  {
    host: "127.0.0.1",
    port: 5672,
    ssl: false,
    vhost: "/",
    user: "guest",
    pass: "guest",
    heartbeat: :server,
    frame_max: 131072,
    auth_mechanism: "PLAIN"
  }
  ```

#### NATS
The NATS implementation provides:

- **Lightweight**: Simple pub/sub with minimal overhead
- **Auto-Pruning**: Automatically cleans up unused subjects
- **High Performance**: Optimized for speed and throughput
- **Default Configuration**: Uses NATS default connection settings

### Choosing a Message Client

You can select your messaging backend when initializing an agent:

```ruby
# For AMQP
agent = MyAgent.new(message_client: Agent99::AmqpMessageClient.new)

# For NATS
agent = MyAgent.new(message_client: Agent99::NatsMessageClient.new)
```

Or configure it via environment variables:

TODO: Need to add this to the configuration class which is still TBD

```bash
# For AMQP
export MESSAGE_SYSTEM=amqp
export RABBITMQ_URL=amqp://guest:guest@localhost:5672

# For NATS
export MESSAGE_SYSTEM=nats
export NATS_URL=nats://localhost:4222
```

### Message Handling

Both implementations support these core operations:

1. **Queue Setup**:
   ```ruby
   queue = message_client.setup(agent_id: id, logger: logger)
   ```

2. **Message Publishing**:
   ```ruby
   message_client.publish({
     header: {
       type:        "request",
       to_uuid:     recipient_id,
       from_uuid:   sender_id,
       event_uuid:  event_id,
       timestamp:   Agent99::Timestamp.new.to_i
     },
     data: payload # or whatever for the agent.
   })
   ```

3. **Message Subscription**:
   ```ruby
   message_client.listen_for_messages(
     queue,
     request_handler:   ->(msg) { handle_request(msg) },
     response_handler:  ->(msg) { handle_response(msg) },
     control_handler:   ->(msg) { handle_control(msg) }
   )
   ```

### Key Differences

1. **Queue Management**:
   - AMQP: Explicit queue creation and deletion
   - NATS: Implicit subject-based routing

2. **Message Persistence**:
   - AMQP: Supports persistent messages and queues
   - NATS: Ephemeral messaging by default

3. **Error Handling**:
   - AMQP: Provides detailed connection and channel errors
   - NATS: Simplified error handling with auto-reconnect

### Best Practices

1. **Error Handling**: Always wrap message operations in begin/rescue blocks
2. **Logging**: Use the provided logger for debugging and monitoring
3. **Configuration**: Use environment variables for deployment flexibility
4. **Testing**: Test your agents with both messaging systems to ensure compatibility

### Monitoring

Both implementations provide logging for:
- Message publication success/failure
- Queue creation and deletion
- Connection status
- Error conditions

Use the logger to monitor your messaging system:
```ruby
message_client.logger.level = Logger::DEBUG  # For detailed logging
```
