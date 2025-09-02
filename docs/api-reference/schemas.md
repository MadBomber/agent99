# Schemas API

Agent99 uses JSON Schema validation to ensure data integrity in agent communication. This document covers the schema system, built-in schemas, and how to create custom validation schemas.

## Overview

Agent99 leverages `simple_json_schema_builder` to define and validate request/response schemas, providing:

- **Type safety** - Ensure data types match expectations
- **Required field validation** - Enforce mandatory fields
- **Format validation** - Validate emails, URLs, dates, etc.
- **Custom validation** - Define business-specific rules
- **Auto-documentation** - Schemas serve as API documentation

## Built-in Schemas

### Header Schema

All Agent99 messages include a standard header:

```ruby
class Agent99::HeaderSchema < SimpleJsonSchemaBuilder::Base
  object do
    string :request_id, required: true, format: :uuid
    string :agent_name, required: true
    string :correlation_id, format: :uuid
    string :timestamp, required: true, format: :datetime
    string :reply_to
    object :metadata do
      # Additional metadata fields
    end
  end
end
```

**Example usage:**
```ruby
header = {
  request_id: SecureRandom.uuid,
  agent_name: "CalculatorAgent",
  correlation_id: SecureRandom.uuid,
  timestamp: Time.now.iso8601,
  metadata: { version: "1.0.0" }
}

# Validate header
Agent99::HeaderSchema.new.validate!(header)
```

### Basic Message Schema

Base schema for all agent messages:

```ruby
class Agent99::MessageSchema < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema, required: true
    # Payload varies by message type
  end
end
```

## Creating Custom Schemas

### Simple Request Schema

```ruby
require 'simple_json_schema_builder'

class GreetingRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    string :name, required: true, minLength: 1, maxLength: 100
    string :language, enum: %w[en es fr de], default: 'en'
    boolean :formal, default: false
  end
end

# Usage in agent
class GreeterAgent < Agent99::Base
  def info
    {
      name: self.class.to_s,
      type: :server,
      capabilities: ['greeting'],
      request_schema: GreetingRequest.schema
    }
  end

  def process_request(payload)
    # Payload is automatically validated against schema
    name = payload[:name]
    language = payload[:language] || 'en'
    formal = payload[:formal] || false
    
    greeting = generate_greeting(name, language, formal)
    send_response(message: greeting)
  end
end
```

### Complex Schema with Nested Objects

```ruby
class OrderRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    
    string :customer_id, required: true, format: :uuid
    
    array :items, required: true, minItems: 1 do
      object do
        string :product_id, required: true, format: :uuid
        integer :quantity, required: true, minimum: 1
        number :unit_price, required: true, minimum: 0
        object :metadata do
          string :color
          string :size, enum: %w[XS S M L XL XXL]
          boolean :gift_wrap, default: false
        end
      end
    end
    
    object :shipping_address, required: true do
      string :street, required: true
      string :city, required: true
      string :state, required: true
      string :zip_code, required: true, pattern: '^\d{5}(-\d{4})?$'
      string :country, required: true, enum: %w[US CA MX]
    end
    
    object :payment do
      string :method, required: true, enum: %w[credit_card paypal bank_transfer]
      string :token, required: true
      number :amount, required: true, minimum: 0
    end
  end
end
```

### Response Schema

```ruby
class OrderResponse < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    
    string :order_id, required: true, format: :uuid
    string :status, required: true, enum: %w[pending confirmed processing shipped delivered cancelled]
    number :total_amount, required: true, minimum: 0
    string :estimated_delivery, format: :datetime
    
    array :items do
      object do
        string :product_id, required: true
        integer :quantity, required: true
        number :line_total, required: true
        string :status, enum: %w[available backordered discontinued]
      end
    end
    
    object :tracking do
      string :carrier
      string :tracking_number
      string :tracking_url, format: :uri
    end
  end
end
```

## Schema Validation

### Automatic Validation

Agent99 automatically validates incoming requests against defined schemas:

