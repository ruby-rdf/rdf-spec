require 'rdf'
require 'rdf/spec'

share_as :RDF_Graph do
  before :each do
    raise '+@new+ must be defined in a before(:each) block' unless instance_variable_get('@new')
  end

  context "unnamed graphs" do
    it "should be instantiable" do
      lambda { @new.call }.should_not raise_error
    end

    it "should be unnamed" do
      graph = @new.call
      graph.unnamed?.should be_true
      graph.named?.should be_false
    end

    it "should not have a context" do
      graph = @new.call
      graph.context.should be_nil
      graph.contexts.size.should == 0
    end
  end

  context "named graphs" do
    it "should be instantiable" do
      lambda { @new.call }.should_not raise_error
    end

    it "should be named" do
      graph = @new.call("http://rdf.rubyforge.org/")
      graph.unnamed?.should be_false
      graph.named?.should be_true
    end

    it "should have a context" do
      graph = @new.call("http://rdf.rubyforge.org/")
      graph.context.should_not be_nil
      graph.contexts.size.should == 1
    end

    it "should be #anonymous? with a Node context" do
      graph = @new.call(RDF::Node.new)
      graph.should be_anonymous
    end

    it "should not be #anonymous? with a URI context" do
      graph = @new.call("http://rdf.rubyforge.org/")
      graph.should_not be_anonymous
    end
  end
end
