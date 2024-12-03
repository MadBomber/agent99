# lib/ai_agent/message_client.rb

require 'bunny'
require 'json'
require 'json_schema'
require 'logger'

class AiAgent::MessageClient
  QUEUE_TTL = 60_000 # 60 seconds TTL
  @instance = nil

  class << self
    def instance
      @instance ||= new
    end
  end

  attr_accessor :logger, :channel, :exchange

  def initialize(logger: Logger.new($stdout))
    @connection = create_amqp_connection
    @channel  = @connection.create_channel
    @exchange = @channel.default_exchange
    @logger   = logger
  end

  def setup(agent_id:, logger:)
    queue = create_queue(agent_id)
    
    # Returning the queue to be used in the Base class
    queue
  end

  def create_queue(agent_id)
    queue_name = "#{agent_id}"
    @channel.queue(queue_name, expires: QUEUE_TTL)
  end

  def listen_for_messages(
      queue,
      request_handler:,
      response_handler:,
      control_handler:
    )
    queue.subscribe(block: true) do |delivery_info, properties, body|
      message = JSON.parse(body, symbolize_names: true)
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
  end


  def publish(message)
    queue_name = message.dig(:header, :to_uuid)

    begin
      json_payload = JSON.generate(message)

      exchange.publish(json_payload, routing_key: queue_name)

      logger.info "Message published successfully to queue: #{queue_name}"
      
      # Return a success status
      { success: true, message: "Message published successfully" }
    
    rescue JSON::GeneratorError => e
      logger.error "Failed to convert payload to JSON: #{e.message}"
      { success: false, error: "JSON conversion error: #{e.message}" }
    
    rescue Bunny::ConnectionClosedError, Bunny::ChannelAlreadyClosed => e
      logger.error "Failed to publish message: #{e.message}"
      { success: false, error: "Publishing error: #{e.message}" }
    
    rescue StandardError => e
      logger.error "Unexpected error while publishing message: #{e.message}"
      { success: false, error: "Unexpected error: #{e.message}" }
    end
  end


  def delete_queue(queue_name)
    return logger.warn("Attempted to delete queue with nil name") if queue_name.nil?

    begin
      queue = @channel.queue(queue_name, passive: true)
      queue.delete
      logger.info "Queue #{queue_name} was deleted"
    rescue Bunny::NotFound
      logger.warn "Queue #{queue_name} not found"
    rescue StandardError => e
      logger.error "Error deleting queue #{queue_name}: #{e.message}"
    end
  end

  private

  def create_amqp_connection
    Bunny.new.tap(&:start)
  rescue Bunny::TCPConnectionFailed, StandardError => e
    logger.error "Failed to connect to AMQP: #{e.message}"
    raise "AMQP Connection Error: #{e.message}. Please check your AMQP server and try again."
  end
end
