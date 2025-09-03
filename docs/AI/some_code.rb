# some_code.rb
# snippets written by the robot
############################################
class KnowledgeNode
  attr_reader :id, :content, :detail_level

  def initialize(id:, content:, detail_level:)
    @id = id
    @content = content
    @detail_level = detail_level
    @connections = {
      more_general: [],
      more_specific: [],
      related: [],
    }
  end

  def add_connection(node:, relationship:)
    @connections[relationship] << node
  end
end

class KnowledgeGraph
  def initialize
    @nodes = {}
  end

  def add_node(node:)
    @nodes[node.id] = node
  end

  def connect_nodes(from_id:, to_id:, relationship:)
    from_node = @nodes[from_id]
    to_node = @nodes[to_id]
    from_node.add_connection(node: to_node, relationship: relationship)
  end

  def get_more_specific(node_id:)
    @nodes[node_id].connections[:more_specific]
  end

  def get_more_general(node_id:)
    @nodes[node_id].connections[:more_general]
  end
end

############################################
require "neo4j"

class Concept
  include Neo4j::ActiveNode
  property :name, type: String
  property :detail_level, type: Integer

  has_many :out, :more_specific, type: :SPECIALIZES, model_class: "Concept"
  has_many :in, :more_general, type: :SPECIALIZES, model_class: "Concept"
end

# Create nodes
general = Concept.create(name: "Science", detail_level: 1)
specific = Concept.create(name: "Physics", detail_level: 2)

# Create relationship
general.more_specific << specific

############################################
require "graphviz"

graph = GraphViz.new(:G, type: :digraph)

node1 = graph.add_nodes("Science")
node2 = graph.add_nodes("Physics")

graph.add_edges(node1, node2)

# See knowledge graph visualization at:
# docs/assets/images/knowledge-graph.svg
# graph.output(png: "knowledge_graph.png")

############################################
require "rgl/adjacency"
require "rgl/dot"

graph = RGL::DirectedAdjacencyGraph.new

graph.add_edge("Science", "Physics")
graph.add_edge("Physics", "Quantum Mechanics")

graph.write_to_graphic_file("jpg")

############################################
require "orientdb"

database = OrientDB::Database.new(url: "remote:localhost/knowledge_graph")

database.create_vertex_type("Concept")

science = database.create_vertex("Concept", name: "Science", detail_level: 1)
physics = database.create_vertex("Concept", name: "Physics", detail_level: 2)

database.create_edge("Specializes", science, physics)

############################################
class KnowledgeNode
  attr_reader :id, :content, :detail_level, :last_accessed

  def initialize(id:, content:, detail_level:)
    @id = id
    @content = content
    @detail_level = detail_level
    @last_accessed = Time.now
    @connections = {
      more_general: [],
      more_specific: [],
      related: [],
    }
  end

  def access
    @last_accessed = Time.now
  end

  def forgettable?(threshold)
    Time.now - @last_accessed > threshold * (1.0 / @detail_level)
  end
end

class TemporalKnowledgeGraph
  def initialize(forget_threshold: 30 * 24 * 60 * 60) # 30 days in seconds
    @nodes = {}
    @forget_threshold = forget_threshold
  end

  def add_node(node:)
    @nodes[node.id] = node
  end

  def access_node(id:)
    node = @nodes[id]
    node.access if node
    node
  end

  def forget_old_nodes
    @nodes.delete_if do |id, node|
      node.forgettable?(@forget_threshold)
    end
  end

  def connect_nodes(from_id:, to_id:, relationship:)
    from_node = @nodes[from_id]
    to_node = @nodes[to_id]
    from_node.connections[relationship] << to_node if from_node && to_node
  end
end

# Usage
graph = TemporalKnowledgeGraph.new(forget_threshold: 60 * 60 * 24) # 1 day

node1 = KnowledgeNode.new(id: 1, content: "Science", detail_level: 1)
node2 = KnowledgeNode.new(id: 2, content: "Physics", detail_level: 2)
node3 = KnowledgeNode.new(id: 3, content: "Quantum Entanglement", detail_level: 3)

