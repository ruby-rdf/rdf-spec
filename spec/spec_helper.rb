require "bundler/setup"
require 'rdf'
require 'rdf/spec'
require 'rdf/spec/matchers'

RSpec.configure do |config|
  config.include(RDF::Spec::Matchers)
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.exclusion_filter = {:ruby => lambda { |version|
    RUBY_VERSION.to_s !~ /^#{version}/
  }}
end
