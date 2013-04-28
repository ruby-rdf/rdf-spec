require 'rdf/spec'

module RDF_Readable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@readable+ must be defined in a before(:each) block' unless instance_variable_get('@readable')
  end

  describe RDF::Readable do
    subject {@readable}
    it {should be_respond_to(:readable?)}
    its(:readable?) {should == subject.readable?}
  end
end
