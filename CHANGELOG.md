# The Changelog

## [Unreleased]

### extract examples into their own repo
- MadBomber/agent99_examples has/will have two to main directories named `simple` and `smarter` where the simple has the Sinatra app as a registry and simple agents that illustrate the use of the AMQP message broker for request, respose and control messages.
- The `smarter` directory will use a rails v8 application with postgresql and LLM access to implement the centra registry along with smarter agents that run in seperate processes as well as the rails process.

## Released

### [0.0.4] 2024-12-14

- This is a [breaking change](docs/breaking_change_v0.0.4.md)
- Replaced the capabilities method with the info method so that lots of stuff can be incorporated into an agent's information packet maintained by the registry.



### [0.0.3] - 2024-12-08

- Document advanced features and update examples
- Add AgentWatcher and ExampleAgent implementations
- Update control actions documentation for Agent99
- Add request flow diagram and update messaging docs
- Update schema documentation for improved clarity
- Reorganize documentation and update architecture details
- Update API reference with detailed implementation guidelines
- Extend agent lifecycle documentation
- Enhance agent discovery documentation and registry logic
- Add KaosSpy example agent
- Update README links to lowercase for consistency
- Add documentation for Agent99 framework
- Add Sinatra dependency and document registry processes

### [0.0.2] - 2024-12-07

- Added examples/control.rb
    - request status from all agents
    - other control messages not worked on yet

### [0.0.1] - 2024-11-28

- Initial release
