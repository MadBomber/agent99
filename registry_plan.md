# Agent99 Registry Architecture Plan

**Note**: The production-ready registry infrastructure will be implemented in a separate repository called **`control-registry`** to maintain clear separation of concerns from the core Agent99 framework. This repository will contain the base classes and pluggable architecture described in this plan.

## Agent Data Schema

### Core Agent Information
```yaml
agent:
  # Identity
  uuid: string                    # Unique identifier (auto-generated)
  name: string                    # Human-readable name
  version: string                 # Agent version
  
  # Classification
  type: enum                      # server, client, hybrid
  namespace: string               # Organizational grouping (e.g., "production.us-east")
  tags: array[string]             # Arbitrary tags for filtering
  
  # Capabilities
  capabilities: array[object]     # What the agent can do
    - name: string                # Capability name (e.g., "calculation")
    - version: string             # Capability version
    - schema: json                # Input/output schema for capability
    - performance: object         # Performance characteristics
        avg_response_time: number
        throughput: number
        success_rate: number
  
  # Network Information
  network:
    hostname: string              # DNS hostname
    ip_addresses: array[string]   # All IPs agent is listening on
    transport_endpoints:          # How to reach this agent
      amqp: string                # amqp://queue_name
      nats: string                # nats://subject
      named_pipe: string          # /tmp/agent99/pipes/agent.in.pipe
      lanet: string               # 192.168.1.100:8080
      http: string                # https://api.example.com/agent
  
  # Health & Status
  status:
    state: enum                   # active, idle, busy, offline, error
    registered_at: timestamp      # When agent joined registry
    last_heartbeat: timestamp     # Last health check
    last_activity: timestamp      # Last request processed
    health_score: number          # 0-100 health rating
    current_load: number          # Current processing load
  
  # Metadata
  metadata:
    owner: string                 # Team/person responsible
    environment: string           # dev, staging, production
    location: string              # Geographic location/datacenter
    runtime: object               # Runtime information
      platform: string            # ruby, python, node, etc.
      version: string             # Runtime version
      dependencies: array[string] # Required libraries
    resources:                    # Resource constraints/usage
      cpu_cores: number
      memory_mb: number
      disk_gb: number
  
  # Security & Auth
  security:
    public_key: string            # For message verification
    auth_tokens: array[string]    # Accepted auth methods
    permissions: array[string]    # What agent is allowed to do
    audit_log: boolean           # Whether to audit this agent
  
  # Relationships
  relationships:
    depends_on: array[uuid]       # Other agents this depends on
    provides_to: array[uuid]      # Agents that depend on this
    peer_group: string            # Logical grouping of peers
```

### Extended Schema for Advanced Features
```yaml
agent_extended:
  # Performance Metrics (time-series data)
  metrics:
    - timestamp: timestamp
      cpu_usage: number
      memory_usage: number
      request_count: number
      error_count: number
      response_times: array[number]
  
  # Service Discovery
  discovery:
    ttl: number                   # Time-to-live in seconds
    priority: number              # Selection priority (lower = higher priority)
    weight: number                # Load balancing weight
    backup_agents: array[uuid]    # Fallback agents
  
  # Semantic Capabilities (AI/ML features)
  semantic:
    capability_embeddings: array[vector]  # Vector representations
    description: string                    # Natural language description
    examples: array[object]               # Example requests/responses
```

## Centralized vs Distributed Architecture

### Why Centralized (Current Approach)

**Advantages:**
- **Simplicity**: Single source of truth, easy to understand
- **Consistency**: No synchronization issues
- **Query Performance**: Fast lookups from single location
- **Management**: Easy backup, monitoring, debugging

**Disadvantages:**
- **Single Point of Failure**: Registry down = system down
- **Scalability Limits**: All queries hit one service
- **Network Latency**: Remote agents have higher latency
- **Bottleneck**: Can become performance bottleneck

### Distributed Architecture Options

#### 1. DNS-Like Hierarchical Model
```
                 Root Registry
                      |
        +-------------+-------------+
        |             |             |
   .americas     .europe      .asia-pacific
        |             |             |
   .us-east      .eu-west      .ap-south
        |             |             |
   [agents]      [agents]       [agents]
```

**Implementation:**
```ruby
class HierarchicalRegistry
  def initialize(parent: nil, zone: nil)
    @parent = parent  # Parent registry
    @zone = zone      # e.g., "us-east.americas"
    @local_agents = {}
    @child_zones = {}
  end
  
  def discover(capability, recursive: true)
    # Check local agents first
    local_results = @local_agents.select { |a| a.has_capability?(capability) }
    
    if local_results.empty? && recursive
      # Query child zones
      @child_zones.each do |zone, registry|
        results = zone.discover(capability)
        return results unless results.empty?
      end
      
      # Query parent if no local results
      @parent&.discover(capability) || []
    else
      local_results
    end
  end
end
```

#### 2. Peer-to-Peer DHT Model
```ruby
# Distributed Hash Table approach (like Kademlia)
class DHTRegistry
  def initialize(node_id)
    @node_id = node_id
    @routing_table = RoutingTable.new
    @local_storage = {}
  end
  
  def store(agent_uuid, agent_data)
    target_node = find_closest_node(hash(agent_uuid))
    if target_node == @node_id
      @local_storage[agent_uuid] = agent_data
    else
      forward_to_node(target_node, agent_uuid, agent_data)
    end
  end
end
```

#### 3. Consensus-Based (Raft/Etcd style)
```ruby
# Multiple registry nodes with leader election
class ConsensusRegistry
  def initialize
    @state = :follower
    @leader = nil
    @peers = []
    @log = []
  end
  
  def register_agent(agent_data)
    if @state == :leader
      # Replicate to majority of peers
      replicate_to_peers(agent_data)
    else
      # Forward to leader
      forward_to_leader(agent_data)
    end
  end
end
```

## DNS-Inspired Model with WHOIS

### Hierarchical Namespace
```
agent99://greeting.services.us-east.americas/
         └─capability
                    └─service_type
                              └─region
                                      └─zone
```

### WHOIS-Like Query System

