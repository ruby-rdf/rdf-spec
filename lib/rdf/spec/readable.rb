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

##
# @deprecated use `it_behaves_like "an RDF::Readable"` instead
module RDF_Readable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  def self.included(mod)
    warn "[DEPRECATION] `RDF_Readable` is deprecated. "\
         "Please use `it_behaves_like 'an RDF::Readable'`"
  end

  describe 'examples for' do
    include_examples 'an RDF::Readable' do
      let(:readable) { @readable }

      before do
        raise '@readable must be defined' unless defined?(readable)
      end
    end
  end
end
