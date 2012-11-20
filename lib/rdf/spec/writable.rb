require 'rdf/spec'

module RDF_Writable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@writable+ must be defined in a before(:each) block' unless instance_variable_get('@writable')

    @filename = File.expand_path("../../../../etc/doap.nt", __FILE__)
    @statements = RDF::NTriples::Reader.new(File.open(@filename)).to_a

    @supports_context = @writable.respond_to?(:supports?) && @writable.supports?(:context)
  end

  describe RDF::Writable do
    it "responds to #writable?" do
      @writable.respond_to?(:readable?)
    end
  
    it "implements #writable?" do
      !!@writable.writable?.should == @writable.writable?
    end

    describe "#<<" do
      it "inserts a reader" do
        reader = RDF::NTriples::Reader.new(File.open(@filename)).to_a
        @writable << reader
        @writable.should have_statement(@statements.first)
        @writable.count.should == @statements.size
      end

      it "inserts a graph" do
        graph = RDF::Graph.new << @statements
        @writable << graph
        @writable.should have_statement(@statements.first)
        @writable.count.should == @statements.size
      end

      it "inserts an enumerable" do
        enumerable = @statements.dup.extend(RDF::Enumerable)
        @writable << enumerable
        @writable.should have_statement(@statements.first)
        @writable.count.should == @statements.size
      end

      it "inserts data responding to #to_rdf" do
        mock = double('mock')
        mock.stub(:to_rdf).and_return(@statements)
        @writable << mock
        @writable.should have_statement(@statements.first)
        @writable.count.should == @statements.size
      end

      it "inserts a statement" do
        @writable << @statements.first
        @writable.should have_statement(@statements.first)
        @writable.count.should == 1
      end
    end

    context "when inserting statements" do
      it "should support #insert" do
        @writable.should respond_to(:insert)
      end

      it "should not raise errors" do
        if @writable.writable?
          lambda { @writable.insert(@statements.first) }.should_not raise_error
        end
      end

      it "should support inserting one statement at a time" do
        if @writable.writable?
          @writable.insert(@statements.first)
          @writable.should have_statement(@statements.first)
        end
      end

      it "should support inserting multiple statements at a time" do
        if @writable.writable?
          @writable.insert(*@statements)
        end
      end

      it "should insert statements successfully" do
        if @writable.writable?
          @writable.insert(*@statements)
          @writable.count.should == @statements.size
        end
      end

      it "should not insert a statement twice" do
        if @writable.writable?
          @writable.insert(@statements.first)
          @writable.insert(@statements.first)
          @writable.count.should == 1
        end
      end

      it "should treat statements with a different context as distinct" do
        if @writable.writable?
          s1 = @statements.first.dup
          s1.context = nil
          s2 = @statements.first.dup
          s2.context = RDF::URI.new("urn:context:1")
          s3 = @statements.first.dup
          s3.context = RDF::URI.new("urn:context:2")
          @writable.insert(s1)
          @writable.insert(s2)
          @writable.insert(s3)
          # If contexts are not suported, all three are redundant
          @writable.count.should == (@supports_context ? 3 : 1)
        end
      end
    end
  end
end
