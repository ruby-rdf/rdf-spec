require 'rdf'
require 'rdf/spec'
require 'rdf/ntriples'

share_as :RDF_Mutable do

  include RDF::Spec::Matchers

  before :each do
    raise '+@filename+ must be defined in a before(:each) block' unless instance_variable_get('@filename')
    raise '+@repo+ must be defined in a before(:each) block' unless instance_variable_get('@repo')
    raise '+@subject+ must be defined in a before(:each) block' unless instance_variable_get('@subject')
    raise '+@context+ must be defined in a before(:each) block' unless instance_variable_get('@context')
  end

  it "should support #load" do
    @repo.respond_to?(:load).should be_true
  end

  context "#load" do
    it "should require an argument" do
      lambda { @repo.load }.should raise_error(ArgumentError)
    end

    it "should accept a string filename argument" do
      lambda { @repo.load(@filename) }.should_not raise_error(ArgumentError)
    end

    it "should accept an optional hash argument" do
      lambda { @repo.load(@filename,{}) }.should_not raise_error(ArgumentError)
    end

    it "should load statements" do
      @repo.load @filename
      @repo.size.should ==  File.readlines(@filename).size
      @repo.should have_subject @subject
    end

    it "should load statements with a context override" do
      @repo.load @filename, :context => @context
      @repo.should have_context @context
      @repo.query(:context => @context).size.should == @repo.size
    end

  end
end
