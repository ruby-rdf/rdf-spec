require 'rdf/spec'

share_as :RDF_Node do
  before :each do
    raise '+@new+ must be defined in a before(:each) block' unless instance_variable_get('@new')
  end

  it "should be instantiable" do
    lambda { @new.call }.should_not raise_error
  end
end
