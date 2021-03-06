# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elastic_search/query_builder/version'

Gem::Specification.new do |spec|
  spec.name          = 'elasticsearch-query-builder'
  spec.version       = ElasticSearch::QueryBuilder::VERSION
  spec.authors       = ['Kickser', 'Federico Farina', 'Alejo Zárate', 'Nicolás Vázquez']
  spec.email         = ['support@goprebo.com', 'federico@goprebo.com', 'ale@goprebo.com', 'nico@goprebo.com']
  spec.summary       = 'Ruby gem to build complex ElasticSearch queries with clauses as methods'
  spec.license       = 'MIT'
  spec.homepage      = 'https://github.com/goprebo/elasticsearch-query-builder'
  spec.metadata['homepage_uri'] = 'https://github.com/goprebo/elasticsearch-query-builder'
  spec.metadata['source_code_uri'] = 'https://github.com/goprebo/elasticsearch-query-builder'
  spec.metadata['changelog_uri'] = 'https://github.com/goprebo/elasticsearch-query-builder'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
