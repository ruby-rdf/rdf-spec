require 'rdf/spec'

module RDF_Indexable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@indexable+ must be defined in a before(:each) block' unless instance_variable_get('@indexable')
  end

  describe RDF::Indexable do
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
end
