require 'rdf/spec'

RSpec.shared_examples 'an RDF::Inferable' do
  include RDF::Spec::Matchers

  it "is_expected.to implement specs" #TODO
end

##
# @deprecated use `it_behaves_like "an RDF::Inferable"` instead
# :nocov:
module RDF_Inferable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  def self.included(mod)
    warn "[DEPRECATION] `RDF_Inferable` is deprecated. "\
         "Please use `it_behaves_like 'an RDF::Inferable'`"
  end

  describe 'examples for' do
    include_examples 'an RDF::Inferable'
  end
end
