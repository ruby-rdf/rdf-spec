require 'rdf/spec'

share_as :RDF_Readable do
  include RDF::Spec::Matchers

  before :each do
    raise '+@readable+ must be defined in a before(:each) block' unless instance_variable_get('@readable')
  end
  
  it "responds to #readable?" do
    @readable.respond_to?(:readable?)
  end
  
  it "implements #readable?" do
    !!@readable.readable?.should == @readable.readable?
  end
end
