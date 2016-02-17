require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/dataset'

describe RDF::Dataset do

  let(:dataset) do
    RDF::Repository.new do |r|
      r.insert(*RDF::Spec.quads)
    end.snapshot
  end

  # @see lib/rdf/spec/dataset.rb in rdf-spec
  it_behaves_like 'an RDF::Dataset'
end
