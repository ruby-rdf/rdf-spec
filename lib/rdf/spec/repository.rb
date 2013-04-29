require 'rdf/spec'

module RDF_Repository
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@repository+ must be defined in a before(:each) block' unless instance_variable_get('@repository')
    @statements = RDF::Spec.quads
    if @repository.empty? && @repository.writable?
      @repository.insert(*@statements)
    elsif @repository.empty?
      raise "+@repository+ must respond to #<< or be pre-populated with the statements in #{RDF::Spec::TRIPLES_FILE} in a before(:each) block"
    end
    @countable = @repository
    @enumerable = @repository
    @queryable = @repository
    @mutable = @repository
  end

  describe RDF::Repository do
    context "when counting statements" do
      require 'rdf/spec/countable'
      include RDF_Countable
    end

    context "when enumerating statements" do
      require 'rdf/spec/enumerable'
      include RDF_Enumerable
    end

    context "when querying statements" do
      require 'rdf/spec/queryable'
      include RDF_Queryable
    end

    context "when updating", :if => lambda {@mutable.mutable?} do
      require 'rdf/spec/mutable'
      before(:each) do
        @mutable.clear
      end
      include RDF_Mutable
    end

    context "as a durable repository", :if => lambda {@repository.mutable?} do
      require 'rdf/spec/durable'

      before :each do
        @repository.clear
        @load_durable ||= lambda { @repository }
      end

      include RDF_Durable
    end
  end
end
