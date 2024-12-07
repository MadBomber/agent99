#!/usr/bin/env ruby
# control.rb

require_relative '../lib/agent99'

class Control < Agent99::Base
  TYPE = :hybrid

  attr_accessor :statuses

  def init
    @agents = @registry_client.fetch_all_agents
    @statuses = {}
  end


  def capabilities
    ['control', 'headquarters', 'secret underground base']
  end


  def send_control_message(message:, payload: {})
    @agents.each do |agent|
      response = @message_client.publish(
        header: {
          to_uuid: agent[:uuid],
          from_uuid: @id,
          event_uuid: SecureRandom.uuid,
          type: 'control',
          timestamp: Agent99::Timestamp.new.to_i
        },
        action: message,
        payload: payload
      )
      puts "Sent #{message} to #{agent[:name]}: #{response[:success] ? 'Success' : 'Failed'}"
    end
  end


  def pause_all
    send_control_message(message: 'pause')
  end


  def resume_all
    send_control_message(message: 'resume')
  end


  def stop_all
    send_control_message(message: 'stop')
  end

  def get_all_status
    @statuses.clear  # Reset statuses before new request
    
    @agents.each do |agent|
      @message_client.publish(
        header: {
          to_uuid:    agent[:uuid],
          from_uuid:  @id,
          event_uuid: SecureRandom.uuid,
          type:       'control',
          timestamp:  Agent99::Timestamp.new.to_i
        },
        action: 'status'
      )
    end

    # Wait for responses (with timeout)
    sleep 2  # Give agents time to respond
    @statuses
  end

  def receive_response
    if payload[:action] == 'response' && payload[:data][:type] == 'status'
      agent_name = payload[:header][:from_uuid]
      @statuses[agent_name] = payload[:data]
      logger.info "Received status from #{agent_name}: #{payload[:data]}"
    elsif payload[:action] == 'status' && payload[:header][:from_uuid] == @id
      # Handle our own status request
      handle_status_request
    end
  end


end


if __FILE__ == $PROGRAM_NAME
  control = Control.new
  
  # Start the message processing in a separate thread
  dispatcher_thread = Thread.new do
    control.run
  end

  # UI thread
  begin
    loop do
      puts "\n1. Pause all agents"
      puts "2. Resume all agents"
      puts "3. Stop all agents"
      puts "4. Get all agents status"
      puts "5. Exit"
      print "\nEnter your choice: "
      
      choice = gets.chomp.to_i

      case choice
      when 1
        control.pause_all
      when 2
        control.resume_all
      when 3
        control.stop_all
      when 4
        statuses = control.get_all_status
        sleep 2 # Give time for responses to arrive
        puts JSON.pretty_generate(control.statuses)
      when 5
        puts "Exiting..."
        Thread.exit
        break
      else
        puts "Invalid choice. Please try again."
      end
    end
  rescue Interrupt
    puts "\nShutting down..."
  ensure
    dispatcher_thread.exit
    control.fini
  end
end

