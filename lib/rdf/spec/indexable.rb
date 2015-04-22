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
