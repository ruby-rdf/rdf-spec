require 'rdf/spec'

RSpec.shared_examples 'an RDF::Indexable' do
  include RDF::Spec::Matchers

  before :each do
    raise 'indexable must be defined with let(:indexable)' unless
      defined? indexable
  end

  subject { indexable }

  it {should respond_to(:indexed?)}
  its(:indexed?) {should == subject.indexed?}
  it {should respond_to(:index!)}

  it "does not raise error on #index! if #indexed?" do
    expect {subject.index!}.not_to raise_error if subject.indexed?
  end

  it "raises error on #index! if not #indexed?" do
    expect {subject.index!}.to raise_error unless subject.indexed?
  end

end

##
# @deprecated use `it_behaves_like "an RDF::Indexable"` instead
module RDF_Indexable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  warn "[DEPRECATION] `RDF_Indexable` is deprecated. "\
       "Please use `it_behaves_like 'an RDF::Indexable'`"

  describe 'examples for' do
    include_examples 'an RDF::Indexable' do
      let(:indexable) { @indexable }

      before do
        raise '@indexable must be defined' unless defined?(indexable)
      end
    end
  end
end
