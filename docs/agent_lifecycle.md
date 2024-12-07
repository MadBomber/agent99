# Agent99 Framework

## Agent Lifecycle

The lifecycle of an agent within Agent99 consists of several stages:

1. **Creation**: An agent is instantiated through the `Agent99::Base` class.
   
2. **Initialization**: The agent performs any necessary startup tasks, such as registering with the registry service and setting up message handlers.

3. **Running**: The agent enters an active state, where it listens for incoming messages, processes requests, and sends responses.

4. **Shutdown**: The agent can gracefully withdraw from the registry and clean up resources.

During the initialization phase, agents must register their capabilities with the registry. Withdrawal from the registry is also supported, allowing for a clean shutdown in case the agent is no longer needed.
