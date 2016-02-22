require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/queryable'

describe RDF::Queryable do
  # @see lib/rdf/spec/queryable.rb in rdf-spec
  it_behaves_like 'an RDF::Queryable' do
    # The available reference implementations are `RDF::Repository` and
    # `RDF::Graph`, but a subclass of Ruby Array implementing
    # `query_pattern` and `query_execute` should do as well
    # FIXME
    let(:queryable) { RDF::Repository.new }
  end
end
