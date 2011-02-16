require 'rdf/spec'

share_as :RDF_Format do
  include RDF::Spec::Matchers

  before(:each) do
    raise raise '+@format_class+ must be defined in a before(:each) block' unless instance_variable_get('@format_class')
  end

  describe ".for" do
    it "detects format using file_name" do
      RDF::Format.each do |f|
        f.file_extensions.each_pair do |sym, content_type|
          RDF::Format.for("foo.#{sym}").should == RDF::Format.for(:file_name => "foo.#{sym}")
          RDF::Format.for("foo.#{sym}").should == RDF::Format.for(:file_extension => sym)
          RDF::Format.for("foo.#{sym}").should == RDF::Format.for(:content_type => content_type)
        end
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
    it "returns a writer" do
      @format_class.each do |f|
        f.writer.should_not be_nil
      end
    end
  end
end
