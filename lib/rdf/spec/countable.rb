require 'rdf/spec'
require 'spec'

share_as :RDF_Countable do
  include RDF::Spec::Matchers

  before :each do
    raise '+@countable+ must be defined in a before(:each) block' unless instance_variable_get('@countable')

    @filename   = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'doap.nt'))
    @statements = RDF::NTriples::Reader.new(File.open(@filename)).to_a

    if @countable.empty?
      if @countable.respond_to?(:<<)
        @statements.each { |statement| @countable << statement }
      else
        raise "+@countable+ must respond to #<< or be pre-populated with the statements in #{@filename} in a before(:each) block"
      end
    end
  end

  context "when counting items" do
    it "should respond to #empty?" do
      @countable.should respond_to(:empty?)
    end

    it "should respond to #count and #size" do
      @countable.should respond_to(*%w(count size))
    end

    it "should implement #empty?" do
      ([].extend(RDF::Countable)).empty?.should be_true
      @countable.empty?.should be_false
    end

    it "should implement #count and #size" do
      %w(count size).each do |method|
        @countable.send(method).should == @statements.size
      end
    end
  end
end