```ruby
class ValidatingAgent < Agent99::Base
  def info
    {
      name: self.class.to_s,
      type: :server,
      capabilities: ['validation_example'],
      request_schema: OrderRequest.schema,
      response_schema: OrderResponse.schema
    }
  end

  def process_request(payload)
    # payload is already validated by framework
    
    order_id = SecureRandom.uuid
    total = calculate_total(payload[:items])
    
    response = {
      order_id: order_id,
      status: 'confirmed',
      total_amount: total,
      estimated_delivery: (Time.now + 7.days).iso8601,
      items: process_items(payload[:items])
    }
    
    # Response will be validated before sending
    send_response(response)
  end
end
```

### Manual Validation

For custom validation scenarios:

```ruby
def process_request(payload)
  # Additional business logic validation
  begin
    validate_business_rules(payload)
  rescue ValidationError => e
    return send_error("Business validation failed: #{e.message}", "BUSINESS_VALIDATION_ERROR")
  end
  
  # Continue processing...
end

private

def validate_business_rules(payload)
  customer_id = payload[:customer_id]
  
  # Check customer exists and is active
  customer = Customer.find(customer_id)
  raise ValidationError, "Customer not found" unless customer
  raise ValidationError, "Customer account suspended" unless customer.active?
  
  # Validate inventory
  payload[:items].each do |item|
    product = Product.find(item[:product_id])
    raise ValidationError, "Product #{item[:product_id]} not available" unless product&.available?
    raise ValidationError, "Insufficient inventory for #{product.name}" if product.stock < item[:quantity]
  end
end
```

## Advanced Schema Features

### Conditional Schemas

```ruby
class ConditionalRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    string :operation, required: true, enum: %w[create update delete]
    
    # Conditional fields based on operation
    if_property :operation, equals: 'create' do
      string :name, required: true
      string :email, required: true, format: :email
    end
    
    if_property :operation, equals: 'update' do
      string :id, required: true, format: :uuid
      string :name
      string :email, format: :email
    end
    
    if_property :operation, equals: 'delete' do
      string :id, required: true, format: :uuid
    end
  end
end
```

### Custom Format Validators

```ruby
# Define custom formats
SimpleJsonSchemaBuilder.configure do |config|
  config.add_format :phone_number, /^\+?[\d\s\-\(\)]+$/
  config.add_format :product_sku, /^[A-Z]{2}\d{6}$/
end

class ProductRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    string :sku, required: true, format: :product_sku
    string :support_phone, format: :phone_number
  end
end
```

### Schema Composition

```ruby
# Base schemas for reuse
class AddressSchema < SimpleJsonSchemaBuilder::Base
  object do
    string :street, required: true
    string :city, required: true
    string :state, required: true
    string :zip_code, required: true
    string :country, required: true
  end
end

class PersonSchema < SimpleJsonSchemaBuilder::Base
  object do
    string :first_name, required: true
    string :last_name, required: true
    string :email, format: :email
    string :phone, format: :phone_number
  end
end

# Compose into larger schema
class CustomerRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    object :personal_info, schema: PersonSchema, required: true
    object :billing_address, schema: AddressSchema, required: true
    object :shipping_address, schema: AddressSchema
  end
end
```

## Schema Testing

### Unit Tests

```ruby
require 'minitest/autorun'

class TestOrderSchema < Minitest::Test
  def test_valid_order_request
    valid_payload = {
      header: {
        request_id: SecureRandom.uuid,
        agent_name: "TestAgent",
        timestamp: Time.now.iso8601
      },
      customer_id: SecureRandom.uuid,
      items: [
        {
          product_id: SecureRandom.uuid,
          quantity: 2,
          unit_price: 29.99
        }
      ],
      shipping_address: {
        street: "123 Main St",
        city: "Anytown",
        state: "CA",
        zip_code: "12345",
        country: "US"
      }
    }
    
    schema = OrderRequest.new
    assert schema.valid?(valid_payload)
  end
  
  def test_invalid_order_request
    invalid_payload = {
      header: {
        request_id: "not-a-uuid",  # Invalid format
        agent_name: "TestAgent",
        timestamp: Time.now.iso8601
      },
      items: [],  # Empty array not allowed
      shipping_address: {
        # Missing required fields
        street: "123 Main St"
      }
    }
    
    schema = OrderRequest.new
    refute schema.valid?(invalid_payload)
    
    errors = schema.validate(invalid_payload)
    assert errors.any? { |e| e.include?("request_id") }
    assert errors.any? { |e| e.include?("items") }
  end
end
```

