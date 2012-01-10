require 'rdf/spec'

share_as :RDF_Format do
  include RDF::Spec::Matchers

  before(:each) do
    raise raise '+@format_class+ must be defined in a before(:each) block' unless instance_variable_get('@format_class')
  end

  describe ".for" do
    RDF::Format.file_extensions.each do |ext, formats|
      it "detects #{formats.first} using file_name foo.#{ext}" do
        RDF::Format.for(:file_name => "foo.#{ext}").should == formats.first
      end

      it "detects #{formats.first} using file_extension #{ext}" do
        RDF::Format.for(:file_extension => ext).should == formats.first
      end
    end

    RDF::Format.content_types.each do |content_type, formats|
      it "detects #{formats.first} using content_type #{content_type}" do
        RDF::Format.for(:content_type => content_type).should == formats.first
      end
    end
  end
  
  describe ".reader" do
    it "returns a reader" do
      @format_class.each do |f|
        f.reader.should_not be_nil
      end
    end
  end
  
  describe ".writer" do
    ##
    # May not return a writer, only does if one is defined by the format
    it "returns a writer" do
      @format_class.each do |f|
        format_namespace = f.name.split('::')[0..-2].inject(Kernel) {|base, const| base.const_get(const)}
        f.writer.should_not be_nil if format_namespace.const_defined?(:Writer)
      end
    end
  end
end
