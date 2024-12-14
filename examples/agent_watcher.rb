#!/usr/bin/env ruby
# examples/agent_watcher.rb
#
# This file defines an AgentWatcher class that monitors a specified directory
# for new Ruby files and dynamically loads and runs them as agents.

# When running, the AgentWatcher does the following:
# 1. Watches the directory specified by AGENT_WATCH_PATH (default: './agents')
# 2. Detects when new .rb files are added to the watched directory
# 3. Attempts to load each new file as a Ruby agent
# 4. If successful, instantiates the agent and runs it in a separate thread
#
# When example_agent.rb is copied into the agents directory:
# 1. The AgentWatcher detects the new file
# 2. It attempts to load the file and extract the agent class
# 3. If the class is a subclass of Agent99::Base, it instantiates the agent
# 4. The new agent is then run in a separate thread
# 5. Any errors during this process are logged for debugging
#
# When AgentWatcher is terminated, it first terminates all of the
# agents that it has previously loaded and then terminates itself.


require 'listen'

require_relative '../lib/agent99'

class AgentWatcher < Agent99::Base
  TYPE = :client

  def capabilities = {
    info: {
      capabilities: %w[ launch_agents watcher launcher ]
    }
  }

  def init
    @watch_path = ENV.fetch('AGENT_WATCH_PATH', './agents')
    setup_watcher
  end

  private

  def setup_watcher
    @listener = Listen.to(@watch_path) do |modified, added, removed|
      added.each do |file|
        handle_new_agent(file)
      end
    end
    
    # Start listening in a separate thread
    @listener.start
  end

  def handle_new_agent(file)
    return unless File.extname(file) == '.rb'
    
    begin
      # Load the new agent file
      require file
      
      # Extract the class name from the file name
      class_name = File.basename(file, '.rb')
                      .split('_')
                      .map(&:capitalize)
                      .join
      
      # Get the class object
      agent_class = Object.const_get(class_name)
      
      # Verify it's an Agent99::Base subclass
      return unless agent_class < Agent99::Base
      
      # Create and run the new agent in a thread
      Thread.new do
        begin
          agent = agent_class.new
          agent.run
        rescue StandardError => e
          logger.error "Error running agent #{class_name}: #{e.message}"
          logger.debug e.backtrace.join("\n")
        end
      end
      
      logger.info "Successfully launched agent: #{class_name}"
    
    rescue LoadError => e
      logger.error "Failed to load agent file #{file}: #{e.message}"
    
    rescue NameError => e
      logger.error "Failed to instantiate agent class from #{file}: #{e.message}"
    
    rescue StandardError => e
      logger.error "Unexpected error handling #{file}: #{e.message}"
      logger.debug e.backtrace.join("\n")
    end
  end

  def fini
    @listener&.stop
    super
  end
end

watcher = AgentWatcher.new
watcher.run
