# lib/agent99/control_actions.rb


module Agent99
  CONTROL_HANDLERS = {
    'shutdown'      => :handle_shutdown,
    'pause'         => :handle_pause,
    'resume'        => :handle_resume,
    'update_config' => :handle_update_config,
    'status'        => :handle_status_request,
    'response'      => :handle_control_response,
  }

  module ControlActions


    ################################################
    private
    
    def handle_control_response
      logger.info "Received control response: #{payload}"
      response_type = payload.dig(:data, :type)
      response_data = payload[:data]

      case response_type
      when 'status'
        logger.info "Status update from agent: #{response_data}"
      when 'error'
        logger.error "Error from agent: #{response_data[:error]}"
      else
        logger.info "Generic control response: #{payload[:message]}"
      end
    end


    # Handles the shutdown control message.
    #
    def handle_shutdown
      logger.info "Received shutdown command. Initiating graceful shutdown..."
      send_control_response("Shutting down")
      fini
      exit(0)
    end


    # Handles the pause control message.
    #
    def handle_pause
      @paused = true
      logger.info "Agent paused"
      send_control_response("Paused")
    end


    # Handles the resume control message.
    #
    def handle_resume
      @paused = false
      logger.info "Agent resumed"
      send_control_response("Resumed")
    end


    # Handles the update_config control message.
    #
    def handle_update_config
      new_config = payload[:config]
      @config = new_config
      logger.info "Configuration updated: #{@config}"
      send_control_response("Configuration updated")
    end


    # Handles the status request control message.
    #
    def handle_status_request
      status = {
        type: 'status',
        id: @id,
        name: @name,
        paused: @paused,
        config: @config,
        uptime: (Time.now - @start_time).to_i
      }
      send_control_response(status)
    end
  end
end

