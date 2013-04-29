require 'rdf/spec'

module RDF_Repository
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@repository+ must be defined in a before(:each) block' unless instance_variable_get('@repository')
    @statements = RDF::Spec.quads
    @enumerable = @repository
  end

  describe RDF::Repository do
    context "when counting statements" do
      require 'rdf/spec/countable'

      before :each do
        if @repository.empty? && @repository.writable?
          @repository.insert(*@statements)
        elsif @repository.empty?
          raise "+@repository+ must respond to #<< or be pre-populated with the statements in #{RDF::Spec::TRIPLES_FILE} in a before(:each) block"
        end
        @countable = @repository
      end

      include RDF_Countable
    end

    context "when enumerating statements" do
      require 'rdf/spec/enumerable'

      before :each do
        if @repository.empty? && @repository.writable?
          @repository.insert(*@statements)
        elsif @repository.empty?
          raise "+@repository+ must respond to #<< or be pre-populated with the statements in #{RDF::Spec::TRIPLES_FILE} in a before(:each) block"
        end
        @enumerable = @repository
      end

      include RDF_Enumerable
    end

    context "when querying statements" do
      require 'rdf/spec/queryable'

      before :each do
        @queryable = @repository
      end

      include RDF_Queryable
    end

    context "when updating" do
      require 'rdf/spec/mutable'

      before :each do
        @mutable = @repository
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
