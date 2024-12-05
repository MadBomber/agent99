# examples/hello_world_request.rb

require_relative '../lib/agent99/header_schema'

class HelloWorldRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema

    string :greeting, required: false,  examples: ["Hello"]
    string :name,     required: true,   examples: ["World"]
  end
end
