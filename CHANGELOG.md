# The Changelog

## [Unreleased]

#### Fixed
- `Agent99::RegistryClient` now configures its HTTP client from the full registry URL, honoring the URL's scheme and path: a base URL like `http://host:8080/registry` sends requests under `/registry`
- Fixed `Agent99::AmqpMessageClient#setup` ignoring its `logger:` after one line; the client now keeps that logger for later receive, publish, and queue logging, as the NATS client does (#20)
- Fixed `Agent99::Timestamp.ts2utc` decoding timestamps ~2.6 years early with garbled sub-second values; it now inverts `utc2ts` exactly, and `Timestamp.new(time)` no longer converts the caller's Time to UTC in place (#4)
- Removed stray notes after `__END__` in `tcp_message_client.rb` (a pasted analysis) and `header_schema.rb` (a stale schema line); nothing read them
- `test/agent99/test_base.rb` now checks method names and visibility on `Agent99::Base` and `Agent99::HeaderManagement` instead of the test double, which defines public methods Base does not have
- **[BREAKING FIX]** `require "agent99"` no longer fails on a clean install: the development-only `debug_me` gem is no longer required and `DebugMe` is no longer mixed into `Object` (#3)
  - Code that called `debug_me` without requiring it, relying on agent99 to mix it in, must now `require "debug_me"` and `include DebugMe` itself
- Fixed a remote `shutdown` control message running `fini` twice and logging a false "fini called with a nil id" warning, and leaving a NATS agent running because the exit was swallowed on the nats-pure handler thread; `handle_shutdown` now exits through the main thread and leaves cleanup to the `at_exit` hook
- Gem package now ships only lib, sig, examples, README, CHANGELOG, and LICENSE (about 1.5 MB down to 80 KB); added `documentation_uri` metadata (#5)
- Fixed the example registry (`examples/registry.rb`) returning 500 on `POST /register` under Rack 3, where the request body cannot be rewound; it no longer calls `request.body.rewind`, and it no longer requires the development-only `debug_me` gem, which it never used (#23)
- Removed the class-body `rescue` at the end of `Agent99::Base`; it only covered load-time evaluation of the class, would have raised `NoMethodError` if it ever ran, and made `ruby -w` warn about mismatched indentation (#8)
- Fixed `Agent99::NatsMessageClient.new` raising `NoMethodError` instead of the NATS connection error when the NATS server is unreachable; the logger is now set before connecting, so the failure is logged and re-raised as intended (#6)
- Fixed `Agent99::NatsMessageClient.new` when no NATS server can be reached: it raised `NoMethodError` (logger not yet set) or let the raw socket error escape unlogged; it now logs the failure and raises the intended "NATS Connection Error" message, with the original error as its `cause` (#6)
- Fixed `Agent99::NatsMessageClient.new` when it cannot connect to NATS: it raised `NoMethodError` (logger not yet set) or let the raw socket error escape unlogged; any connect failure is now logged and raised as the intended "NATS Connection Error" message, with the original error as its `cause` (#6)
- `require "agent99"` now loads `Agent99::VERSION` and `Agent99::HeaderSchema`; README step 1 raised `NameError` without an extra require (#15, #21)
- Fixed `examples/maxwell_agent86.rb#receive_response`: it took an argument the framework never passes, called `loger`, and logged the literal text `response.inspect` (#22)
- Fixed `examples/control.rb` raising `TypeError` on pause, resume, shutdown, and update_config acknowledgements, whose `data` is a String rather than a Hash (#16)
- Fixed an agent that failed to register carrying on with a `nil` id and an unaddressable queue while logging that it had registered; it now logs the failure and exits with status 1 (#19)
- Fixed the header helpers (`header`, `from_uuid`, `to_uuid`, ...) returning the previous request's header inside `receive_response` and `receive_control`, or raising `NoMethodError` before any request arrived; they now always read the current message (#18)
- Fixed `discover_agent` raising `NoMethodError` when the registry is unreachable or returns an error; it now logs and raises the documented "No agents available" `RuntimeError` (#35)
- Fixed `get(:field)` replacing an explicit `false` or `nil` in the request with the schema example; the default is now used only when the field is absent (#36)
- Fixed `get(:field)` raising `NameError` when the field is missing and the agent defines no `REQUEST_SCHEMA`; it now returns `nil` (a top-level `::REQUEST_SCHEMA` is ignored) (#14)


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
