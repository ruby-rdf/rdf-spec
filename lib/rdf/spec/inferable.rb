require 'rdf/spec'

RSpec.shared_examples 'an RDF::Inferable' do
  include RDF::Spec::Matchers

  it "should implement specs" #TODO
end

##
# @deprecated use `it_behaves_like "an RDF::Inferable"` instead
module RDF_Inferable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  warn "[DEPRECATION] `RDF_Inferable` is deprecated. "\
       "Please use `it_behaves_like 'an RDF::Inferable'`"

  describe 'examples for' do
    include_examples 'an RDF::Inferable'
  end
end
