# Agent99 Framework

## Agent Lifecycle

The lifecycle of an agent within Agent99 consists of several key stages that are managed through dedicated lifecycle methods. Understanding these stages and their corresponding methods is crucial for proper agent implementation.

### Lifecycle Stages

![Agent Lifecycle](../assets/images/agent-lifecycle.svg)

1. **Creation**: An agent is instantiated through the `Agent99::Base` class.
2. **Initialization**: The agent sets up resources and establishes connections.
3. **Running**: The agent processes messages and performs its designated tasks.
4. **Shutdown**: The agent performs cleanup and gracefully terminates.

### Core Lifecycle Methods

#### The `init` Method

The `init` method is called automatically after the agent has been registered but before it starts processing messages. Its primary purpose is to perform any additional setup required for the agent following the default initialization provided by the `Agent99::Base` class. This may include:

- Setting up initial state
- Establishing connections to other agents or resources
- Discovering dependencies or agents to communicate with
- Sending initial messages to specific agents

Here’s an example implementation:

```ruby
def init  
  @state      = initialize_state
  @resources  = setup_resources
end
```

#### Custom Initialization

Agents can choose to either use the default behavior provided by the `Agent99::Base` class or implement their own `initialize` method to customize the `logger`, `message_client`, and `registry_client` attributes. For instance:

1. **Using Defaults**: If you do not define an `initialize` method in your agent class, it will inherit the defaults:

```ruby
class MyAgent < Agent99::Base
  # Inherits default logger, message_client, and registry_client
end
```

2. **Customizing Initialization**: If you need custom initialization, you can ignore the `init` method and override the `initialize` method:

```ruby
class MyCustomAgent < Agent99::Base
  def initialize(
      registry_client:  CustomRegistryClient.new,
      message_client:   CustomMessageClient.new,
      logger:           Logger.new('custom_agent.log')
    )
    super  # Registers the Agent and setups its message queue

    # Additional state or resource initialization required
    # by the new agent
  end
end
```

In this case, the custom agent not need the `init` method to perform any additional setup.

#### The `fini` Method

The `fini` method is setup to be invoked when the `exit` method is called within `initialize` method by the `on_exit { fini }` hook.

The `fini` method ensures proper cleanup during agent shutdown:

The default `fini` method does:
- Withdrawing from the registry
- Closing message queue connections

If your agent requires additional cleanup or state presistence you should implement a custom `fini` method to do things like:
- Cleaning up resources
- Saving state (if required)
- Releasing system resources

Example implementation:

```ruby
def fini
  save_state if @state
  cleanup_resources
  deregister_from_registry
  
  super  # Always call super last for proper framework cleanup
end
```

### Best Practices

1. **Proper Method Ordering**:
   - Always call `super` first in `initialize`.
   - Always call `super` last in `fini`.
   - This order ensures proper framework initialization and cleanup.

2. **Resource Management**:
   - Initialize all resources in `init` or `initialize`.
   - Clean up all resources in `fini`.
   - Handle cleanup idempotently.

3. **Error Handling**:
   - Implement robust error handling in all methods.
   - Ensure `fini` can handle partial initialization states.
   - Log all significant lifecycle events.

4. **State Management**:
   - Initialize state clearly.
   - Save or cleanup state properly in `fini`.
   - Consider persistence needs.

### Important Considerations

- Agents can be implemented as stand-alone processes.
- When an agent is implemented within the context of a larger application process, the agent should be "run" within its own thread.
    ```ruby
    begin
      my_agent = MyAgent.new
      Thread.new { my_agent.run }
    end
    ```
- Agents handle only one request message at a time.
- The `fini` method is called automatically during graceful shutdowns.

### Framework Integration

The Agent99 framework automatically manages the lifecycle of agents:

1. Calls `init` (if present) after agent creation.
2. Monitors agent health during operation.
3. Calls `fini` during shutdown (`on_exit {fini}`).
4. Handles cleanup if initialization fails.

This automated lifecycle management ensures reliable agent operation within the framework.

