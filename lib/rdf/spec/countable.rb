require 'rdf/spec'

RSpec.shared_examples 'an RDF::Countable' do
  include RDF::Spec::Matchers

  before do
    raise 'countable must be set with `let(:countable)' unless
      defined? countable

    @statements = RDF::Spec.quads

    if countable.empty?
      if (countable.writable? rescue false)
        countable.send(:insert_statements, @statements)
      elsif countable.respond_to?(:<<)
        @statements.each { |statement| countable << statement }
      else
        raise "+countable+ must respond to #<< or be pre-populated with the" \
              "statements in #{RDF::Spec::TRIPLES_FILE} in a before block"
      end
    end
  end

  describe RDF::Countable do
    subject {countable}

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

##
# @deprecated use `it_behaves_like "an RDF::Countable"` instead
module RDF_Countable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  warn "[DEPRECATION] `RDF_Countable` is deprecated. "\
       "Please use `it_behaves_like 'an RDF::Countable'`"

  describe 'examples for' do
    include_examples 'an RDF::Countable' do
      let(:countable) { @countable }

      before do
        raise '@countable must be defined' unless defined?(countable)
      end
    end
  end
end
