require 'rdf/spec'

module RDF_Reader
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before(:each) do
    raise '+@reader+ must be defined in a before(:each) block' unless instance_variable_get('@reader')
    @reader_class = @reader.class
  end

  describe RDF::Reader do
    describe ".each" do
      it "yields each reader" do
        @reader_class.each do |r|
          expect(r).not_to  be_nil
        end
      end
    end

    describe ".open" do
      before(:each) do
        RDF::Util::File.stub(:open_file).and_yield(StringIO.new("foo"))
      end

      it "yields reader given file_name" do
        @reader_class.format.each do |f|
          RDF::Util::File.stub(:open_file).and_yield(StringIO.new("foo"))
          f.file_extensions.each_pair do |sym, content_type|
            reader_mock = double("reader")
            expect(reader_mock).to receive(:got_here)
            expect(@reader_class).to receive(:for).with(:file_name => "foo.#{sym}").and_return(@reader_class)
            @reader_class.open("foo.#{sym}") do |r|
              expect(r).to be_a(RDF::Reader)
              reader_mock.got_here
            end
          end
        end
      end

      it "yields reader given symbol" do
        @reader_class.format.each do |f|
          RDF::Util::File.stub(:open_file).and_yield(StringIO.new("foo"))
          sym = f.to_sym  # Like RDF::NTriples::Format => :ntriples
          reader_mock = double("reader")
          expect(reader_mock).to receive(:got_here)
          expect(@reader_class).to receive(:for).with(sym).and_return(@reader_class)
          @reader_class.open("foo.#{sym}", :format => sym) do |r|
            expect(r).to be_a(RDF::Reader)
            reader_mock.got_here
          end
        end
      end

      it "yields reader given {:file_name => file_name}" do
        @reader_class.format.each do |f|
          RDF::Util::File.stub(:open_file).and_yield(StringIO.new("foo"))
          f.file_extensions.each_pair do |sym, content_type|
            reader_mock = double("reader")
            expect(reader_mock).to receive(:got_here)
            expect(@reader_class).to receive(:for).with(:file_name => "foo.#{sym}").and_return(@reader_class)
            @reader_class.open("foo.#{sym}", :file_name => "foo.#{sym}") do |r|
              expect(r).to be_a(RDF::Reader)
              reader_mock.got_here
            end
          end
        end
      end

      it "yields reader given {:content_type => 'a/b'}" do
        @reader_class.format.each do |f|
          RDF::Util::File.stub(:open_file).and_yield(StringIO.new("foo"))
          f.content_types.each_pair do |content_type, formats|
            reader_mock = double("reader")
            expect(reader_mock).to receive(:got_here)
            expect(@reader_class).to receive(:for).with(:content_type => content_type, :file_name => "foo").and_return(@reader_class)
            @reader_class.open("foo", :content_type => content_type) do |r|
              expect(r).to be_a(RDF::Reader)
              reader_mock.got_here
            end
          end
        end
      end
    end

    describe ".format" do
      it "returns itself even if given explicit format" do
        other_format = @reader_class == RDF::NTriples::Reader ? :nquads : :ntriples
        expect(@reader_class.for(other_format)).to eq @reader_class
      end
    end

    describe ".new" do
      it "sets @input to StringIO given a string" do
        reader_mock = double("reader")
        expect(reader_mock).to receive(:got_here)
        @reader_class.new("string") do |r|
          reader_mock.got_here
          expect(r.instance_variable_get(:@input)).to be_a(StringIO)
        end
      end
    
      it "sets @input to input given something other than a string" do
        reader_mock = double("reader")
        expect(reader_mock).to receive(:got_here)
        file = StringIO.new("")
        @reader_class.new(file) do |r|
          reader_mock.got_here
          expect(r.instance_variable_get(:@input)).to eq file
        end
      end
    
      it "sets validate given :validate => true" do
        # Either set validate, or through error, due to invalid input (null input may be invalid)
        begin
          @reader_class.new("string", :validate => true) do |r|
            expect(r).to be_valid
          end
        rescue
          expect($!).to be_a(RDF::ReaderError)  # An error is acceptable
        end
      end
    
      it "sets canonicalize given :canonicalize => true" do
        reader_mock = double("reader")
        expect(reader_mock).to receive(:got_here)
        @reader_class.new("string", :canonicalize => true) do |r|
          reader_mock.got_here
          expect(r).to be_canonicalize
        end
      end
    
      it "sets intern given :intern => true" do
        reader_mock = double("reader")
        expect(reader_mock).to receive(:got_here)
        @reader_class.new("string", :intern => true) do |r|
          reader_mock.got_here
          expect(r).to be_intern
        end
      end
    
      it "sets prefixes given :prefixes => {}" do
        reader_mock = double("reader")
        expect(reader_mock).to receive(:got_here)
        @reader_class.new("string", :prefixes => {:a => "b"}) do |r|
          reader_mock.got_here
          expect(r.prefixes).to eq({:a => "b"})
        end
      end
    end
  
    describe "#prefixes=" do
      it "sets prefixes from hash" do
        @reader.prefixes = {:a => "b"}
        expect(@reader.prefixes).to eq({:a => "b"})
      end
    end
  
    describe "#prefix" do
      {
        nil     => "nil",
        :a      => "b",
        "foo"   => "bar",
      }.each_pair do |pfx, uri|
        it "sets prefix(#{pfx}) to #{uri}" do
          expect(@reader.prefix(pfx, uri)).to eq uri
          expect(@reader.prefix(pfx)).to eq uri
        end
      end
    end
  end
end
