require 'rdf/spec'
require 'fileutils'

share_as :RDF_Writer do
  include RDF::Spec::Matchers

  before(:each) do
    raise '+@writer+ must be defined in a before(:each) block' unless instance_variable_get('@writer')
    @writer_class = @writer.class
  end

  describe ".each" do
    it "yields each writer" do
      @writer_class.each do |r|
        r.should_not be_nil
      end
    end
  end
  
  describe ".buffer" do
    it "calls .new with buffer and other arguments" do
      @writer_class.should_receive(:new)
      @writer_class.buffer do |r|
        r.should be_a(@writer_class)
      end
    end
  end

  describe ".open" do
    before(:each) do
      RDF::Util::File.stub!(:open_file).and_yield(StringIO.new("foo"))
      @dir = File.join(File.expand_path(File.dirname(__FILE__)), "tmp")
      Dir.mkdir(@dir)
      @basename = File.join(@dir, "foo")
    end
    
    after(:each) do
      FileUtils.rm_rf(File.join(File.expand_path(File.dirname(__FILE__)), "tmp"))
    end

    it "yields writer given file_name" do
      @writer_class.format.each do |f|
        f.file_extensions.each_pair do |sym, content_type|
          writer_mock = mock("writer")
          writer_mock.should_receive(:got_here)
          @writer_class.should_receive(:for).with(:file_name => "#{@basename}.#{sym}").and_return(@writer_class)
          @writer_class.open("#{@basename}.#{sym}") do |r|
            r.should be_a(RDF::Writer)
            writer_mock.got_here
          end
        end
      end
    end

    it "yields writer given symbol" do
      @writer_class.format.each do |f|
        sym = f.name.to_s.split('::')[-2].downcase.to_sym  # Like RDF::NTriples::Format => :ntriples
        writer_mock = mock("writer")
        writer_mock.should_receive(:got_here)
        @writer_class.should_receive(:for).with(sym).and_return(@writer_class)
        @writer_class.open("#{@basename}.#{sym}", :format => sym) do |r|
          r.should be_a(RDF::Writer)
          writer_mock.got_here
        end
      end
    end

    it "yields writer given {:file_name => file_name}" do
      @writer_class.format.each do |f|
        f.file_extensions.each_pair do |sym, content_type|
          writer_mock = mock("writer")
          writer_mock.should_receive(:got_here)
          @writer_class.should_receive(:for).with(:file_name => "#{@basename}.#{sym}").and_return(@writer_class)
          @writer_class.open("#{@basename}.#{sym}", :file_name => "#{@basename}.#{sym}") do |r|
            r.should be_a(RDF::Writer)
            writer_mock.got_here
          end
        end
      end
    end

    it "yields writer given {:content_type => 'a/b'}" do
      @writer_class.format.each do |f|
        f.content_types.each_pair do |content_type, formats|
          writer_mock = mock("writer")
          writer_mock.should_receive(:got_here)
          @writer_class.should_receive(:for).with(:content_type => content_type, :file_name => @basename).and_return(@writer_class)
          @writer_class.open(@basename, :content_type => content_type) do |r|
            r.should be_a(RDF::Writer)
            writer_mock.got_here
          end
        end
      end
    end
  end

  describe ".format" do
    it "returns itself even if given explicit format" do
      other_format = @writer_class == RDF::NTriples::Writer ? :nquads : :ntriples
      @writer_class.for(other_format).should == @writer_class
    end
  end

  describe ".new" do
    it "sets @output to $stdout by default" do
      writer_mock = mock("writer")
      writer_mock.should_receive(:got_here)
      save, $stdout = $stdout, StringIO.new

      @writer_class.new do |r|
        writer_mock.got_here
        r.instance_variable_get(:@output).should == $stdout
      end
      $stdout = save
    end
    
    it "sets @output to file given something other than a string" do
      writer_mock = mock("writer")
      writer_mock.should_receive(:got_here)
      file = mock("file")
      file.should_receive(:write).any_number_of_times
      @writer_class.new(file) do |r|
        writer_mock.got_here
        r.instance_variable_get(:@output).should == file
      end
    end
    
    it "sets prefixes given :prefixes => {}" do
      writer_mock = mock("writer")
      writer_mock.should_receive(:got_here)
      @writer_class.new(StringIO.new, :prefixes => {:a => "b"}) do |r|
        writer_mock.got_here
        r.prefixes.should == {:a => "b"}
      end
    end
    
    #it "calls #write_prologue" do
    #  writer_mock = mock("writer")
    #  writer_mock.should_receive(:got_here)
    #  @writer_class.any_instance.should_receive(:write_prologue)
    #  @writer_class.new(StringIO.new) do |r|
    #    writer_mock.got_here
    #  end
    #end
    #
    #it "calls #write_epilogue" do
    #  writer_mock = mock("writer")
    #  writer_mock.should_receive(:got_here)
    #  @writer_class.any_instance.should_receive(:write_epilogue)
    #  @writer_class.new(StringIO.new) do |r|
    #    writer_mock.got_here
    #  end
    #end
  end
  
  describe "#prefixes=" do
    it "sets prefixes from hash" do
      @writer.prefixes = {:a => "b"}
      @writer.prefixes.should == {:a => "b"}
    end
  end
  
  describe "#prefix" do
    {
      nil     => "nil",
      :a      => "b",
      "foo"   => "bar",
    }.each_pair do |pfx, uri|
      it "sets prefix(#{pfx}) to #{uri}" do
        @writer.prefix(pfx, uri).should == uri
        @writer.prefix(pfx).should == uri
      end
    end
  end
end
