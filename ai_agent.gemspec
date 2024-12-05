# frozen_string_literal: true

require_relative "lib/ai_agent/version"

Gem::Specification.new do |spec|
  spec.name     = "ai_agent"
  spec.version  = AiAgent::VERSION
  spec.authors  = ["Dewayne VanHoozer"]
  spec.email    = ["dvanhoozer@gmail.com"]

  spec.summary      = "An intelligent agent framework for Ruby"
  spec.description  = <<~TEXT
    `ai_agent` is a Ruby gem designed to facilitate the creation and management 
    of intelligent agents, providing a straightforward interface for tasks such 
    as natural language processing, context handling, and conversing with various AI 
    models. It allows developers to smoothly integrate and utilize AI capabilities 
    within Ruby applications while ensuring flexibility and ease of customization.
  TEXT

  spec.homepage     = "https://github.com/MadBomber/ai_agemt"
  spec.license      = "MIT"

  spec.required_ruby_version = ">= 3.3.0"

  # Specify the gem server as rubygems.org
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  # Populate metadata with appropriate URLs
  spec.metadata["homepage_uri"]     = spec.homepage
  spec.metadata["source_code_uri"]  = "https://github.com/MadBomber/ai_agent"
  spec.metadata["changelog_uri"]    = "https://github.com/MadBomber/ai_agent/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.require_paths  = ["lib", "examples"]

  spec.add_dependency "ai_client"
  spec.add_dependency "bunny"
  spec.add_dependency "nats-pure"
  spec.add_dependency "simple_json_schema_builder"

  spec.add_development_dependency "amazing_print"
  spec.add_development_dependency "debug_me"
  spec.add_development_dependency "hashdiff"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "tocer"
end
