require 'rdf/spec'

RSpec.shared_examples 'an RDF::Dataset' do
  include RDF::Spec::Matchers

  before :each do
    raise 'dataset must be set with `let(:dataset)' unless
      defined? dataset

    if repository.empty?
      raise "+dataset+ must respond be pre-populated with the statements in #{RDF::Spec::TRIPLES_FILE} in a before block"
    end
  end

  let(:countable)    { dataset }
  let(:enumerable)   { dataset }
  let(:queryable)    { dataset }

  context "when counting statements" do
    require 'rdf/spec/countable'
    it_behaves_like 'an RDF::Countable'
  end

  context "when enumerating statements" do
    require 'rdf/spec/enumerable'
    it_behaves_like 'an RDF::Enumerable'
  end

  context "as durable" do
    require 'rdf/spec/durable'
    before { @load_durable ||= lambda { dataset } }

    it_behaves_like 'an RDF::Durable'
  end

  context "when querying statements" do
    require 'rdf/spec/queryable'
    it_behaves_like 'an RDF::Queryable'
  end

  describe '#isolation_level' do
    it 'is an allowable isolation level' do
      expect(described_class::ISOLATION_LEVELS)
        .to include(subject.isolation_level)
    end
  end
end
