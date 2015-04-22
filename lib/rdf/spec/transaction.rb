require 'rdf/spec'

# Pass in an instance of RDF::Transaction as follows:
#
#   it_behaves_like "RDF::Transaction", RDF::Transaction
shared_examples "RDF::Transaction" do |klass|
  include RDF::Spec::Matchers

  subject {klass.new(:context => RDF::URI("name"), :insert => RDF::Graph.new, :delete => RDF::Graph.new)}

  describe "#initialize" do
    subject {klass}
    it "accepts a graph" do
      g = double("graph")
      this = subject.new(:graph => g)
      expect(this.graph).to eq g
    end

    it "accepts a context" do
      c = double("context")
      this = subject.new(:graph => c)
      expect(this.graph).to eq c
      expect(this.context).to eq c

      this = subject.new(:context => c)
      expect(this.graph).to eq c
      expect(this.context).to eq c
    end

    it "accepts inserts" do
      g = double("inserts")
      this = subject.new(:insert => g)
      expect(this.inserts).to eq g
    end

    it "accepts deletes" do
      g = double("deletes")
      this = subject.new(:delete => g)
      expect(this.deletes).to eq g
    end
  end

  its(:deletes) {should be_a(RDF::Enumerable)}
  its(:inserts) {should be_a(RDF::Enumerable)}
  it {should be_mutable}
  it {should_not be_readable}

  it "does not respond to #load" do
    expect {subject.load("http://example/")}.to raise_error(NoMethodError)
  end

  it "does not respond to #update" do
    expect {subject.update(RDF::Statement.new)}.to raise_error(NoMethodError)
  end

  it "does not respond to #clear" do
    expect {subject.clear}.to raise_error(NoMethodError)
  end

  describe "#execute" do
    let(:s) {RDF::Statement.new(RDF::URI("s"), RDF::URI("p"), RDF::URI("o"))}
    let(:r) {double("repository")}

    it "deletes statements" do
      expect(r).to receive(:delete).with(s)
      expect(r).not_to receive(:insert)
      subject.delete(s)
      subject.execute(r)
    end

    it "inserts statements" do
      expect(r).not_to receive(:delete)
      expect(r).to receive(:insert).with(s)
      subject.insert(s)
      subject.execute(r)
    end

    it "calls before_execute" do
      expect(subject).to receive(:before_execute).with(r, {})
      subject.execute(r)
    end

    it "calls after_execute" do
      expect(subject).to receive(:after_execute).with(r, {})
      subject.execute(r)
    end

    it "returns self" do
      expect(subject.execute(r)).to eq subject
    end
  end

  describe "#delete_statement" do
    let(:s) {RDF::Statement.new(RDF::URI("s"), RDF::URI("p"), RDF::URI("o"))}
    it "adds statement to #deletes" do
      subject.delete(s)
      expect(subject.deletes.to_a).to eq [s]
    end
  end

  describe "#insert_statement" do
    let(:s) {RDF::Statement.new(RDF::URI("s"), RDF::URI("p"), RDF::URI("o"))}
    it "adds statement to #inserts" do
      subject.insert(s)
      expect(subject.inserts.to_a).to eq [s]
    end
  end
end
