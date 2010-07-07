require 'rdf'
require 'rdf/spec'

share_as :RDF_Value do
  before :each do
    raise '+@value+ must be defined in a before(:each) block' unless instance_variable_get('@value')
    raise '+@resource+ must be defined in a before(:each) block' unless instance_variable_get('@resource')
  end

  describe RDF::Value do
    it "should not be instantiable" do
      lambda { @value.call }.should raise_error(NoMethodError)
    end
  end

  describe RDF::Resource do
    it "should instantiate blank nodes" do
      resource = @resource.call('_:foobar')
      resource.class.should == RDF::Node
      resource.id.should == 'foobar'
    end

    it "should instantiate URIs" do
      resource = @resource.call('http://rdf.rubyforge.org/')
      resource.class.should == RDF::URI
      resource.to_s.should == 'http://rdf.rubyforge.org/'
    end
  end
end
