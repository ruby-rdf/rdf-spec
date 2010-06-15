require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/queryable'

describe RDF::Queryable do
  before :each do
    @statements = RDF::NTriples::Reader.new(File.open(@file = 'etc/doap.nt')).to_a
    @queryable  = @statements.dup.extend(RDF::Queryable)
    @subject    = RDF::URI('http://rubygems.org/gems/rdf')
  end

  # @see lib/rdf/spec/queryable.rb
  it_should_behave_like RDF_Queryable
end
