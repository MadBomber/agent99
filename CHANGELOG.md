# The Changelog

## [Unreleased]


## Released

### [0.0.5] 2025-09-03

#### Added
- Comprehensive demo runner (`examples/run_demo.rb`) for Agent99 framework with multiple scenarios
- Agent2Agent (A2A) protocol specification and documentation
- Model Context Protocol (MCP) documentation
- Hierarchical Temporal Memory (HTM) simulation and documentation
- GitHub Actions workflow for documentation deployment
- SQLite-based registry implementation
- Bad agent example for testing and security demonstrations
- HTM simulation script using SQLite database

#### Changed
- Updated README.md for improved clarity and structural improvements
- Improved control command handling in Control agent example
- Enhanced examples with better error handling and user experience
- Updated Gemfile.lock to reflect dependency upgrades

#### Fixed
- **[BREAKING FIX]** Disabled broken JsonSchema validation to prevent runtime crashes
  - Schema validation now returns empty array instead of crashing with `NameError: uninitialized constant Agent99::MessageProcessing::JsonSchema`
  - Added TODO comment for future proper schema validation implementation
- Fixed RabbitMQ dependency check hanging in demo runner
  - Changed from `rabbitmq-server --help` to `which rabbitmq-server` for faster, non-blocking check
- Demo runner now properly handles infrastructure startup and cleanup

#### Removed
- Removed SQLite registry implementation (replaced with improved Sinatra-based registry)
- Removed debug statements from various components

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
