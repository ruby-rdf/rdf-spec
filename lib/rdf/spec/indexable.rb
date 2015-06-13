require 'rdf/spec'

RSpec.shared_examples 'an RDF::Indexable' do
  include RDF::Spec::Matchers

  before :each do
    raise 'indexable must be defined with let(:indexable)' unless
      defined? indexable
  end

  subject { indexable }

  it {should respond_to(:indexed?)}
  it {should respond_to(:index!)}

  it "returns boolean for #indexed?" do
    expect(subject.indexed?).to satisfy {|x| x.is_a?(TrueClass) || x.is_a?(FalseClass)}
  end

  it "returns self on #index!" do
    expect(subject.index!).to be
  end
end

##
# @deprecated use `it_behaves_like "an RDF::Indexable"` instead
module RDF_Indexable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  def self.included(mod)
    warn "[DEPRECATION] `RDF_Indexable` is deprecated. "\
         "Please use `it_behaves_like 'an RDF::Indexable'`"
  end

  describe 'examples for' do
    include_examples 'an RDF::Indexable' do
      let(:indexable) { @indexable }

      before do
        raise '@indexable must be defined' unless defined?(indexable)
      end
    end
  end
end
