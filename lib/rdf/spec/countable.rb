require 'rdf/spec'

module RDF_Countable
  extend RSpec::SharedContext
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

  describe RDF::Countable do
    it "responds to #empty?" do
      @countable.should respond_to(:empty?)
    end

    it "responds to #count and #size" do
      @countable.should respond_to(:count, :size)
    end

    it "implements #empty?" do
      ([].extend(RDF::Countable)).empty?.should be_true
      ([42].extend(RDF::Countable)).empty?.should be_false
      @countable.empty?.should be_false
    end

    it "implements #count and #size" do
      %w(count size).each do |method|
        @countable.send(method).should >= @statements.size
      end
    end

    it "returns countable enumerators" do
      @countable.to_enum.should be_countable
      @countable.enum_for.should be_countable
      @countable.enum_for(:each).should be_countable
    end
  end
end
