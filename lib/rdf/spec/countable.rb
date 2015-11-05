require 'rdf/spec'

RSpec.shared_examples 'an RDF::Countable' do
  include RDF::Spec::Matchers

  let(:statements) {RDF::Spec.quads}
  before do
    raise 'countable must be set with `let(:countable)' unless
      defined? countable

    if countable.empty?
      if (countable.writable? rescue false)
        countable.send(:insert_statements, statements)
      elsif countable.respond_to?(:<<)
        statements.each { |statement| countable << statement }
      else
        raise "+countable+ must respond to #<< or be pre-populated with the" \
              "statements in #{RDF::Spec::TRIPLES_FILE} in a before block"
      end
    end
  end

  describe RDF::Countable do
    subject {countable}

    it {is_expected.to respond_to(:empty?)}
    it {is_expected.to_not be_empty}
    it {is_expected.to respond_to(:count)}
    its(:count) {is_expected.to eq statements.size}
    it {is_expected.to respond_to(:size)}
    its(:size) {is_expected.to eq statements.size}

    context "when empty" do
      subject {[].extend(RDF::Countable)}
      it {is_expected.to be_empty}
      its(:count) {is_expected.to eq 0}
      its(:size) {is_expected.to eq 0}
    end

    its(:to_enum) {is_expected.to be_countable}
    its(:enum_for) {is_expected.to be_countable}
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

  def self.included(mod)
    warn "[DEPRECATION] `RDF_Countable` is deprecated. "\
         "Please use `it_behaves_like 'an RDF::Countable'`"
  end

  describe 'examples for' do
    include_examples 'an RDF::Countable' do
      let(:countable) { @countable }

      before do
        raise '@countable must be defined' unless defined?(countable)
      end
    end
  end
end
