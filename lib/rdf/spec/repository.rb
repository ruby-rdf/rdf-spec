require 'rdf/spec'

RSpec.shared_examples 'an RDF::Repository' do
  include RDF::Spec::Matchers

  before :each do
    raise 'repository must be set with `let(:repository)' unless
      defined? repository

    if repository.empty? && repository.writable?
      repository.insert(*RDF::Spec.quads)
    elsif repository.empty?
      raise "+@repository+ must respond to #<< or be pre-populated with the statements in #{RDF::Spec::TRIPLES_FILE} in a before(:each) block"
    end
  end

  let(:mutable) { repository }
  let(:dataset) { repository.supports?(:snapshots) ? repository.snapshot : repository }
  subject { repository }

  context 'as dataset' do
    require 'rdf/spec/dataset'
    it_behaves_like 'an RDF::Dataset'
  end

  context 'as transactable' do
    require 'rdf/spec/transactable'
    let(:transactable) { repository }
    it_behaves_like 'an RDF::Transactable'
  end
  
  context "when updating" do
    require 'rdf/spec/mutable'

    before { mutable.clear if mutable.mutable? }
    it_behaves_like 'an RDF::Mutable'
    
    describe '#delete_insert' do
      it 'updates transactionally' do
        if mutable.mutable? && mutable.supports?(:atomic_writes)
          expect(mutable).to receive(:commit_transaction).and_call_original
          statement = RDF::Statement(:s, RDF::URI.new("urn:predicate:1"), :o)

          mutable.delete_insert([statement], [statement])
        end
      end
    end
  end

  context "with snapshot support" do

    describe '#snapshot' do
      it 'is not implemented when #supports(:snapshots) is false' do
        unless subject.supports?(:snapshots) 
          expect { subject.snapshot }.to raise_error NotImplementedError
        end
      end
    end

    it 'returns a queryable #snapshot' do
      if subject.supports? :snapshots
        expect(subject.snapshot).to be_a RDF::Queryable
        expect(mutable.snapshot).to be_a RDF::Dataset
      end
    end

    it 'has repeatable read isolation or better' do
      if repository.supports? :snapshots
        good_isolation = [:repeatable_read, :snapshot, :serializable]
        expect(good_isolation).to include repository.isolation_level
      end
    end

    it 'gives an accurate snapshot' do
      if subject.supports? :snapshots
        snap = subject.snapshot
        expect(snap.query([:s, :p, :o]))
          .to contain_exactly(*subject.query([:s, :p, :o]))
      end
    end

    it 'gives static snapshot' do
      if subject.supports? :snapshots
        snap = subject.snapshot
        expect { subject.clear }
          .not_to change { snap.query([:s, :p, :o]).to_a }
      end
    end
  end
end
