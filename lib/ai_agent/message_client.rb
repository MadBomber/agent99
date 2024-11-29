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

  attr_accessor :logger

  def initialize(logger: Logger.new($stdout))
    @connection = create_amqp_connection
    @channel = @connection.create_channel
    @logger = logger
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
      message = JSON.parse(body)
      logger.debug "Received message: #{message.inspect}"

      case message["type"]
      when "request"
        request_handler.call(message)
      when "response"
        response_handler.call(message)
      when "control"
        control_handler.call(message)
      else
        raise NotImplementedError, "Unsupported message type"
      end
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