```ruby
class Agent99Whois
  def whois(query)
    # Support multiple query types
    case query
    when /^uuid:(.+)/
      lookup_by_uuid($1)
    when /^capability:(.+)/
      lookup_by_capability($1)
    when /^namespace:(.+)/
      lookup_by_namespace($1)
    when /^owner:(.+)/
      lookup_by_owner($1)
    else
      fuzzy_search(query)
    end
  end
  
  def format_whois_response(agent)
    <<~WHOIS
      Agent UUID: #{agent.uuid}
      Agent Name: #{agent.name}
      Namespace: #{agent.namespace}
      Type: #{agent.type}
      
      Capabilities:
      #{agent.capabilities.map { |c| "  - #{c.name} (v#{c.version})" }.join("\n")}
      
      Network Information:
        Hostname: #{agent.network.hostname}
        IP Addresses: #{agent.network.ip_addresses.join(', ')}
        Transports: #{agent.network.transport_endpoints.keys.join(', ')}
      
      Status:
        State: #{agent.status.state}
        Registered: #{agent.status.registered_at}
        Last Seen: #{agent.status.last_heartbeat}
        Health Score: #{agent.status.health_score}/100
      
      Administrative Contact:
        Owner: #{agent.metadata.owner}
        Environment: #{agent.metadata.environment}
        Location: #{agent.metadata.location}
      
      Registry Information:
        Registry Server: #{self.server_name}
        Registry Zone: #{self.zone}
        Query Time: #{Time.now}
    WHOIS
  end
end
```

### CLI WHOIS Command
```bash
# Query agent information
$ agent99 whois uuid:86c7f0d1-e3a4-4e5c-b8a9-2d4f5e6a7b8c

# Find agents by capability
$ agent99 whois capability:greeting

# Find all agents in namespace
$ agent99 whois namespace:production.us-east

# Find agents by owner
$ agent99 whois owner:platform-team

# Fuzzy search
$ agent99 whois "calculation service"
```

### DNS-Like Resolution with Load Balancing

#### Agent Names vs UUIDs
**Design Principle: Names for Services, UUIDs for Instances**

```ruby
# UUID: Always unique (instance identifier)
uuid: "86c7f0d1-e3a4-4e5c-b8a9-2d4f5e6a7b8c"

# Name: Can have duplicates (service identifier)
name: "calculation_agent"
```

#### Multiple Agents with Same Name = Service Scaling
```yaml
# Multiple instances of the same service
- uuid: "uuid-001"
  name: "financial_processor"  # Same name
  instance: 1
  zone: "us-east.americas"
  status: "active"
  load: 45%

- uuid: "uuid-002" 
  name: "financial_processor"  # Same name
  instance: 2
  zone: "us-east.americas" 
  status: "active"
  load: 78%

- uuid: "uuid-003"
  name: "financial_processor"  # Same name
  instance: 3
  zone: "us-west.americas"
  status: "active"
  load: 23%
```

#### DNS-Like Resolution with Load Balancing
```ruby
class Agent99Resolver
  def resolve(query, strategy: :round_robin)
    # Parse hierarchical query
    # financial_processor.services.us-east.americas
    parts = query.split('.')
    
    service_name = parts[0]    # "financial_processor" 
    service_type = parts[1]    # "services"
    region = parts[2]          # "us-east"
    zone = parts[3]            # "americas"
    
    # Find all agents with matching name
    registry = find_registry(zone, region)
    agents = registry.find_by_name(service_name)
    
    # Filter by health and availability
    healthy_agents = agents.select { |a| a.health_score > 70 && a.status == "active" }
    
    # Apply load balancing strategy
    select_agent(healthy_agents, strategy)
  end
  
  private
  
  def select_agent(agents, strategy)
    case strategy
    when :round_robin
      @round_robin_index = (@round_robin_index || 0) + 1
      agents[@round_robin_index % agents.size]
      
    when :least_loaded
      agents.min_by { |agent| agent.current_load }
      
    when :random
      agents.sample
      
    when :proximity
      agents.min_by { |agent| calculate_latency(agent) }
      
    when :weighted
      # Consider both load and health score
      agents.max_by { |agent| (agent.health_score * 0.7) + ((100 - agent.current_load) * 0.3) }
    end
  end
end
```

#### Service Discovery Patterns
```ruby
# 1. Exact service name resolution
agents = resolver.resolve("financial_processor.services.us-east.americas")
# Returns: One agent from the pool based on load balancing

# 2. Get all instances of a service
all_instances = registry.find_all_by_name("financial_processor")
# Returns: All agents with that name across all zones

# 3. Service health check
healthy_count = registry.count_healthy("financial_processor")
# Returns: Number of healthy instances

# 4. Geographic distribution
east_agents = resolver.resolve("financial_processor.services.us-east.americas")
west_agents = resolver.resolve("financial_processor.services.us-west.americas")
```

#### Naming Strategies for Scaling

**Strategy 1: Service Classes**
```yaml
# Multiple agents providing same service
name: "calculation_service"      # Same name = same service type
instances: 5                     # 5 instances for scaling
capability: "mathematical_computation"
```

**Strategy 2: Versioned Services**
```yaml
# Different versions of same service
- name: "payment_processor_v1"   # Legacy version
- name: "payment_processor_v2"   # Current version  
- name: "payment_processor_v3"   # Beta version
```

**Strategy 3: Specialized Variants**
```yaml
# Specialized versions of base service
- name: "image_processor_gpu"    # GPU-optimized
- name: "image_processor_cpu"    # CPU-optimized
- name: "image_processor_edge"   # Edge-optimized
```

#### Registry Schema Enhancement for Scaling
```yaml
agent:
  uuid: string                   # Always unique
  name: string                   # Can have duplicates
  service_class: string          # Logical service grouping
  instance_id: number            # Instance number within service
  
  # Scaling metadata
  scaling:
    min_instances: number        # Minimum required instances
    max_instances: number        # Maximum allowed instances
    target_load: number          # Target load per instance
    scale_metric: string         # CPU, memory, requests_per_second
  
  # Load balancing
  load_balancing:
    weight: number               # Weighted round-robin weight
    priority: number             # Higher priority = preferred
    sticky_sessions: boolean     # Client session affinity
```

### Benefits of Duplicate Names

#### 1. Horizontal Scaling
```ruby
# Start with one agent
register_agent(name: "data_processor", instance: 1)

# Scale up by adding more instances
register_agent(name: "data_processor", instance: 2)
register_agent(name: "data_processor", instance: 3)

# Client code doesn't change - still requests "data_processor"
agent = resolver.resolve("data_processor.services.production")
```

