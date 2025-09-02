# Agent99 Framework API Reference

## Agent Implementation Requirements

When creating a new agent by subclassing `Agent99::Base`, you must implement certain methods and may optionally override others.

### Required Methods

#### `info`
 The `info` method provides a comprehensive information packet about the agent. It returns a hash containing key details that are crucial for agent registration and discovery within the system.
```ruby
def info
  {
    name:             self.class.to_s,
    type:             :server,
    capabilities:     %w[ greeter hello_world hello-world hello],
    request_schema:   MaxwellRequest.schema,
    # response_schema:  {}, # Agent99::RESPONSE.schema
    # control_schema:   {}, # Agent99::CONTROL.schema
    # error_schema:     {}, # Agent99::ERROR.schema
  }
end
```

Entries for **:name** and **:capabilities** are required.  Other entries are optional.  This entire info packet is stored by the central registry and provided to other agents on a discover "hit" so that the inquiring agents know all the target agent is willing to tell them.

#### `receive_request`
Handles incoming request messages. Must be implemented if the agent accepts requests.
```ruby
def receive_request
  # Process the request message in @payload
  # Access message data via @payload[:data]
  # Send response using send_response(response_data)
end
```

### Optional Methods

#### `init`
Called after registration but before message processing begins. Use for additional setup.
```ruby
def init
  @state = initialize_state
  @resources = setup_resources
end
```

#### `fini`
Called during shutdown. Override to add custom cleanup.
```ruby
def fini
  cleanup_resources
  save_state if @state
  super  # Always call super last
end
```

#### `receive_response`
Handles incoming response messages. Override if the agent processes responses.
```ruby
def receive_response
  # Process the response message in @payload
end
```

## Message Client Interface

To implement a custom message client, create a class that implements these methods:

### Required Methods

#### `initialize(logger: Logger.new($stdout))`
Sets up the messaging connection.

#### `setup(agent_id:, logger:)`
Initializes message queues/topics for the agent.
- Returns: queue/topic identifier

#### `listen_for_messages(queue, request_handler:, response_handler:, control_handler:)`
Starts listening for messages.
- `queue`: Queue/topic to listen on
- `request_handler`: Lambda for handling requests
- `response_handler`: Lambda for handling responses
- `control_handler`: Lambda for handling control messages

#### `publish(message)`
Publishes a message.
- `message`: Hash containing the message with :header and payload
- Returns: Hash with :success and optional :error

#### `delete_queue(queue_name)`
Cleans up agent's message queue/topic.

## Registry Client Interface

To implement a custom registry client, create a class that implements these methods:

### Required Methods

#### `initialize(base_url: ENV.fetch('REGISTRY_BASE_URL', 'http://localhost:4567'), logger: Logger.new($stdout))`
Sets up the registry connection.

#### `register(name:, capabilities:)`
Registers an agent with the registry.
- Returns: UUID string for the agent

#### `withdraw(id)`
Removes an agent from the registry.

## Base Class Public Methods

The `Agent99::Base` class provides these public methods:

#### `run`
Starts the agent's message processing loop.

#### `discover_agent(capability:, how_many: 1, all: false)`
Finds other agents by capability.
- Returns: Array of agent information hashes

#### `send_response(response)`
Sends a response message.
- `response`: Hash containing the response data

## Message Types

Messages in Agent99 must include a `:header` with:
- `:type`: One of "request", "response", or "control"
- `:to_uuid`: Destination agent's UUID
- `:from_uuid`: Sending agent's UUID
- `:event_uuid`: UUID to link request to response
- `:timestamp`: Integer (`Agent99::Timestamp.new.to_i`)

Example request message structure:
```ruby
{
  header: {
    type:       'request',
    to_uuid:    ,
    from_uuid:  ,
    event_uuid: ,
    timestamp:  ,
  },
  # agent specific parameters
}
```
