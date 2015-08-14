require 'rdf/spec'
require 'rdf/ntriples'

RSpec.shared_examples 'an RDF::Mutable' do
  include RDF::Spec::Matchers

  before do
    raise 'mutable must be defined with let(:mutable)' unless
      defined? mutable

    @supports_context = mutable.respond_to?(:supports?) && mutable.supports?(:context)
  end

  let(:resource) { RDF::URI('http://rubygems.org/gems/rdf') }
  let(:context) { RDF::URI('http://example.org/context') }

  describe RDF::Mutable do
    subject { mutable }

    context "readability" do
      require 'rdf/spec/readable'

      let(:readable) { mutable }
      it_behaves_like 'an RDF::Readable'
    end

    context "writability" do
      require 'rdf/spec/writable'

      let(:writable) { mutable }
      it_behaves_like 'an RDF::Writable'
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
        skip("mutability") unless subject.mutable?
        expect { subject.load(RDF::Spec::TRIPLES_FILE) }.not_to raise_error
      end

      it "should accept an optional hash argument" do
        skip("mutability") unless subject.mutable?
        expect { subject.load(RDF::Spec::TRIPLES_FILE, {}) }.not_to raise_error
      end

      it "should load statements" do
        skip("mutability") unless subject.mutable?
        subject.load RDF::Spec::TRIPLES_FILE
        expect(subject.size).to eq  File.readlines(RDF::Spec::TRIPLES_FILE).size
        expect(subject).to have_subject(resource)
      end

      it "should load statements with a context override" do
        skip("mutability and contextuality") unless (subject.mutable? && @supports_context)
        subject.load RDF::Spec::TRIPLES_FILE, :context => context
        expect(subject).to have_context(context)
        expect(subject.query(:context => context).size).to eq subject.size
      end
    end

    context "#from_{reader}" do
      it "should instantiate a reader" do
        reader = double("reader")
        expect(reader).to receive(:new).and_return(RDF::Spec.quads.first)
        allow(RDF::Reader).to receive(:for).and_call_original
        expect(RDF::Reader).to receive(:for).with(:a_reader).and_return(reader)
        subject.send(:from_a_reader)
      end
    end

    context "when deleting statements" do
      before :each do
        @statements = RDF::NTriples::Reader.new(File.open(RDF::Spec::TRIPLES_FILE)).to_a
        subject.insert(*@statements)
      end

      it "should not raise errors" do
        skip("mutability") unless subject.mutable?
        expect { subject.delete(@statements.first) }.not_to raise_error
      end

      it "should support deleting one statement at a time" do
        skip("mutability") unless subject.mutable?
        subject.delete(@statements.first)
        expect(subject).not_to  have_statement(@statements.first)
      end

      it "should support deleting multiple statements at a time" do
        skip("mutability") unless subject.mutable?
        subject.delete(*@statements)
        expect(subject.find { |s| subject.has_statement?(s) }).to be_nil
      end

      it "should support wildcard deletions" do
        skip("mutability") unless subject.mutable?
        # nothing deleted
        require 'digest/sha1'
        count = subject.count
        subject.delete([nil, nil, Digest::SHA1.hexdigest(File.read(__FILE__))])
        expect(subject).not_to  be_empty
        expect(subject.count).to eq count

        # everything deleted
        subject.delete([nil, nil, nil])
        expect(subject).to be_empty
      end

      it "should only delete statements when the context matches" do
        skip("mutability") unless subject.mutable?
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
        expect(subject.count).to eq count

        # Delete one by one
        subject.delete(s1)
        expect(subject.count).to eq count - (@supports_context ? 1 : 1)
        subject.delete(s2)
        expect(subject.count).to eq count - (@supports_context ? 2 : 1)
        subject.delete(s3)
        expect(subject.count).to eq count - (@supports_context ? 3 : 1)
      end
    end
  end
end

##
# @deprecated use `it_behaves_like "an RDF::Mutable"` instead
module RDF_Mutable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  def self.included(mod)
    warn "[DEPRECATION] `RDF_Mutable` is deprecated. "\
         "Please use `it_behaves_like 'an RDF::Mutable'`"
  end

  describe 'examples for' do
    include_examples 'an RDF::Mutable' do
      let(:mutable) { @mutable }

      before do
        raise '@mutable must be defined' unless defined?(mutable)
      end
    end
  end
end
