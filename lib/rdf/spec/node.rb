require 'rdf/spec'

share_as :RDF_Node do
  before :each do
    raise '+@new+ must be defined in a before(:each) block' unless instance_variable_get('@new')
  end

  it "should be instantiable" do
    lambda { @new.call }.should_not raise_error
  end
  
  it "== a node with the same identifier" do
    @new.call("a").should == @new.call("a")
  end

  
  it "not eql? a node with the same identifier", :pending => "SPARQL compatibility" do
    @new.call("a").should_not be_eql(@new.call("a"))
  end
end
