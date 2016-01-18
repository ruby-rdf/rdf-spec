require 'rdf/spec'

RSpec.shared_examples 'an RDF::Indexable' do
  include RDF::Spec::Matchers

  before :each do
    raise 'indexable must be defined with let(:indexable)' unless
      defined? indexable
  end

  subject { indexable }

  it {is_expected.to respond_to(:indexed?)}
  it {is_expected.to respond_to(:index!)}

  it "returns boolean for #indexed?" do
    expect(subject.indexed?).to satisfy {|x| x.is_a?(TrueClass) || x.is_a?(FalseClass)}
  end

  it "returns self on #index!" do
    expect(subject.index!).to eql(subject)
  end
end
