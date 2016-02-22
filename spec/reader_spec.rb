# -*- encoding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/ntriples'
require 'rdf/spec/reader'

describe RDF::NTriples::Reader do
  let!(:doap) {File.expand_path("../../etc/doap.nt", __FILE__)}
  let!(:doap_count) {File.open(doap).each_line.to_a.length}
  subject { RDF::NTriples::Reader.new }

  # @see lib/rdf/spec/reader.rb in rdf-spec
  it_behaves_like 'an RDF::Reader' do
    let(:reader) { RDF::NTriples::Reader.new }
    let(:reader_input) { File.read(doap) }
    let(:reader_count) { doap_count }
  end
end
