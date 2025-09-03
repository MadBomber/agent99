# Agent99 Demo Runner

This is a comprehensive demo script that allows you to easily run and explore Agent99 framework examples.

## Quick Start

```bash
# List available demo scenarios
./run_demo.rb --list

# Run the basic demo (Maxwell Agent86 + Chief interaction)
./run_demo.rb

# Run with verbose output to see what's happening
./run_demo.rb -v -s basic
```

## Features

- 🏗️ **Automatic Infrastructure**: Starts registry service and RabbitMQ (if available)
- 🎬 **Orchestrated Execution**: Manages multiple agents with proper timing
- 🧹 **Clean Shutdown**: Handles Ctrl+C gracefully, cleaning up all processes
- 📊 **Progress Feedback**: Shows what's happening and estimated duration
- 🔍 **Dependency Checking**: Warns about missing optional dependencies
- 🎯 **Multiple Scenarios**: Choose from different demo configurations

## Available Scenarios

### Basic (`-s basic`) - Default, ~10 seconds
- **Maxwell Agent86**: Service agent that responds to "hello world" requests
- **Chief Agent**: Client agent that discovers agents and sends requests
- **Demonstrates**: Basic agent-to-agent communication, discovery, request/response

### Control (`-s control`) - ~15 seconds  
- **Maxwell Agent86**: Service agent
- **Control Agent**: Hybrid agent that manages other agents using control messages
- **Demonstrates**: Control message system, agent management, pause/resume functionality

### Watcher (`-s watcher`) - ~20 seconds
- **Agent Watcher**: Monitors directory for new agent files
- **Dynamic Loading**: Automatically loads and starts new agents
- **Demonstrates**: Runtime agent loading, file system monitoring

### Security (`-s security`) - ~10 seconds ⚠️ Educational Only
- **Maxwell Agent86**: Service agent  
- **KAOS Spy**: Malicious agent that demonstrates security vulnerabilities
- **Demonstrates**: Security considerations, agent registry vulnerabilities
- **Warning**: This shows attack patterns for educational purposes

### All (`-s all`) - ~60 seconds
- Runs multiple scenarios in sequence (skips security for safety)
- **Demonstrates**: Full framework capabilities

## Command Line Options

```bash
./run_demo.rb [options]

Options:
    -s, --scenario SCENARIO    Demo scenario to run (basic, control, watcher, security, all)
    -l, --list                 List available scenarios
    -v, --verbose              Show detailed output from agents
        --no-cleanup           Keep processes running (for debugging)
    -h, --help                 Show help message

Examples:
    ./run_demo.rb                    # Run basic demo with default settings
    ./run_demo.rb -s watcher -v      # Run watcher demo with verbose output
    ./run_demo.rb --list             # List all available scenarios
```

## What You'll See

The demo runner shows:

1. **🔍 Dependency Check**: Verifies required files exist, warns about optional dependencies
2. **🏗️ Infrastructure Startup**: Registry service and RabbitMQ (if available)  
3. **🎬 Scenario Execution**: Agents starting, registering, communicating
4. **📊 Progress Updates**: What's happening and time remaining
5. **🧹 Clean Shutdown**: All processes terminated gracefully

## Dependencies

### Required (Bundled)
- Ruby 3.0+
- Agent99 framework (in parent directory)
- Example agent files

### Optional (Enhanced Experience)
```bash
# Message broker for production-like messaging
brew install rabbitmq-server

# Enhanced output formatting for Chief agent
brew install boxes
```

**Note**: Demo works without optional dependencies using fallback implementations.

## Troubleshooting

### "Permission denied" error
```bash
chmod +x run_demo.rb
```

### "No agents available" error
- Check that registry service started successfully
- Try running with `-v` flag to see detailed logs
- Ensure no other processes are using port 4567

### RabbitMQ connection issues
- RabbitMQ is optional - demo works without it
- If installed but not starting: `brew services restart rabbitmq`
- Demo uses fallback message client if RabbitMQ unavailable

### Ctrl+C doesn't stop everything
- Demo has signal handlers for graceful shutdown
- If processes persist: `./run_demo.rb --no-cleanup` then manually kill
- Check for zombie processes: `ps aux | grep ruby`

## Architecture

The demo runner:

1. **Validates Environment**: Checks for required files and optional dependencies
2. **Starts Infrastructure**: Registry service (port 4567) and RabbitMQ if available
3. **Orchestrates Agents**: Starts agents in proper sequence with timing
4. **Monitors Execution**: Tracks agent processes and handles timeouts
5. **Cleanup**: Terminates all spawned processes on completion or interrupt

## Extending

To add new scenarios:

1. Edit `SCENARIOS` hash in `run_demo.rb`
2. Add agent files to `agents` array
3. Specify duration and any special handling
4. Update documentation

Example:
```ruby
'my_scenario' => {
  description: 'My custom agent demonstration',
  agents: ['my_agent1.rb', 'my_agent2.rb'],
  duration: 15
}
```