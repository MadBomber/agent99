# examples/agent_watcher.rb

require 'listen'
require_relative '../lib/agent99'

class AgentWatcher < Agent99::Base
  TYPE = :client

  def capabilities = %w'launch_agents watcher launcher]

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