#### 2. Rolling Deployments
```ruby
# Deploy new version alongside old
register_agent(name: "api_gateway", version: "v2.1", weight: 10)   # New version, low traffic
# Keep old version running
# api_gateway v2.0 instances still handling 90% traffic

# Gradually shift traffic
update_agent_weight("api_gateway", version: "v2.1", weight: 50)    # 50/50 split
update_agent_weight("api_gateway", version: "v2.1", weight: 100)   # Full traffic

# Remove old instances
withdraw_agents(name: "api_gateway", version: "v2.0")
```

#### 3. Geographic Distribution
```ruby
# Same service deployed globally
register_agent(name: "user_service", zone: "us-east.americas")
register_agent(name: "user_service", zone: "eu-west.europe") 
register_agent(name: "user_service", zone: "ap-south.asia")

# Resolver picks closest instance automatically
local_agent = resolver.resolve("user_service.services.#{local_zone}")
```

#### 4. Fault Tolerance
```ruby
# Multiple instances provide redundancy
if primary_agent_fails?
  # Registry automatically routes to healthy instances
  backup_agent = resolver.resolve("critical_service.services.production")
  # No application code changes needed
end
```

## Security Implications of Duplicate Names

### Security Risks

#### 1. Agent Impersonation Attack
**Threat**: Malicious agent registers with same name as legitimate service
```ruby
# Legitimate agent
register_agent(name: "payment_processor", owner: "finance_team", uuid: "legitimate-uuid")

# Malicious agent impersonating
register_agent(name: "payment_processor", owner: "attacker", uuid: "malicious-uuid")
# Now load balancer might route sensitive payments to attacker!
```

#### 2. Service Hijacking
**Threat**: Attacker deploys agent with higher priority/weight
```ruby
# Attacker registers with higher priority
register_agent(
  name: "user_authentication", 
  priority: 1,           # Higher than legitimate agents (priority: 10)
  weight: 1000,          # Much higher weight
  zone: "production"
)
# All authentication requests now go to malicious agent
```

#### 3. Data Exfiltration via DNS-like Queries
**Threat**: Attacker queries for sensitive services
```bash
# Reconnaissance attacks
$ agent99 whois capability:financial_processor
$ agent99 discover namespace:production.sensitive
# Exposes internal architecture and service locations
```

#### 4. Namespace Pollution
**Threat**: Filling namespace with fake agents
```ruby
# Spam attack - register thousands of fake agents
1000.times do |i|
  register_agent(name: "critical_service", instance: i, owner: "attacker")
end
# Legitimate agents drowned out by noise
```

### Security Controls & Mitigations

#### 1. Ownership-Based Authorization
```ruby
class Agent99::Registry::SecurityManager
  def register_agent(agent_data, credentials)
    # Verify authorization to use this service name
    if existing_service?(agent_data[:name])
      unless authorized_for_service?(credentials, agent_data[:name])
        raise UnauthorizedError, "Not authorized to register agents for service: #{agent_data[:name]}"
      end
    else
      # First registration - establish ownership
      establish_service_ownership(agent_data[:name], credentials[:owner])
    end
    
    # Additional validations
    verify_digital_signature(agent_data, credentials)
    check_certificate_chain(credentials[:cert])
    validate_network_location(agent_data[:network])
    
    register(agent_data)
  end
  
  private
  
  def authorized_for_service?(credentials, service_name)
    service_owners = get_service_owners(service_name)
    service_owners.include?(credentials[:owner]) ||
      has_delegation_permission?(credentials[:owner], service_name)
  end
end
```

#### 2. Digital Signatures & Certificates
```yaml
agent:
  uuid: string
  name: string
  
  # Security credentials
  security:
    public_key: string              # Agent's public key
    certificate: string             # X.509 certificate
    certificate_authority: string   # Issuing CA
    signature: string               # Registry entry signature
    
    # Service authorization
    service_authorization:
      service_name: string          # Authorized service name
      authorized_by: string         # Who granted permission
      expires_at: timestamp         # Permission expiration
      permissions: array[string]    # Specific permissions
```

#### 3. Namespace Access Control Lists (ACLs)
```ruby
class ServiceACL
  def initialize(service_name)
    @service_name = service_name
    @owners = []           # Full control
    @operators = []        # Can deploy instances
    @readers = []          # Can query only
  end
  
  def can_register?(user, action = :register)
    case action
    when :register
      @owners.include?(user) || @operators.include?(user)
    when :query
      @owners.include?(user) || @operators.include?(user) || @readers.include?(user)
    when :modify_acl
      @owners.include?(user)
    end
  end
end

# Usage
payment_acl = ServiceACL.new("payment_processor")
payment_acl.owners = ["finance_team_lead"]
payment_acl.operators = ["finance_team", "platform_team"]  
payment_acl.readers = ["monitoring_team", "audit_team"]
```

#### 4. Multi-Factor Registration Validation
```ruby
def secure_register_agent(agent_data, credentials)
  # 1. Cryptographic proof of identity
  verify_agent_signature(agent_data, credentials[:private_key])
  
  # 2. Network location validation  
  verify_network_location(agent_data[:network][:ip_addresses])
  
  # 3. Service ownership check
  verify_service_authorization(agent_data[:name], credentials[:owner])
  
  # 4. Certificate chain validation
  verify_certificate_chain(credentials[:certificate])
  
  # 5. Rate limiting
  enforce_registration_rate_limits(credentials[:owner])
  
  # 6. Audit logging
  audit_log.record_registration(agent_data, credentials, result: :success)
  
  register_with_security_metadata(agent_data, credentials)
end
```

#### 5. Query Authorization & Audit
```ruby
class SecureRegistryQuery
  def whois(query, requester_credentials)
    # Check query permissions
    unless authorized_for_query?(requester_credentials, query)
      audit_log.record_unauthorized_query(query, requester_credentials)
      raise UnauthorizedError, "Insufficient permissions for query"
    end
    
    # Filter results based on permissions
    results = perform_query(query)
    filter_sensitive_data(results, requester_credentials)
  end
  
  private
  
  def filter_sensitive_data(results, credentials)
    results.map do |agent|
      case credentials[:clearance_level]
      when :public
        agent.slice(:name, :capabilities, :status)  # Basic info only
      when :operator  
        agent.except(:security, :internal_metadata) # Most info
      when :admin
        agent  # Full access
      end
    end
  end
end
```

