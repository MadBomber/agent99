# Agent99 Framework

## Schema Definition

Schemas can be defined using `SimpleJsonSchemaBuilder`. Define your request and response schemas according to the expected data structure.

Example:

```ruby
class MyAgentRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    string :greeting, required: false, examples: ["Hello"]
    string :name, required: true, examples: ["World"]
  end
end
```
