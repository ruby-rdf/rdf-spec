require 'rdf/spec'

RSpec.shared_examples 'an RDF::Repository' do
  include RDF::Spec::Matchers

  before :each do
    raise 'repository must be set with `let(:repository)' unless
      defined? repository

    @statements = RDF::Spec.quads
    if repository.empty? && repository.writable?
      repository.insert(*@statements)
    elsif repository.empty?
      raise "+@repository+ must respond to #<< or be pre-populated with the statements in #{RDF::Spec::TRIPLES_FILE} in a before(:each) block"
    end
  end

  let(:mutable) { repository }
  let(:dataset) { repository }

  context 'as dataset' do
    require 'rdf/spec/dataset'
    it_behaves_like 'an RDF::Dataset'
  end
  
  context "when updating" do
    require 'rdf/spec/mutable'

    before { mutable.clear }
    it_behaves_like 'an RDF::Mutable'
    
    describe '#delete_insert' do
      it 'updates transactionally' do
        expect(mutable).to receive(:commit_transaction).and_call_original
        statement = RDF::Statement(:s, RDF::URI.new("urn:predicate:1"), :o)
                                    
        mutable.delete_insert([statement], [statement])
      end
    end
  end
 
  describe "#transaction" do
    it 'gives an immutable transaction' do
      expect { subject.transaction { insert([]) } }.to raise_error TypeError
    end

    it 'commits a successful transaction' do
      statement = RDF::Statement(:s, RDF.type, :o)
      expect(subject).to receive(:commit_transaction).and_call_original
    
      expect do
        subject.transaction(mutable: true) do
          insert(statement)
        end
      end.to change { subject.statements }.to contain_exactly(statement)
    end

    it 'rolls back a failed transaction' do
      original_contents = subject.statements
      expect(subject).to receive(:rollback_transaction).and_call_original

      expect do
        subject.transaction(mutable: true) do
          delete(*@statements)
          raise 'my error'
        end
      end.to raise_error RuntimeError

      expect(subject.statements).to contain_exactly(*original_contents)
    end
  end

  context "with snapshot support" do
    it 'returns a queryable #snapshot' do
      if repository.supports? :snapshots
        expect(repository.snapshot).to be_a RDF::Queryable
      end
    end

    it 'has repeatable read isolation or better' do
      if repository.supports? :snapshots
        good_isolation = [:repeatable_read, :snapshot, :serializable]
        expect(good_isolation).to include repository.isolation_level
      end
    end

    it 'gives an accurate snapshot' do
      if repository.supports? :snapshots
        snap = repository.snapshot
        expect(snap.query([:s, :p, :o]))
          .to contain_exactly(*repository.query([:s, :p, :o]))
      end
    end

    it 'gives static snapshot' do
      if repository.supports? :snapshots
        snap = repository.snapshot
        expect { repository.clear }
          .not_to change { snap.query([:s, :p, :o]).to_a }
      end
    end
  end
end
