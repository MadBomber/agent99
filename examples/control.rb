#!/usr/bin/env ruby
# control.rb

require_relative '../lib/agent99'

class Control < Agent99::Base
  TYPE          = :hybrid

  def init
    @agents = @registry_client.fetch_all_agents
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
    statuses = {}
    @agents.each do |agent|
      response = @message_client.publish(
        header: {
          to_uuid: agent[:uuid],
          from_uuid: @id,
          event_uuid: SecureRandom.uuid,
          type: 'control',
          timestamp: Agent99::Timestamp.new.to_i
        },
        action: 'status'
      )

      debug_me{[
        :response
      ]}

      statuses[agent[:name]] = response[:payload] if response[:success]
    end

    statuses
  end
end


if __FILE__ == $PROGRAM_NAME
  control = Control.new

  puts "1. Pause all agents"
  puts "2. Resume all agents"
  puts "3. Stop all agents"
  puts "4. Get all agents status"
  puts "5. Exit"

  loop do
    print "Enter your choice: "
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
      debug_me{[
        :statuses
      ]}
      puts JSON.pretty_generate(statuses)
    when 5
      puts "Exiting..."
      break
    else
      puts "Invalid choice. Please try again."
    end
  end
end

