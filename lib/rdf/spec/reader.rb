require 'rdf/spec'

share_as :RDF_Reader do
  include RDF::Spec::Matchers

  before(:each) do
    raise '+@reader+ must be defined in a before(:each) block' unless instance_variable_get('@reader')
    @reader_class = @reader.class
  end

  describe ".each" do
    it "yields each reader" do
      @reader_class.each do |r|
        r.superclass.should == RDF::Reader
      end
    end
  end

  describe ".open" do
    before(:each) do
      RDF::Util::File.stub!(:open_file).and_yield(StringIO.new("foo"))
    end

    it "yields reader given file_name" do
      @reader_class.format.each do |f|
        f.file_extensions.each_pair do |sym, content_type|
          reader_mock = mock("reader")
          reader_mock.should_receive(:got_here)
          @reader_class.should_receive(:for).with(:file_name => "foo.#{sym}").and_return(@reader_class)
          @reader_class.open("foo.#{sym}") do |r|
            r.should be_a(RDF::Reader)
            reader_mock.got_here
          end
        end
      end
    end

    it "yields reader given symbol" do
      @reader_class.format.each do |f|
        sym = f.name.to_s.split('::')[-2].downcase.to_sym  # Like RDF::NTriples::Format => :ntriples
        reader_mock = mock("reader")
        reader_mock.should_receive(:got_here)
        @reader_class.should_receive(:for).with(sym).and_return(@reader_class)
        @reader_class.open("foo.#{sym}", :format => sym) do |r|
          r.should be_a(RDF::Reader)
          reader_mock.got_here
        end
      end
    end

    it "yields reader given {:file_name => file_name}" do
      @reader_class.format.each do |f|
        f.file_extensions.each_pair do |sym, content_type|
          reader_mock = mock("reader")
          reader_mock.should_receive(:got_here)
          @reader_class.should_receive(:for).with(:file_name => "foo.#{sym}").and_return(@reader_class)
          @reader_class.open("foo.#{sym}", :file_name => "foo.#{sym}") do |r|
            r.should be_a(RDF::Reader)
            reader_mock.got_here
          end
        end
      end
    end

    it "yields reader given {:content_type => 'a/b'}" do
      @reader_class.format.each do |f|
        f.content_types.each_pair do |content_type, formats|
          reader_mock = mock("reader")
          reader_mock.should_receive(:got_here)
          @reader_class.should_receive(:for).with(:content_type => content_type, :file_name => "foo").and_return(@reader_class)
          @reader_class.open("foo", :content_type => content_type) do |r|
            r.should be_a(RDF::Reader)
            reader_mock.got_here
          end
        end
      end
    end
  end
end
