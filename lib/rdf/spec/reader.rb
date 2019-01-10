require 'rdf/spec'
require 'webmock/rspec'

RSpec.shared_examples 'an RDF::Reader' do
  include RDF::Spec::Matchers

  before(:each) do
    raise 'reader must be defined with let(:reader)' unless defined? reader
    raise 'reader_input must be defined with let(:reader_input)' unless defined? reader_input
    raise 'reader_count must be defined with let(:reader_count)' unless defined? reader_count
    # define reader_invalid_input for invalid input
  end
  before(:each) {WebMock.disable_net_connect!}
  after(:each) {WebMock.allow_net_connect!}

  let(:reader_class) { reader.class }
  let(:format_class) { reader_class.format }

  describe ".each" do
    it "yields each reader" do
      reader_class.each do |r|
        expect(r).not_to  be_nil
      end
    end
  end

  describe ".open" do
    it "yields reader given file_name" do
      allow(RDF::Util::File).to receive(:open_file).and_yield(StringIO.new(reader_input))
      format_class.file_extensions.each_pair do |sym, content_type|
        reader_mock = double("reader")
        expect(reader_mock).to receive(:got_here)
        expect(RDF::Reader).to receive(:for).with(file_name: "foo.#{sym}").and_return(reader_class)
        RDF::Reader.open("foo.#{sym}") do |r|
          expect(r).to be_a(reader_class)
          reader_mock.got_here
        end
      end
    end

    it "yields reader given symbol" do
      allow(RDF::Util::File).to receive(:open_file).and_yield(StringIO.new(reader_input))
      sym = format_class.to_sym  # Like RDF::NTriples::Format => :ntriples
      reader_mock = double("reader")
      expect(reader_mock).to receive(:got_here)
      expect(RDF::Reader).to receive(:for).with(sym).and_return(reader_class)
      RDF::Reader.open("foo.#{sym}", format: sym) do |r|
        expect(r).to be_a(reader_class)
        reader_mock.got_here
      end
    end

    it "yields reader given {file_name: file_name}" do
      allow(RDF::Util::File).to receive(:open_file).and_yield(StringIO.new(reader_input))
      format_class.file_extensions.each_pair do |sym, content_type|
        reader_mock = double("reader")
        expect(reader_mock).to receive(:got_here)
        expect(RDF::Reader).to receive(:for).with(file_name: "foo.#{sym}").and_return(reader_class)
        RDF::Reader.open("foo.#{sym}", file_name: "foo.#{sym}") do |r|
          expect(r).to be_a(reader_class)
          reader_mock.got_here
        end
      end
    end

    it "yields reader given {content_type: 'a/b'}" do
      allow(RDF::Util::File).to receive(:open_file).and_yield(StringIO.new(reader_input))
      format_class.content_types.each_pair do |content_type, formats|
        reader_mock = double("reader")
        expect(reader_mock).to receive(:got_here)
        expect(RDF::Reader).to receive(:for).with(content_type: content_type, file_name: "foo").and_return(reader_class)
        RDF::Reader.open("foo", content_type: content_type) do |r|
          expect(r).to be_a(reader_class)
          reader_mock.got_here
        end
      end
    end

    it "yields reader when returned content_type matches" do
      format_class.content_types.each_pair do |content_type, formats|
        uri = "http://example/foo"
        reader_mock = double("reader")
        expect(reader_mock).to receive(:got_here)
        expect(RDF::Reader).to receive(:for).and_return(reader_class)

        WebMock.stub_request(:get, uri).
          to_return(body: "BODY",
                    status: 200,
                    headers: { 'Content-Type' => content_type})

        RDF::Reader.open(uri) do |r|
          expect(r).to be_a(reader_class)
          reader_mock.got_here
        end
      end
    end

    it "sets Accept header from reader" do
      uri = "http://example/foo"
      accept = (format_class.accept_type + %w(*/*;q=0.1)).join(", ")
      reader_mock = double("reader")
      expect(reader_mock).to receive(:got_here)
      WebMock.stub_request(:get, uri).with do |request|
        expect(request.headers['Accept']).to eql accept
      end.to_return(body: "foo")

      reader_class.open(uri) do |r|
        expect(r).to be_a(reader_class)
        reader_mock.got_here
      end
    end

    it "sets Accept header from symbol" do
      uri = "http://example/foo"
      sym = format_class.to_sym  # Like RDF::NTriples::Format => :ntriples
      accept = (format_class.accept_type + %w(*/*;q=0.1)).join(", ")
      reader_mock = double("reader")
      expect(reader_mock).to receive(:got_here)
      WebMock.stub_request(:get, uri).with do |request|
        expect(request.headers['Accept']).to eql accept
      end.to_return(body: "foo")
      expect(RDF::Reader).to receive(:for).with(sym).and_return(reader_class)

      RDF::Reader.open(uri, format: sym) do |r|
        expect(r).to be_a(reader_class)
        reader_mock.got_here
      end
    end
  end

  describe ".format" do
    it "returns a format class if given no format" do
      expect(reader_class.format).not_to be_nil
    end

    it "returns nil if given a format" do
      other_format = reader_class == RDF::NTriples::Reader ? :nquads : :ntriples
      expect(reader_class.format(other_format)).to be_nil
    end
  end

  describe ".new" do
    it "sets @input to StringIO given a string" do
      reader_mock = double("reader")
      expect(reader_mock).to receive(:got_here)
      reader_class.new(reader_input) do |r|
        reader_mock.got_here
        expect(r.instance_variable_get(:@input)).to be_a(StringIO)
      end
    end

    it "sets @input to input given something other than a string" do
      reader_mock = double("reader")
      expect(reader_mock).to receive(:got_here)
      file = StringIO.new(reader_input)
      reader_class.new(file) do |r|
        reader_mock.got_here
        expect(r.instance_variable_get(:@input)).to eq file
      end
    end

    it "validates given validate: true" do
      reader_class.new(reader_input, validate: true) do |r|
        expect(r).to be_valid
      end
    end

    it "invalidates on any logged error if validate: true" do
      logger = RDF::Spec.logger
      reader_class.new(reader_input, validate: true, logger: logger) do |r|
        expect(r).to be_valid
        r.log_error("some error")
        expect(r).not_to be_valid
      end
      expect(logger.to_s).to include("ERROR")
    end

    it "invalidates given invalid input and validate: true" do
      invalid_input = reader_invalid_input rescue "!!invalid input??"
      logger = RDF::Spec.logger
      reader_class.new(invalid_input, validate: true, logger: logger) do |r|
        expect(r).not_to be_valid
        expect(logger.to_s).to include("ERROR")
      end
    end

    it "sets canonicalize given canonicalize: true" do
      reader_mock = double("reader")
      expect(reader_mock).to receive(:got_here)
      reader_class.new(reader_input, canonicalize: true) do |r|
        reader_mock.got_here
        expect(r).to be_canonicalize
      end
    end

    it "sets intern given intern: true" do
      reader_mock = double("reader")
      expect(reader_mock).to receive(:got_here)
      reader_class.new(reader_input, intern: true) do |r|
        reader_mock.got_here
        expect(r).to be_intern
      end
    end

    it "sets prefixes given prefixes: {}" do
      reader_mock = double("reader")
      expect(reader_mock).to receive(:got_here)
      reader_class.new(reader_input, prefixes: {a: "b"}) do |r|
        reader_mock.got_here
        expect(r.prefixes).to include({a: "b"})
      end
    end
  end

  describe "#prefixes=" do
    it "sets prefixes from hash" do
      reader.prefixes = {a: "b"}
      expect(reader.prefixes).to eq({a: "b"})
    end
  end

  describe "#prefix" do
    {
      nil     => "nil",
      :a      => "b",
      "foo"   => "bar",
    }.each_pair do |pfx, uri|
      it "sets prefix(#{pfx}) to #{uri}" do
        expect(reader.prefix(pfx, uri)).to eq uri
        expect(reader.prefix(pfx)).to eq uri
      end
    end
  end

  context RDF::Enumerable do
    it "#count" do
      reader_class.new(reader_input) {|r| expect(r.count).to eq reader_count}
    end
    it "#empty?" do
      reader_class.new(reader_input) {|r| expect(r).not_to be_empty}
    end

    it "#statements" do
      reader_class.new(reader_input) {|r| expect(r.statements.count).to eq reader_count}
    end
    it "#has_statement?" do
      reader_class.new(reader_input) {|r| expect(r).to respond_to(:has_statement?)}
    end
    it "#each_statement" do
      reader_class.new(reader_input) {|r| expect(r.each_statement.count).to eq reader_count}
    end
    it "#enum_statement" do
      reader_class.new(reader_input) {|r| expect(r.enum_statement.count).to eq reader_count}
    end

    it "#triples" do
      reader_class.new(reader_input) {|r| expect(r.triples.count).to eq reader_count}
    end
    it "#each_triple" do
      reader_class.new(reader_input) {|r| expect(r.each_triple.count).to eq reader_count}
    end
    it "#enum_triple" do
      reader_class.new(reader_input) {|r| expect(r.enum_triple.count).to eq reader_count}
    end

    it "#quads" do
      reader_class.new(reader_input) {|r| expect(r.quads.count).to eq reader_count}
    end
    it "#each_quad" do
      reader_class.new(reader_input) {|r| expect(r.each_quad.count).to eq reader_count}
    end
    it "#enum_quad" do
      reader_class.new(reader_input) {|r| expect(r.enum_quad.count).to eq reader_count}
    end

  end
end
