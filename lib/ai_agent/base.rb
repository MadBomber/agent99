# lib/ai_agent/base.rb

require 'logger'
require 'json'
require 'json_schema'

require_relative 'timestamp'
require_relative 'registry_client'
require_relative 'message_client'


class AiAgent::Base
  MESSAGE_TYPES = %w[ request response control ]

  attr_reader :id, :capabilities, :name, :payload, :header, :logger, :queue
  attr_accessor :registry_client, :message_client

  def initialize(
      registry_client:  AiAgent::RegistryClient.new, 
      message_client:   AiAgent::MessageClient.new,
      logger:           Logger.new($stdout)
    )

    at_exit do
      # when an agent has an id then it most likely
      # has a message queue as well as a regristration
      # that need to be cleaned up on exit
      if id
        self.cleanup
        self.withdraw
      end
    end

    @payload          = nil
    @name             = self.class.name
    @capabilities     = capabilities
    @id               = nil
    @registry_client  = registry_client
    @message_client   = message_client
    @logger           = logger

    @registry_client.logger = logger
    register

    @queue  = message_client.setup(
                agent_id: id,
                logger:   logger,
                # options:  {} # like blocking, non-blocking etc.
              )

    init if self.respond_to? :init
  end

  def run
    logger.info "Agent #{@name} is waiting for messages"
    
    dispatcher
  end



  def register
    @id = registry_client.register(
            name:         @name, 
            capabilities: capabilities
          )
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


  def return_address
    return_header = header.dup

    return_header[:to_uuid]   = from_uuid
    return_header[:from_uuid] = to_uuid
    return_header[:timestamp] = AiAgent::Timestamp.new.to_i
    return_header[:type]      = 'response'

    return_header
  end


  def send_response(response)
    response[:header] = return_address
    @message_client.publish(from_uuid, response)
  end

  def dispatcher
    message_client.listen_for_messages(
      queue,
      request_handler:  ->(message) { process_request(message) },
      response_handler: ->(message) { process_response(message) },
      control_handler:  ->(message) { process_control(message) }
    )
  end


  def process(delivery_info, metadata, message)
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

  def process_request(message)
    @payload  = message
    @header   = payload[:header]
    return unless validate_schema.empty?
    receive_request
  end

  def process_response(message)
    @payload = message
    receive_response
  end

  def process_control(message)
    @payload = message
    receive_control
  end


  # verify that the @payload object matches
  # the agent's request schema
  #
  def validate_schema
    schema = JsonSchema.parse!(self.class::REQUEST_SCHEMA)

    # Expand $ref nodes if there are any
    schema.expand_references!

    # Use the json_schema gem to validate the request body against the defined schema
    validator = JsonSchema::Validator.new(schema)
    
    begin
      validator.validate(@payload)
      [] # No errors
    rescue JsonSchema::ValidationError => e
      errors = e.messages
      logger.error "#{errors}"

      # Inform the sender about the validation errors
      response = {
        type: 'error',
        errors: errors
      }
      send_response(response)
    end
  end

  def cleanup
    @message_client&.delete_queue(@id)
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

