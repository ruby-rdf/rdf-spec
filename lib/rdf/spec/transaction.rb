require 'rdf/spec'

# Pass in an instance of RDF::Transaction as follows:
#
#   it_behaves_like "an RDF::Transaction", RDF::Transaction
shared_examples "an RDF::Transaction" do |klass|
  include RDF::Spec::Matchers

  before do
    raise 'repository must be set with `let(:repository)' unless 
      defined? repository
  end

  subject { klass.new(repository, mutable: true) }

  it { is_expected.to be_readable }
  it { is_expected.to be_queryable }

  context "when querying statements" do
    require 'rdf/spec/queryable'
    let(:queryable) do
      repository.insert(*RDF::Spec.quads)
      q = klass.new(repository, mutable: true)
    end
    it_behaves_like 'an RDF::Queryable'
  end

  describe "#initialize" do
    it 'accepts a repository' do
      repo = double('repository')
      allow(repo).to receive_messages(:supports? => false)

      expect(klass.new(repo).repository).to eq repo
    end

    it 'defaults immutable (read only)' do
      expect(klass.new(repository).mutable?).to be false
    end

    it 'allows mutability' do
      expect(klass.new(repository, mutable: true)).to be_mutable
    end

    it 'accepts a graph_name' do
      graph_uri = RDF::URI('http://example.com/graph_1')
      
      expect(klass.new(repository, graph_name: graph_uri).graph_name)
        .to eq graph_uri
    end

    it 'defaults graph_name to nil' do
      expect(klass.new(repository).graph_name).to be_nil
    end
  end

  it "does not respond to #load" do
    expect { subject.load("http://example/") }.to raise_error(NoMethodError)
  end

  it "does not respond to #update" do
    expect { subject.update(RDF::Statement.new) }.to raise_error(NoMethodError)
  end

  it "does not respond to #clear" do
    expect { subject.clear }.to raise_error(NoMethodError)
  end

  describe '#changes' do
    it 'is a changeset' do
      expect(subject.changes).to be_a RDF::Changeset
    end

    it 'is initially empty' do
      expect(subject.changes).to be_empty
    end
  end

  describe "#delete" do
    let(:st) { RDF::Statement(:s, RDF::URI('p'), 'o') }
    
    it 'adds to deletes' do
      repository.insert(st)

      expect do 
        subject.delete(st)
        subject.execute
      end.to change { subject.repository.empty? }.from(false).to(true)
    end

    it 'adds multiple to deletes' do
      sts = [st] << RDF::Statement(:x, RDF::URI('y'), 'z')
      repository.insert(*sts)

      expect do
        subject.delete(*sts)
        subject.execute
      end.to change { subject.repository.empty? }.from(false).to(true)
    end

    it 'adds enumerable to deletes' do
      sts = [st] << RDF::Statement(:x, RDF::URI('y'), 'z')
      sts.extend(RDF::Enumerable)
      repository.insert(sts)

      expect do
        subject.delete(sts)
        subject.execute
      end.to change { subject.repository.empty? }.from(false).to(true)
    end

    context 'with a graph_name' do
      subject { klass.new(repository, mutable: true, graph_name: graph_uri) }
      
      let(:graph_uri) { RDF::URI('http://example.com/graph_1') }
      
      it 'adds the graph_name to statements' do
        repository.insert(st)
        with_name = st.dup
        with_name.graph_name = graph_uri
        repository.insert(with_name)

        expect do 
          subject.delete(st)
          subject.execute
        end.to change { subject.repository.statements }

        expect(subject.repository).not_to have_statement(with_name)
        expect(subject.repository).to have_statement(st)
      end
    end
  end

  describe "#insert" do
    let(:st) { RDF::Statement(:s, RDF::URI('p'), 'o') }
    
    it 'adds to inserts' do
      expect do
        subject.insert(st)
        subject.execute
      end.to change { subject.repository.statements }
              .to contain_exactly(st)
    end

    it 'adds multiple to inserts' do
      sts = [st] << RDF::Statement(:x, RDF::URI('y'), 'z')
      
      expect do
        subject.insert(*sts)
        subject.execute
      end.to change { subject.repository.statements }
              .to contain_exactly(*sts)
    end

    it 'adds enumerable to inserts' do
      sts = [st] << RDF::Statement(:x, RDF::URI('y'), 'z')
      sts.extend(RDF::Enumerable)

      expect do
        subject.insert(sts)
        subject.execute
      end.to change { subject.repository.statements }
              .to contain_exactly(*sts)
    end

    context 'with a graph_name' do
      subject { klass.new(repository, mutable: true, graph_name: graph_uri) }
      
      let(:graph_uri) { RDF::URI('http://example.com/graph_1') }
      
      it 'adds the graph_name to statements' do
        with_name = st.dup
        with_name.graph_name = graph_uri

        expect do 
          subject.insert(st)
          subject.execute
        end.to change { subject.repository }

        expect(subject.repository).to have_statement(with_name)
      end

      it 'retains existing graph names' do
        st.graph_name = RDF::URI('g')
        
        expect do 
          subject.insert(st)
          subject.execute
        end.to change { subject.repository.statements }

        expect(subject.repository).to have_statement(st)
      end
    end
  end

  describe '#execute' do
    # @todo: test isolation semantics!

    context 'after rollback' do
      before { subject.rollback }

      it 'does not execute' do
        expect { subject.execute }
          .to raise_error RDF::Transaction::TransactionError
      end
    end
  end

  describe '#rollback' do
    before { subject.insert(st); subject.delete(st) }
    let(:st) { RDF::Statement(:s, RDF::URI('p'), 'o') }

    it 'empties changes when available' do
      expect { subject.rollback }.to change { subject.changes }.to be_empty
    end
  end
end

shared_examples "RDF_Transaction" do |klass|
  it_behaves_like 'an RDF::Transaction', klass
end
