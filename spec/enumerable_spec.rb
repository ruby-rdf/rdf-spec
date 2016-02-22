require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/enumerable'

describe RDF::Enumerable do
  # @see lib/rdf/spec/enumerable.rb in rdf-spec
  it_behaves_like 'an RDF::Enumerable' do
    # The available reference implementations are `RDF::Repository` and
    # `RDF::Graph`, but a plain Ruby array will do fine as well:
    let(:enumerable) { RDF::Spec.quads.extend(described_class) }
  end
end
