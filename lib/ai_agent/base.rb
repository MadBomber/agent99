# lib/ai_agent/base.rb

require 'logger'
require 'json'
require 'json_schema'

require_relative 'timestamp'
require_relative 'registry_client'
require_relative 'message_client'


class AiAgent::Base
  MESSAGE_TYPES = %w[request response control]

  attr_reader :id, :capabilities, :name, :payload, :header, :logger, :queue
  attr_accessor :registry_client, :message_client

  def initialize(
    registry_client: AiAgent::RegistryClient.new,
    message_client: AiAgent::MessageClient.new,
    logger: Logger.new($stdout)
  )
    @payload = nil
    @name = self.class.name
    @capabilities = capabilities
    @id = nil
    @registry_client = registry_client
    @message_client = message_client
    @logger = logger

    @registry_client.logger = logger
    register

    @queue = message_client.setup(
      agent_id: id,
      logger:
    )

    init if respond_to?(:init)
  
    setup_signal_handlers
  end

  def setup_signal_handlers
    at_exit { fini }

    signals = %w[INT TERM QUIT]
    signals.each do |signal|
      Signal.trap(signal) do
        STDERR.puts "\nReceived #{signal} signal. Initiating graceful shutdown..."
        exit
      end
    end
  end


  def run = dispatcher

  def register
    @id = registry_client.register(name:, capabilities:)
    logger.info "Registered Agent #{name} with ID: #{id}"
  rescue StandardError => e
    handle_error("Error during registration", e)
  end

  def withdraw
    registry_client.withdraw(@id) if @id
    @id = nil
  end


  def discover_agent(
      capability:, 
      how_many:     1, 
      all:          false
    )
    result = @registry_client.discover(capability: capability)

    if result.empty?
      logger.error "No agents found for capability: #{capability}"
      raise "No agents available"
    end

    if all
      result
    else
      result.sample(how_many)
    end
  end


  private

  def fini
    if id
      queue_name = id
      withdraw # side-effect: will set id to nil
      @message_client&.delete_queue(queue_name)
    else
      logger.warn('fini called with a nil id')
    end
  end


  def dispatcher
    message_client.listen_for_messages(
      queue,
      request_handler: ->(message) { process_request(message) },
      response_handler: ->(message) { process_response(message) },
      control_handler: ->(message) { process_control(message) }
    )
  end

  def process_request(message)
    @payload = message
    @header = payload[:header]
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

  def validate_schema
    schema = JsonSchema.parse!(self.class::REQUEST_SCHEMA)
    schema.expand_references!
    validator = JsonSchema::Validator.new(schema)
    
    validator.validate(@payload)
    []
  rescue JsonSchema::ValidationError => e
    handle_error("Validation error", e)
    send_response(type: 'error', errors: e.messages)
    e.messages
  end

  def receive_request = logger.info "Received request: #{payload}"

  def receive_response = logger.info "Received response: #{payload}"

  def receive_control = logger.info "Received control message: #{payload}"

  def capabilities = []

  def get(field) = payload[field] || default(field)

  def default(field) = self.class::REQUEST_SCHEMA.dig(:properties, field, :examples)&.first

  def header      = @payload[:header]
  def to_uuid     = header[:to_uuid]
  def from_uuid   = header[:from_uuid]
  def event_uuid  = header[:event_uuid]
  def timestamp   = header[:timestamp]
  def type        = header[:type]

  def handle_error(message, error)
    logger.error "#{message}: #{error.message}"
    logger.debug error.backtrace.join("\n")
  end

  def send_response(response)
    response[:header] = return_address
    @message_client.publish(response)
  end

  def return_address
    header.merge(
      to_uuid: from_uuid,
      from_uuid: to_uuid,
      timestamp: AiAgent::Timestamp.new.to_i,
      type: 'response'
    )
  end
end