#### 6. Registry Integrity Protection
```ruby
class RegistryIntegrityManager
  def register_agent(agent_data)
    # Create tamper-proof registry entry
    registry_entry = {
      agent: agent_data,
      registered_at: Time.now.utc,
      registered_by: current_user,
      integrity_hash: calculate_integrity_hash(agent_data),
      previous_entry_hash: get_last_entry_hash  # Blockchain-like chaining
    }
    
    # Sign the entire entry
    registry_entry[:registry_signature] = sign_entry(registry_entry)
    
    store_registry_entry(registry_entry)
  end
  
  def verify_registry_integrity
    # Verify the chain of registry entries hasn't been tampered with
    verify_entry_chain
    verify_all_signatures
    detect_unauthorized_modifications
  end
end
```

### Access Control Models

#### Model 1: Hierarchical Ownership
```
finance_team_lead (owner)
├── finance_team (operators)
│   ├── payment_processor_v1
│   ├── payment_processor_v2  
│   └── billing_service
└── contractors (readers only)
```

#### Model 2: Service-Based RBAC
```ruby
# Role definitions
roles = {
  service_owner: [:register, :modify, :delete, :query, :admin],
  service_operator: [:register, :modify, :query],
  service_reader: [:query],
  auditor: [:query_audit_logs, :security_scan]
}

# Service permissions
"payment_processor" => {
  owners: ["alice@finance.com"],
  operators: ["finance-team@company.com"],
  readers: ["monitoring@company.com", "audit@company.com"]
}
```

#### Model 3: Certificate-Based Trust
```ruby
# Only agents with valid certificates from trusted CAs can register
trusted_cas = [
  "CN=Company Internal CA",
  "CN=Finance Department CA", 
  "CN=Platform Team CA"
]

def validate_agent_certificate(cert)
  # 1. Certificate is from trusted CA
  ca_valid = trusted_cas.include?(cert.issuer)
  
  # 2. Certificate hasn't expired
  time_valid = cert.not_after > Time.now
  
  # 3. Certificate hasn't been revoked
  revocation_valid = !certificate_revoked?(cert)
  
  # 4. Service name matches certificate subject
  service_authorized = cert.subject.include?(agent_data[:name])
  
  ca_valid && time_valid && revocation_valid && service_authorized
end
```

### Recommendation: Layered Security Approach

1. **Authentication**: Strong cryptographic identity
2. **Authorization**: Service-level ACLs + ownership
3. **Audit**: Complete logging of all registry operations  
4. **Integrity**: Tamper-proof registry entries
5. **Isolation**: Network-level validation of agent locations
6. **Monitoring**: Real-time detection of suspicious patterns

## Current Implementation Analysis

### Existing Sinatra-Based Registry
The current registry implementation (`examples/registry.rb`) is a simple Sinatra web application with:

**Current Features:**
- **In-memory storage**: Simple Ruby array (`AGENT_REGISTRY = []`)
- **RESTful HTTP API**: POST /register, GET /discover, DELETE /withdraw
- **Basic discovery**: Simple keyword matching for capabilities
- **Human-readable**: JSON responses, web interface potential
- **Stateless**: Data lost on restart

**Limitations:**
- **No persistence**: Registry data lost on process restart
- **Single point of failure**: No redundancy or high availability
- **Limited scalability**: In-memory array won't scale beyond single process
- **Simple matching**: Only exact keyword matching, no semantic search
- **HTTP-only**: Requires HTTP client for all interactions
- **No authentication**: Any agent can register/withdraw any other agent

## Alternative Registry Architectures

### 1. Redis-Based Registry

**Architecture:**
```
Agent99 Agents ←→ Redis Server (Registry Data Store)
                   ├─ Hash: agents:{uuid} → agent data
                   ├─ Set: capabilities:{capability} → agent UUIDs
                   └─ Sorted Set: agent_heartbeats → timestamp scores
```

**Advantages:**
- **Persistence**: Optional RDB/AOF persistence
- **High performance**: In-memory with optional disk backing
- **Pub/Sub**: Built-in notification for registry changes
- **TTL support**: Automatic agent expiration
- **Clustering**: Redis Cluster for high availability
- **Rich data structures**: Sets, sorted sets, hashes for efficient queries

**Disadvantages:**
- **External dependency**: Requires Redis server
- **Limited query capabilities**: No complex queries without Lua scripts
- **Memory constraints**: All data must fit in memory

### 2. Database-Based Registry (SQLite/PostgreSQL)

**Architecture:**
```sql
-- SQLite/PostgreSQL Schema
CREATE TABLE agents (
  uuid TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT,
  registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_heartbeat TIMESTAMP,
  metadata JSONB
);

CREATE TABLE capabilities (
  id INTEGER PRIMARY KEY,
  agent_uuid TEXT REFERENCES agents(uuid) ON DELETE CASCADE,
  capability TEXT NOT NULL,
  description TEXT
);

-- Vector extension for semantic search (PostgreSQL)
CREATE EXTENSION vector;
ALTER TABLE capabilities ADD COLUMN embedding vector(384);
```

**Advantages:**
- **Full persistence**: ACID compliance, backups, replication
- **Complex queries**: SQL for sophisticated discovery patterns
- **Semantic search**: Vector embeddings for capability matching
- **Audit trail**: Historical tracking of agent registrations
- **Mature tooling**: Extensive ecosystem for management and monitoring

**Disadvantages:**
- **Higher latency**: Disk I/O for every operation
- **Complexity**: Requires database administration
- **External dependency**: Database server required

### 3. Filesystem-Based Registry

**Architecture:**
```
/var/lib/agent99/registry/
├── agents/
│   ├── {uuid1}.json      # Agent metadata
│   ├── {uuid2}.json
│   └── {uuid3}.json
├── capabilities/
│   ├── greeting.txt       # List of agent UUIDs with this capability
│   ├── calculation.txt
│   └── data_processing.txt
└── index.json             # Master index for quick lookups
```

**Advantages:**
- **No dependencies**: Uses only filesystem
- **Simple backup**: Just copy files
- **Human readable**: Direct file inspection
- **Git-compatible**: Can version control registry state
- **Distributed potential**: Can sync via rsync, NFS, etc.

