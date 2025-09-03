# Agent99 Framework Examples - 86 and the Chief

FYI ... I am in the process of extracting this examples directory out into its own repository:  [MadBomber/agent99_examples](https://github.com/MadBomber/agent99_examples)

This folder contains example implementations using the Agent99 framework. The framework provides a foundation for building AI agents that can communicate with each other through a message-based system.

## Files

### 1. maxwell_agent86.rb

This file demonstrates a basic agent implementation using the Agent99 framework.

- Class: `MaxwellAgent86 < Agent99::Base`
- Functionality: Responds to "hello world" requests
- Key methods:
  - `receive_request`: Handles incoming requests
  - `validate_request`: Validates the request against a schema
  - `process`: Generates the response

### 2. chief_agent.rb

This file shows how to create a client that interacts with the MaxwellAgent86 agent.

- Class: `ChiefAgent < Agent99::Base`
- Functionality: Sends a request to an agent who can be a greeter and processes the response
- Key methods:
  - `init`: Initiates the request sending process
  - `send_request`: Builds and sends the request
  - `receive_response`: Handles the response from the HelloWorld agent

### 3. mexwell_request.rb

This file defines the schema for MaxwellAgent86 requests using SimpleJsonSchemaBuilder.

- Class: `MaxwellRequest < SimpleJsonSchemaBuilder::Base`
- Defines the structure of a valid HelloWorld request

### 4. registry.rb

This file implements a simple registry service for AI agents using Sinatra.

- Functionality: Allows agents to register, discover other agents, and withdraw from the registry
- Endpoints:
  - GET `/healthcheck`: Returns the number of registered agents
  - POST `/register`: Registers a new agent
  - GET `/discover`: Discovers agents by capability
  - DELETE `/withdraw/:uuid`: Withdraws an agent from the registry
  - GET `/`: Lists all registered agents

### 5. control_agent.rb

Example use of control messages.

### 6. kaos_spy.rb
  - Agent 99 was kinnapped by KAOS and forced to reveal the secrets of Control's centralized registry and communications network.
  - The KAOS spy raided hacked the registry, stole the records for all of Control's agents in the field and DOX'ed them on social media.
  - That was not enough for KAOS.  Knowing the secret UUID for each agent, KAOS proceeded to turn off the communication network one queue at a time.
  - Get Smart -- Get Security

### 7. agent_watcher.rb

This file implements an agent watcher that dynamically loads and runs new agents.

- Class: `AgentWatcher < Agent99::Base`
- Functionality: Monitors a specified directory for new Ruby files and loads them as agents
- Key features:
  - Watches a configurable directory (default: './agents')
  - Detects new .rb files added to the watched directory
  - Dynamically loads new files as Ruby agents
  - Instantiates and runs each new agent in a separate thread
  - Handles errors during the loading and running process
  - Terminates all loaded agents when the watcher is stopped
- Key methods:
  - `init`: Sets up the file watcher
  - `setup_watcher`: Configures the directory listener
  - `handle_new_agent`: Processes newly detected agent files

### 8. example_agent.rb

This file provides a simple example agent that can be dynamically loaded by the AgentWatcher.

- Class: `ExampleAgent < Agent99::Base`
- Functionality: Demonstrates a basic agent that can be dynamically loaded
- Key features:
  - Defines capabilities as a rubber stamp and yes-man
  - Responds to all requests with a success status
- Key methods:
  - `capabilities`: Defines the agent's capabilities
  - `receive_request`: Handles incoming requests and sends a response

Note: To use the example_agent.rb, first run the AgentWatcher, then copy example_agent.rb into the 'agents' directory. The AgentWatcher will automatically detect, load, and run the new agent.

## Usage

There are two ways to run the Agent99 examples:

### 🚀 Automated Demo Runner (Recommended)

The easiest way to run examples is with the comprehensive demo runner:

```bash
./run_demo.rb --list                    # List all available scenarios
./run_demo.rb                          # Run default 'basic' scenario  
./run_demo.rb -s basic                  # Basic Maxwell/Chief interaction
./run_demo.rb -s control                # Control agent demonstration  
./run_demo.rb -s watcher                # Dynamic agent loading demo
./run_demo.rb -s security               # Security demonstration (KAOS spy)
./run_demo.rb -s all                    # Run multiple scenarios in sequence
./run_demo.rb -v -s basic               # Verbose output
./run_demo.rb --help                    # Show all options
```

The demo runner automatically:
- ✅ Checks dependencies (RabbitMQ, boxes command, etc.)
- 🏗️ Starts infrastructure (registry service, RabbitMQ if available)
- 🎬 Orchestrates multiple agents with proper timing
- 🧹 Handles cleanup on exit or interrupt
- 📊 Provides progress feedback and duration estimates

**Available Scenarios:**
- **basic** (~10s): Maxwell Agent86 and Chief interaction
- **control** (~15s): Control agent managing other agents  
- **watcher** (~20s): Agent watcher dynamically loading new agents
- **security** (~10s): KAOS spy demonstration (educational security example)
- **all** (~60s): Run multiple scenarios in sequence

### 📋 Manual Setup (Original Method)

From the examples directory you will need to start three different processes.  You will want to keep them all in the forgound so it would be best to start them in different terminal windows.

Start the sample registry first: `./registry.rb`

Then start the service agent: `./maxwell_agent86.rb`
Maxwell will will register itself, get its UUID and setup a message queue to which it will listen for its service requests.

Finally start the chief agent in charge: `./chief_agent.rb`
The Chief also registers itself but no other agent can give the Chief missions.  That's his job.  The chief gets his mission UUID, sets up a message queue to listen for the reports from the field after he sends out his request (aka order)

But first the Chief asks the registry for the UUIDs of all agents who can handle a "greeter" request.  The Chief selects one of those agents and sends the agent a greet request.  The Chief then waits for a response to the request.  When it comes in, the chiefs displays the response and terminates.

Run the chief a few times in a roll.  Some times the agent to whom the Chief issues his requests does not always respond the you would expect.

### 🔧 Optional Dependencies

For the best experience, install these optional dependencies:

```bash
# For message broker (recommended)
brew install rabbitmq-server

# For enhanced chief agent output
brew install boxes
```

**Note:** The framework works without these dependencies using fallback implementations.

![Agent99 Framework Diagram](diagram.png)


