# Agent99 Framework

## Control Actions

Agent99 includes the following control actions:

- `shutdown`: Gracefully stop the agent and withdraw from the registry.
- `pause`: Temporarily halt the agent's activity without unregistering it.
- `resume`: Reactivate a paused agent.

Custom control actions can also be implemented by defining additional methods in the agent class, following the existing control action pattern.
