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
      klass.new(repository)
    end
    it_behaves_like 'an RDF::Queryable'

    context 'with a graph_name' do
      let(:queryable) do
        graph_name = RDF::URI('http://example.com/g')
        graph = RDF::Graph.new(graph_name: graph_name, data: repository)
        graph.insert(*RDF::Spec.quads)
        klass.new(repository, graph_name: graph_name)
      end
      it_behaves_like 'an RDF::Queryable'
    end

    context 'with a false graph_name' do
      let(:queryable) do
        graph = RDF::Graph.new(data: repository)
        graph.insert(*RDF::Spec.quads)
        graph_name = false
        klass.new(repository, graph_name: graph_name)
      end
      it_behaves_like 'an RDF::Queryable'
    end
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
    let(:st) { RDF::Statement(:s, RDF::URI('http://example.com/p'), 'o') }
    
    it 'adds to deletes' do
      repository.insert(st)

      expect do 
        subject.delete(st)
        subject.execute
      end.to change { subject.repository.empty? }.from(false).to(true)
    end

    it 'adds multiple to deletes' do
      sts = [st] << RDF::Statement(:x, RDF::URI('http://example.com/y'), 'z')
      repository.insert(*sts)

      expect do
        subject.delete(*sts)
        subject.execute
      end.to change { subject.repository.empty? }.from(false).to(true)
    end

    it 'adds enumerable to deletes' do
      sts = [st] << RDF::Statement(:x, RDF::URI('http://example.com/y'), 'z')
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

      it 'overwrites existing graph names' do
        st.graph_name = RDF::URI('http://example.com/g')
        repository.insert(st)
        
        expect do 
          subject.delete(st)
          subject.execute
        end.not_to change { subject.repository.statements }
      end

      it 'overwrites existing default graph name' do
        st.graph_name = false

        repository.insert(st)
        
        expect do 
          subject.delete(st)
          subject.execute
        end.not_to change { subject.repository.statements }
      end
    end
  end

  describe "#insert" do
    let(:st) { RDF::Statement(:s, RDF::URI('http://example.com/p'), 'o') }
    
    it 'adds to inserts' do
      expect do
        subject.insert(st)
        subject.execute
      end.to change { subject.repository.statements }
              .to contain_exactly(st)
    end

    it 'adds multiple to inserts' do
      sts = [st] << RDF::Statement(:x, RDF::URI('http://example.com/y'), 'z')
      
      expect do
        subject.insert(*sts)
        subject.execute
      end.to change { subject.repository.statements }
              .to contain_exactly(*sts)
    end

    it 'adds enumerable to inserts' do
      sts = [st] << RDF::Statement(:x, RDF::URI('http://example.com/y'), 'z')
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
        end.to change { subject.repository.statements }

        expect(subject.repository).to have_statement(with_name)
      end

      it 'overwrites existing graph names' do
        st.graph_name = RDF::URI('http://example.com/g')
        with_name = st.dup
        with_name.graph_name = graph_uri

        expect do 
          subject.insert(st)
          subject.execute
        end.to change { subject.repository.statements }

        expect(subject.repository).not_to have_statement(st)
        expect(subject.repository).to have_statement(with_name)
      end

      it 'overwrites existing default graph name' do
        st.graph_name = false
        with_name = st.dup
        with_name.graph_name = graph_uri

        expect do
          subject.insert(st)
          subject.execute
        end.to change { subject.repository.statements }
        
        expect(subject.repository).not_to have_statement(st)
        expect(subject.repository).to have_statement(with_name)
      end
    end
  end

  describe '#mutated?' do
    let(:st) { RDF::Statement(:s, RDF::URI('http://example.com/p'), 'o') }

    it 'returns true after a successful insert' do
      begin 
        expect { subject.insert(st) }
          .to change { subject.mutated? }.from(false).to(true)
      rescue NotImplementedError; end
    end

    it 'returns true after a successful delete' do
      repository.insert(st)

      begin 
        expect { subject.delete(st) }
          .to change { subject.mutated? }.from(false).to(true)
      rescue NotImplementedError; end
    end
  end

  describe '#execute' do
    let(:st) { RDF::Statement(:s, RDF::URI('http://example.com/p'), 'o') }
      
    context 'after rollback' do
      before { subject.rollback }

      it 'does not execute' do
        expect { subject.execute }
          .to raise_error RDF::Transaction::TransactionError
      end
    end

    context 'when :read_committed' do
      it 'does not read uncommitted statements' do
        unless subject.isolation_level == :read_uncommitted
          read_tx = klass.new(repository, mutable: true)
          subject.insert(st)
          
          expect(read_tx.statements).not_to include(st)
        end
      end

      it 'reads committed statements' do
        if subject.isolation_level == :read_committed
          read_tx = klass.new(repository)
          subject.insert(st)
          subject.execute
          
          expect(read_tx.statements).to include(st)
        end
      end
    end

    context 'when :repeatable_read' do
      it 'does not read committed statements already read' do
        if subject.isolation_level == :repeatable_read || 
           subject.isolation_level == :snapshot        || 
           subject.isolation_level == :serializable
          read_tx = klass.new(repository)
          subject.insert(st)
          subject.execute

          expect(read_tx.statements).not_to include(st)
        end
      end
    end

    context 'when :snapshot' do
      it 'does not read committed statements' do
        if subject.isolation_level == :snapshot     ||
           subject.isolation_level == :serializable
          read_tx = klass.new(repository)
          subject.insert(st)
          subject.execute

          expect(read_tx.statements).not_to include(st)
        end
      end

      it 'reads current transaction state' do
        if subject.isolation_level == :snapshot     ||
           subject.isolation_level == :serializable
          subject.insert(st)
          expect(subject.statements).to include(st)
        end
      end
    end

    context 'when :serializable' do
      it 'raises an error if conflicting changes are present' do
        if subject.isolation_level == :serializable
          subject.insert(st)
          repository.insert(st)
          
          expect { subject.execute }
            .to raise_error RDF::Transaction::TransactionError
        end
      end
    end
  end

  describe '#rollback' do
    before { subject.insert(st); subject.delete(st) }
    let(:st) { RDF::Statement(:s, RDF::URI('http://example.com/p'), 'o') }

    it 'empties changes when available' do
      expect { subject.rollback }.to change { subject.changes }.to be_empty
    end
  end
end

shared_examples "RDF_Transaction" do |klass|
  it_behaves_like 'an RDF::Transaction', klass
end
