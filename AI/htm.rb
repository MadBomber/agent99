# File: examples/AI/htm.rb

require 'sqlite3'
require 'securerandom'
require 'time'

class HTMDemo
  STATES = %w[STM MTM LTM PM].freeze

  def initialize(db_name: 'htm_demo.db')
    @db = SQLite3::Database.new(db_name)
    @db.results_as_hash = true
    create_tables
  end

  def create_tables
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS htm_cells (
        id INTEGER PRIMARY KEY,
        column_id INTEGER NOT NULL,
        state TEXT NOT NULL,
        last_accessed DATETIME NOT NULL,
        hit_count INTEGER NOT NULL DEFAULT 0,
        data TEXT NOT NULL
      )
    SQL

    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS htm_columns (
        id INTEGER PRIMARY KEY,
        layer INTEGER NOT NULL
      )
    SQL
  end

  def create_column(layer:)
    @db.execute('INSERT INTO htm_columns (layer) VALUES (?)', [layer])
    @db.last_insert_row_id
  end

  def create_cell(column_id:, data:)
    @db.execute(<<-SQL, {
      INSERT INTO htm_cells (column_id, state, last_accessed, data)
      VALUES (:column_id, :state, :last_accessed, :data)
    SQL
      column_id:     column_id,
      state:         'STM',
      last_accessed: Time.now.strftime('%Y-%m-%dT%H:%M:%S%z'),
      data:          data
    })
    @db.last_insert_row_id
  end

  def update_cell(id:)
    @db.execute(<<-SQL, {
      UPDATE htm_cells
      SET hit_count = hit_count + 1, last_accessed = :last_accessed
      WHERE id = :id
    SQL
      id:            id,
      last_accessed: Time.now.strftime('%Y-%m-%dT%H:%M:%S%z')
    })
  end

  def promote_cell(id:)
    current_state = @db.get_first_value('SELECT state FROM htm_cells WHERE id = ?', [id])
    current_index = STATES.index(current_state)
    
    if current_index < STATES.length - 1
      new_state = STATES[current_index + 1]
      @db.execute('UPDATE htm_cells SET state = ? WHERE id = ?', [new_state, id])
    end
  end

  def forget_cell(id:)
    current_state = @db.get_first_value('SELECT state FROM htm_cells WHERE id = ?', [id])
    current_index = STATES.index(current_state)
    
    if current_index > 0
      new_state = STATES[current_index - 1]
      @db.execute('UPDATE htm_cells SET state = ? WHERE id = ?', [new_state, id])
    end
  end

  def search_cells(query:, limit: 5)
    @db.execute(<<-SQL, {
      SELECT * FROM htm_cells
      WHERE data LIKE :query
      ORDER BY hit_count DESC
      LIMIT :limit
    SQL
      query: "%#{query}%",
      limit: limit
    })
  end

  def display_stats
    puts "HTM Statistics:"
    puts "---------------"
    
    STATES.each do |state|
      count = @db.get_first_value('SELECT COUNT(*) FROM htm_cells WHERE state = ?', [state])
      puts "#{state} cells: #{count}"
    end

    total_cells = @db.get_first_value('SELECT COUNT(*) FROM htm_cells')
    total_columns = @db.get_first_value('SELECT COUNT(*) FROM htm_columns')
    puts "Total cells: #{total_cells}"
    puts "Total columns: #{total_columns}"
  end
end

# Usage example
htm = HTMDemo.new

# Create some columns and cells
5.times do |i|
  column_id = htm.create_column(layer: i % 3 + 1)
  10.times do
    htm.create_cell(column_id: column_id, data: SecureRandom.hex(10))
  end
end

# Simulate some cell activations and promotions
20.times do
  cell_id = htm.search_cells(query: SecureRandom.hex(5), limit: 1).first&.fetch('id')
  if cell_id
    htm.update_cell(id: cell_id)
    htm.promote_cell(id: cell_id) if rand < 0.3
  end
end

# Simulate some cell forgetting
10.times do
  cell_id = htm.search_cells(query: SecureRandom.hex(5), limit: 1).first&.fetch('id')
  htm.forget_cell(id: cell_id) if cell_id && rand < 0.2
end

# Display final statistics
htm.display_stats

