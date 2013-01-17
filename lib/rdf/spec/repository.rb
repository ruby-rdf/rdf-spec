require 'rdf/spec'

module RDF_Repository
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@repository+ must be defined in a before(:each) block' unless instance_variable_get('@repository')
    @filename   = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'doap.nt'))
    @statements = RDF::NTriples::Reader.new(File.open(@filename)).to_a
    @enumerable = @repository
  end

  describe RDF::Repository do
    context "when counting statements" do
      require 'rdf/spec/countable'

      before :each do
        @countable = @repository
        @countable.insert(*@statements)
      end

      include RDF_Countable
    end

    context "when enumerating statements" do
      require 'rdf/spec/enumerable'

      before :each do
        @enumerable = @repository
        @enumerable.insert(*@statements)
      end

      include RDF_Enumerable
    end

    context "when querying statements" do
      require 'rdf/spec/queryable'

      before :each do
        @queryable = @repository
        @subject   = RDF::URI.new('http://rubygems.org/gems/rdf')
      end

      include RDF_Queryable
    end

    context "when updating" do
      require 'rdf/spec/mutable'

      before :each do
        @mutable = @repository
        @subject = RDF::URI.new('http://rubygems.org/gems/rdf')
        @context = RDF::URI.new('http://example.org/context')
      end

      include RDF_Mutable
    end

    context "as a durable repository" do
      require 'rdf/spec/durable'

      before :each do
        @load_durable ||= lambda { @repository }
      end

      include RDF_Durable
    end
  end
end
