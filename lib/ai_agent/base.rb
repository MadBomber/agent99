#!/usr/bin/env ruby
# experiments/agents/ai_agent/base.rb

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
  end


  # Returns the number of waiting messages
  def waiting
    @queue&.count
  end

  def message?
    @queue.waiting > 0
  end

  def message
    return nil unless message?

    @payload  = @queue.next

    debug_me{[
      :payload,
      'payload.class'
    ]}

    validate_schema.empty?
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
  
  def header      = @payload['header']
  def from_uuid   = header['from_uuid']
  def to_uuid     = header['to_uuid']
  def event_uuid  = header['event_uuid']
  def timestamp   = header['timestamp']


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


  def capabilities
    raise NotImplementedError, "#{self.class} must implement a #{__method__} method."
  end
end

