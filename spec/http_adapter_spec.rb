require File.join(File.dirname(__FILE__), 'spec_helper')
require 'webmock/rspec'
require 'rdf/ntriples'
require 'rdf/spec/http_adapter'

context "HTTP Adapters" do
  before(:each) {WebMock.disable_net_connect!}
  after(:each) {WebMock.allow_net_connect!}

  context "using Net::HTTP" do
    it_behaves_like 'an RDF::HttpAdapter' do
      let(:http_adapter) { RDF::Util::File::NetHttpAdapter }
    end
  end
end