### Schema Documentation Generation

```ruby
class SchemaDocGenerator
  def self.generate_docs(schema_class, output_file)
    schema = schema_class.schema
    
    docs = {
      title: schema_class.name,
      description: extract_description(schema),
      properties: extract_properties(schema),
      required: schema.dig('required') || [],
      examples: generate_examples(schema)
    }
    
    File.write(output_file, docs.to_json)
  end
  
  private
  
  def self.extract_properties(schema)
    schema.dig('properties') || {}
  end
  
  def self.generate_examples(schema)
    # Generate example data based on schema
    example_generator = JsonSchemaExampleGenerator.new(schema)
    example_generator.generate
  end
end

# Generate documentation
SchemaDocGenerator.generate_docs(OrderRequest, 'docs/schemas/order_request.json')
```

## Error Handling

### Schema Validation Errors

```ruby
class OrderAgent < Agent99::Base
  def process_request(payload)
    # Framework automatically validates, but you can catch validation errors
    begin
      validate_additional_rules(payload)
    rescue Agent99::SchemaValidationError => e
      return send_error(
        "Validation failed: #{e.message}",
        "SCHEMA_VALIDATION_ERROR",
        {
          errors: e.validation_errors,
          schema_version: "1.0.0"
        }
      )
    end
    
    # Process valid request...
  end
  
  private
  
  def validate_additional_rules(payload)
    # Custom validation beyond schema
    if payload[:items].sum { |item| item[:quantity] } > 100
      raise Agent99::SchemaValidationError, "Order too large (max 100 items)"
    end
  end
end
```

### Schema Version Management

```ruby
class VersionedSchema
  SCHEMA_VERSIONS = {
    "1.0" => OrderRequestV1,
    "1.1" => OrderRequestV11,
    "2.0" => OrderRequestV2
  }.freeze
  
  def self.validate(payload, version = "2.0")
    schema_class = SCHEMA_VERSIONS[version]
    raise ArgumentError, "Unsupported schema version: #{version}" unless schema_class
    
    schema = schema_class.new
    unless schema.valid?(payload)
      errors = schema.validate(payload)
      raise Agent99::SchemaValidationError, "Validation failed: #{errors.join(', ')}"
    end
    
    payload
  end
end

# Usage in agent
def process_request(payload)
  schema_version = header_value('schema_version') || "2.0"
  validated_payload = VersionedSchema.validate(payload, schema_version)
  
  # Process with validated payload...
end
```

## Best Practices

### 1. Schema Design
- **Be explicit**: Define all expected fields and types
- **Use descriptive names**: Clear field names and descriptions
- **Version your schemas**: Plan for schema evolution
- **Provide examples**: Include example payloads in documentation

### 2. Validation Strategy
- **Validate early**: Catch errors as soon as possible
- **Provide clear errors**: Include helpful validation messages
- **Use business validation**: Complement schema validation with business rules
- **Test thoroughly**: Cover valid and invalid cases

### 3. Performance
- **Cache compiled schemas**: Don't recompile schemas on every request
- **Validate incrementally**: Only validate changed portions when possible
- **Monitor validation time**: Track validation performance
- **Use appropriate depth**: Don't over-validate in performance-critical paths

### 4. Evolution
- **Backward compatibility**: Plan for schema changes
- **Optional fields**: Use optional fields for new features
- **Deprecation strategy**: Plan how to retire old schema versions
- **Migration support**: Provide tools to migrate between schema versions

## Next Steps

- **[Agent99::Base](agent99-base.md)** - Core agent class reference
- **[Message Clients](message-clients.md)** - Message broker APIs
- **[Schema Definition](../agent-development/schema-definition.md)** - Detailed schema guide