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
