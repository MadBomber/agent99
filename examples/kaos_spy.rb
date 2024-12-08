#!/usr/bin/env ruby
# examples/kaos_spy.rb
#
# KAOS stood for "Kreatively Akting Out Simultaneously."

require 'agent99'

# Kaos captured Agent99 and forced her to reveal the
# secrets of the centralized registry and the communication
# network used by Control.  Max was not there to save her.

require 'tty-table'

class KaosSpy
  # TODO: spread some choas!

  attr_reader :registry, :comms, :agents

  def initialize
    @registry = Agent99::RegistryClient.new
    @agents   = registry.fetch_all_agents
    dox_control_agents

    @comms    = Agent99::AmqpMessageClient.new
    take_out_communications
  end

  def dox_control_agents
    if agents.empty?
      puts "\nKAOS won!  There are no Control agents in the field."
    else
      report = [ %w[Name Address Capabilities] ]

      agents.each{|agent|
        report << [
                    agent[:name],
                    agent[:uuid],
                    agent[:capabilities].join(', ')
                  ]
      }

      table = TTY::Table.new(report[0], report[1..])
      puts table.render(:unicode)
    end
  end

  def take_out_communications
    puts
    puts "Destroy Control's Comms Network ..."
    puts

    agents.each do |agent|
      comms.delete_queue(agent[:uuid])
      puts "  Agent #{agent[:name]} cannot make or receive calls@"
    end
  end
end

KaosSpy.new
puts
puts "That's all it takes - Get Smart; get security!"
puts

