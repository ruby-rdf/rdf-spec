require 'rdf'   # @see http://rubygems.org/gems/rdf
require 'rdf/isomorphic' # @see http://rubygems.org/gems/rdf-isomorphic
require 'rspec' # @see http://rubygems.org/gems/rspec
require 'rdf/spec/inspects'
require 'rspec/its'

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
  #     include RDF_Enumerable
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
  #     include RDF_Repository
  #   end
  #
  # @see http://rubygems.org/gems/rdf
  # @see http://rspec.info/
  #
  # @author [Arto Bendiken](http://ar.to/)
  # @author [Ben Lavender](http://bhuga.net/)
  module Spec
    autoload :Matchers, 'rdf/spec/matchers'
    autoload :VERSION,  'rdf/spec/version'
    TRIPLES_FILE = File.expand_path("../../../etc/triples.nt", __FILE__)
    QUADS_FILE = File.expand_path("../../../etc/quads.nq", __FILE__)

    ##
    # Return quads for tests
    #
    # @return [Array<RDF::Statement>]
    def self.quads
      require 'rdf/nquads'
      (@quads ||=  RDF::NQuads::Reader.new(File.open(QUADS_FILE)).to_a).dup
    end

    ##
    # Return triples for tests
    #
    # @return [Array<RDF::Statement>]
    def self.triples
      require 'rdf/ntriples'
      (@triples ||=  RDF::NTriples::Reader.new(File.open(TRIPLES_FILE)).to_a).dup
    end

    # Logger used for Specs; allows clearing and converting to string
    require 'logger'
    def self.logger
      logger = Logger.new(StringIO.new)
      def logger.clear
        @logdev.instance_variable_set(:@dev, StringIO.new)
      end
      def logger.to_s
        dev = @logdev.instance_variable_get(:@dev)
        dev.rewind
        dev.read
      end
      logger.level = Logger::DEBUG
      logger.formatter = lambda {|severity, datetime, progname, msg| "#{severity} #{msg}\n"}
      logger
    end
  end # Spec
end # RDF
