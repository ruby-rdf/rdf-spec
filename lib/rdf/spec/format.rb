require 'rdf/spec'

share_as :RDF_Format do
  include RDF::Spec::Matchers

  before(:each) do
    raise raise '+@format_class+ must be defined in a before(:each) block' unless instance_variable_get('@format_class')
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
