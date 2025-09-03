# Advanced Examples

This section contains advanced examples demonstrating sophisticated Agent99 patterns, distributed architectures, and real-world use cases.

## Microservices Architecture Example

A complete e-commerce microservices system using Agent99:

### Order Processing Service

```ruby
require 'agent99'
require 'simple_json_schema_builder'

class OrderRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: Agent99::HeaderSchema
    string :customer_id, required: true, format: :uuid
    array :items, required: true, minItems: 1 do
      object do
        string :product_id, required: true, format: :uuid
        integer :quantity, required: true, minimum: 1
        number :unit_price, required: true, minimum: 0
      end
    end
    object :shipping_address, required: true do
      string :street, required: true
      string :city, required: true
      string :state, required: true
      string :zip_code, required: true
      string :country, required: true
    end
  end
end

class OrderProcessingAgent < Agent99::Base
  def initialize
    super
    @orders = {}
  end

  def info
    {
      name: self.class.to_s,
      type: :hybrid,
      capabilities: ['order_processing', 'e_commerce'],
      request_schema: OrderRequest.schema
    }
  end

  def process_request(payload)
    order_id = SecureRandom.uuid
    
    # Validate inventory
    inventory_check = check_inventory(payload[:items])
    unless inventory_check[:available]
      return send_error("Insufficient inventory", "INVENTORY_ERROR", inventory_check)
    end
    
    # Process payment
    payment_result = process_payment(payload[:customer_id], inventory_check[:total])
    unless payment_result[:success]
      return send_error("Payment failed", "PAYMENT_ERROR", payment_result)
    end
    
    # Create order
    order = create_order(order_id, payload, payment_result)
    
    # Trigger fulfillment
    trigger_fulfillment(order)
    
    # Send notifications
    notify_customer(order)
    
    send_response(
      order_id: order_id,
      status: 'confirmed',
      total: inventory_check[:total],
      estimated_delivery: (Time.now + 7.days).iso8601
    )
  end

  private

  def check_inventory(items)
    inventory_agents = discover_agents(['inventory'])
    return { available: false, error: 'No inventory service' } if inventory_agents.empty?
    
    inventory_agent = inventory_agents.first
    total = 0
    
    items.each do |item|
      request = {
        product_id: item[:product_id],
        quantity: item[:quantity]
      }
      
      response = send_request(inventory_agent[:name], request)
      unless response && response[:available]
        return {
          available: false,
          product_id: item[:product_id],
          error: 'Insufficient stock'
        }
      end
      
      total += item[:unit_price] * item[:quantity]
    end
    
    { available: true, total: total }
  end

  def process_payment(customer_id, amount)
    payment_agents = discover_agents(['payment'])
    return { success: false, error: 'No payment service' } if payment_agents.empty?
    
    payment_agent = payment_agents.first
    request = {
      customer_id: customer_id,
      amount: amount,
      currency: 'USD'
    }
    
    response = send_request(payment_agent[:name], request)
    response || { success: false, error: 'Payment service unavailable' }
  end

  def create_order(order_id, payload, payment_result)
    order = {
      id: order_id,
      customer_id: payload[:customer_id],
      items: payload[:items],
      shipping_address: payload[:shipping_address],
      payment_id: payment_result[:payment_id],
      total: payment_result[:amount],
      status: 'confirmed',
      created_at: Time.now.iso8601
    }
    
    @orders[order_id] = order
    order
  end

  def trigger_fulfillment(order)
    fulfillment_agents = discover_agents(['fulfillment'])
    return unless fulfillment_agents.any?
    
    fulfillment_agent = fulfillment_agents.first
    request = {
      order_id: order[:id],
      items: order[:items],
      shipping_address: order[:shipping_address]
    }
    
    # Async fulfillment request
    Thread.new do
      send_request(fulfillment_agent[:name], request)
    end
  end

  def notify_customer(order)
    notification_agents = discover_agents(['notification'])
    return unless notification_agents.any?
    
    notification_agent = notification_agents.first
    request = {
      type: 'order_confirmation',
      customer_id: order[:customer_id],
      order_id: order[:id],
      template_data: {
        order_total: order[:total],
        item_count: order[:items].size
      }
    }
    
    # Async notification
    Thread.new do
      send_request(notification_agent[:name], request)
    end
  end
end
```

