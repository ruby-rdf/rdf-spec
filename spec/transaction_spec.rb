require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/transaction'

describe RDF::Transaction do
  let(:repository) { RDF::Repository.new }
  # @see lib/rdf/spec/transaction.rb in rdf-spec
  it_behaves_like "an RDF::Transaction", RDF::Transaction
end
