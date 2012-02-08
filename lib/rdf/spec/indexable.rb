require 'rdf/spec'

share_as :RDF_Indexable do
  include RDF::Spec::Matchers

  before :each do
    raise '+@indexable+ must be defined in a before(:each) block' unless instance_variable_get('@indexable')
  end
  
  it "responds to #indexed?" do
    @indexable.respond_to?(:indexed?)
  end
  
  it "implements #indexed?" do
    !!@indexable.indexed?.should == @indexable.indexed?
  end
  
  it "responds to #index!" do
    @indexable.respond_to?(:index!)
  end
  
  it "does not raise error on #index! if #indexed?" do
    lambda {@indexable.index!}.should_not raise_error if @indexable.indexed?
  end
  
  it "raises error on #index! if not #indexed?" do
    lambda {@indexable.index!}.should raise_error unless @indexable.indexed?
  end
end
