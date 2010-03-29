require 'rdf/spec'
require 'spec'

share_as :RDF_Repository do
  include RDF::Spec::Matchers

  before :each do
    raise '+@repository+ must be defined in a before(:each) block' unless instance_variable_get('@repository')
    @filename   = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'doap.nt'))
    @statements = RDF::NTriples::Reader.new(File.open(@filename)).to_a
    @enumerable = @repository
  end

  it "should be empty initially" do
    @repository.empty?.should be_true
    @repository.count.should be_zero
  end

  it "should be readable" do
    @repository.readable?.should be_true
  end

  it "should be mutable" do
    @repository.immutable?.should be_false
    @repository.mutable?.should be_true
  end

  context "when updating" do
    require 'rdf/spec/mutable'

    before :each do
      @subject    = RDF::URI.new("http://rubygems.org/gems/rdf")
      @context    = RDF::URI.new("http://example.org/context")
    end

    it_should_behave_like RDF_Mutable

  end

  context "when enumerating statements" do
    require 'rdf/spec/enumerable'

    before :each do
      @repository.insert(*@statements)
      @enumerable = @repository
    end

    it_should_behave_like RDF_Enumerable
  end

end
