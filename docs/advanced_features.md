# Agent99 Framework

## Advanced Features

Ruby supports dynamic loading and deployment of libraries at runtime.  Agent99 takes advantage of this ability through the `AgentWatcher` system. This powerful feature allows you to:

- Monitor a directory for new agent files
- Automatically load and instantiate new agents when detected
- Run multiple agents within the same process
- Manage agent lifecycle independently

### Using AgentWatcher

The `AgentWatcher` (found in `examples/agent_watcher.rb`) provides a framework for dynamically loading and running agents:

1. Start the AgentWatcher:
```ruby
watcher = AgentWatcher.new
watcher.run
```

2. Deploy new agents by copying their .rb files to the watched directory (default: './agents'):
```bash
cp my_new_agent.rb agents/
```

The AgentWatcher will:
- Detect the new file
- Load the agent class
- Instantiate the agent
- Run it in a separate thread

### Example Implementation

```ruby
class MyDynamicAgent < Agent99::Base  
  def info
    {
      # ...
      type:         :server,
      capabilities: ['my_capability'],
      # ...
    }
  end
  
  def receive_request
    # Handle requests
    send_response(status: 'success')
  end
end
```

## Multi-Agent Processing

Agent99 supports running multiple agents within the same process, with each agent running in its own thread. This approach:

- Reduces resource overhead compared to separate processes
- Maintains isolation between agents
- Allows efficient inter-agent communication
- Simplifies agent management

### Benefits

1. **Resource Efficiency**: Share common resources while maintaining agent isolation
2. **Simplified Deployment**: Manage multiple agents through a single process
3. **Enhanced Communication**: Direct inter-agent communication within the same process
4. **Centralized Management**: Monitor and control multiple agents from a single point

### Implementation Considerations

When running multiple agents in the same process:

1. Each agent runs in its own thread for isolation
2. Agents can still communicate through the standard messaging system
3. Errors in one agent won't affect others
4. Resource sharing is handled automatically by the framework

### Example Setup

Using AgentWatcher to manage multiple agents:

```ruby
# Start the watcher
watcher = AgentWatcher.new
watcher.run

# Deploy multiple agents
cp agent1.rb agents/
cp agent2.rb agents/
cp agent3.rb agents/
```

Each agent will run independently in its own thread while sharing the same process space.

## Best Practices

1. **Error Handling**
    - Implement proper error handling in each agent
    - Use the built-in logging system
    - Monitor agent health through status checks

2. **Resource Management**
    - Monitor memory usage when running many agents
    - Implement proper cleanup in the `fini` method
    - Use appropriate thread pool sizes

3. **Deployment**
    - Use meaningful file names for easy identification
    - Maintain clear separation of concerns between agents
    - Document agent dependencies and requirements

4. **Monitoring**
    - Implement health checks in your agents
    - Use logging for debugging and monitoring
    - Set up appropriate alerting for critical agents