graph.add_node(node: node1)
graph.add_node(node: node2)
graph.add_node(node: node3)

graph.connect_nodes(from_id: 1, to_id: 2, relationship: :more_specific)
graph.connect_nodes(from_id: 2, to_id: 3, relationship: :more_specific)

# Simulate passage of time and node access
sleep(2)
graph.access_node(id: 1)
graph.access_node(id: 2)

sleep(2)
graph.forget_old_nodes
# At this point, node3 might be forgotten, while node1 and node2 are retained


############################################
require "set"

class HTMNode
  attr_reader :id, :content, :detail_level, :last_accessed, :access_count

  def initialize(id:, content:, detail_level:)
    @id = id
    @content = content
    @detail_level = detail_level
    @last_accessed = Time.now
    @access_count = 0
    @connections = Set.new
  end

  def access
    @last_accessed = Time.now
    @access_count += 1
  end

  def add_connection(node)
    @connections.add(node)
  end

  def relevance_score(current_time)
    time_factor = 1.0 / (current_time - @last_accessed)
    detail_factor = 1.0 / @detail_level
    access_factor = Math.log(@access_count + 1)
    time_factor * detail_factor * access_factor
  end
end

class HTMRAG
  def initialize(forget_threshold: 30 * 24 * 60 * 60) # 30 days in seconds
    @nodes = {}
    @forget_threshold = forget_threshold
  end

  def add_node(node)
    @nodes[node.id] = node
  end

  def connect_nodes(from_id, to_id)
    @nodes[from_id].add_connection(@nodes[to_id])
  end

  def forget_old_nodes
    current_time = Time.now
    @nodes.delete_if do |_, node|
      current_time - node.last_accessed > @forget_threshold
    end
  end

  def retrieve_context(query, max_tokens: 1000)
    relevant_nodes = find_relevant_nodes(query)
    construct_context(relevant_nodes, max_tokens)
  end

  private

  def find_relevant_nodes(query)
    # This is a placeholder for semantic search
    # In a real implementation, you'd use embeddings or other NLP techniques
    @nodes.values.sort_by { |node| -node.relevance_score(Time.now) }
  end

  def construct_context(nodes, max_tokens)
    context = ""
    token_count = 0

    nodes.each do |node|
      break if token_count >= max_tokens

      node_content = node.content
      node_tokens = node_content.split.size # Simple tokenization

      if token_count + node_tokens <= max_tokens
        context += node_content + " "
        token_count += node_tokens
        node.access
      else
        remaining_tokens = max_tokens - token_count
        truncated_content = node_content.split[0...remaining_tokens].join(" ")
        context += truncated_content + " "
        break
      end
    end

    context.strip
  end
end

# Usage example
rag = HTMRAG.new

