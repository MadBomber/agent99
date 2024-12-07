# Agent99 Framework

## Agent Discovery

Agents can easily discover each other based on their declared capabilities. Here’s how the process works:

1. Agents register their capabilities with the central registry upon startup.
2. When an agent needs to discover others, it queries the registry for agents with specific capabilities.
3. The registry responds with a list of available agents, allowing for dynamic interaction based on capabilities.
