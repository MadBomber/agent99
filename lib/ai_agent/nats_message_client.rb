# lib/ai_agent/nats_message_client.rb

require 'nats/client'
require 'json'
require 'logger'

class AiAgent::NatsMessageClient
  @instance = nil

  class << self
    def instance
      @instance ||= new
    end
  end

  attr_accessor :logger, :nats

  def initialize(logger: Logger.new($stdout))
    @nats = create_nats_connection
    @logger = logger
  end

  def setup(agent_id:, logger:)
    @logger = logger
    # NATS doesn't require explicit queue creation, so we'll just return the agent_id
    agent_id
  end

  def listen_for_messages(
    queue,
    request_handler:,
    response_handler:,
    control_handler:
  )
    @nats.subscribe(queue) do |msg|
      message = JSON.parse(msg.data, symbolize_names: true)
      logger.debug "Received message: #{message.inspect}"

      type = message.dig(:header, :type)

      case type
      when "request"
        request_handler.call(message)
      when "response"
        response_handler.call(message)
      when "control"
        control_handler.call(message)
      else
        raise NotImplementedError, "Unsupported message type: #{type}"
      end
    end

    # Keep the connection open
    loop { sleep 1 }
  end

  def publish(message)
    queue_name = message.dig(:header, :to_uuid)

    begin
      json_payload = JSON.generate(message)

      @nats.publish(queue_name, json_payload)

      logger.info "Message published successfully to queue: #{queue_name}"
      
      # Return a success status
      { success: true, message: "Message published successfully" }
    
    rescue JSON::GeneratorError => e
      logger.error "Failed to convert payload to JSON: #{e.message}"
      { success: false, error: "JSON conversion error: #{e.message}" }
    
    rescue NATS::IO::TimeoutError => e
      logger.error "Failed to publish message: #{e.message}"
      { success: false, error: "Publishing error: #{e.message}" }
    
    rescue StandardError => e
      logger.error "Unexpected error while publishing message: #{e.message}"
      { success: false, error: "Unexpected error: #{e.message}" }
    end
  end

  def delete_queue(queue_name)
    # NATS doesn't have the concept of deleting queues.
    # Subjects are automatically cleaned up when there are no more subscribers.
    logger.info "NATS doesn't require explicit queue deletion. Subject #{queue_name} will be automatically cleaned up."
  end


  ################################################
  private
  
  def create_nats_connection
    NATS.connect
  rescue NATS::IO::ConnectError => e
    logger.error "Failed to connect to NATS: #{e.message}"
    raise "NATS Connection Error: #{e.message}. Please check your NATS server and try again."
  end
end

