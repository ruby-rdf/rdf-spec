require 'rdf/spec'

module RDF_Countable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@countable+ must be defined in a before(:each) block' unless instance_variable_get('@countable')

    @statements = RDF::Spec.quads

    if @countable.empty?
      if (@countable.writable? rescue false)
        @countable.insert_statements(@statements)
      elsif @countable.respond_to?(:<<)
        @statements.each { |statement| @countable << statement }
      else
        raise "+@countable+ must respond to #<< or be pre-populated with the statements in #{RDF::Spec::TRIPLES_FILE} in a before(:each) block"
      end
    end
  end

  describe RDF::Countable do
    subject {@countable}

    it {should respond_to(:empty?)}
    it {should_not be_empty}
    it {should respond_to(:count)}
    its(:count) {should == @statements.size}
    it {should respond_to(:size)}
    its(:size) {should == @statements.size}

    context "when empty" do
      subject {[].extend(RDF::Countable)}
      it {should be_empty}
      its(:count) {should == 0}
      its(:size) {should == 0}
    end

    its(:to_enum) {should be_countable}
    its(:enum_for) {should be_countable}
    it "#enum_for(:each)" do
      expect(subject.enum_for(:each)).to be_countable
    end
  end
end
