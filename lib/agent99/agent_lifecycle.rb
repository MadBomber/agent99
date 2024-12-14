# lib/agent99/agent_lifecycle.rb

module Agent99::AgentLifecycle

  # Initializes a new AI agent with the given configuration.
  #
  # @param registry_client [Agent99::RegistryClient] The client for agent registration
  # @param message_client [Agent99::AmqpMessageClient] The client for message handling
  # @param logger [Logger] The logger instance for the agent
  #
  def initialize(registry_client: Agent99::RegistryClient.new,
                 message_client: Agent99::AmqpMessageClient.new,
                 logger: Logger.new($stdout))
    @agents           = {}
    @payload          = nil
    @name             = self.class.name
    @capabilities     = capabilities
    @id               = nil
    @registry_client  = registry_client
    @message_client   = message_client
    @logger           = logger

    validate_info_keys

    @registry_client.logger = logger
    register(info)

    @queue = message_client.setup(agent_id: id, logger:)

    init if respond_to?(:init)
  
    setup_signal_handlers
  end


  def validate_info_keys
    required_keys = [:name, :capabilities]
    if respond_to? :info
      missing_keys = required_keys - info.keys
      unless missing_keys.empty?
        logger.error <<~MESSAGE
          This agent's info method is missing 
          #{1 == missing_keys.size ? 'a required key' : 'some required keys'}: 
          #{missing_keys}
        MESSAGE
        .split("\n").join
        exit(1)
      end
    else
      logger.error "An agent must implement the info method"
      exit(1)
    end
  end


  # Registers the agent with the registry service.
  #
  # @raise [StandardError] If registration fails
  #
  def register(agent_info)
    @id = registry_client.register(info: agent_info)
    logger.info "Registered Agent #{name} with ID: #{id}"
  rescue StandardError => e
    handle_error("Error during registration", e)
  end

  # Withdraws the agent from the registry service.
  #
  def withdraw
    registry_client.withdraw(@id) if @id
    @id = nil
  end


  # Performs cleanup operations when the agent is shutting down.
  #
  def fini
    if id
      queue_name = id
      withdraw
      @message_client&.delete_queue(queue_name)
    else
      logger.warn('fini called with a nil id')
    end
  end

  ################################################
  private
  
  # Checks if the agent is currently paused.
  #
  # @return [Boolean] True if the agent is paused, false otherwise
  #
  def paused?
    @paused
  end

  # Sets up signal handlers for graceful shutdown.
  #
  def setup_signal_handlers
    at_exit { fini }

    %w[INT TERM QUIT].each do |signal|
      Signal.trap(signal) do
        STDERR.puts "\nReceived #{signal} signal. Initiating graceful shutdown..."
        exit
      end
    end
  end
end