### Inventory Management Service

```ruby
class InventoryAgent < Agent99::Base
  def initialize
    super
    @inventory = load_inventory_data
    @mutex = Mutex.new
  end

  def info
    {
      name: self.class.to_s,
      type: :server,
      capabilities: ['inventory', 'stock_management']
    }
  end

  def process_request(payload)
    product_id = payload.dig(:product_id)
    quantity = payload.dig(:quantity)

    @mutex.synchronize do
      product = @inventory[product_id]
      
      unless product
        return send_error("Product not found", "PRODUCT_NOT_FOUND")
      end
      
      available_quantity = product[:stock]
      
      if available_quantity >= quantity
        # Reserve stock
        @inventory[product_id][:stock] -= quantity
        @inventory[product_id][:reserved] += quantity
        
        send_response(
          available: true,
          product_id: product_id,
          reserved_quantity: quantity,
          remaining_stock: @inventory[product_id][:stock]
        )
      else
        send_response(
          available: false,
          product_id: product_id,
          requested_quantity: quantity,
          available_quantity: available_quantity
        )
      end
    end
  end

  private

  def load_inventory_data
    # Simulate inventory database
    {
      SecureRandom.uuid => { name: 'Widget A', stock: 100, reserved: 0, price: 29.99 },
      SecureRandom.uuid => { name: 'Widget B', stock: 50, reserved: 0, price: 39.99 },
      SecureRandom.uuid => { name: 'Widget C', stock: 25, reserved: 0, price: 49.99 }
    }
  end
end
```

### Payment Processing Service

```ruby
class PaymentAgent < Agent99::Base
  def initialize
    super
    @payments = {}
  end

  def info
    {
      name: self.class.to_s,
      type: :server,
      capabilities: ['payment', 'billing']
    }
  end

  def process_request(payload)
    customer_id = payload.dig(:customer_id)
    amount = payload.dig(:amount)
    currency = payload.dig(:currency, 'USD')
    
    # Simulate payment processing
    payment_id = SecureRandom.uuid
    
    # Simulate occasional payment failures
    if rand < 0.05 # 5% failure rate
      return send_error("Payment declined", "PAYMENT_DECLINED", {
        reason: 'insufficient_funds',
        payment_id: payment_id
      })
    end
    
    # Process payment
    payment_result = {
      payment_id: payment_id,
      customer_id: customer_id,
      amount: amount,
      currency: currency,
      status: 'completed',
      processed_at: Time.now.iso8601,
      transaction_id: "txn_#{SecureRandom.hex(8)}"
    }
    
    @payments[payment_id] = payment_result
    
    send_response(
      success: true,
      payment_id: payment_id,
      amount: amount,
      transaction_id: payment_result[:transaction_id]
    )
  end
end
```

## Event-Driven Architecture Example

Implementing an event-driven system with Agent99:

### Event Bus Agent

```ruby
class EventBusAgent < Agent99::Base
  def initialize
    super
    @subscribers = {}
    @events = []
  end

  def info
    {
      name: self.class.to_s,
      type: :hybrid,
      capabilities: ['event_bus', 'pub_sub', 'messaging']
    }
  end

  def process_request(payload)
    action = payload.dig(:action)
    
    case action
    when 'publish'
      publish_event(payload)
    when 'subscribe'
      subscribe_to_events(payload)
    when 'get_events'
      get_events(payload)
    else
      send_error("Unknown action: #{action}", "INVALID_ACTION")
    end
  end

  private

  def publish_event(payload)
    event = {
      id: SecureRandom.uuid,
      type: payload[:event_type],
      source: payload[:source],
      data: payload[:data],
      timestamp: Time.now.iso8601
    }
    
    @events << event
    
    # Notify subscribers
    subscribers = @subscribers[event[:type]] || []
    subscribers.each do |subscriber|
      notify_subscriber(subscriber, event)
    end
    
    send_response(
      event_id: event[:id],
      published: true,
      subscribers_notified: subscribers.size
    )
  end

  def subscribe_to_events(payload)
    event_type = payload[:event_type]
    subscriber = payload[:subscriber]
    
    @subscribers[event_type] ||= []
    @subscribers[event_type] << subscriber unless @subscribers[event_type].include?(subscriber)
    
    send_response(
      subscribed: true,
      event_type: event_type,
      subscriber: subscriber
    )
  end

  def get_events(payload)
    event_type = payload[:event_type]
    since = payload[:since] ? Time.parse(payload[:since]) : (Time.now - 3600)
    
    filtered_events = @events.select do |event|
      (event_type.nil? || event[:type] == event_type) &&
      Time.parse(event[:timestamp]) >= since
    end
    
    send_response(
      events: filtered_events,
      count: filtered_events.size
    )
  end

  def notify_subscriber(subscriber, event)
    Thread.new do
      begin
        agents = discover_agents([subscriber])
        if agents.any?
          agent = agents.first
          send_request(agent[:name], {
            action: 'handle_event',
            event: event
          })
        end
      rescue => e
        logger.error "Failed to notify subscriber #{subscriber}: #{e.message}"
      end
    end
  end
end
```

