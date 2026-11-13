# The Changelog

## [Unreleased]

#### Fixed
- Fixed AMQP agent queues never expiring: `create_queue` passed `expires:`, which Bunny silently ignores; it now declares the RabbitMQ `x-expires` argument, and the messaging docs no longer claim messages survive a broker restart or carry a TTL (#76)
- An agent now replies `{error: "Unknown control action: <name>"}` to a control message whose action it has no handler for; it only logged a warning and sent nothing, leaving the controller waiting (#75)
- Fixed a dead "documentation" link in `docs/core-concepts/what-is-an-agent.md`; it pointed at a `docs/README.md` that no longer exists and now links to the docs home (#74)
- Getting-started and example docs now query the example registry at `/` and `/discover?capability=...`; they used `/agents` and `/agents/discover/...`, which return 404 (#73)
- Fixed `Agent99::NatsMessageClient#publish` raising `NameError` instead of returning an error result when the NATS publish failed; it rescued the nonexistent `NATS::IO::TimeoutError` (now `NATS::IO::Timeout`). Added tests for NATS publish, message dispatch and `delete_queue` (#72)
- `test/agent99/test_amqp_message_client.rb` now tests the real `Agent99::AmqpMessageClient` (publish and its error branches, message dispatch, queue creation and deletion) through a Bunny-free fake channel; most of its tests exercised only the test mock (#71)
- Fixed `examples/maxwell_request.rb` raising `NameError` when loaded on its own; it required only `header_schema`, which needs the rest of the library, and now requires `agent99` (#70)
- Fixed misspellings in the docs and `examples/start_rabbitmq_and_registry.sh`, including the `RegristryClient` and `@agnet_1` identifiers in agent-registry code samples (#68)
- Fixed docs code samples that did not parse (the agent-registry irb walkthrough, an unclosed class in what-is-an-agent, shell lines in a Ruby fence), replaced the nonexistent `on_exit` hook with `at_exit`, and dropped a call to the nonexistent `deregister_from_registry` from the `fini` example (#67)
- Corrected the method signatures in `docs/agent99_framework/`: `register(info:)`, positional `publish(message)` and `delete_queue(queue_name)`, and a message client `initialize` that takes only `logger:` (AMQP also takes `config:`) (#66)
- Fixed `examples/run_demo.rb` generating watcher-demo agents with `require_relative '../lib/agent99'`, which from `examples/agents/` points at a missing `examples/lib/agent99`; it now uses `../../lib/agent99` (#65)
- Docs now name the registry URL variable `AGENT99_REGISTRY_URL`, which `RegistryClient` reads; four pages said `REGISTRY_BASE_URL`, which nothing reads (#64)
- Fixed `bin/console` raising `LoadError: cannot load such file -- irb` on Ruby 4.0+, where irb is a bundled gem; `irb` is now in the Gemfile (#63)
- Fixed the custom control action snippet in `docs/advanced-topics/control-actions.md`: bare `CONTROL_HANDLERS` raised `NameError` inside an agent class; it now uses `Agent99::CONTROL_HANDLERS` and notes that the table is shared by every agent in the process (#62)
- Agents may now define `info` and `init` as private methods: startup exited with "must implement the info method" for a private `info` and silently skipped a private `init`; an `info` hash with String keys now gets a "must use Symbol keys" error instead of a report that present keys are missing (#61)
- Added tests for the pause, resume, update_config and status control handlers and the handler-error reply; the suite's test agent replaced the library's control path, so none of them were exercised (#60)
- Docs no longer present 0.0.4 as the current version: the overview points at RubyGems and the CHANGELOG instead of a hard-coded number, and "Recent Updates" gains a 0.0.5 entry and the correct 0.0.4 date (#59)
- Removed a fixed `sleep 0.5` from the test suite's mock registry startup; the connect/retry loop already waits for the port, and the full suite drops from about 40 s to about 6 s (#58)
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
- Re-locked the development bundle (`Gemfile.lock`) so it installs on Ruby 4.0 and builds on Ruby 4.1: tocer 20.5, rbtree 0.4.7 / sorted_set 1.1.0, Bundler 4.0.23, plus `ruby` and `x86_64-linux` platforms (#7)
- Fixed `bin/test` reporting "All tests PASSED" and exiting 0 when a test file failed or crashed; it now counts failures from every file, counts a crashed file as an error, exits 1 on any failure, and only runs `test_*.rb` files outside `test/support` (#33)
- `test/agent99/test_gemspec.rb` now skips, with a message, when the source tree is not a git checkout (git archive, Download ZIP) instead of reporting four failures (#37)
- Fixed the test commands in `test/README.md`: they globbed `*_test.rb`, matched no files, and silently ran nothing; they now use the Rake test tasks, and the single-file commands add `-Itest` so `test_helper` loads (#34)
- Removed the `test_coverage` and `test_verbose` Rake tasks; they set environment variables nothing reads and ran the plain suite (#32)
- Fixed six README "Key Features" links that pointed at anchors that do not exist; they now go to the matching README section or `docs/` page (#31)
- Fixed `bin/console` requiring the old `ai_agent` name, which raised `LoadError`; it now requires `agent99` (#30)
- Declared `logger` as a runtime dependency; the library requires it, and on Ruby 4.0 it is a bundled gem that was only present through `sinatra` (#25)
- README Quick Start, `docs/getting-started/quick-start.md`, and `docs/getting-started/basic-example.md` now override the `receive_request` hook instead of the private `process_request` dispatcher, which left `payload` unset so the first agent could not respond (#24)
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
