# Agent99 Framework

## Custom Agent Implementation

### Creating a Custom Agent

To create a custom agent:

1. Subclass `Agent99::Base`.
2. Define the request and response schemas.
3. Implement the `receive_request` and `receive_response` methods.

Example:

```ruby
class MyCustomAgent < Agent99::Base
  REQUEST_SCHEMA = MyAgentRequest.schema

  def receive_request
    # Handle incoming request
    response = { result: "Handled request" }
    send_response(response)
  end

  def receive_response
    # Handle incoming response from another agent
  end
end
```

