#!/usr/bin/env ruby
# examples/run_demo.rb
#
# Comprehensive demo script for Agent99 framework examples
# This script orchestrates running multiple examples automatically
#

require 'optparse'
require 'fileutils'
require 'timeout'

class Agent99Demo
  EXAMPLES_DIR = File.dirname(__FILE__)
  
  # Available demo scenarios
  SCENARIOS = {
    'basic' => {
      description: 'Basic Maxwell Agent86 and Chief interaction',
      agents: ['maxwell_agent86.rb', 'chief_agent.rb'],
      duration: 10
    },
    'control' => {
      description: 'Control agent managing other agents',
      agents: ['maxwell_agent86.rb', 'control.rb'],
      duration: 15
    },
    'watcher' => {
      description: 'Agent watcher dynamically loading new agents',
      agents: ['agent_watcher.rb'],
      duration: 20,
      special: :watcher_demo
    },
    'security' => {
      description: 'KAOS spy demonstration (security example)',
      agents: ['maxwell_agent86.rb', 'kaos_spy.rb'],
      duration: 10,
      warning: 'This demonstrates a malicious agent for educational purposes'
    },
    'all' => {
      description: 'Run multiple scenarios in sequence',
      agents: [],
      duration: 60,
      special: :run_all_scenarios
    }
  }
  
  def initialize
    @pids = []
    @registry_pid = nil
    @rabbitmq_pid = nil
    @options = {
      scenario: 'basic',
      verbose: false,
      no_cleanup: false,
      list_only: false
    }
    setup_signal_handlers
  end
  
  def run(args = ARGV)
    parse_options(args)
    
    if @options[:list_only]
      list_scenarios
      return
    end
    
    puts "🚀 Starting Agent99 Demo: #{@options[:scenario]}"
    puts "📁 Working directory: #{EXAMPLES_DIR}"
    puts
    
    scenario = SCENARIOS[@options[:scenario]]
    unless scenario
      puts "❌ Unknown scenario: #{@options[:scenario]}"
      list_scenarios
      exit 1
    end
    
    if scenario[:warning]
      puts "⚠️  WARNING: #{scenario[:warning]}"
      puts "Continue? (y/N): "
      response = gets.chomp.downcase
      unless response == 'y' || response == 'yes'
        puts "Demo cancelled."
        exit 0
      end
      puts
    end
    
    begin
      check_dependencies
      start_infrastructure
      
      case scenario[:special]
      when :run_all_scenarios
        run_all_scenarios
      when :watcher_demo
        run_watcher_demo
      else
        run_scenario(scenario)
      end
      
    rescue Interrupt
      puts "\n🛑 Demo interrupted by user"
    rescue => e
      puts "❌ Error running demo: #{e.message}"
      puts e.backtrace.first(5) if @options[:verbose]
    ensure
      cleanup unless @options[:no_cleanup]
    end
  end
  
  private
  
  def parse_options(args)
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.separator ""
      opts.separator "Agent99 Framework Demo Runner"
      opts.separator ""
      opts.separator "Options:"
      
      opts.on("-s", "--scenario SCENARIO", "Demo scenario to run (#{SCENARIOS.keys.join(', ')})") do |s|
        @options[:scenario] = s
      end
      
      opts.on("-l", "--list", "List available scenarios") do
        @options[:list_only] = true
      end
      
      opts.on("-v", "--verbose", "Verbose output") do
        @options[:verbose] = true
      end
      
      opts.on("--no-cleanup", "Don't cleanup processes on exit (for debugging)") do
        @options[:no_cleanup] = true
      end
      
      opts.on("-h", "--help", "Show this help") do
        puts opts
        exit
      end
      
      opts.separator ""
      opts.separator "Examples:"
      opts.separator "  #{$0} -s basic     # Run basic Maxwell/Chief demo"
      opts.separator "  #{$0} -s security  # Run security demonstration"
      opts.separator "  #{$0} -l           # List all available scenarios"
    end.parse!(args)
  end
  
  def list_scenarios
    puts "Available demo scenarios:"
    puts
    SCENARIOS.each do |name, config|
      puts "  #{name.ljust(12)} - #{config[:description]}"
      puts "#{' ' * 17}Duration: ~#{config[:duration]}s"
      puts "#{' ' * 17}Warning: #{config[:warning]}" if config[:warning]
      puts
    end
  end
  
  def check_dependencies
    puts "🔍 Checking dependencies..."
    
    # Check if Ruby scripts exist
    required_files = %w[registry.rb]
    scenario = SCENARIOS[@options[:scenario]]
    required_files += scenario[:agents] if scenario[:agents]
    
    required_files.each do |file|
      path = File.join(EXAMPLES_DIR, file)
      unless File.exist?(path)
        puts "❌ Missing required file: #{file}"
        exit 1
      end
    end
    
    # Check for rabbitmq (optional warning)
    begin
      system("rabbitmq-server --help > /dev/null 2>&1")
      unless $?.success?
        puts "⚠️  RabbitMQ not found. Install with: brew install rabbitmq-server"
        puts "   Continuing anyway - agents will use fallback message client"
      end
    rescue
      puts "⚠️  Could not check for RabbitMQ"
    end
    
    # Check for boxes command (used by chief_agent)
    begin
      system("boxes --help > /dev/null 2>&1")
      unless $?.success?
        puts "ℹ️  'boxes' command not found. Install with: brew install boxes"
        puts "   Chief agent output will be plain text"
      end
    rescue
    end
    
    puts "✅ Dependencies check complete"
    puts
  end
  
  def start_infrastructure
    puts "🏗️  Starting infrastructure..."
    
    Dir.chdir(EXAMPLES_DIR) do
      # Start RabbitMQ in background (if available)
      if system("which rabbitmq-server > /dev/null 2>&1")
        puts "   Starting RabbitMQ server..."
        @rabbitmq_pid = spawn("rabbitmq-server", out: "/dev/null", err: "/dev/null")
        sleep 3  # Give RabbitMQ time to start
      end
      
      # Start registry
      puts "   Starting registry service on http://localhost:4567..."
      @registry_pid = spawn("ruby registry.rb", out: @options[:verbose] ? $stdout : "/dev/null")
      sleep 2  # Give registry time to start
      
      # Test registry connection
      begin
        require 'net/http'
        response = Net::HTTP.get_response(URI('http://localhost:4567/healthcheck'))
        if response.code == '200'
          puts "✅ Registry service started successfully"
        else
          raise "Registry returned status #{response.code}"
        end
      rescue => e
        puts "❌ Failed to connect to registry: #{e.message}"
        exit 1
      end
    end
    
    puts
  end
  
  def run_scenario(scenario)
    puts "🎬 Running scenario: #{scenario[:description]}"
    puts "   Duration: ~#{scenario[:duration]} seconds"
    puts
    
    Dir.chdir(EXAMPLES_DIR) do
      agent_pids = []
      
      # Start each agent
      scenario[:agents].each_with_index do |agent, index|
        puts "   Starting agent: #{agent}"
        
        if agent == 'chief_agent.rb'
          # Chief agent runs once and exits, so we handle it specially
          sleep 1  # Give other agents time to register
          puts "   🎯 Running Chief Agent (one-shot)..."
          system("ruby #{agent}")
        else
          # Regular agents run continuously
          pid = spawn("ruby #{agent}", 
                     out: @options[:verbose] ? $stdout : "/dev/null",
                     err: @options[:verbose] ? $stderr : "/dev/null")
          agent_pids << pid
          @pids << pid
          sleep 1  # Stagger startup
        end
      end
      
      unless scenario[:agents].include?('chief_agent.rb')
        # For continuous scenarios, run for specified duration
        puts "   ⏱️  Running for #{scenario[:duration]} seconds..."
        puts "   Press Ctrl+C to stop early"
        sleep scenario[:duration]
      end
    end
    
    puts "✅ Scenario completed"
  end
  
  def run_watcher_demo
    puts "🎬 Running Agent Watcher Demo"
    puts "   This demo shows dynamic agent loading"
    puts
    
    Dir.chdir(EXAMPLES_DIR) do
      # Ensure agents directory exists
      FileUtils.mkdir_p('agents')
      
      # Start the agent watcher
      puts "   Starting Agent Watcher..."
      watcher_pid = spawn("ruby agent_watcher.rb", 
                         out: @options[:verbose] ? $stdout : "/dev/null")
      @pids << watcher_pid
      
      sleep 3
      
      puts "   📂 Copying example_agent.rb to agents/ directory..."
      FileUtils.cp('example_agent.rb', 'agents/example_agent_demo.rb')
      
      sleep 5
      
      puts "   📂 Adding second agent..."
      # Create a simple second agent
      File.write('agents/demo_agent2.rb', generate_demo_agent_code('DemoAgent2', ['demo', 'test2']))
      
      sleep 5
      
      puts "   📂 Adding third agent..."
      File.write('agents/demo_agent3.rb', generate_demo_agent_code('DemoAgent3', ['demo', 'test3']))
      
      puts "   ⏱️  Letting agents run for 15 seconds..."
      sleep 15
      
      # Cleanup created files
      FileUtils.rm_rf('agents/example_agent_demo.rb') rescue nil
      FileUtils.rm_rf('agents/demo_agent2.rb') rescue nil
      FileUtils.rm_rf('agents/demo_agent3.rb') rescue nil
    end
    
    puts "✅ Agent Watcher demo completed"
  end
  
  def run_all_scenarios
    puts "🎬 Running All Scenarios"
    puts
    
    %w[basic control security].each do |scenario_name|
      puts "=" * 60
      scenario = SCENARIOS[scenario_name]
      
      if scenario[:warning]
        puts "⚠️  Skipping #{scenario_name}: #{scenario[:warning]}"
        puts "   Run with -s #{scenario_name} to run individually"
        next
      end
      
      run_scenario(scenario)
      puts
      
      # Brief pause between scenarios
      sleep 3
      cleanup_agents
    end
    
    puts "=" * 60
    puts "✅ All scenarios completed"
  end
  
  def generate_demo_agent_code(class_name, capabilities)
    <<~RUBY
      require_relative '../lib/agent99'
      
      class #{class_name} < Agent99::Base
        def info
          {
            name: self.class.to_s,
            type: :server,
            capabilities: #{capabilities.inspect}
          }
        end
        
        private
        
        def receive_request
          send_response({ result: "Hello from \#{self.class.name}!" })
        end
      end
      
      # Auto-start when loaded
      agent = #{class_name}.new
      agent.run
    RUBY
  end
  
  def setup_signal_handlers
    %w[INT TERM QUIT].each do |signal|
      Signal.trap(signal) do
        puts "\n🛑 Received #{signal} signal, cleaning up..."
        cleanup
        exit 0
      end
    end
  end
  
  def cleanup
    puts "🧹 Cleaning up processes..."
    cleanup_agents
    cleanup_infrastructure
    puts "✅ Cleanup complete"
  end
  
  def cleanup_agents
    @pids.each do |pid|
      begin
        Process.kill('TERM', pid)
        Process.wait(pid, Process::WNOHANG)
      rescue Errno::ESRCH, Errno::ECHILD
        # Process already terminated
      rescue => e
        puts "⚠️  Error terminating process #{pid}: #{e.message}" if @options[:verbose]
      end
    end
    @pids.clear
  end
  
  def cleanup_infrastructure
    if @registry_pid
      begin
        Process.kill('TERM', @registry_pid)
        Process.wait(@registry_pid, Process::WNOHANG)
      rescue Errno::ESRCH, Errno::ECHILD
      rescue => e
        puts "⚠️  Error terminating registry: #{e.message}" if @options[:verbose]
      end
    end
    
    if @rabbitmq_pid
      begin
        Process.kill('TERM', @rabbitmq_pid)
        Process.wait(@rabbitmq_pid, Process::WNOHANG)
      rescue Errno::ESRCH, Errno::ECHILD
      rescue => e
        puts "⚠️  Error terminating RabbitMQ: #{e.message}" if @options[:verbose]
      end
      
      # Also try rabbitmqctl stop as backup
      system("rabbitmqctl stop > /dev/null 2>&1") rescue nil
    end
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  demo = Agent99Demo.new
  demo.run
end