**Disadvantages:**
- **Performance**: File I/O for each operation
- **Concurrency**: File locking complexity
- **No queries**: Must implement search logic
- **Scalability**: Degrades with many agents

### 4. Agent99-Based Registry (Self-Hosted)

**Architecture:**
```ruby
class RegistryAgent < Agent99::Base
  def info
    {
      name: "RegistryAgent",
      type: :hybrid,
      capabilities: ['registry', 'discovery', 'agent_management'],
      persistence: :configurable  # Redis, DB, or filesystem
    }
  end
  
  def process_request(payload)
    case payload[:action]
    when 'register'
      register_agent(payload[:agent_info])
    when 'discover'
      discover_agents(payload[:capability])
    when 'withdraw'
      withdraw_agent(payload[:uuid])
    end
  end
end
```

**Advantages:**
- **Dogfooding**: Registry uses Agent99 infrastructure
- **Distributed**: Multiple registry agents for redundancy
- **Transport agnostic**: Uses Agent99's transport layers
- **Consistent**: Same patterns as other agents
- **Extensible**: Add capabilities like semantic search easily

**Disadvantages:**
- **Bootstrap problem**: How to find registry agent initially?
- **Complexity**: Registry becomes dependent on Agent99 itself
- **Circular dependency**: Registry needs registry to register itself

## Recommended Hybrid Architecture

### Dual-Plugin Architecture: Frontend + Backend

**Complete Registry System:**
```
┌─────────────────────────────────────────────────────────┐
│           Frontend Interfaces (Pluggable)              │
├─────────────────────────────────────────────────────────┤
│ • Agent99 Frontend (dogfooding)                        │
│ • Sinatra HTTP API (lightweight)                       │
│ • Rails HTTP API + Admin UI (full-featured)           │
│ • CLI Interface (command-line management)              │
│ • gRPC Service (high-performance RPC)                  │
├─────────────────────────────────────────────────────────┤
│          Registry Core (CRUD Operations)               │
├─────────────────────────────────────────────────────────┤
│           Backend Storage (Pluggable)                  │
├─────────────────────────────────────────────────────────┤
│ • Memory • Redis • Database • Filesystem • Distributed │
└─────────────────────────────────────────────────────────┘
```

### Frontend Interface Plugins

#### 1. Agent99 Frontend (Registry as an Agent)
```ruby
class RegistryAgent < Agent99::Base
  def initialize(backend: :redis)
    @registry = Agent99::Registry.new(backend: backend)
    super
  end
  
  def info
    {
      name: "RegistryAgent",
      type: :hybrid,
      capabilities: ['registry.register', 'registry.discover', 
                    'registry.withdraw', 'registry.admin']
    }
  end
  
  def process_request(payload)
    case payload[:action]
    when 'register'
      @registry.register(payload[:agent_info])
    when 'discover'
      @registry.discover(payload[:capability])
    when 'withdraw'
      @registry.withdraw(payload[:uuid])
    when 'stats'
      @registry.statistics
    end
  end
end
```

#### 2. Sinatra HTTP Frontend (Current, Enhanced)
```ruby
class RegistryHTTP < Sinatra::Base
  def initialize(backend: :redis)
    @registry = Agent99::Registry.new(backend: backend)
    super
  end
  
  # RESTful API
  post '/register' do
    @registry.register(json_body)
  end
  
  # Human UI for troubleshooting
  get '/admin' do
    @agents = @registry.list_all
    erb :admin_dashboard
  end
end
```

#### 3. Rails Frontend (Enterprise Features)
```ruby
class RegistryController < ApplicationController
  before_action :authenticate_admin!, only: [:admin]
  
  def register
    @registry.register(agent_params)
    render json: { uuid: agent.uuid }
  end
  
  # Rich admin interface
  def admin
    @agents = @registry.list_all
    @stats = @registry.statistics
    @health = @registry.health_check
  end
end
```

#### 4. CLI Frontend (Command-Line Management)
```ruby
class RegistryCLI < Thor
  def initialize
    @registry = Agent99::Registry.new(
      backend: ENV['REGISTRY_BACKEND'] || :redis
    )
  end
  
  desc "list", "List all registered agents"
  option :format, default: "table"
  def list
    agents = @registry.list_all
    case options[:format]
    when "json"
      puts agents.to_json
    when "table"
      print_table(agents)
    when "yaml"
      puts agents.to_yaml
    end
  end
  
  desc "discover CAPABILITY", "Find agents by capability"
  def discover(capability)
    agents = @registry.discover(capability)
    print_table(agents)
  end
  
  desc "show UUID", "Show details for specific agent"
  def show(uuid)
    agent = @registry.get_agent(uuid)
    puts agent.to_yaml
  end
  
  desc "health", "Check registry health"
  def health
    status = @registry.health_check
    puts "Registry Status: #{status[:status]}"
    puts "Total Agents: #{status[:agent_count]}"
    puts "Active Agents: #{status[:active_count]}"
    puts "Backend: #{status[:backend_type]}"
  end
  
  desc "watch", "Live monitoring of registry changes"
  def watch
    @registry.subscribe do |event|
      puts "[#{Time.now}] #{event[:type]}: #{event[:agent_uuid]}"
    end
  end
end
```

### Agent99 with CLI Component

**Integrated Agent99 + CLI Design:**
```ruby
class RegistryAgent < Agent99::Base
  attr_reader :cli_enabled
  
  def initialize(backend: :redis, cli: false)
    @registry = Agent99::Registry.new(backend: backend)
    @cli_enabled = cli
    
    if @cli_enabled
      start_cli_interface
    end
    
    super
  end
  
  private
  
  def start_cli_interface
    Thread.new do
      # Run CLI in separate thread
      RegistryCLI.new(@registry).start
    end
  end
  
  # Or expose CLI through agent messages
  def process_request(payload)
    case payload[:action]
    when 'cli_command'
      execute_cli_command(payload[:command], payload[:args])
    else
      # Regular registry operations
    end
  end
  
  def execute_cli_command(command, args)
    case command
    when 'list'
      format_agents_list(@registry.list_all, args[:format])
    when 'watch'
      subscribe_to_changes
    when 'export'
      export_registry_data(args[:format])
    end
  end
end
```

### Primary Strategy: Pluggable Storage Backends

