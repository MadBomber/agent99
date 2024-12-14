# Message Client Documentation for Agent99 Framework

## Overview

The Message Client is a crucial component of the Agent99 Framework, providing an interface for agents to communicate with each other through a message broker. This document outlines the required methods and functionalities that should be implemented in any message client to ensure compatibility with the Agent99 Framework.

## Message Format Requirements

All messages sent and received through the Agent99 Framework must adhere to the following format requirements:

1. **JSON Format**: All messages must be in JSON format. This ensures consistency and ease of parsing across different implementations and languages.

2. **Header Element**: Each message must include a `header` element that conforms to the `HeaderSchema` defined for the Agent99 Framework. The `HeaderSchema` is as follows:

```ruby
class Agent99::HeaderSchema < SimpleJsonSchemaBuilder::Base
  object do
    string  :from_uuid,   required: true, examples: [SecureRandom.uuid]
    string  :to_uuid,     required: true, examples: [SecureRandom.uuid]
    string  :event_uuid,  required: true, examples: [SecureRandom.uuid]
    string  :type,        required: true, examples: %w[request response control]
    integer :timestamp,   required: true, examples: [Agent99::Timestamp.new.to_i]
  end
end
```

3. **Message Types**: The `type` field in the header must be one of: `request`, `response`, or `control`.

4. **Validation**: All incoming messages are validated against the appropriate schema based on their type. If validation errors are found, an error response message is returned to the sender.

## Class: MessageClient

### Initialization

```ruby
def initialize(config: {}, logger: Logger.new($stdout))
  # Implementation details...
end
```

Creates a new instance of the MessageClient.

- `config:` A hash containing configuration options for the message broker connection.
- `logger:` A logger instance for output (default: stdout logger).

### Public Methods

#### setup

```ruby
def setup(agent_id:, logger:)
  # Implementation details...
end
```

Sets up the necessary resources for an agent to start communicating.

- `agent_id:` The unique identifier for the agent.
- `logger:` A logger instance for output.
- Returns: An object representing the agent's message queue or channel.

#### listen_for_messages

```ruby
def listen_for_messages(
  queue,
  request_handler:,
  response_handler:,
  control_handler:
)
  # Implementation details...
end
```

Starts listening for incoming messages on the specified queue.

- `queue:` The queue or channel object returned by the `setup` method.
- `request_handler:` A callable object to handle incoming request messages.
- `response_handler:` A callable object to handle incoming response messages.
- `control_handler:` A callable object to handle incoming control messages.

#### publish

```ruby
def publish(message:)
  # Implementation details...
end
```

Publishes a message to the specified queue.

- `message:` A hash containing the message to be published. This must be in JSON format and include a header that conforms to the `HeaderSchema`.
- Returns: A hash indicating the success or failure of the publish operation, including details if the message structure is invalid.

#### delete_queue

```ruby
def delete_queue(queue_name:)
  # Implementation details...
end
```

Deletes the specified queue or cleans up resources associated with it.

- `queue_name:` The name of the queue to be deleted.

### Implementation Notes

1. **Message Validation**: Implement thorough validation for all incoming and outgoing messages. Ensure that they are in JSON format and contain a header that conforms to the `HeaderSchema`. If validation fails for incoming messages, send an error response to the sender with details about the validation issues.

2. **Error Handling**: Implement robust error handling for all methods, especially for connection, publishing, and validation errors.

3. **Logging**: Provide detailed logging for all operations, including successful actions, validation results, and errors.

4. **Performance and Scalability**: Optimize the client to handle a large number of JSON-formatted messages efficiently, considering potential performance impacts of validation.

5. **Thread Safety**: Ensure that the client is thread-safe, particularly when handling message validation and publishing.

By adhering to these requirements and implementing the MessageClient with these considerations, developers can ensure that their implementations will be fully compatible with the Agent99 Framework. The strict adherence to JSON formatting and the inclusion of a standardized header in all messages promotes consistency and reliability in inter-agent communication within the framework.

