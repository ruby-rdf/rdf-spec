require 'rdf'   # @see http://rubygems.org/gems/rdf
require 'rspec' # @see http://rubygems.org/gems/rspec

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
  #   RSpec.configure do |config|
  #     config.include(RDF::Spec::Matchers)
  #   end
  #
  # @example Using the shared examples for `RDF::Enumerable`
  #   require 'rdf/spec/enumerable'
  #   
  #   describe RDF::Enumerable do
  #     before :each do
  #       @statements = RDF::NTriples::Reader.new(File.open("etc/doap.nt")).to_a
  #       @enumerable = @statements.dup.extend(RDF::Enumerable)
  #     end
  #     
  #     it_should_behave_like RDF_Enumerable
  #   end
  #
  # @example Using the shared examples for `RDF::Repository`
  #   require 'rdf/spec/repository'
  #   
  #   describe RDF::Repository do
  #     before :each do
  #       @repository = RDF::Repository.new
  #     end
  #     
  #     it_should_behave_like RDF_Repository
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
  end # Spec
end # RDF