**Design Pattern (Control-Registry Repository):**
```ruby
module Control
  module Registry
    module DataStorage
      class Base
        def register(agent_info); raise NotImplementedError; end
        def discover(capability); raise NotImplementedError; end
        def withdraw(uuid); raise NotImplementedError; end
        def get_agent(uuid); raise NotImplementedError; end
        def list_all; raise NotImplementedError; end
        def heartbeat(uuid); raise NotImplementedError; end
      end
      
      class Redis < Base
        # Redis implementation
      end
      
      class Database < Base
        # SQLite/PostgreSQL implementation
      end
      
      class Filesystem < Base
        # Filesystem implementation
      end
      
      class Memory < Base
        # Current in-memory implementation
      end
    end
    
    module Frontend
      class Base
        def initialize(data_storage:)
          @storage = data_storage
        end
      end
      
      class Agent99 < Base
        # Agent99-based frontend
      end
      
      class Sinatra < Base  
        # HTTP API frontend
      end
      
      class CLI < Base
        # Command-line frontend
      end
    end
  end
end
```

### Registry Access Patterns (Using Control-Registry)

**1. Direct Library Access**
```ruby
# Using the control-registry gem
storage = Control::Registry::DataStorage::Redis.new
registry = Control::Registry::Core.new(storage: storage)
uuid = registry.register(agent_info)
```

**2. HTTP API Frontend**
```ruby
# HTTP API using control-registry backend
storage = Control::Registry::DataStorage::Redis.new
frontend = Control::Registry::Frontend::Sinatra.new(data_storage: storage)
frontend.start_server
```

**3. Agent99 Registry Agent**
```ruby
# Registry as an Agent99 agent using control-registry
class RegistryAgent < Agent99::Base
  def initialize
    storage = Control::Registry::DataStorage::Redis.new
    @registry_frontend = Control::Registry::Frontend::Agent99.new(data_storage: storage)
  end
end
```

### Storage Backend Recommendations

**Development Environment:**
- **Memory Backend**: Fast iteration, no dependencies
- **Filesystem Backend**: Persistence without external services

**Production - Small Scale (< 100 agents):**
- **SQLite Backend**: Simple, reliable, no server required
- **Filesystem Backend**: For embedded systems

**Production - Medium Scale (100-10,000 agents):**
- **Redis Backend**: High performance, pub/sub notifications
- **PostgreSQL Backend**: If complex queries needed

**Production - Large Scale (10,000+ agents):**
- **Redis Cluster**: Distributed, high availability
- **PostgreSQL + Redis**: PostgreSQL for persistence, Redis for cache

## Implementation Roadmap

**Repository Structure**: The following implementation will be done in the `control-registry` repository, with integration points back to the `agent99` core framework.

### Phase 1: Control-Registry Foundation (Week 1)
- [ ] Create `control-registry` repository with proper gem structure
- [ ] Create `Control::Registry::Frontend::Base` base class for frontend plugins
- [ ] Create `Control::Registry::DataStorage::Base` base class for storage backends  
- [ ] Implement `MemoryBackend` (extract from current Sinatra)
- [ ] Create backend factory pattern and plugin discovery system
- [ ] Add configuration system for backend/frontend selection

### Phase 2: Redis Backend (Week 2)
- [ ] Implement `Control::Registry::DataStorage::Redis` class
- [ ] Add Redis data structures for agents and capabilities
- [ ] Implement pub/sub for registry change notifications
- [ ] Add TTL-based agent expiration
- [ ] Create Redis connection pooling

### Phase 3: Database Backend (Week 3)
- [ ] Implement `Control::Registry::DataStorage::Database` with SQLite support
- [ ] Design schema for agents and capabilities
- [ ] Add PostgreSQL support (optional)
- [ ] Implement vector search for semantic discovery (PostgreSQL)
- [ ] Add database migration system

### Phase 4: Filesystem Backend (Week 4)
- [ ] Implement `Control::Registry::DataStorage::Filesystem` class
- [ ] Design directory structure for agent data
- [ ] Add file locking for concurrent access
- [ ] Implement atomic file operations
- [ ] Add index file for performance optimization

### Phase 5: Frontend Interfaces (Week 5)
- [ ] Create `Control::Registry::Frontend::Agent99` (registry as an agent)
- [ ] Create `Control::Registry::Frontend::Sinatra` (HTTP API)
- [ ] Create `Control::Registry::Frontend::CLI` (command-line interface)
- [ ] Solve bootstrap problem for Agent99 frontend (well-known addresses)
- [ ] Add distributed registry coordination

### Phase 6: Advanced Features & Security (Week 6)
- [ ] Implement security framework with authentication and authorization
- [ ] Add semantic capability matching with embeddings
- [ ] Agent health monitoring and automatic deregistration
- [ ] Registry federation for multi-cluster setups
- [ ] MCP server integration for AI-powered operations
- [ ] Audit logging and compliance features

## Frontend Interface Comparison

### Decision Matrix for Frontend Selection

| Frontend | Use Case | Pros | Cons |
|----------|----------|------|------|
| **Agent99** | Distributed systems | Dogfooding, uses Agent99 transport | Bootstrap complexity |
| **Sinatra** | Lightweight deployments | Simple, minimal dependencies | Limited UI capabilities |
| **Rails** | Enterprise deployments | Rich UI, authentication, audit trails | Heavy framework |
| **CLI** | DevOps/Admin | Direct access, scriptable | No remote access |
| **gRPC** | Microservices | High performance, type-safe | Complex setup |

### Frontend Composability

**Multiple Frontends, Same Backend:**
```ruby
# Start multiple frontends for the same registry backend
registry_backend = Agent99::Registry.new(backend: :redis)

# Agent99 frontend for agent-to-agent communication
agent_frontend = RegistryAgent.new(registry: registry_backend)

# HTTP API for external systems
http_frontend = RegistryHTTP.new(registry: registry_backend)

# CLI for administrators
cli_frontend = RegistryCLI.new(registry: registry_backend)

# All frontends operate on the same data
```

### CLI Integration Patterns

#### Pattern 1: Standalone CLI Tool
```bash
# Direct CLI access to registry
$ agent99-registry list
$ agent99-registry discover greeting
$ agent99-registry show uuid-12345
$ agent99-registry watch  # Live updates
```

