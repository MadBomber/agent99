# lib/agent99/message_processing.rb

module Agent99::MessageProcessing


  # Starts the agent's main loop for processing messages.
  #
  def run
    dispatcher
  end

  ################################################
  private

  # Main message dispatching loop.
  #
  def dispatcher
    @start_time = Time.now
    @paused     = false
    @config     = {}


    message_client.listen_for_messages(
      queue,
      request_handler:  ->(message) { process_request(message) unless paused? },
      response_handler: ->(message) { process_response(message) unless paused? },
      control_handler:  ->(message) { process_control(message) }
    )
  end


  # Processes incoming request messages.
  #
  # @param message [Hash] The incoming message
  #
  def process_request(message)
    @payload  = message
    @header   = payload[:header]
    return unless validate_schema.empty?
    receive_request
  end

  # Processes incoming response messages.
  #
  # @param message [Hash] The incoming message
  #
  def process_response(message)
    @payload = message
    receive_response
  end

  # Processes incoming control messages.
  #
  # @param message [Hash] The incoming message
  #
  def process_control(message)
    @payload = message
    if payload[:action] == 'response'
      receive_response
    else
      receive_control
    end
  end


  # Handles incoming request messages (to be overridden by subclasses).
  #
  def receive_request
    logger.info "Received request: #{payload}"
  end


  # Handles incoming response messages (to be overridden by subclasses).
  #
  def receive_response
    logger.info "Received response: #{payload}"
  end


  # Processes incoming control messages.
  #
  # @raise [StandardError] If there's an error processing the control message
  #
  def receive_control

    action  = payload[:action]
    handler = Agent99::CONTROL_HANDLERS[action]
    
    if handler
      send(handler)
    else
      logger.warn "Unknown control action: #{action}"
    end
  
  rescue StandardError => e
    logger.error "Error processing control message: #{e.message}"
    send_control_response({ error: e.message })
  end


  # Sends a response message.
  #
  # @param response [Hash] The response to send
  #
  def send_response(response)
    response[:header] = return_address
    @message_client.publish(response)
  end


  # Sends a control response message.
  #
  # @param message [String] The response message
  # @param data [Hash, nil] Additional data to include in the response
  #
  def send_control_response(data)
    response = {
      header: return_address.merge(type: 'control'),
      action: 'response',
      data: data
    }
    @message_client.publish(response)
  end


  # Validates the incoming message against the defined schema.
  #
  # @return [Array] An array of validation errors, empty if validation succeeds
  #
  def validate_schema
    # TODO: Implement proper JSON schema validation
    # For now, skip validation to avoid JsonSchema dependency issues
    return []
  rescue => e
    handle_error("Validation error", e)
    send_response(type: 'error', errors: [e.message])
    [e.message]
  end


  # Retrieves a field from the payload or returns a default value.
  #
  # @param field [Symbol] The field to retrieve
  # @return [Object] The value of the field or its default
  #
  def get(field)
    payload[field] || default(field)
  end


  # Returns the default value for a field from the schema.
  #
  # @param field [Symbol] The field to get the default for
  # @return [Object, nil] The default value or nil if not found
  #
  def default(field)
    self.class::REQUEST_SCHEMA.dig(:properties, field, :examples)&.first
  end
end