node1 = HTMNode.new(id: 1, content: "AI is a broad field of computer science.", detail_level: 1)
node2 = HTMNode.new(id: 2, content: "Machine Learning is a subset of AI focused on data-driven
algorithms.", detail_level: 2)
node3 = HTMNode.new(id: 3, content: "Neural networks are a type of machine learning model
inspired by biological neurons.", detail_level: 3)

rag.add_node(node1)
rag.add_node(node2)
rag.add_node(node3)

rag.connect_nodes(1, 2)
rag.connect_nodes(2, 3)

context = rag.retrieve_context("What is AI?", max_tokens: 50)
puts context


############################################
class Proposition
  attr_reader :id, :content
  attr_accessor :next, :related

  def initialize(id:, content:)
    @id = id
    @content = content
    @next = nil
    @related = []
  end
end

class PropositionGraph
  attr_reader :propositions

  def initialize
    @propositions = {}
  end

  def add_proposition(prop)
    @propositions[prop.id] = prop
  end

  def connect(from_id:, to_id:, relationship: :next)
    from_prop = @propositions[from_id]
    to_prop = @propositions[to_id]
    if relationship == :next
      from_prop.next = to_prop
    else
      from_prop.related << to_prop
    end
  end

  def similarity_score(other_graph)
    sequence_similarity = calculate_sequence_similarity(other_graph)
    structure_similarity = calculate_structure_similarity(other_graph)
    (sequence_similarity + structure_similarity) / 2.0
  end

  private

  def calculate_sequence_similarity(other_graph)
    # Implement sequence comparison logic here
    # This could involve comparing the 'next' chains of both graphs
    # Return a score between 0 and 1
  end

  def calculate_structure_similarity(other_graph)
    # Implement structure comparison logic here
    # This could involve comparing the 'related' connections of both graphs
    # Return a score between 0 and 1
  end
end

class GraphBasedRAG
  def initialize
    @stored_graphs = []
  end

  def add_graph(graph)
    @stored_graphs << graph
  end

  def retrieve_context(prompt_graph, top_n: 3)
    scored_graphs = @stored_graphs.map do |graph|
      {
        graph: graph,
        score: graph.similarity_score(prompt_graph),
      }
    end

    top_graphs = scored_graphs.sort_by { |g| -g[:score] }.take(top_n)
    construct_context(top_graphs)
  end

  private

  def construct_context(top_graphs)
    # Implement logic to construct context from top graphs
    # This could involve extracting key propositions or summarizing the graphs
  end
end

# Usage example
rag = GraphBasedRAG.new

# Create and add some stored graphs
graph1 = PropositionGraph.new
prop1 = Proposition.new(id: 1, content: "AI is a field of computer science")
prop2 = Proposition.new(id: 2, content: "Machine Learning is a subset of AI")
graph1.add_proposition(prop1)
graph1.add_proposition(prop2)
graph1.connect(from_id: 1, to_id: 2)
rag.add_graph(graph1)

# ... Add more graphs ...

# Create a graph from the prompt
prompt_graph = PropositionGraph.new
prompt_prop1 = Proposition.new(id: 1, content: "What is AI")
prompt_prop2 = Proposition.new(id: 2, content: "How does it relate to Machine Learning")
prompt_graph.add_proposition(prompt_prop1)
prompt_graph.add_proposition(prompt_prop2)
prompt_graph.connect(from_id: 1, to_id: 2)

# Retrieve context
context = rag.retrieve_context(prompt_graph)
puts context


############################################
require "pg"

class GraphDatabase
  def initialize(dbname:, user:, password:)
    @conn = PG.connect(dbname: dbname, user: user, password: password)
    @conn.exec("CREATE EXTENSION IF NOT EXISTS age")
    @conn.exec("LOAD 'age'")
    @conn.exec("SET search_path = ag_catalog, \"$user\", public")
  end

  def create_graph(name)
    @conn.exec("SELECT create_graph('#{name}')")
  end

  def add_vertex(graph, properties)
    props = properties.map { |k, v| "#{k}: '#{v}'" }.join(", ")
    @conn.exec("SELECT * FROM cypher('#{graph}', $$ CREATE (:Proposition {#{props}}) $$) as (v
agtype)")
  end

  def add_edge(graph, from_id, to_id, relationship)
    @conn.exec("SELECT * FROM cypher('#{graph}', $$ MATCH (a), (b) WHERE id(a) = #{from_id} AND
id(b) = #{to_id} CREATE (a)-[:#{relationship}]->(b) $$) as (e agtype)")
  end

  def query(graph, cypher)
    result = @conn.exec("SELECT * FROM cypher('#{graph}', $$ #{cypher} $$) as (result agtype)")
    result.map { |row| row["result"] }
  end
end

# Usage
db = GraphDatabase.new(dbname: "your_db", user: "your_user", password: "your_password")
db.create_graph("knowledge_graph")
db.add_vertex("knowledge_graph", { content: "AI is a field of computer science", detail_level: 1 })
db.add_vertex("knowledge_graph", { content: "Machine Learning is a subset of AI", detail_level: 2 })
db.add_edge("knowledge_graph", 0, 1, "SPECIALIZES")

result = db.query("knowledge_graph", "MATCH (p:Proposition) RETURN p")
puts result


############################################
class PropositionGraphDatabase
  def initialize(dbname:, user:, password:)
    @db = GraphDatabase.new(dbname: dbname, user: user, password: password)
    @db.create_graph("proposition_graph")
  end

  def add_proposition(content:, detail_level:)
    @db.add_vertex("proposition_graph", { content: content, detail_level: detail_level })
  end

  def connect_propositions(from_id:, to_id:, relationship: "NEXT")
    @db.add_edge("proposition_graph", from_id, to_id, relationship)
  end

  def find_similar_graphs(prompt_graph)
    # This is a simplified example. In practice, you'd need a more sophisticated
    # algorithm to compare graph structures.
    cypher = "" "
MATCH path = (start:Proposition)-[:NEXT*]->(end:Proposition)
WHERE NOT (end)-[:NEXT]->()
WITH path, nodes(path) AS props
RETURN path,
reduce(similarity = 0, p IN props |
similarity + CASE WHEN p.content CONTAINS '#{prompt_graph.first.content}' THEN 1 ELSE 0 END
) AS similarity_score
ORDER BY similarity_score DESC
LIMIT 5
" ""
    @db.query("proposition_graph", cypher)
  end
end

# Usage
graph_db = PropositionGraphDatabase.new(dbname: "your_db", user: "your_user", password: "your_password")
graph_db.add_proposition(content: "AI is a field of computer science", detail_level: 1)
graph_db.add_proposition(content: "Machine Learning is a subset of AI", detail_level: 2)
graph_db.connect_propositions(from_id: 0, to_id: 1)

prompt_graph = [OpenStruct.new(content: "What is AI")]
similar_graphs = graph_db.find_similar_graphs(prompt_graph)
puts similar_graphs


############################################
class PropositionGraphDatabase
  def initialize(dbname:, user:, password:)
    @db = GraphDatabase.new(dbname: dbname, user: user, password: password)
    @db.create_graph("proposition_graph")
  end

  def add_proposition(content:, detail_level:)
    @db.add_vertex("proposition_graph", { content: content, detail_level: detail_level })
  end

  def connect_propositions(from_id:, to_id:, relationship: "NEXT")
    @db.add_edge("proposition_graph", from_id, to_id, relationship)
  end

  def find_similar_graphs(prompt_graph)
    # This is a simplified example. In practice, you'd need a more sophisticated
    # algorithm to compare graph structures.
    cypher = "" "
MATCH path = (start:Proposition)-[:NEXT*]->(end:Proposition)
WHERE NOT (end)-[:NEXT]->()
WITH path, nodes(path) AS props
RETURN path,
reduce(similarity = 0, p IN props |
similarity + CASE WHEN p.content CONTAINS '#{prompt_graph.first.content}' THEN 1 ELSE 0 END
) AS similarity_score
ORDER BY similarity_score DESC
LIMIT 5
" ""
    @db.query("proposition_graph", cypher)
  end
end

# Usage
graph_db = PropositionGraphDatabase.new(dbname: "your_db", user: "your_user", password: "your_password")
graph_db.add_proposition(content: "AI is a field of computer science", detail_level: 1)
graph_db.add_proposition(content: "Machine Learning is a subset of AI", detail_level: 2)
graph_db.connect_propositions(from_id: 0, to_id: 1)

prompt_graph = [OpenStruct.new(content: "What is AI")]
similar_graphs = graph_db.find_similar_graphs(prompt_graph)
puts similar_graphs


############################################
require "openai"
require "json"

class KnowledgeGraphGenerator
  def initialize(api_key)
    @client = OpenAI::Client.new(access_token: api_key)
  end

  def generate_graph(text)
    prompt = <<~PROMPT
      Given the following paragraph, create a knowledge graph.
Output the result as a JSON object with the following structure:
{
"nodes": [
{"id": "unique_id", "label": "concept or entity", "type": "entity_type"}
],
"edges": [
{"source": "source_id", "target": "target_id", "label": "relationship"}
]
}

Paragraph:
#{text}

JSON Knowledge Graph:
    PROMPT

    response = @client.chat(
      parameters: {
        model: "gpt-4", # or "gpt-3.5-turbo" if you don't have GPT-4 access
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
      },
    )

    JSON.parse(response.dig("choices", 0, "message", "content"))
  end
end

class KnowledgeGraph
  attr_reader :nodes, :edges

  def initialize(data)
    @nodes = data["nodes"]
    @edges = data["edges"]
  end

  def to_s
    "Nodes:\n" + @nodes.map { |n| " #{n["id"]}: #{n["label"]} (#{n["type"]})" }.join("\n") +
    "\nEdges:\n" + @edges.map { |e|
      " #{e["source"]} -> #{e["target"]}: #{e["label"]}"
    }.join("\n")
  end
end

# Usage
generator = KnowledgeGraphGenerator.new("your-openai-api-key")

text = "Artificial Intelligence (AI) is a broad field of computer science focused on creating
intelligent machines that can perform tasks that typically require human intelligence. Machine
Learning, a subset of AI, uses statistical techniques to give computer systems the ability to
'learn' from data, without being explicitly programmed. Deep Learning, a further
specialization of Machine Learning, uses neural networks with many layers (hence 'deep') to
analyze various factors of data."

graph_data = generator.generate_graph(text)
graph = KnowledgeGraph.new(graph_data)

puts graph


############################################
require "json"

class KnowledgeGraph
  attr_reader :nodes, :edges

  def initialize(data)
    @nodes = data["nodes"]
    @edges = data["edges"]
  end

  def to_s
    "Nodes:\n" + @nodes.map { |n| " #{n["id"]}: #{n["label"]} (#{n["type"]})" }.join("\n") +
    "\nEdges:\n" + @edges.map { |e|
      " #{e["source"]} -> #{e["target"]}: #{e["label"]}"
    }.join("\n")
  end
end

# Assuming the JSON is stored in a variable called 'json_data'
graph_data = JSON.parse(json_data)
graph = KnowledgeGraph.new(graph_data)

puts graph

pin "vis-network", to: "https://ga.jspm.io/npm:vis-network@9.1.6/standalone/esm/vis-network.js"


############################################
# app/controllers/knowledge_graphs_controller.rb
class KnowledgeGraphsController < ApplicationController
  def show
    @graph_data = {
      nodes: [
        { id: 1, label: "Resident", group: "Person" },
        { id: 2, label: "Bossier City", group: "Location" },
        { id: 3, label: "Louisiana", group: "Location" },
        { id: 4, label: "2021 Tahoe LS", group: "Vehicle" },
        { id: 5, label: "Poor eyesight", group: "Condition" },
        { id: 6, label: "Driving restriction", group: "Regulation" },
      ],
      edges: [
        { from: 1, to: 2, label: "resides in" },
        { from: 2, to: 3, label: "located in" },
        { from: 1, to: 4, label: "owns" },
        { from: 1, to: 5, label: "has condition" },
        { from: 1, to: 6, label: "subject to" },
        { from: 6, to: 4, label: "applies to" },
        { from: 5, to: 6, label: "causes" },
      ],
    }
  end
end

# config/routes.rb
Rails.application.routes.draw do
  get "knowledge_graph", to: "knowledge_graphs#show"
  # ... other routes ...
end

# app/controllers/knowledge_graphs_controller.rb
class KnowledgeGraphsController < ApplicationController
  def new
    @knowledge_graph = KnowledgeGraph.new
  end

  def create
    @knowledge_graph = KnowledgeGraph.new(knowledge_graph_params)
    if @knowledge_graph.save
      redirect_to @knowledge_graph
    else
      render :new
    end
  end

  def show
    @knowledge_graph = KnowledgeGraph.find(params[:id])
    @graph_data = JSON.parse(@knowledge_graph.graph_data)
  end

  private

  def knowledge_graph_params
    params.require(:knowledge_graph).permit(:input_text)
  end
end
