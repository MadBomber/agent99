# lib/ai_agent/control_actions.rb


module AiAgent::ControlActions


  ################################################
  private
  
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
      id: @id,
      name: @name,
      paused: @paused,
      config: @config,
      uptime: (Time.now - @start_time).to_i
    }
    send_control_response("Status", status)
  end
end
