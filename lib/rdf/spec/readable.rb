require 'rdf/spec'

RSpec.shared_examples 'an RDF::Readable' do
  include RDF::Spec::Matchers

  before do
    raise 'readable must be defined in with let(:readable)' unless
      defined? readable
  end

  describe RDF::Readable do
    subject { readable }
    it { is_expected.to respond_to :readable? }
    it { is_expected.to respond_to :readable? }
    its(:readable?) { is_expected.to eq subject.readable? }
  end
end
