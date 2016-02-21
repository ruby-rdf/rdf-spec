require 'rdf/spec'
require 'rdf/ntriples'

RSpec.shared_examples 'an RDF::Mutable' do
  include RDF::Spec::Matchers

  before do
    raise 'mutable must be defined with let(:mutable)' unless
      defined? mutable

    skip "Immutable resource" unless mutable.mutable?
    @statements = RDF::Spec.triples
    @supports_named_graphs = mutable.respond_to?(:supports?) && mutable.supports?(:graph_name)
    @supports_literal_equality = mutable.respond_to?(:supports?) && mutable.supports?(:literal_equality)
  end

  let(:resource) { RDF::URI('http://rubygems.org/gems/rdf') }
  let(:graph_name) { RDF::URI('http://example.org/graph_name') }
  let(:non_bnode_statements) {@statements.reject(&:node?)}

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
      it "should require an argument" do
        expect { subject.load }.to raise_error(ArgumentError)
      end

      it "should accept a string filename argument" do
        expect { subject.load(RDF::Spec::TRIPLES_FILE) }.not_to raise_error
      end

      it "should accept an optional hash argument" do
        expect { subject.load(RDF::Spec::TRIPLES_FILE, {}) }.not_to raise_error
      end

      it "should load statements" do
        subject.load RDF::Spec::TRIPLES_FILE
        expect(subject.size).to eq  File.readlines(RDF::Spec::TRIPLES_FILE).size
        is_expected.to have_subject(resource)
      end

      it "should load statements with a graph_name override" do
        if @supports_named_graphs
          subject.load RDF::Spec::TRIPLES_FILE, graph_name: graph_name
          is_expected.to have_graph(graph_name)
          expect(subject.query(graph_name: graph_name).size).to eq subject.size
        end
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

    context "when updating statements" do
      let(:s1) { RDF::Statement(resource, RDF::URI.new("urn:predicate:1"), RDF::URI.new("urn:object:1")) }
      let(:s2) { RDF::Statement(resource, RDF::URI.new("urn:predicate:2"), RDF::URI.new("urn:object:2")) }

      before :each do
        subject.insert(*[s1,s2])
      end

      after :each do
        subject.delete(*[s1,s2])
      end

      it "should not raise errors" do
        s1_updated = RDF::Statement(resource, RDF::URI.new("urn:predicate:1"), RDF::URI.new("urn:object:2"))
        expect { subject.update(s1_updated) }.not_to raise_error
      end

      it "should support updating one statement at a time with an object" do
        s1_updated = RDF::Statement(resource, RDF::URI.new("urn:predicate:1"), RDF::URI.new("urn:object:2"))
        subject.update(s1_updated)
        expect(subject.has_statement?(s1_updated)).to be true
        expect(subject.has_statement?(s1)).to be false
      end

      it "should support updating one statement at a time without an object" do
        s1_deleted = RDF::Statement(resource, RDF::URI.new("urn:predicate:1"), nil)
        subject.update(s1_deleted)
        expect(subject.has_statement?(s1)).to be false
      end

      it "should support updating an array of statements at a time" do
        s1_updated = RDF::Statement(resource, RDF::URI.new("urn:predicate:1"), RDF::URI.new("urn:object:2"))
        s2_updated = RDF::Statement(resource, RDF::URI.new("urn:predicate:2"), RDF::URI.new("urn:object:3"))
        subject.update(*[s1_updated, s2_updated])
        expect(subject.has_statement?(s1_updated)).to be true
        expect(subject.has_statement?(s2_updated)).to be true
        expect(subject.has_statement?(s1)).to be false
        expect(subject.has_statement?(s2)).to be false
      end

      it "should support updating an enumerable of statements at a time" do
        s1_updated = RDF::Statement(resource, RDF::URI.new("urn:predicate:1"), RDF::URI.new("urn:object:2"))
        s2_updated = RDF::Statement(resource, RDF::URI.new("urn:predicate:2"), RDF::URI.new("urn:object:3"))
        updates = [s1_updated, s2_updated]
        updates.extend(RDF::Enumerable)
        subject.update(updates)
        expect(subject.has_statement?(s1_updated)).to be true
        expect(subject.has_statement?(s2_updated)).to be true
        expect(subject.has_statement?(s1)).to be false
        expect(subject.has_statement?(s2)).to be false
      end
    end

    context "when deleting statements" do
      before :each do
        subject.insert(*@statements)
      end

      it "should not raise errors" do
        expect { subject.delete(non_bnode_statements.first) }.not_to raise_error
      end

      it "should support deleting one statement at a time" do
        subject.delete(non_bnode_statements.first)
        is_expected.not_to  have_statement(non_bnode_statements.first)
      end

      it "should support deleting multiple statements at a time" do
        subject.delete(*@statements)
        expect(subject.find { |s| subject.has_statement?(s) }).to be_nil
      end

      it "should support wildcard deletions" do
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

      it "should only delete statements when the graph_name matches" do
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

      it 'does not delete literal with different language' do
        if subject.mutable?
          en = RDF::Literal('abc', language: 'en')
          fi = RDF::Literal('abc', language: 'fi')

          subject.insert([RDF::URI('s'), RDF::URI('p'), en])
          expect { subject.delete([RDF::URI('s'), RDF::URI('p'), fi]) }
            .not_to change { subject.count }
        end
      end

      it 'does not delete literal with different datatype' do
        if subject.mutable? && @supports_literal_equality
          float = RDF::Literal::Float.new(1.0)
          double = RDF::Literal::Double.new(1.0)

          subject.insert([RDF::URI('s'), RDF::URI('p'), float])
          
          expect { subject.delete([RDF::URI('s'), RDF::URI('p'), double]) }
            .not_to change { subject.count }
        end
      end

      describe '#delete_insert' do
        let(:statement) do
          RDF::Statement.new(resource, 
                             RDF::URI.new("urn:predicate:1"), 
                             RDF::URI.new("urn:object:1"))
        end

        it 'deletes and inserts' do
          subject.delete_insert(@statements, [statement])
          is_expected.to contain_exactly statement
        end

        it 'deletes before inserting' do
          subject.delete_insert(@statements, [@statements.first])
          is_expected.to contain_exactly @statements.first
        end

        it 'deletes patterns' do
          pattern = [non_bnode_statements.first.subject, nil, nil]
          expect { subject.delete_insert([pattern], []) }
            .to change { subject.has_subject?(non_bnode_statements.first.subject) }
            .from(true).to(false)
        end

        it 'handles Enumerables' do
          dels = non_bnode_statements.take(10)
          dels.extend(RDF::Enumerable)
          ins = RDF::Graph.new << statement
          expect { subject.delete_insert(dels, ins) }
            .to change { dels.find { |s| subject.include?(s) } }.to be_nil
          is_expected.to include statement
        end

        it 'handles Graph names' do
          if @supports_named_graphs
            dels = non_bnode_statements.take(10).map do |st|
              RDF::Statement.from(st.to_hash.merge(graph_name: RDF::URI('fake')))
            end
            dels.map! { |st| st.graph_name = RDF::URI('fake'); st }
            dels.extend(RDF::Enumerable)
            expect { subject.delete_insert(dels, []) }
              .not_to change { subject.statements.count }
          end
        end

        context 'when transactions are supported' do
          it 'updates atomically' do
            if subject.mutable? && subject.supports?(:atomic_write)
              contents = subject.statements.to_a

              expect { subject.delete_insert(@statements, [nil]) }
                .to raise_error ArgumentError
              expect(subject.statements).to contain_exactly(*contents)
            end
          end
        end
      end
    end
    
    describe '#apply_changeset' do
      let(:changeset) { RDF::Changeset.new }

      it 'is a no-op when changeset is empty' do
        expect { subject.apply_changeset(changeset) }
          .not_to change { subject.statements }
      end

      it 'inserts statements' do
        changeset.insert(*non_bnode_statements)

        expect { subject.apply_changeset(changeset) }
          .to change { subject.statements }
               .to contain_exactly(*non_bnode_statements)
      end

      it 'deletes statements' do
        subject.insert(*non_bnode_statements)
        deletes = non_bnode_statements.take(10)
        
        changeset.delete(*deletes)
        subject.apply_changeset(changeset)

        expect(subject).not_to include(*deletes)
      end

      it 'deletes before inserting' do
        statement = non_bnode_statements.first
        
        changeset.insert(statement)
        changeset.delete(statement)
        subject.apply_changeset(changeset)

        expect(subject).to include(statement)
      end
    end
  end
end