### Event Subscriber Example

```ruby
class AuditAgent < Agent99::Base
  def initialize
    super
    @audit_log = []
    subscribe_to_events
  end

  def info
    {
      name: self.class.to_s,
      type: :hybrid,
      capabilities: ['audit', 'logging', 'compliance']
    }
  end

  def process_request(payload)
    action = payload.dig(:action)
    
    case action
    when 'handle_event'
      handle_event(payload[:event])
    when 'get_audit_log'
      get_audit_log(payload)
    else
      send_error("Unknown action: #{action}", "INVALID_ACTION")
    end
  end

  private

  def subscribe_to_events
    event_bus_agents = discover_agents(['event_bus'])
    return unless event_bus_agents.any?
    
    event_bus = event_bus_agents.first
    
    # Subscribe to various event types
    %w[order_created payment_processed user_login].each do |event_type|
      send_request(event_bus[:name], {
        action: 'subscribe',
        event_type: event_type,
        subscriber: 'audit'
      })
    end
  end

  def handle_event(event)
    audit_entry = {
      id: SecureRandom.uuid,
      event_id: event[:id],
      event_type: event[:type],
      source: event[:source],
      timestamp: event[:timestamp],
      data: event[:data],
      processed_at: Time.now.iso8601
    }
    
    @audit_log << audit_entry
    
    # Log to file or database
    File.open('audit.log', 'a') do |f|
      f.puts audit_entry.to_json
    end
    
    send_response(
      audit_id: audit_entry[:id],
      logged: true
    )
  end

  def get_audit_log(payload)
    event_type = payload[:event_type]
    since = payload[:since] ? Time.parse(payload[:since]) : (Time.now - 86400)
    
    filtered_entries = @audit_log.select do |entry|
      (event_type.nil? || entry[:event_type] == event_type) &&
      Time.parse(entry[:timestamp]) >= since
    end
    
    send_response(
      audit_entries: filtered_entries,
      count: filtered_entries.size
    )
  end
end
```

## Distributed Cache Example

Building a distributed cache using multiple Agent99 agents:

### Cache Coordinator

