# experiments/agents/header_schema.rb

require 'simple_json_schema_builder'
require_relative 'timestamp'

class AiAgent::HeaderSchema < SimpleJsonSchemaBuilder::Base
  object do
    string  :from_uuid,   required: true, examples: [SecureRandom.uuid]
    string  :to_uuid,     required: true, examples: [SecureRandom.uuid]
    string  :event_uuid,  required: true, examples: [SecureRandom.uuid]
    string  :type,        required: true, examples: %w[request response control]
    integer :timestamp,   required: true, examples: [AiAgent::Timestamp.new.to_i]
  end
end
