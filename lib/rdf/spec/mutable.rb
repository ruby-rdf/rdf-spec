require 'rdf'
require 'rdf/spec'
require 'rdf/ntriples'

share_as :RDF_Mutable do

  include RDF::Spec::Matchers

  before :each do
    raise '+@filename+ must be defined in a before(:each) block' unless instance_variable_get('@filename')
    raise '+@repository+ must be defined in a before(:each) block' unless instance_variable_get('@repository')
    raise '+@subject+ must be defined in a before(:each) block' unless instance_variable_get('@subject')
    raise '+@context+ must be defined in a before(:each) block' unless instance_variable_get('@context')
  end

  it "should support #load" do
    @repository.respond_to?(:load).should be_true
  end

  context "#load" do
    it "should require an argument" do
      lambda { @repository.load }.should raise_error(ArgumentError)
    end

    it "should accept a string filename argument" do
      lambda { @repository.load(@filename) }.should_not raise_error(ArgumentError)
    end

    it "should accept an optional hash argument" do
      lambda { @repository.load(@filename,{}) }.should_not raise_error(ArgumentError)
    end

    it "should load statements" do
      @repository.load @filename
      @repository.size.should ==  File.readlines(@filename).size
      @repository.should have_subject @subject
    end

    it "should load statements with a context override" do
      @repository.load @filename, :context => @context
      @repository.should have_context @context
      @repository.query(:context => @context).size.should == @repository.size
    end

  end

  context "when inserting statements" do

    before :each do
      @statements = RDF::NTriples::Reader.new(File.open(@filename)).to_a
    end

    it "should support #insert" do
      @repository.should respond_to(:insert)
    end

    it "should not raise errors" do
      lambda { @repository.insert(@statements.first) }.should_not raise_error
    end

    it "should support inserting one statement at a time" do
      @repository.insert(@statements.first)
      @repository.should have_statement(@statements.first)
    end

    it "should support inserting multiple statements at a time" do
      @repository.insert(*@statements)
    end

    it "should insert statements successfully" do
      @repository.insert(*@statements)
      @repository.count.should == @statements.size
    end
  end

  context "when deleting statements" do

    before :each do
      @statements = RDF::NTriples::Reader.new(File.open(@filename)).to_a
      @repository.insert(*@statements)
    end

    it "should support #delete" do
      @repository.should respond_to(:delete)
    end

    it "should not raise errors" do
      lambda { @repository.delete(@statements.first) }.should_not raise_error
    end

    it "should support deleting one statement at a time" do
      @repository.delete(@statements.first)
      @repository.should_not have_statement(@statements.first)
    end

    it "should support deleting multiple statements at a time" do
      @repository.delete(*@statements)
      @statements.find { |s| @repository.has_statement?(s) }.should be_false
    end

  end

  context "when clearing all statements" do
    it "should support #clear" do
      @repository.should respond_to(:clear)
    end
  end
end
