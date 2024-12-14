# experiments/agents/agent99/registry_client.rb

require 'json'
require 'net/http'
require 'uri'

class Agent99::RegistryClient
  attr_accessor :logger

  def initialize(
      base_url: ENV.fetch('AGENT99_REGISTRY_URL', 'http://localhost:4567'),
      logger:   Logger.new($stdout)
    )
    @base_url     = base_url
    @logger       = logger
    @http_client  = Net::HTTP.new(URI.parse(base_url).host, URI.parse(base_url).port)
  end

  def register(info:)
    payload = info
    request = create_request(:post, "/register", payload)
    @id     = send_request(request)
  end

  def withdraw(id)
    return logger.warn("Agent not registered") unless id

    request = create_request(:delete, "/withdraw/#{id}")
    send_request(request)
  end


  def discover(capability:)
    encoded_capability = URI.encode_www_form_component(capability)
    request = create_request(:get, "/discover?capability=#{encoded_capability}")
    send_request(request)
  end


  def fetch_all_agents
    request   = create_request(:get, "/")
    response  = send_request(request)
  end

  ################################################
  private

  def create_request(method, path, body = nil)
    request       = Object.const_get("Net::HTTP::#{method.capitalize}").new(path, { "Content-Type" => "application/json" })
    request.body  = body.to_json if body
    request
  end

  def send_request(request)
    response = @http_client.request(request)

    handle_response(response)
  
  rescue JSON::ParserError => e
    logger.error "JSON parsing error: #{e.message}"
    nil
  
  rescue StandardError => e
    logger.error "Request error: #{e.message}"
    nil
  end

  def handle_response(response)
    case response
    when Net::HTTPOK
      JSON.parse(response.body, symbolize_names: true)
    when Net::HTTPCreated
      JSON.parse(response.body, symbolize_names: true)[:uuid]
    when Net::HTTPNoContent
      logger.info "Action completed successfully."
      nil
    else
      logger.error "Error: #{JSON.parse(response.body, symbolize_names: true)[:error]}"
      nil
    end
  end
end
