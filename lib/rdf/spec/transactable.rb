require 'rdf/spec'

RSpec.shared_examples 'an RDF::Transactable' do
  include RDF::Spec::Matchers

  let(:statements) { RDF::Spec.quads }

  before do
    raise '`transactable` must be set with `let(:transactable)`' unless
      defined? transactable
  end

  subject { transactable }

  describe "#transaction" do
    it 'gives an immutable transaction' do
      expect { subject.transaction { insert([]) } }.to raise_error TypeError
    end

    it 'commits a successful transaction' do
      statement = RDF::Statement(:s, RDF.type, :o)
      expect(subject).to receive(:commit_transaction).and_call_original
      
      expect do
        subject.transaction(mutable: true) { insert(statement) }
      end.to change { subject.statements }.to include(statement)
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

    context 'without block given' do
      it 'returns a transaction' do
        expect(subject.transaction).to be_a RDF::Transaction
      end

      it 'the returned transaction is live' do
        tx = subject.transaction(mutable: true)
        tx.insert(RDF::Statement(:s, RDF.type, :o))
        expect { tx.execute }.not_to raise_error
      end
    end
  end
end
