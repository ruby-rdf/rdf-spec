require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/repository'

describe RDF::Repository do
  # @see lib/rdf/spec/repository.rb in rdf-spec
  it_behaves_like 'an RDF::Repository' do
    # The available reference implementations are `RDF::Repository` and
    # `RDF::Graph`, but a plain Ruby array will do fine as well:
    let(:repository) { RDF::Repository.new }
  end
end
