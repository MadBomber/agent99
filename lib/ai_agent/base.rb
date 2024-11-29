# lib/ai_agent/base.rb

require 'logger'

require_relative 'registry_client'
require_relative 'message_client'

class AiAgent::Base
  MESSAGE_TYPES = %w[ request response control ]

  attr_reader :id, :capabilities, :name, :payload
  attr_accessor :registry_client, :message_client

  def initialize(
      registry_client:  RegistryClient.new, 
      message_client:   MessageClient.new,
      logger:           Logger.new($stdout)
    )
    @payload          = nil
    @name             = self.class.name
    @capabilities     = capabilities
    @id               = nil
    @registry_client  = registry_client
    @message_client   = message_client
    @logger           = logger

    @registry_client.logger = logger
  end

  def run
    logger.info "Agent #{@name} is running"
    register

    @queue  = message_client.setup(
                id:       id, # SMELL: not available yer
                types:    MESSAGE_TYPES,
                logger:   logger,
                options:  {} # like blocking, non-blocking etc.
              )
    dispatcher
  end



  def register
    @id = registry_client.register(name: @name, capabilities: capabilities)
    logger.info "Registered Agent #{@name} with ID: #{@id}"
  rescue StandardError => e
    logger.error "Error during registration: #{e.message}"
  end


  def withdraw
    registry_client.withdraw(@id) if @id
    @id = nil
  end

  ################################################
  private
  
  def header
    @payload[:header]
  end

  def from_uuid
    header[:from_uuid]
  end

  def to_uuid
    header[:to_uuid]
  end

  def event_uuid
    header[:event_uuid]
  end

  def timestamp
    header[:timestamp]
  end


  def dispatcher
    queue.subscribe do |delivery_info, metadata, message|
      process(delivery_info, metadata, message)
    end
  end


  def process(delivery_info, metadata, message)
    debug_me{[
      :delivery_info,
      :metadata,
      :message
    ]}

    @payload = JSON.parse(message, symbolize_names: true)

    case type
    when 'request'
      return unless validate_schema.empty?
      receive_request
    when 'response'
      receive_response
    when 'control'
      receive_control
    else
      logger.error "Unknown type: #{type}"
    end
  end


  # verify that the @payload object matches
  # the agent's request schema
  #
  def validate_schema
    # Use the json_schema gem to validate the request body against the defined schema
    validator = JSONSchema::Validator.new(REQUEST_SCHEMA)
    
    begin
      validator.validate(@payload)
      [] # No errors
    rescue JSONSchema::ValidationError => e
      errors = e.messages
      logger.error "#{errors}"

      debug_me{[
        :errors
      ]}

      # TODO: tell the sending there was errors?
    end
  end


  def receive_request
    raise NotImplementedError, "#{self.class} must implement a #{__method__} method."
  end


  def receive_response
    raise NotImplementedError, "#{self.class} must implement a #{__method__} method."
  end

  def receive_control
    raise NotImplementedError, "#{self.class} must implement a #{__method__} method."
  end


  def capabilities
    raise NotImplementedError, "#{self.class} must implement a #{__method__} method."
  end
end

