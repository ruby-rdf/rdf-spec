# -*- encoding: utf-8 -*-
require 'rdf/spec'
require 'webmock/rspec'

RSpec.shared_examples 'an RDF::HttpAdapter' do
  let(:doap_file) {File.expand_path("../../../../etc/doap.nt", __FILE__)}

  before(:each) do
    raise '`http_adapter` must be defined with `let(:http_adapter`' unless
      defined? http_adapter
  end

  let(:uri) {"http://ruby-rdf.github.com/rdf/etc/doap.nt"}

  let(:opened) {double("opened")}
  before(:each) do
    expect(opened).to receive(:opened)
  end

  context "using a HTTP client" do
    before { RDF::Util::File.http_adapter = http_adapter }
    after { RDF::Util::File.http_adapter = nil }

    it "returns an http URL" do
      WebMock.stub_request(:get, uri).
        to_return(body: File.read(doap_file),
                  status: 200,
                  headers: { 'Content-Type' => RDF::NTriples::Format.content_type.first})
      f = RDF::Util::File.open_file(uri)
      expect(f).to respond_to(:read)
      expect(f.content_type).to eq RDF::NTriples::Format.content_type.first
      expect(f.code).to eq 200
      opened.opened
    end

    it "adds Accept header using defined readers" do
      content_types = RDF::Reader.map {|r| r.format.content_type}.flatten.uniq
      WebMock.stub_request(:get, uri).with do |request|
        expect(request.headers['Accept']).to include(*content_types)
      end.to_return(body: "foo")
      RDF::Util::File.open_file(uri) do |f|
        opened.opened
      end
    end

    it "adds Accept header with low-priority */*" do
      WebMock.stub_request(:get, uri).with do |request|
        expect(request.headers['Accept']).to include('*/*;q=0.1')
      end.to_return(body: "foo")
      RDF::Util::File.open_file(uri) do |f|
        opened.opened
      end
    end

    it "used provided Accept header" do
      WebMock.stub_request(:get, uri).with do |request|
        expect(request.headers["Accept"]).to include('a/b')
      end.to_return(body: "foo")
      RDF::Util::File.open_file(uri, headers: {"Accept" => "a/b"}) do |f|
        opened.opened
      end
    end

    it "sets content_type and encoding to utf-8 if absent" do
      WebMock.stub_request(:get, uri).to_return(body: "foo", headers: {"Content-Type" => "text/turtle"})
      RDF::Util::File.open_file(uri) do |f|
        expect(f.content_type).to eq "text/turtle"
        expect(f.charset).to eq "utf-8"
        expect(f.external_encoding.to_s.downcase).to eq "utf-8"
        opened.opened
      end
    end

    it "sets content_type and encoding if provided and UTF" do
      WebMock.stub_request(:get, uri).to_return(body: "foo".force_encoding("UTF-16"), headers: {"Content-Type" => "text/turtle ; charset=UTF-16"})
      RDF::Util::File.open_file(uri) do |f|
        expect(f.content_type).to eq "text/turtle"
        expect(f.charset).to eq "utf-16"
        expect(f.external_encoding.to_s.downcase).to eq "utf-16"
        opened.opened
      end
    end

    it "sets content_type and encoding to UTF-8 if provided and not UTF" do
      WebMock.stub_request(:get, uri).to_return(body: "foo".force_encoding("ISO-8859-4"), headers: {"Content-Type" => "text/turtle ; charset=ISO-8859-4"})
      RDF::Util::File.open_file(uri) do |f|
        expect(f.content_type).to eq "text/turtle"
        expect(f.charset).to eq "iso-8859-4"
        expect(f.external_encoding.to_s.downcase).to eq "utf-8"
        opened.opened
      end
    end

    it "sets last_modified if provided" do
      WebMock.stub_request(:get, uri).to_return(body: "foo", headers: {"Last-Modified" => "Thu, 24 Oct 2013 23:46:56 GMT"})
      RDF::Util::File.open_file(uri) do |f|
        expect(f.last_modified).to eq DateTime.parse("Thu, 24 Oct 2013 23:46:56 GMT")
        opened.opened
      end
    end

    it "sets etag if provided" do
      WebMock.stub_request(:get, uri).to_return(body: "foo", headers: {"ETag" => "abc123"})
      RDF::Util::File.open_file(uri) do |f|
        expect(f.etag).to eq "abc123"
        opened.opened
      end
    end

    it "sets arbitrary header" do
      WebMock.stub_request(:get, uri).to_return(body: "foo", headers: {"Foo" => "Bar"})
      RDF::Util::File.open_file(uri) do |f|
        expect(f.headers[:foo]).to eq "Bar"
        opened.opened
      end
    end

    context "redirects" do
      it "sets base_uri to resource" do
        WebMock.stub_request(:get, uri).to_return(body: "foo")
        RDF::Util::File.open_file(uri) do |f|
          expect(f.base_uri).to eq uri
          opened.opened
        end
      end

      it "sets base_uri to location if present" do
        WebMock.stub_request(:get, uri).to_return(body: "foo", headers: {"Location" => "http://example/"})
        RDF::Util::File.open_file(uri) do |f|
          expect(f.base_uri).to eq "http://example/"
          opened.opened
        end
      end

      it "follows 301 and uses new location" do
        WebMock.stub_request(:get, uri).to_return({status: 301, headers: {"Location" => "http://example/"}})
        WebMock.stub_request(:get, "http://example/").to_return({body: "foo"})
        RDF::Util::File.open_file(uri) do |f|
          expect(f.base_uri).to eq "http://example/"
          expect(f.read).to eq "foo"
          opened.opened
        end
      end

      it "follows 302 and uses new location" do
        WebMock.stub_request(:get, uri).to_return({status: 302, headers: {"Location" => "http://example/"}})
        WebMock.stub_request(:get, "http://example/").to_return({body: "foo"})
        RDF::Util::File.open_file(uri) do |f|
          expect(f.base_uri).to eq "http://example/"
          expect(f.read).to eq "foo"
          opened.opened
        end
      end

      it "follows 303 and uses new location" do
        WebMock.stub_request(:get, uri).to_return({status: 303, headers: {"Location" => "http://example/"}})
        WebMock.stub_request(:get, "http://example/").to_return({body: "foo"})
        RDF::Util::File.open_file(uri) do |f|
          expect(f.base_uri).to eq "http://example/"
          expect(f.read).to eq "foo"
          opened.opened
        end
      end

      it "follows 307 and uses new location" do
        WebMock.stub_request(:get, uri).to_return({status: 307, headers: {"Location" => "http://example/"}})
        WebMock.stub_request(:get, "http://example/").to_return({body: "foo"})
        RDF::Util::File.open_file(uri) do |f|
          expect(f.base_uri).to eq "http://example/"
          expect(f.read).to eq "foo"
          opened.opened
        end
      end

      it "follows 302 to a relative location" do
        rel = "../etc/doap.ttl"

        WebMock.stub_request(:get, uri).to_return({status: 302, headers: {"Location" => rel}})
        WebMock.stub_request(:get, RDF::URI(uri).join(rel).to_s).to_return({body: "foo"})
        RDF::Util::File.open_file(uri) do |f|
          expect(f.base_uri).to eq RDF::URI(uri).join(rel).to_s
          expect(f.read).to eq "foo"
          opened.opened
        end
      end

      it "raises an IOError for HTTP 4xx status codes" do
        opened.opened

        WebMock.stub_request(:get, uri).to_return({status: 404})
        expect do
          RDF::Util::File.open_file(uri)
        end.to raise_exception IOError
      end

      it "raises an IOError for HTTP 5xx status codes" do
        opened.opened

        WebMock.stub_request(:get, uri).to_return({status: 500})
        expect do
          RDF::Util::File.open_file(uri)
        end.to raise_exception IOError
      end
    end

    context "proxy" do
      it "requests through proxy" do
        WebMock.stub_request(:get, uri).
          to_return(body: File.read(doap_file),
                    status: 200,
                    headers: { 'Content-Type' => RDF::NTriples::Format.content_type.first})
        RDF::Util::File.open_file(uri, proxy: "http://proxy.example.com") do |f|
          opened.opened
        end
        expect(WebMock).to have_requested(:get, uri)
      end
    end

    context "https" do
      let(:uri) {"https://some/secure/uri"}

      it "returns an https URL" do
        WebMock.stub_request(:get, uri).
          to_return(body: "foo",
                    status: 200,
                    headers: { 'Content-Type' => RDF::NTriples::Format.content_type.first})
        f = RDF::Util::File.open_file(uri)
        expect(f).to respond_to(:read)
        expect(f.content_type).to eq RDF::NTriples::Format.content_type.first
        expect(f.code).to eq 200
        opened.opened
      end
    end

    context "links" do
      {
        "no links" => [
          '',
          []
        ],
        "rel" => [
          '<http://example.com/foo>; rel="self"',
          [["http://example.com/foo", [%w(rel self)]]]
        ],
        "rel-meta" => [
          '<http://example.com/>; rel="up"; meta="bar"',
          [["http://example.com/", [%w(rel up), %w(meta bar)]]]
        ],
        'bar' => [
          '<http://example.com/>',
          [["http://example.com/", []]]
        ],
        'two links' => [
          '<http://example.com/foo>; rel="self", <http://example.com/>; rel="up"; meta="bar"',
          [
            ["http://example.com/foo", [%w(rel self)]],
            ["http://example.com/", [%w(rel up), %w(meta bar)]]
          ]
        ]
      }.each do |name, (input, output)|
        it name do
          WebMock.stub_request(:get, uri).
            to_return(body: "content",
                      status: 200,
                      headers: {
                        'Content-Type' => RDF::NTriples::Format.content_type.first,
                        'Link' => input
                      })
          RDF::Util::File.open_file(uri) do |f|
            expect(f).to respond_to(:read)
            expect(f.links.to_a).to eq output
            opened.opened
          end
        end
      end

      it "can find a link using #find_link" do
        WebMock.stub_request(:get, uri).
          to_return(body: "content",
                    status: 200,
                    headers: {
                      'Content-Type' => RDF::NTriples::Format.content_type.first,
                      'Link' => '<http://example.com/foo> rel="describedby" type="application/n-triples"'
                    })
        RDF::Util::File.open_file(uri) do |f|
          expect(f.links.find_link(['rel', 'describedby']).to_a).to eq ['http://example.com/foo', [%w(rel describedby)]]
          opened.opened
        end
      end
    end
  end

end

##
# @deprecated use `it_behaves_like "an RDF::HttpAdapter"` instead
module RDF_HttpAdapter
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  def self.included(mod)
    warn "[DEPRECATION] `RDF_HttpAdapter` is deprecated. "\
         "Please use `it_behaves_like 'an RDF::HttpAdapter'`"
  end

  describe 'examples for' do
    include_examples 'an RDF::HttpAdapter' do
      let(:http_adapter) { @http_adapter }

      before do
        raise '@http_adapter must be defined' unless defined?(http_adapter)
      end
    end
  end
end