#### Pattern 2: Agent99 with Embedded CLI
```ruby
# Agent that provides CLI interface
class RegistryAgentWithCLI < Agent99::Base
  def initialize
    super
    start_repl if ENV['REGISTRY_CLI_MODE']
  end
  
  def start_repl
    require 'pry'
    binding.pry  # Drop into interactive console
  end
end
```

#### Pattern 3: Remote CLI via Agent99 Messages
```ruby
# CLI that sends commands through Agent99 transport
class RemoteRegistryCLI
  def initialize
    @agent = Agent99::Base.new
  end
  
  def execute(command)
    response = @agent.send_request(
      to: 'registry_agent',
      action: 'cli_command',
      command: command
    )
    display_response(response)
  end
end

# Usage: 
# $ agent99-cli registry list
# $ agent99-cli registry discover calculation
```

## Configuration Examples

### Environment Variables
```bash
# Backend selection
AGENT99_REGISTRY_BACKEND=redis

# Redis configuration
AGENT99_REGISTRY_REDIS_URL=redis://localhost:6379/0
AGENT99_REGISTRY_REDIS_TTL=3600

# Database configuration
AGENT99_REGISTRY_DB_URL=sqlite://registry.db
AGENT99_REGISTRY_DB_POOL_SIZE=10

# Filesystem configuration
AGENT99_REGISTRY_FS_PATH=/var/lib/agent99/registry
AGENT99_REGISTRY_FS_SYNC_INTERVAL=30
```

### YAML Configuration
```yaml
registry:
  backend: redis
  redis:
    url: redis://localhost:6379/0
    ttl: 3600
    namespace: agent99:registry
  
  # Fallback chain
  fallbacks:
    - filesystem
    - memory
  
  # Replication
  replicas:
    - redis://backup1:6379/0
    - redis://backup2:6379/0
```

## Security Considerations

### Authentication & Authorization
```ruby
class Agent99::Registry::Backend
  def register(agent_info, credentials)
    authenticate!(credentials)
    authorize!(:register, agent_info)
    # ... registration logic
  end
end
```

### Secure Communication
- **TLS/SSL**: For HTTP API and database connections
- **Authentication tokens**: JWT or API keys for agent registration
- **Rate limiting**: Prevent registry flooding
- **Input validation**: Sanitize all registry inputs

## Migration Strategy

### From Current In-Memory to Persistent Backend

**Step 1: Backward Compatible Update**
```ruby
# Update current Sinatra app
class RegistryApp < Sinatra::Base
  def initialize
    # Start with memory backend (current behavior)
    @backend = Agent99::Registry::MemoryBackend.new
    
    # Optional persistence layer
    if ENV['REGISTRY_PERSISTENCE']
      @persistent_backend = Agent99::Registry::RedisBackend.new
      @backend = Agent99::Registry::CacheBackend.new(
        cache: @backend,
        persistent: @persistent_backend
      )
    end
  end
end
```

**Step 2: Data Migration**
```ruby
# Migrate existing agents to new backend
class RegistryMigrator
  def migrate(from_backend, to_backend)
    from_backend.list_all.each do |agent|
      to_backend.register(agent)
    end
  end
end
```

## Model Context Protocol (MCP) Integration

### Registry as MCP Server

The Agent99 registry can expose itself as an MCP server, providing AI assistants with direct access to agent information and management capabilities.

#### MCP Tools for Agent Management
```ruby
class Agent99RegistryMCPServer < MCPServer
  def initialize(registry)
    @registry = registry
    super
  end

  def tools
    [
      {
        name: "discover_agents",
        description: "Find agents by capability, namespace, or status",
        inputSchema: {
          type: "object",
          properties: {
            capability: { type: "string" },
            namespace: { type: "string" },
            status: { type: "string" },
            health_threshold: { type: "number" }
          }
        }
      },
      
      {
        name: "agent_whois",
        description: "Get detailed information about specific agents",
        inputSchema: {
          type: "object", 
          properties: {
            query: { 
              type: "string", 
              description: "UUID, capability, owner, or search term" 
            }
          },
          required: ["query"]
        }
      },
      
      {
        name: "semantic_agent_search",
        description: "Find agents using natural language descriptions",
        inputSchema: {
          type: "object",
          properties: {
            description: { 
              type: "string", 
              description: "Natural language description of needed capability"
            }
          }
        }
      },
      
      {
        name: "diagnose_agent_issues",
        description: "Analyze agent problems and suggest solutions",
        inputSchema: {
          type: "object",
          properties: {
            symptoms: { type: "string" },
            affected_agents: { type: "array", items: { type: "string" } }
          }
        }
      },
      
      {
        name: "suggest_agent_placement",
        description: "Recommend optimal agent deployment locations",
        inputSchema: {
          type: "object", 
          properties: {
            capability_needed: { type: "string" },
            performance_requirements: { type: "object" }
          }
        }
      }
    ]
  end

  def call_tool(name, arguments)
    case name
    when "discover_agents"
      @registry.discover_with_filters(arguments)
    when "agent_whois"
      @registry.whois(arguments[:query])
    when "semantic_agent_search"
      @registry.semantic_search(arguments[:description])
    when "diagnose_agent_issues"
      @registry.diagnose_problems(arguments[:symptoms], arguments[:affected_agents])
    when "suggest_agent_placement"
      @registry.suggest_placement(arguments)
    end
  end
end
```

#### MCP Resources for Documentation
```ruby
def resources
  [
    {
      uri: "agent99://schemas/agent",
      name: "Agent Registration Schema",
      description: "JSON schema for agent registration data",
      mimeType: "application/json"
    },
    
    {
      uri: "agent99://docs/capabilities", 
      name: "Capability Documentation",
      description: "Available agent capabilities and their usage patterns",
      mimeType: "text/markdown"
    },
    
    {
      uri: "agent99://topology/current",
      name: "Live Network Topology", 
      description: "Current agent network topology and health status",
      mimeType: "application/json"
    },
    
    {
      uri: "agent99://metrics/performance",
      name: "Performance Metrics",
      description: "Agent performance data and trends",
      mimeType: "application/json"
    }
  ]
end
```

### AI-Powered Agent Operations

