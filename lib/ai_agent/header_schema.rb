# experiments/agents/header_schema.rb

require 'simple_json_schema_builder'

class AiAgent::HeaderSchema < SimpleJsonSchemaBuilder::Base
  object do
    string  :from_uuid,   required: true, examples: [SecureRandom.uuid]
    string  :to_uuid,     required: true, examples: [SecureRandom.uuid]
    string  :event_uuid,  required: true, examples: [SecureRandom.uuid]
    integer :timestamp,   required: true, examples: [Timestamp.new.to_i]
  end
end
