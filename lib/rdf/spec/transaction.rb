require 'rdf/spec'

# Pass in an instance of RDF::Transaction as follows:
#
#   it_behaves_like "RDF_Transaction", RDF::Transaction
shared_examples "RDF_Transaction" do |klass|
  include RDF::Spec::Matchers

  describe RDF::Transaction do
    subject {klass.new(:context => RDF::URI("name"), :insert => RDF::Graph.new, :delete => RDF::Graph.new)}

    describe "#initialize" do
      subject {klass}
      it "accepts a graph" do
        g = mock("graph")
        this = subject.new(:graph => g)
        this.graph.should == g
      end

      it "accepts a context" do
        c = mock("context")
        this = subject.new(:graph => c)
        this.graph.should == c
        this.context.should == c

        this = subject.new(:context => c)
        this.graph.should == c
        this.context.should == c
      end

      it "accepts inserts" do
        g = mock("inserts")
        this = subject.new(:insert => g)
        this.inserts.should == g
      end

      it "accepts deletes" do
        g = mock("deletes")
        this = subject.new(:delete => g)
        this.deletes.should == g
      end
    end

    its(:deletes) {should be_a(RDF::Enumerable)}
    its(:inserts) {should be_a(RDF::Enumerable)}
    it {should be_mutable}
    it {should_not be_readable}

    it "does not respond to #load" do
      lambda {subject.load("http://example/")}.should raise_error(NoMethodError)
    end

    it "does not respond to #update" do
      lambda {subject.update(RDF::Statement.new)}.should raise_error(NoMethodError)
    end

    it "does not respond to #clear" do
      lambda {subject.clear}.should raise_error(NoMethodError)
    end

    describe "#execute" do
      let(:s) {RDF::Statement.new(RDF::URI("s"), RDF::URI("p"), RDF::URI("o"))}
      let(:r) {mock("repository")}

      it "deletes statements" do
        r.should_receive(:delete).with(s)
        r.should_not_receive(:insert)
        subject.delete(s)
        subject.execute(r)
      end

      it "inserts statements" do
        r.should_not_receive(:delete)
        r.should_receive(:insert).with(s)
        subject.insert(s)
        subject.execute(r)
      end

      it "calls before_execute" do
        subject.should_receive(:before_execute).with(r, {})
        subject.execute(r)
      end

      it "calls after_execute" do
        subject.should_receive(:after_execute).with(r, {})
        subject.execute(r)
      end

      it "returns self" do
        subject.execute(r).should == subject
      end
    end
  
    describe "#delete_statement" do
      let(:s) {RDF::Statement.new(RDF::URI("s"), RDF::URI("p"), RDF::URI("o"))}
      it "adds statement to #deletes" do
        subject.delete(s)
        subject.deletes.to_a.should == [s]
      end
    end
  
    describe "#insert_statement" do
      let(:s) {RDF::Statement.new(RDF::URI("s"), RDF::URI("p"), RDF::URI("o"))}
      it "adds statement to #inserts" do
        subject.insert(s)
        subject.inserts.to_a.should == [s]
      end
    end
  end
end
