require 'rdf/spec'

module RDF_Transaction
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@transaction+ must be defined in a before(:each) block' unless instance_variable_get('@transaction')
  end

  describe RDF::Transaction do
    #TODO
    describe "#initialize" do
      it "accepts a graph"
      it "accepts a context"
      it "accepts inserts"
      it "accepts deletes"
    end
  
    describe "#graph" do
      it "is mutable"
    end
  
    describe "#deletes" do
      it "is mutable"
    end
  
    describe "#inserts" do
      it "is mutable"
    end
  
    describe "#readable?" do
      it "returns false" do
        @transaction.readable?.should be_false
      end
    end
  
    describe "#execute" do
      it "deletes statements"
      it "inserts statements"
      it "calls before_execute"
      it "calls after_execute"
      it "returns self"
      it "does not delete statements on failures"
      it "does not insert statements on failures"
    end
  
    describe "#delete_statement" do
      it "adds statement to #deletes"
      it "does not remove statement from graph"
    end
  
    describe "#insert_statement" do
      it "adds statement to #inserts"
      it "does not add statement to graph"
    end
  
    it "does not respond to #load"
    it "does not respond to #update"
    it "does not respond to #clear"
  end
end
