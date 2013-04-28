require 'rdf/spec'

# To use RDF::Durable to check that a repository maintains information between
# instantiations, add a Proc that creates a repository before each item, and
# clean that up after every run.  Example:
#describe RDF::DataObjects::Repository do
#  context "The SQLite adapter" do
#    before :each do
#      @repository = RDF::DataObjects::Repository.new "sqlite3://:memory:"
#      @load_durable = lambda { RDF::DataObjects::Repository.new "sqlite3:test.db" }
#    end
#
#    after :each do
#      File.delete('test.db') if File.exists?('test.db')
#    end
#
#    include RDF_Repository
#  end
#end
module RDF_Durable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@load_durable+ must be defined in a before(:each) block' unless instance_variable_get('@load_durable')
  end

  describe RDF::Durable do
    it "should support #durable?" do
      @load_durable.call.should respond_to(:durable?)
      [true,false].member?(@load_durable.call.durable?).should be_true
    end

    it "should support #nondurable?" do
      @load_durable.call.should respond_to(:nondurable?)
      [true,false].member?(@load_durable.call.nondurable?).should be_true
    end

    it "should not be both durable and nondurable" do
      @load_durable.call.nondurable?.should_not == @load_durable.call.durable?
    end

    it "should save contents between instantiations" do
      if @load_durable.call.durable?
        @load_durable.call.load(RDF::Spec::TRIPLES_FILE)
        @load_durable.call.count.should == File.readlines(RDF::Spec::TRIPLES_FILE).size
      end
    end
  end
end
