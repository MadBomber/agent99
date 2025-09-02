# Agent99 Framework

## Schema Definition

Agent99 uses `SimpleJsonSchemaBuilder` for defining message schemas. This gem was chosen for its Ruby-like DSL that makes schema definitions readable and maintainable, while still producing JSON Schema compatible output.

### Header Schema

All messages in Agent99 must include a header that conforms to this schema:

```ruby
class Agent99::HeaderSchema < SimpleJsonSchemaBuilder::Base
  object do
    string :type,       required: true, 
                          enum: %w[request response control]
    string  :to_uuid,   required: true
    string  :from_uuid, required: true
    string  :event_uuid,required: true
    integer :timestamp, required: true
  end
end
```

### Request Schema Example

Define your agent's request schema by inheriting from SimpleJsonSchemaBuilder::Base:

```ruby
class MyAgentRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    string :greeting, required: false,  examples: ["Hello"]
    string :name,     required: true,   examples: ["World"]
  end
end
```

In this example, the agent has two parameters that it uses from the request message: greeting and name; however, greeting is not required.  **The Agent99 framework will use the first item in the examples array as a default for optional parameters.**

### Automatic Schema Validation

Agent99 automatically validates incoming request messages against your agent's REQUEST_SCHEMA:

1. When a request arrives, the framework checks if your agent class defines REQUEST_SCHEMA
2. If defined, the message is validated before reaching your receive_request method
3. If validation fails:
   - An error response is automatically sent back to the requester
   - Your receive_request method is not called
   - The validation errors are logged

Example validation error response:

```ruby
{
  header: {
    type:       'error',
    to_uuid:    original_from_uuid,
    from_uuid:  agent_id,
    event_uuid: original_event_uuid,
    timestamp:  current_timestamp
  },
  errors: ['Required property "name" not found in request']
}
```

### Why SimpleJsonSchemaBuilder?

SimpleJsonSchemaBuilder was chosen for Agent99 because it:

1. Provides a Ruby-native DSL for schema definition
2. Generates standard JSON Schema output
3. Supports schema composition and reuse
4. Includes built-in validation
5. Has excellent performance characteristics
6. Maintains type safety through static analysis

The gem allows us to define schemas that are both human-readable and machine-validatable, while staying within the Ruby ecosystem.