#### Natural Language Agent Discovery
```bash
# AI assistant with MCP registry access
User: "Find all calculation agents that are currently having issues"

AI: I'll check the registry for calculation agents with health problems.
[Uses discover_agents tool with capability: "calculation", health_threshold: 70]

AI: Found 3 calculation agents with issues:
- agent_calc_01 (uuid: abc-123): High error rate (45% failures), CPU: 95%
- agent_calc_03 (uuid: def-456): Offline for 15 minutes  
- agent_calc_07 (uuid: ghi-789): Memory usage critical (98%)

Would you like me to get more details about any of these agents?

User: "What's the root cause of agent_calc_01's problems?"

AI: [Uses diagnose_agent_issues tool]
Based on the metrics, agent_calc_01 is experiencing:
1. High CPU due to inefficient algorithm in recent deployment
2. Error rate spike correlates with increased request complexity
3. Recommend: Rollback to previous version or increase resource allocation
```

#### Intelligent Troubleshooting
```bash
User: "Our financial reporting system is slow today"

AI: I'll analyze agents involved in financial reporting.
[Uses semantic_agent_search with "financial reporting data processing"]

AI: Found 5 agents in the financial reporting pipeline:
- data_ingestion_agent: Normal (health: 85%)
- financial_processor_01: Degraded (health: 60%) - High latency
- report_generator: Normal (health: 90%)  
- financial_processor_02: Critical (health: 30%) - Frequent timeouts

The bottleneck appears to be financial_processor_02. It's showing:
- 300% normal response time
- 15% timeout rate
- Memory usage at 95%

Recommended actions:
1. Scale up financial_processor_02 instance
2. Route traffic to financial_processor_01 as backup
3. Investigate memory leak in recent deployment
```

#### Automated Deployment Assistance
```bash
User: "We need to deploy a new image processing agent. Where should it go?"

AI: [Uses suggest_agent_placement tool]
Based on current topology and load patterns:

Recommended placement: us-west-datacenter-2
- Lowest latency to image storage (15ms avg)
- Available compute capacity (40% CPU utilization)
- Network proximity to related agents
- Fallback options available in same zone

Alternative locations:
1. us-west-datacenter-1 (higher latency to storage: 45ms)
2. us-east-datacenter-1 (cross-region, 120ms latency)

Would you like me to initiate the deployment process?
```

### MCP Integration Benefits

#### For Developers
- **Natural language queries**: "Show me broken agents" instead of complex API calls
- **Intelligent debugging**: AI correlates symptoms across agent fleet
- **Context-aware help**: AI understands agent relationships and dependencies

#### For Operations Teams
- **Proactive monitoring**: AI predicts failures before they occur
- **Smart alerting**: Reduced false positives through intelligent correlation
- **Automated remediation**: AI suggests and can execute fixes

#### For System Architecture
- **Protocol standardization**: MCP provides standard AI integration interface
- **Tool composability**: Registry tools combine with other MCP servers
- **Future-ready**: Prepared for AI agent orchestration and management

### Implementation Architecture

```ruby
# Complete registry with MCP integration
class Agent99RegistryWithMCP
  def initialize(backend: :redis)
    @registry = Agent99::Registry.new(backend: backend)
    @mcp_server = Agent99RegistryMCPServer.new(@registry)
  end
  
  def start
    # Start all frontend interfaces
    start_http_api       # Traditional REST API
    start_agent_frontend # Agent99 messaging interface
    start_mcp_server     # MCP for AI integration
    start_cli_interface  # Command line tools
    start_grpc_server    # High-performance RPC (optional)
  end
  
  private
  
  def start_mcp_server
    # MCP server runs alongside other interfaces
    Thread.new { @mcp_server.run }
  end
end
```

## Use Case Examples

### Development Environment
```yaml
# Simple setup for development
frontend: cli           # Direct CLI access
backend: filesystem     # No external dependencies
path: ./dev_registry    # Local directory
```

### Small Team Deployment
```yaml
# Balanced features and simplicity
frontend: 
  - sinatra            # HTTP API
  - cli                # Admin access
backend: sqlite        # Simple database
auth: basic            # Basic authentication
```

### Enterprise Deployment
```yaml
# Full-featured production system
frontend:
  - agent99            # Internal agent communication
  - rails              # Rich admin UI
  - grpc              # High-performance API
backend: 
  primary: postgresql  # Complex queries
  cache: redis        # Performance optimization
auth: oauth2          # Enterprise SSO
audit: enabled        # Compliance logging
```

### Distributed Multi-Cluster
```yaml
# Globally distributed system
frontend:
  - agent99           # Distributed agents
  - cli               # Local troubleshooting
backend:
  type: federated     # Multiple registries
  regions:
    - us-east: redis-cluster
    - eu-west: redis-cluster
    - ap-south: redis-cluster
sync: eventual        # Cross-region sync
```

## Recommendations

### Immediate Actions (Maintain Compatibility)
1. **Refactor current registry** into backend abstraction
2. **Add Redis backend** as optional persistence layer
3. **Keep Sinatra API** for backward compatibility
4. **Add health monitoring** for registered agents

### Medium-term Evolution
1. **Implement Registry Agent** for distributed access
2. **Add database backend** for complex queries
3. **Integrate with SmartMessage** transport layer
4. **Add semantic search** capabilities

### Long-term Vision
1. **Fully distributed registry** with no single point of failure
2. **Federation support** for multi-cluster deployments
3. **AI-powered discovery** with semantic understanding
4. **Self-healing registry** with automatic reconciliation

---

## Repository Separation Strategy

### Agent99 Core Repository
- Contains core Agent99 framework and coordination logic
- Includes simple in-memory registry example (current Sinatra implementation)
- Depends on `control-registry` gem for production registry features
- Integration points for registry discovery and agent coordination

### Control-Registry Repository
- Contains production-ready registry infrastructure
- Pluggable frontend architecture (Agent99, Sinatra, CLI, gRPC)
- Pluggable backend architecture (Memory, Redis, Database, Filesystem)
- Security framework and authentication systems
- DNS-like hierarchical model with WHOIS functionality
- MCP integration for AI-powered operations
- Comprehensive test suite and documentation

### Integration
```ruby
# Agent99 using control-registry
require 'control-registry'

# Agent99 can use control-registry for production deployments
storage = Control::Registry::DataStorage::Redis.new
registry_client = Control::Registry::Client.new(storage: storage)

class MyAgent < Agent99::Base
  def initialize
    @registry = registry_client
    super
  end
end
```

---

*Last Updated: 2025-01-03*  
*Status: Ready for Control-Registry Implementation*  
*Repository: Separate `control-registry` repository established*