```ruby
class CacheCoordinator < Agent99::Base
  def initialize
    super
    @ring = ConsistentHashRing.new
    @cache_nodes = {}
    discover_cache_nodes
  end

  def info
    {
      name: self.class.to_s,
      type: :hybrid,
      capabilities: ['cache_coordinator', 'distributed_cache']
    }
  end

  def process_request(payload)
    operation = payload.dig(:operation)
    key = payload.dig(:key)
    
    case operation
    when 'get'
      get_from_cache(key)
    when 'set'
      set_in_cache(key, payload[:value], payload[:ttl])
    when 'delete'
      delete_from_cache(key)
    when 'stats'
      get_cache_stats
    else
      send_error("Unknown operation: #{operation}", "INVALID_OPERATION")
    end
  end

  private

  def discover_cache_nodes
    cache_nodes = discover_agents(['cache_node'])
    
    cache_nodes.each do |node|
      @ring.add_node(node[:name])
      @cache_nodes[node[:name]] = node
    end
    
    logger.info "Discovered #{cache_nodes.size} cache nodes"
  end

  def get_from_cache(key)
    node_name = @ring.get_node(key)
    node = @cache_nodes[node_name]
    
    return send_error("No cache nodes available", "NO_CACHE_NODES") unless node
    
    response = send_request(node[:name], {
      operation: 'get',
      key: key
    })
    
    if response && response[:found]
      send_response(
        found: true,
        value: response[:value],
        node: node_name
      )
    else
      send_response(
        found: false,
        node: node_name
      )
    end
  end

  def set_in_cache(key, value, ttl = nil)
    node_name = @ring.get_node(key)
    node = @cache_nodes[node_name]
    
    return send_error("No cache nodes available", "NO_CACHE_NODES") unless node
    
    response = send_request(node[:name], {
      operation: 'set',
      key: key,
      value: value,
      ttl: ttl
    })
    
    send_response(
      stored: response && response[:stored],
      node: node_name
    )
  end

  def delete_from_cache(key)
    node_name = @ring.get_node(key)
    node = @cache_nodes[node_name]
    
    return send_error("No cache nodes available", "NO_CACHE_NODES") unless node
    
    response = send_request(node[:name], {
      operation: 'delete',
      key: key
    })
    
    send_response(
      deleted: response && response[:deleted],
      node: node_name
    )
  end

  def get_cache_stats
    stats = {}
    
    @cache_nodes.each do |node_name, node|
      response = send_request(node[:name], { operation: 'stats' })
      stats[node_name] = response if response
    end
    
    send_response(
      node_stats: stats,
      total_nodes: @cache_nodes.size
    )
  end
end

# Simple consistent hash ring implementation
class ConsistentHashRing
  def initialize
    @ring = {}
    @sorted_keys = []
  end

  def add_node(node_name, virtual_nodes = 150)
    virtual_nodes.times do |i|
      key = Digest::SHA1.hexdigest("#{node_name}:#{i}").to_i(16)
      @ring[key] = node_name
    end
    @sorted_keys = @ring.keys.sort
  end

  def get_node(key)
    return nil if @ring.empty?
    
    hash = Digest::SHA1.hexdigest(key.to_s).to_i(16)
    
    # Find first node >= hash
    idx = @sorted_keys.bsearch_index { |k| k >= hash }
    idx ||= 0  # Wrap around to first node
    
    @ring[@sorted_keys[idx]]
  end
end
```

### Cache Node

```ruby
class CacheNodeAgent < Agent99::Base
  def initialize(node_id = nil)
    super
    @node_id = node_id || "cache_#{SecureRandom.hex(4)}"
    @cache = {}
    @stats = { gets: 0, sets: 0, deletes: 0, hits: 0, misses: 0 }
    @mutex = Mutex.new
    
    # Start TTL cleanup thread
    start_ttl_cleanup
  end

  def info
    {
      name: "#{self.class}_#{@node_id}",
      type: :server,
      capabilities: ['cache_node', 'storage']
    }
  end

  def process_request(payload)
    operation = payload.dig(:operation)
    
    case operation
    when 'get'
      get_value(payload[:key])
    when 'set'
      set_value(payload[:key], payload[:value], payload[:ttl])
    when 'delete'
      delete_value(payload[:key])
    when 'stats'
      get_stats
    when 'clear'
      clear_cache
    else
      send_error("Unknown operation: #{operation}", "INVALID_OPERATION")
    end
  end

  private

  def get_value(key)
    @mutex.synchronize do
      @stats[:gets] += 1
      
      entry = @cache[key]
      
      if entry && !expired?(entry)
        @stats[:hits] += 1
        send_response(
          found: true,
          value: entry[:value],
          expires_at: entry[:expires_at]
        )
      else
        @stats[:misses] += 1
        @cache.delete(key) if entry # Clean up expired entry
        send_response(found: false)
      end
    end
  end

  def set_value(key, value, ttl = nil)
    @mutex.synchronize do
      @stats[:sets] += 1
      
      entry = {
        value: value,
        created_at: Time.now,
        expires_at: ttl ? Time.now + ttl : nil
      }
      
      @cache[key] = entry
      
      send_response(
        stored: true,
        expires_at: entry[:expires_at]
      )
    end
  end

  def delete_value(key)
    @mutex.synchronize do
      @stats[:deletes] += 1
      deleted = @cache.delete(key)
      
      send_response(deleted: !deleted.nil?)
    end
  end

  def get_stats
    @mutex.synchronize do
      send_response(
        node_id: @node_id,
        stats: @stats.dup,
        cache_size: @cache.size,
        memory_usage: estimate_memory_usage
      )
    end
  end

  def clear_cache
    @mutex.synchronize do
      cleared_count = @cache.size
      @cache.clear
      
      send_response(
        cleared: true,
        entries_removed: cleared_count
      )
    end
  end

  def expired?(entry)
    entry[:expires_at] && entry[:expires_at] < Time.now
  end

  def estimate_memory_usage
    # Simple memory estimation
    @cache.to_s.bytesize
  end

  def start_ttl_cleanup
    Thread.new do
      loop do
        sleep(60) # Run every minute
        
        @mutex.synchronize do
          expired_keys = @cache.select { |k, v| expired?(v) }.keys
          expired_keys.each { |key| @cache.delete(key) }
          
          logger.debug "Cleaned up #{expired_keys.size} expired cache entries" if expired_keys.any?
        end
      end
    end
  end
end
```

