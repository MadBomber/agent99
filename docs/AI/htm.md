# Hierarchical Temporal Memory in AI Systems

## Table of Contents
- [Introduction](#introduction)
- [Understanding Hierarchical Temporal Memory](#understanding-hierarchical-temporal-memory)
- [Layers of Memory](#layers-of-memory)
- [Topic Columns](#topic-columns)
- [Memory Cell Promotion and Forgetting](#memory-cell-promotion-and-forgetting)
- [Implications for AI Systems](#implications-for-ai-systems)
- [Conclusion](#conclusion)
- [Some Code Ideas](#some-code-ideas)

## Introduction

Hierarchical Temporal Memory (HTM) is a computational model that mimics some aspects of the neocortex, developed by the Numenta research company. It focuses on how the brain processes information over time and is designed to learn patterns and sequences in data. HTM operates on principles of hierarchy, meaning it organizes information in layers, and temporal memory, which enables it to remember sequences and make predictions based on temporal patterns. This model is particularly effective for tasks involving time series data and has applications in anomaly detection, robotics, and various cognitive computing tasks.

## Understanding Hierarchical Temporal Memory

Hierarchical Temporal Memory is inspired by the theory of how the brain works, particularly focusing on how it learns patterns and sequences. The fundamental ideas were put forward by Jeff Hawkins, co-founder of Numenta, who theorized that real intelligence is derived from understanding and manipulating temporal sequences.

HTM leverages a structure that is hierarchical and spatially organized. Each level of the hierarchy processes information at varying degrees of abstraction. The bottom layers deal with raw sensory input, while the upper layers interpret this data into meaningful contexts.

This model is particularly valuable in applications involving complex time series, where the demand for understanding sequences over time is crucial. The capability of HTM to generalize from sparse data makes it unique compared to traditional machine learning techniques.

## Layers of Memory

HTM's architecture consists of several layers, each designed for specific functions. The bottom layer, known as the input layer, is responsible for receiving raw data inputs. Subsequent layers process this information, identifying patterns and sequences that inform decisions.

1. **Input Layer**: Receives sensory data and converts it into a usable format for the next layer.
2. **Temporal Pooling Layer**: Captures the temporal dependencies in the data.
3. **Spatial Pooling Layer**: Encodes spatial relationships and builds a representation of the input data.

This multi-layered approach enables HTM to build increasingly sophisticated representations of the data at each layer, akin to how the neocortex might operate.

## Topic Columns

Each "column" in HTM can be viewed as a mini-neural network that processes input from the layer below it. These columns work in parallel to learn spatial and temporal patterns. Thus, they respond to specific features of the incoming data, allowing HTM to develop a hierarchy of data features. Columns also facilitate learning through inhibition, promoting the most active neurons while suppressing others.

## Memory Cell Promotion and Forgetting

The mechanisms by which HTM promotes or forgets memory cells mirror more biological processes. 

### Promotion

Cells that consistently provide accurate predictions based on the learned sequence are promoted. For instance, if certain neurons within a column recognize patterns that lead to accurate outcomes, they're trained to engage more actively depending on their performance over time.

### Forgetting

Forgetting is equally important; neurons that fail to respond to valid sequences are gradually demoted. This ensures that the model does not become overly reliant on outdated information, allowing new patterns and sequences to emerge and be incorporated.

## Implications for AI Systems

By modeling the functioning of the neocortex, HTM introduces a new paradigm in machine learning, emphasizing time and sequences over static data processing. This has significant implications in various fields:

- **Anomaly Detection**: In finance, HTM can be used to identify unusual patterns in transactions that may indicate fraud.
- **Robotics**: Robots leveraging HTM can learn from their experiences in real-time, adapting to environmental changes dynamically.
- **Natural Language Processing**: Understanding the temporal relationships between phrases can enhance language models, leading to more contextually accurate interpretations.

## Conclusion

Hierarchical Temporal Memory presents a powerful framework for understanding and replicating the cognitive processes of the human brain. With its ability to learn from temporal patterns, it opens new frontiers in artificial intelligence and machine learning.

## Some Code Ideas

```ruby
require 'active_record'

class CreateHtmTable < ActiveRecord::Migration[7.0]
  def change
    create_table :htm do |t|
      t.uuid     :event,         null: false
      t.text     :proposition,   null: false
      t.string   :state,         null: false
      t.datetime :last_accessed, null: false
      t.integer  :hit_count,     null: false, default: 0
      t.float    :vector,        null: false, array: true, limit: 2048

      t.timestamps
    end

    add_index :htm, :event, unique: true
    add_index :htm, :state

    execute <<-SQL
      ALTER TABLE htm
      ADD CONSTRAINT check_state
      CHECK (state IN ('STM', 'MTM', 'LTM', 'PM'))
    SQL

    execute <<-SQL
      ALTER TABLE htm
      ADD CONSTRAINT check_vector_length
      CHECK (array_length(vector, 1) = 2048)
    SQL
  end
end
```

This is a notional model for the table. I'm having second thoughts about keeping track of the hit count. I think maybe access time is all that is needed and that is provided by the AR timestamps.

```ruby
require 'active_record'
require 'neighbors'

class Htm < ActiveRecord::Base
  STATES = %w[STM MTM LTM PM].freeze

  validates :event,       presence: true
  validates :proposition, presence: true
  validates :state,       presence: true, inclusion: { in: STATES }
  validates :vector,      presence: true, length: { is: 2048 }

  def self.search_and_update(event_uuid:, query_vector:, top_k: 10)
    records = where(event: event_uuid)
    vectors = records.pluck(:vector)

    neighbor_search = Neighbors::NearestNeighbors.new(vectors)
    nearest_indices = neighbor_search.search(query_vector, k: top_k)

    nearest_records = records.where(id: records.ids.values_at(*nearest_indices))
    
    nearest_records.each do |record|
      record.hit_count     += 1
      record.last_accessed  = Time.current
      record.save!
    end

    nearest_records
  end

  def update_state
    event_config = StateConfig.find_by(event: event)
    current_time = Time.current
    time_since_creation = current_time - created_at
    time_since_last_access = current_time - last_accessed

    if should_promote?(event_config, time_since_creation)
      promote_state
    elsif should_demote?(event_config, time_since_last_access)
      demote_state
    end
  end

  private

  def should_promote?(config, time_delta)
    current_state_index = STATES.index(state)
    return false if current_state_index == STATES.length - 1

    next_state = STATES[current_state_index + 1]
    time_delta > config.promotion_time(next_state) &&
      hit_count > config.promotion_hits(next_state)
  end

  def should_demote?(config, time_delta)
    current_state_index = STATES.index(state)
    return false if current_state_index == 0

    time_delta < config.demotion_time(state) &&
      hit_count < config.demotion_hits(state)
  end

  def promote_state
    current_index = STATES.index(state)
    self.state    = STATES[current_index + 1] if current_index < STATES.length - 1
    save!
  end

  def demote_state
    current_index = STATES.index(state)
    self.state    = STATES[current_index - 1] if current_index > 0
    save!
  end
end

class StateConfig < ActiveRecord::Base
  def promotion_time(state)
    case state
    when 'MTM' then mtm_promotion_time
    when 'LTM' then ltm_promotion_time
    when 'PM'  then pm_promotion_time
    else 0
    end
  end

  def promotion_hits(state)
    case state
    when 'MTM' then mtm_promotion_hits
    when 'LTM' then ltm_promotion_hits
    when 'PM'  then pm_promotion_hits
    else 0
    end
  end

  def demotion_time(state)
    case state
    when 'MTM' then mtm_demotion_time
    when 'LTM' then ltm_demotion_time
    when 'PM'  then pm_demotion_time
    else Float::INFINITY
    end
  end

  def demotion_hits(state)
    case state
    when 'MTM' then mtm_demotion_hits
    when 'LTM' then ltm_demotion_hits
    when 'PM'  then pm_demotion_hits
    else Float::INFINITY
    end
  end
end
```


