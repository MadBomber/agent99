# examples/hello_world_request.rb

require_relative '../lib/ai_agent/header_schema'

class HelloWorldRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: AiAgent::HeaderSchema

    string :greeting, required: false,  examples: ["Hello"]
    string :name,     required: true,   examples: ["World"]
  end
end