## Real-time Analytics Pipeline

Building a real-time analytics system:

### Data Ingestion Agent

```ruby
class DataIngestionAgent < Agent99::Base
  def initialize
    super
    @buffer = []
    @buffer_mutex = Mutex.new
    @batch_size = 100
    @flush_interval = 30 # seconds
    
    start_batch_processor
  end

  def info
    {
      name: self.class.to_s,
      type: :hybrid,
      capabilities: ['data_ingestion', 'stream_processing']
    }
  end

  def process_request(payload)
    action = payload.dig(:action)
    
    case action
    when 'ingest'
      ingest_data(payload[:data])
    when 'flush'
      flush_buffer
    when 'stats'
      get_ingestion_stats
    else
      send_error("Unknown action: #{action}", "INVALID_ACTION")
    end
  end

  private

  def ingest_data(data)
    enriched_data = {
      id: SecureRandom.uuid,
      raw_data: data,
      ingested_at: Time.now.iso8601,
      source_ip: header_value('source_ip'),
      user_agent: header_value('user_agent')
    }
    
    @buffer_mutex.synchronize do
      @buffer << enriched_data
      
      if @buffer.size >= @batch_size
        flush_buffer_unsafe
      end
    end
    
    send_response(
      ingested: true,
      data_id: enriched_data[:id],
      buffer_size: @buffer.size
    )
  end

  def flush_buffer
    @buffer_mutex.synchronize do
      flush_buffer_unsafe
    end
  end

  def flush_buffer_unsafe
    return if @buffer.empty?
    
    batch = @buffer.dup
    @buffer.clear
    
    # Send to analytics processor
    analytics_agents = discover_agents(['analytics_processor'])
    
    if analytics_agents.any?
      analytics_agent = analytics_agents.first
      
      Thread.new do
        send_request(analytics_agent[:name], {
          action: 'process_batch',
          batch: batch,
          batch_size: batch.size
        })
      end
    else
      logger.warn "No analytics processors available, data lost"
    end
    
    logger.info "Flushed batch of #{batch.size} records"
  end

  def start_batch_processor
    Thread.new do
      loop do
        sleep(@flush_interval)
        flush_buffer
      end
    end
  end

  def get_ingestion_stats
    @buffer_mutex.synchronize do
      send_response(
        buffer_size: @buffer.size,
        batch_size: @batch_size,
        flush_interval: @flush_interval
      )
    end
  end
end
```

These advanced examples demonstrate:

- **Complex microservices architectures** with multiple interacting services
- **Event-driven patterns** with pub/sub messaging
- **Distributed systems concepts** like consistent hashing and caching
- **Real-time data processing** with buffering and batch processing
- **Error handling and resilience** patterns
- **Performance optimization** techniques
- **Production-ready patterns** with monitoring and stats

Each example can be extended further with additional features like:
- Persistence layers (databases, file systems)
- Authentication and authorization
- Rate limiting and throttling  
- Circuit breakers and retry logic
- Distributed tracing and monitoring
- Configuration management
- Health checks and service discovery

## Next Steps

- **[Multi-Agent Processing](../advanced-topics/multi-agent-processing.md)** - Coordination patterns
- **[Performance Considerations](../operations/performance-considerations.md)** - Optimization techniques
- **[Configuration](../operations/configuration.md)** - Production deployment settings