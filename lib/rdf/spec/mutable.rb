require 'rdf/spec'
require 'rdf/ntriples'

module RDF_Mutable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@mutable+ must be defined in a before(:each) block' unless instance_variable_get('@mutable')

    @supports_context = @mutable.respond_to?(:supports?) && @mutable.supports?(:context)
  end
  let(:resource) {RDF::URI('http://rubygems.org/gems/rdf')}
  let(:context) {RDF::URI('http://example.org/context')}

  describe RDF::Mutable do
    subject {@mutable}

    context "readability" do
      require 'rdf/spec/readable'

      before :each do
        @readable = @mutable
      end

      include RDF_Readable
    end

    context "writability" do
      require 'rdf/spec/writable'

      before :each do
        @writable = @mutable
      end

      include RDF_Writable
    end

    it {should be_empty}
    it {should be_readable}
    it {should be_writable}
    it {should be_mutable}
    it {should_not be_immutable}
    it {should respond_to(:load)}
    it {should respond_to(:clear)}
    it {should respond_to(:delete)}

    its(:count) {should be_zero}

    context "#load" do
      it "should require an argument" do
        expect { subject.load }.to raise_error(ArgumentError)
      end

      it "should accept a string filename argument" do
        pending("mutability", :unless => subject.mutable?) do
          expect { subject.load(RDF::Spec::TRIPLES_FILE) }.not_to raise_error
        end
      end

      it "should accept an optional hash argument" do
        pending("mutability", :unless => subject.mutable?) do
          expect { subject.load(RDF::Spec::TRIPLES_FILE, {}) }.not_to raise_error
        end
      end

      it "should load statements" do
        pending("mutability", :unless => subject.mutable?) do
          subject.load RDF::Spec::TRIPLES_FILE
          subject.size.should ==  File.readlines(RDF::Spec::TRIPLES_FILE).size
          subject.should have_subject(resource)
        end
      end

      it "should load statements with a context override" do
        pending("mutability and contextuality", :unless => (subject.mutable? && @supports_context)) do
          subject.load RDF::Spec::TRIPLES_FILE, :context => context
          subject.should have_context(context)
          subject.query(:context => context).size.should == subject.size
        end
      end
    end

    context "#from_{reader}" do
      it "should instantiate a reader" do
        reader = double("reader")
        reader.should_receive(:new).and_return(RDF::NTriples::Reader.new(""))
        RDF::Reader.should_receive(:for).with(:a_reader).and_return(reader)
        subject.send(:from_a_reader)
      end
    end

    context "when deleting statements" do
      before :each do
        @statements = RDF::NTriples::Reader.new(File.open(RDF::Spec::TRIPLES_FILE)).to_a
        subject.insert(*@statements)
      end

      it "should not raise errors" do
        pending("mutability", :unless => subject.mutable?) do
          expect { subject.delete(@statements.first) }.not_to raise_error
        end
      end

      it "should support deleting one statement at a time" do
        pending("mutability", :unless => subject.mutable?) do
          subject.delete(@statements.first)
          subject.should_not have_statement(@statements.first)
        end
      end

      it "should support deleting multiple statements at a time" do
        pending("mutability", :unless => subject.mutable?) do
          subject.delete(*@statements)
          subject.find { |s| subject.has_statement?(s) }.should be_false
        end
      end

      it "should support wildcard deletions" do
        pending("mutability", :unless => subject.mutable?) do
          # nothing deleted
          require 'digest/sha1'
          count = subject.count
          subject.delete([nil, nil, random = Digest::SHA1.hexdigest(File.read(__FILE__))])
          subject.should_not be_empty
          subject.count.should == count

          # everything deleted
          subject.delete([nil, nil, nil])
          subject.should be_empty
        end
      end

      it "should only delete statements when the context matches" do
        pending("mutability", :unless => subject.mutable?) do
          # Setup three statements identical except for context
          count = subject.count + (@supports_context ? 3 : 1)
          s1 = RDF::Statement.new(resource, RDF::URI.new("urn:predicate:1"), RDF::URI.new("urn:object:1"))
          s2 = s1.dup
          s2.context = RDF::URI.new("urn:context:1")
          s3 = s1.dup
          s3.context = RDF::URI.new("urn:context:2")
          subject.insert(s1)
          subject.insert(s2)
          subject.insert(s3)
          subject.count.should == count

          # Delete one by one
          subject.delete(s1)
          subject.count.should == count - (@supports_context ? 1 : 1)
          subject.delete(s2)
          subject.count.should == count - (@supports_context ? 2 : 1)
          subject.delete(s3)
          subject.count.should == count - (@supports_context ? 3 : 1)
        end
      end
    end
  end
end
