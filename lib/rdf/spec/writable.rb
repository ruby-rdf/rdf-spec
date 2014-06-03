require 'rdf/spec'

module RDF_Writable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@writable+ must be defined in a before(:each) block' unless instance_variable_get('@writable')

    @filename = RDF::Spec::TRIPLES_FILE
    @statements = RDF::NTriples::Reader.new(File.open(@filename)).to_a

    @supports_context = @writable.respond_to?(:supports?) && @writable.supports?(:context)
  end

  describe RDF::Writable do
    subject {@writable}
    let(:statement) {@statements.detect {|s| s.to_a.all? {|r| r.uri?}}}
    let(:count) {@statements.size}

    it {should respond_to(:writable?)}
    its(:writable?) {should == !!subject.writable?}
  
    describe "#<<" do
      it "inserts a reader" do
        skip("writability") unless subject.writable?
        reader = RDF::NTriples::Reader.new(File.open(@filename)).to_a
        subject << reader
        expect(subject).to have_statement(statement)
        expect(subject.count).to eq count
      end

      it "inserts a graph" do
        skip("writability") unless subject.writable?
        graph = RDF::Graph.new << @statements
        subject << graph
        expect(subject).to have_statement(statement)
        expect(subject.count).to eq count
      end

      it "inserts an enumerable" do
        skip("writability") unless subject.writable?
        enumerable = @statements.dup.extend(RDF::Enumerable)
        subject << enumerable
        expect(subject).to have_statement(statement)
        expect(subject.count).to eq count
      end

      it "inserts data responding to #to_rdf" do
        skip("writability") unless subject.writable?
        mock = double('mock')
        allow(mock).to receive(:to_rdf).and_return(@statements)
        subject << mock
        expect(subject).to have_statement(statement)
        expect(subject.count).to eq count
      end

      it "inserts a statement" do
        skip("writability") unless subject.writable?
        subject << statement
        expect(subject).to have_statement(statement)
        expect(subject.count).to eq 1
      end

      it "inserts an invalid statement" do
        skip("writability") unless subject.writable?
        s = RDF::Statement.from([nil, nil, nil])
        expect(s).not_to  be_valid
        subject << s
        expect(subject.count).to eq 1
      end
    end

    context "when inserting statements" do
      it "should support #insert" do
        skip("writability") unless subject.writable?
        expect(subject).to respond_to(:insert)
      end

      it "should not raise errors" do
        skip("writability") unless subject.writable?
        expect { subject.insert(statement) }.not_to raise_error
      end

      it "should support inserting one statement at a time" do
        skip("writability") unless subject.writable?
        subject.insert(statement)
        expect(subject).to have_statement(statement)
      end

      it "should support inserting multiple statements at a time" do
        skip("writability") unless subject.writable?
        subject.insert(*@statements)
      end

      it "should insert statements successfully" do
        skip("writability") unless subject.writable?
        subject.insert(*@statements)
        expect(subject.count).to eq count
      end

      it "should not insert a statement twice" do
        skip("writability") unless subject.writable?
        subject.insert(statement)
        subject.insert(statement)
        expect(subject.count).to eq 1
      end

      it "should treat statements with a different context as distinct" do
        skip("writability") unless subject.writable?
        s1 = statement.dup
        s1.context = nil
        s2 = statement.dup
        s2.context = RDF::URI.new("urn:context:1")
        s3 = statement.dup
        s3.context = RDF::URI.new("urn:context:2")
        subject.insert(s1)
        subject.insert(s2)
        subject.insert(s3)
        # If contexts are not suported, all three are redundant
        expect(subject.count).to eq (@supports_context ? 3 : 1)
      end
    end
  end
end
