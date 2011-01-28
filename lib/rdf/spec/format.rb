require 'rdf/spec'

share_as :RDF_Format do
  include RDF::Spec::Matchers

  before(:each) do
    raise '+@format_class+ must be defined in a before(:each) block' unless instance_variable_get('@format_class')
  end

  describe ".each" do
    it "yields each format" do
      @format_class.each do |f|
        f.superclass.should == RDF::Format
      end
    end
  end

  describe ".for" do
    it "detects format using file_name" do
      @format_class.each do |f|
        f.file_extensions.each_pair do |sym, content_type|
          RDF::Format.for("foo.#{sym}").should == f
        end
      end
    end

    it "detects format using symbol" do
      @format_class.each do |f|
        sym = f.name.to_s.split('::')[-2].downcase.to_sym  # Like RDF::NTriples::Format => :ntriples
        RDF::Format.for(sym).should == f
      end
    end

    it "detects format using {:file_name => file_name}" do
      @format_class.each do |f|
        f.file_extensions.each_pair do |sym, content_type|
          RDF::Format.for(:file_name => "foo.#{sym}").should == f
        end
      end
    end

    it "detects format using {:file_extension => ext}" do
      @format_class.each do |f|
        f.file_extensions.each_pair do |sym, content_type|
          RDF::Format.for(:file_extension => sym).should == f
        end
      end
    end

    it "detects format using {:content_type => 'a/b'}" do
      @format_class.each do |f|
        f.content_types.each_pair do |content_type, formats|
          format = RDF::Format.for(:content_type => content_type)
          formats.first.should include(format)
          formats.first.should include(f)
        end
      end
    end
  end
  
  describe ".reader" do
    it "returns a reader" do
      @format_class.each do |f|
        f.reader.superclass.should == RDF::Reader
      end
    end
  end
  
  describe ".writer" do
    it "returns a writer" do
      @format_class.each do |f|
        f.writer.superclass.should == RDF::Writer
      end
    end
  end
end
