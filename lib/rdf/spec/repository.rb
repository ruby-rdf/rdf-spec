require 'rdf/spec'

RSpec.shared_examples 'an RDF::Repository' do
  include RDF::Spec::Matchers

  before :each do
    raise 'repository must be set with `let(:repository)' unless
      defined? repository

    @statements = RDF::Spec.quads
    if repository.empty? && repository.writable?
      repository.insert(*@statements)
    elsif repository.empty?
      raise "+@repository+ must respond to #<< or be pre-populated with the statements in #{RDF::Spec::TRIPLES_FILE} in a before(:each) block"
    end
  end

  let(:countable) { repository }
  let(:enumerable) { repository }
  let(:queryable) { repository }
  let(:mutable) { repository }

  context "when counting statements" do
    require 'rdf/spec/countable'
    it_behaves_like 'an RDF::Countable'
  end

  context "when enumerating statements" do
    require 'rdf/spec/enumerable'
    it_behaves_like 'an RDF::Enumerable'
  end

  context "when querying statements" do
    require 'rdf/spec/queryable'
    it_behaves_like 'an RDF::Queryable'
  end

  # FIXME: This should be condition on the repository being mutable
  context "when updating" do
    require 'rdf/spec/mutable'

    before { mutable.clear }

    it_behaves_like 'an RDF::Mutable'
  end

  # FIXME: This should be condition on the repository being mutable
  context "as a durable repository" do
    require 'rdf/spec/durable'

    before :each do
      repository.clear
      @load_durable ||= lambda { repository }
    end

    it_behaves_like 'an RDF::Durable'
  end
end

##
# @deprecated use `it_behaves_like "an RDF::Repository"` instead
# :nocov:
module RDF_Repository
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  def self.included(mod)
    warn "[DEPRECATION] `RDF_Repository` is deprecated. "\
         "Please use `it_behaves_like 'an RDF::Repository'`"
  end

  describe 'examples for' do
    include_examples 'an RDF::Repository' do
      let(:repository) { @repository }

      before do
        raise '@repository must be defined' unless defined?(repository)
      end
    end
  end
end
