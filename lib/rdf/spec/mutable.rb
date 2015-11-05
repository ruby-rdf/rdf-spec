require 'rdf/spec'
require 'rdf/ntriples'

RSpec.shared_examples 'an RDF::Mutable' do
  include RDF::Spec::Matchers

  before do
    raise 'mutable must be defined with let(:mutable)' unless
      defined? mutable

    @supports_named_graphs = mutable.respond_to?(:supports?) && mutable.supports?(:graph_name)
  end

  let(:resource) { RDF::URI('http://rubygems.org/gems/rdf') }
  let(:graph_name) { RDF::URI('http://example.org/graph_name') }

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

    it {is_expected.to be_empty}
    it {is_expected.to be_readable}
    it {is_expected.to be_writable}
    it {is_expected.to be_mutable}
    it {is_expected.to_not be_immutable}
    it {is_expected.to respond_to(:load)}
    it {is_expected.to respond_to(:clear)}
    it {is_expected.to respond_to(:delete)}

    its(:count) {is_expected.to be_zero}

    context "#load" do
      it "is_expected.to require an argument" do
        expect { subject.load }.to raise_error(ArgumentError)
      end

      it "is_expected.to accept a string filename argument" do
        expect { subject.load(RDF::Spec::TRIPLES_FILE) }.not_to raise_error if subject.mutable?
      end

      it "is_expected.to accept an optional hash argument" do
        expect { subject.load(RDF::Spec::TRIPLES_FILE, {}) }.not_to raise_error if subject.mutable?
      end

      it "is_expected.to load statements" do
        if subject.mutable?
          subject.load RDF::Spec::TRIPLES_FILE
          expect(subject.size).to eq  File.readlines(RDF::Spec::TRIPLES_FILE).size
          is_expected.to have_subject(resource)
        end
      end

      it "is_expected.to load statements with a graph_name override" do
        if subject.mutable? && @supports_named_graphs
          subject.load RDF::Spec::TRIPLES_FILE, graph_name: graph_name
          is_expected.to have_graph(graph_name)
          expect(subject.query(graph_name: graph_name).size).to eq subject.size
        end
      end
    end

    context "#from_{reader}" do
      it "is_expected.to instantiate a reader" do
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

      it "is_expected.to not raise errors" do
        expect { subject.delete(@statements.first) }.not_to raise_error if subject.mutable?
      end

      it "is_expected.to support deleting one statement at a time" do
        if subject.mutable?
          subject.delete(@statements.first)
          is_expected.not_to  have_statement(@statements.first)
        end
      end

      it "is_expected.to support deleting multiple statements at a time" do
        if subject.mutable?
          subject.delete(*@statements)
          expect(subject.find { |s| subject.has_statement?(s) }).to be_nil
        end
      end

      it "is_expected.to support wildcard deletions" do
        if subject.mutable?
          # nothing deleted
          require 'digest/sha1'
          count = subject.count
          subject.delete([nil, nil, Digest::SHA1.hexdigest(File.read(__FILE__))])
          is_expected.not_to  be_empty
          expect(subject.count).to eq count

          # everything deleted
          subject.delete([nil, nil, nil])
          is_expected.to be_empty
        end
      end

      it "is_expected.to only delete statements when the graph_name matches" do
        if subject.mutable?
          # Setup three statements identical except for graph_name
          count = subject.count + (@supports_named_graphs ? 3 : 1)
          s1 = RDF::Statement.new(resource, RDF::URI.new("urn:predicate:1"), RDF::URI.new("urn:object:1"))
          s2 = s1.dup
          s2.graph_name = RDF::URI.new("urn:graph_name:1")
          s3 = s1.dup
          s3.graph_name = RDF::URI.new("urn:graph_name:2")
          subject.insert(s1)
          subject.insert(s2)
          subject.insert(s3)
          expect(subject.count).to eq count

          # Delete one by one
          subject.delete(s1)
          expect(subject.count).to eq count - (@supports_named_graphs ? 1 : 1)
          subject.delete(s2)
          expect(subject.count).to eq count - (@supports_named_graphs ? 2 : 1)
          subject.delete(s3)
          expect(subject.count).to eq count - (@supports_named_graphs ? 3 : 1)
        end
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
