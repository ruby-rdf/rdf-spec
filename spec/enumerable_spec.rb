require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/enumerable'

describe RDF::Enumerable do
  before :each do
    @statements = RDF::NTriples::Reader.new(File.open('etc/doap.nt')).to_a
    @enumerable = @statements.dup.extend(RDF::Enumerable)
  end

  # @see lib/rdf/spec/enumerable.rb
  it_should_behave_like RDF_Enumerable
end
