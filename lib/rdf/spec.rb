require 'rdf'

module RDF
  ##
  # **`RDF::Spec`** provides RSpec extensions for RDF.rb.
  #
  # @example Requiring the `RDF::Spec` module
  #   require 'rdf/spec'
  #
  # @example Including the matchers in `spec/spec_helper.rb`
  #   require 'rdf/spec'
  #   
  #   Spec::Runner.configure do |config|
  #     config.include(RDF::Spec::Matchers)
  #   end
  #
  # @see http://rdf.rubyforge.org/
  # @see http://rspec.info/
  #
  # @author [Arto Bendiken](http://ar.to/)
  # @author [Ben Lavender](http://bhuga.net/)
  module Spec
    autoload :Matchers, 'rdf/spec/matchers'
    autoload :VERSION,  'rdf/spec/version'
  end # module Spec
end # module RDF
