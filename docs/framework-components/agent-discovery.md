# Agent99 Framework

## Agent Discovery

Agents within the Agent99 Framework can efficiently discover one another based on their declared capabilities. This feature fosters dynamic interactions that enhance the collaborative functionality of the agents.

### Overview

The agent discovery process involves the following steps:

1. **Registration**: Agents register their capabilities with a central registry upon startup.
2. **Discovery**: When an agent needs to discover other agents, it queries the registry for agents with specific capabilities.
3. **Response**: The registry responds with a list of available agents, allowing them to interact based on their capabilities.

### Declaring Capabilities in the Info Method

Each agent must implement the `info` method to declare its capabilities as an array of strings:

```ruby
def info
  {
    # ...
    capabilities:  ['process_image', 'face_detection'],
    # ...
  }
end
```

**Note**: The discovery mechanism is based on an exact match (case insensitive) between the requested capability and the entries in the agent's capabilities array in its information packet. For example, if an agent declares its capabilities as mentioned above, a discovery request for `'FACE_DETECTION'` will successfully match.

### Discovery API

To find other agents, use the `discover_agent` method. Here are some usage examples:

```ruby
# Find a single agent with a specific capability
agent = discover_agent(capability: 'face_detection')

# Find multiple agents 
agents = discover_agent(capability: 'process_image', how_many: 3)

# Find all agents with a specific capability
all_agents = discover_agent(capability: 'process_image', all: true)
```

### Important Note on Capabilities

- **Single Capability**: A seeking agent can only request one kind of capability at a time.
- **Semantics-Based Capabilities**: The development roadmap includes enhancements towards semantic-based capabilities that could allow for more complex interactions between agents in the future.  This would be a change from the current Array of Strings to a single String that is a description of the services the agent provides.  This would be consistent with the way in which LLMs currently find Tools for augmented generation.

### Registry Configuration

The registry client comes with default settings, which you can override as needed:

- **URL**: Default is `http://localhost:4567` (you can override this using the `REGISTRY_BASE_URL` environment variable).
- **Interface**: Supports a standard HTTP REST interface.
- **Reconnection**: Automatic reconnection handling is provided to ensure reliable communication.

### Best Practices

1. **Check Discovery Success**: Always verify if agent discovery succeeded before attempting to establish communication with the discovered agent.
2. **Use Specific Capability Names**: This ensures that the correct agents are matched during the discovery process, avoiding ambiguity.
3. **Implement Multiple Capabilities**: Consider declaring multiple capabilities per agent to enhance its versatility and improve interaction possibilities.

With these guidelines, you can effectively implement and utilize the agent discovery feature within the Agent99 Framework, ensuring robust and dynamic interactions among agents based on their declared capabilities.

