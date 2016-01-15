require 'rdf/spec'

RSpec.shared_examples 'an RDF::Writable' do
  include RDF::Spec::Matchers
  let(:filename) {RDF::Spec::TRIPLES_FILE}
  let(:statements) {RDF::NTriples::Reader.new(File.open(filename)).to_a}
  let(:supports_graph_name) {writable.respond_to?(:supports?) && writable.supports?(:graph_name)}

  before :each do
    raise 'writable must be defined in with let(:readable)' unless
      defined? writable
  end

  subject { writable }
  let(:statement) {statements.detect {|s| s.to_a.all? {|r| r.uri?}}}
  let(:count) {statements.size}

  it {is_expected.to respond_to(:writable?)}
  its(:writable?) {is_expected.to eq !!subject.writable?}

  describe "#<<" do
    it "inserts a reader" do
      if subject.writable?
        reader = RDF::NTriples::Reader.new(File.open(filename)).to_a
        subject << reader
        is_expected.to have_statement(statement)
        expect(subject.count).to eq count
      end
    end

    it "inserts a graph" do
      if subject.writable?
        graph = RDF::Graph.new << statements
        subject << graph
        is_expected.to have_statement(statement)
        expect(subject.count).to eq count
      end
    end

    it "inserts an enumerable" do
      if subject.writable?
        enumerable = statements.dup.extend(RDF::Enumerable)
        subject << enumerable
        is_expected.to have_statement(statement)
        expect(subject.count).to eq count
      end
    end

    it "inserts data responding to #to_rdf" do
      if subject.writable?
        mock = double('mock')
        allow(mock).to receive(:to_rdf).and_return(statements)
        subject << mock
        is_expected.to have_statement(statement)
        expect(subject.count).to eq count
      end
    end

    it "inserts a statement" do
      if subject.writable?
        subject << statement
        is_expected.to have_statement(statement)
        expect(subject.count).to eq 1
      end
    end
  end

  context "when inserting statements" do
    it "should support #insert" do
      is_expected.to respond_to(:insert) if subject.writable?
    end

    it "should not raise errors" do
      expect { subject.insert(statement) }.not_to raise_error if subject.writable?
    end

    it "should support inserting one statement at a time" do
      if subject.writable?
        subject.insert(statement)
        is_expected.to have_statement(statement)
      end
    end

    it "should support inserting multiple statements at a time" do
      if subject.writable?
        subject.insert(*statements)
        statements.each do |statement|
          is_expected.to have_statement(statement) unless statement.to_a.any?(&:node?)
        end
      end
    end

    it "should insert statements successfully" do
      if subject.writable?
        subject.insert(*statements)
        expect(subject.count).to eq count
      end
    end

    it "should not insert a statement twice" do
      if subject.writable?
        subject.insert(statement)
        subject.insert(statement)
        expect(subject.count).to eq 1
      end
    end

    it "should not insert an incomplete statement" do
      if subject.writable?
        expect {subject.insert(RDF::Statement.from(statement.to_hash.merge(subject: nil)))}.to raise_error(ArgumentError)
        expect {subject.insert(RDF::Statement.from(statement.to_hash.merge(predicate: nil)))}.to raise_error(ArgumentError)
        expect {subject.insert(RDF::Statement.from(statement.to_hash.merge(object: nil)))}.to raise_error(ArgumentError)
        expect(subject.count).to eql 0
      end
    end

    it "should treat statements with a different graph_name as distinct" do
      if subject.writable?
        s1 = statement.dup
        s1.graph_name = nil
        s2 = statement.dup
        s2.graph_name = RDF::URI.new("urn:context:1")
        s3 = statement.dup
        s3.graph_name = RDF::URI.new("urn:context:2")
        subject.insert(s1)
        subject.insert(s2)
        subject.insert(s3)
        # If graph_names are not suported, all three are redundant
        expect(subject.count).to eq (supports_graph_name ? 3 : 1)
      end
    end
  end
end
