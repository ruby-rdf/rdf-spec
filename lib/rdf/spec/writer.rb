require 'rdf/spec'
require 'fileutils'
require 'tmpdir'

RSpec.shared_examples 'an RDF::Writer' do
  include RDF::Spec::Matchers

  before(:each) do
    raise 'writer must be defined with let(:writer)' unless
      defined? writer
  end
  let(:writer_class) { writer.class }
  let(:reader_class) { writer_class.format.reader}
  let(:format_class) { writer_class.format }

  let(:graph) do
    @rdf_writer_iv_graph ||= begin
      n1 = RDF::Node("a")
      n2 = RDF::Node("a")
      p = RDF::URI("http://example/pred")
      s1 = RDF::Statement(n1, p, n1)
      s2 = RDF::Statement(n2, p, n2)
      s3 = RDF::Statement(n1, p, n2)
      s4 = RDF::Statement(n2, p, n1)
      RDF::Graph.new.insert(s1, s2, s3, s4)
    end
  end

  let(:serialized) do
    @rdf_writer_iv_serialized ||= begin
      writer_class.buffer do |w|
        w << graph
      end
    end
  end

  describe ".each" do
    it "yields each writer" do
      writer_class.each do |r|
        expect(r).not_to be_nil
      end
    end
  end

  describe ".buffer" do
    it "calls .new with buffer and other arguments" do
      expect(writer_class).to receive(:new)
      writer_class.buffer do |r|
        expect(r).to be_a(writer_class)
      end
    end

    it "should serialize different BNodes sharing a common identifier to using different BNode ids" do
      if reader_class
        expect(serialized).not_to be_empty
        graph2 = RDF::Graph.new do |g|
          g << reader_class.new(serialized)
        end
        expect(graph2.count).to eql 4
      end
    end

    it "returns a string" do
      expect(serialized).to be_a(String)
    end

    it "should use encoding defined for format by default" do
      writer_class.new do |w|
        expect(serialized.encoding).to eql w.encoding
      end
    end

    it "should use provided encoding if specified" do
      str = writer_class.buffer(encoding: Encoding::ASCII_8BIT) do |w|
        w << graph
      end

      expect(str.encoding).to eql Encoding::ASCII_8BIT
    end
  end

  describe ".open" do
    before(:each) do
      allow(RDF::Util::File).to receive(:open_file).and_yield(StringIO.new("foo"))
      @rdf_writer_iv_dir = Dir.mktmpdir
      @rdf_writer_iv_basename = File.join(@rdf_writer_iv_dir, "foo")
    end

    after(:each) do
      FileUtils.rm_rf(@rdf_writer_iv_dir)
    end

    it "yields writer given file_name" do
      format_class.file_extensions.each_pair do |sym, content_type|
        writer_mock = double("writer")
        expect(writer_mock).to receive(:got_here)
        expect(writer_class).to receive(:for).with({file_name: "#{@rdf_writer_iv_basename}.#{sym}"}).and_return(writer_class)
        writer_class.open("#{@rdf_writer_iv_basename}.#{sym}") do |r|
          expect(r).to be_a(RDF::Writer)
          writer_mock.got_here
        end
      end
    end

    it "yields writer given symbol" do
      sym = format_class.to_sym  # Like RDF::NTriples::Format => :ntriples
      writer_mock = double("writer")
      expect(writer_mock).to receive(:got_here)
      expect(writer_class).to receive(:for).with(sym).and_return(writer_class)
      writer_class.open("#{@rdf_writer_iv_basename}.#{sym}", format: sym) do |r|
        expect(r).to be_a(RDF::Writer)
        writer_mock.got_here
      end
    end

    it "yields writer given {file_name: file_name}" do
      format_class.file_extensions.each_pair do |sym, content_type|
        writer_mock = double("writer")
        expect(writer_mock).to receive(:got_here)
        expect(writer_class).to receive(:for).with({file_name: "#{@rdf_writer_iv_basename}.#{sym}"}).and_return(writer_class)
        writer_class.open("#{@rdf_writer_iv_basename}.#{sym}", file_name: "#{@rdf_writer_iv_basename}.#{sym}") do |r|
          expect(r).to be_a(RDF::Writer)
          writer_mock.got_here
        end
      end
    end

    it "yields writer given {content_type: 'a/b'}" do
      format_class.content_types.each_pair do |content_type, formats|
        writer_mock = double("writer")
        expect(writer_mock).to receive(:got_here)
        expect(writer_class).to receive(:for).with({content_type: content_type, file_name: @rdf_writer_iv_basename}).and_return(writer_class)
        writer_class.open(@rdf_writer_iv_basename, content_type: content_type) do |r|
          expect(r).to be_a(RDF::Writer)
          writer_mock.got_here
        end
      end
    end
  end

  describe ".format" do
    it "returns itself even if given explicit format" do
      other_format = writer_class == RDF::NTriples::Writer ? :nquads : :ntriples
      expect(writer_class.for(other_format)).to eq writer_class
    end
  end

  describe ".new" do
    it "sets @output to $stdout by default" do
      writer_mock = double("writer")
      expect(writer_mock).to receive(:got_here)
      save, $stdout = $stdout, StringIO.new

      writer_class.new do |r|
        writer_mock.got_here
        expect(r.instance_variable_get(:@output)).to eq $stdout
      end
      $stdout = save
    end

    it "sets @output to file given something other than a string" do
      writer_mock = double("writer")
      expect(writer_mock).to receive(:got_here)
      file = StringIO.new
      writer_class.new(file) do |r|
        writer_mock.got_here
        expect(r.instance_variable_get(:@output)).to eq file
      end
    end

    it "sets prefixes given prefixes: {}" do
      writer_mock = double("writer")
      expect(writer_mock).to receive(:got_here)
      writer_class.new(StringIO.new, prefixes: {a: "b"}) do |r|
        writer_mock.got_here
        expect(r.prefixes).to eq({a: "b"})
      end
    end

    it "raises WriterError if writing an invalid statement" do
      file = StringIO.new
      expect do
        writer_class.new(file, logger: false) do |w|
          w << RDF::Statement(
                 RDF::URI("https://rubygems.org/gems/rdf"),
                 RDF::URI("http://purl.org/dc/terms/creator"),
                 nil)
        end
      end.to raise_error(RDF::WriterError)
    end

    it "raises WriterError on any logged error" do
      file = StringIO.new
      logger = RDF::Spec.logger
      expect do
        writer_class.new(file, logger: logger) do |w|
          w.log_error("some error")
        end
      end.to raise_error(RDF::WriterError)
      expect(logger.to_s).to include("ERROR")
    end

    # FIXME: RSpec seems to blead over __write_epilogue_without_any_instance__ to other specs
    #it "calls #write_prologue" do
    #  writer_mock = double("writer")
    #  expect(writer_mock).to receive(:got_here)
    #  expect_any_instance_of(writer_class).to receive(:write_epilogue)
    #  writer_class.new(StringIO.new) do |r|
    #    writer_mock.got_here
    #  end
    #end
    #
    #it "calls #write_epilogue" do
    #  writer_mock = double("writer")
    #  expect(writer_mock).to receive(:got_here)
    #  expect_any_instance_of(writer_class).to receive(:write_epilogue)
    #  writer_class.new(StringIO.new) do |r|
    #    writer_mock.got_here
    #  end
    #end
  end

  describe "#prefixes=" do
    it "sets prefixes from hash" do
      writer.prefixes = {a: "b"}
      expect(writer.prefixes).to eq({a: "b"})
    end
  end

  describe "#prefix" do
    {
      nil     => "nil",
      :a      => "b",
      "foo"   => "bar",
    }.each_pair do |pfx, uri|
      it "sets prefix(#{pfx}) to #{uri}" do
        expect(writer.prefix(pfx, uri)).to eq uri
        expect(writer.prefix(pfx)).to eq uri
      end
    end
  end
end
