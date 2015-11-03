require 'rdf/spec'

RSpec.shared_examples 'an RDF::Format' do
  include RDF::Spec::Matchers

  before(:each) do
    raise 'format_class must be defined with let(:format_class)' unless
      defined? format_class
  end

  subject { format_class }

  describe ".for" do
    RDF::Format.file_extensions.each do |ext, formats|
      it "detects #{formats.first} using file path foo.#{ext}" do
        expect(RDF::Format.for("foo.#{ext}")).to eq formats.last
      end

      it "detects #{formats.first} using file_name foo.#{ext}" do
        expect(RDF::Format.for(file_name: "foo.#{ext}")).to eq formats.last
      end

      it "detects #{formats.first} using file_extension #{ext}" do
        expect(RDF::Format.for(file_extension: ext)).to eq formats.last
      end
    end

    RDF::Format.content_types.each do |content_type, formats|
      it "detects #{formats.first} using content_type #{content_type}" do
        expect(RDF::Format.for(content_type: content_type)).to eq formats.last
      end
    end
  end

  describe ".reader" do
    it "returns a reader" do
      subject.each do |f|
        expect(f.reader).not_to  be_nil
      end
    end
  end

  describe ".writer" do
    ##
    # May not return a writer, only does if one is defined by the format
    it "returns a writer" do
      subject.each do |f|
        format_namespace = f.name.split('::')[0..-2].inject(Kernel) {|base, const| base.const_get(const)}
        expect(f.writer).not_to  be_nil if format_namespace.const_defined?(:Writer)
      end
    end
  end
end

##
# @deprecated use `it_behaves_like "an RDF::Format"` instead
module RDF_Format
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  def self.included(mod)
    warn "[DEPRECATION] `RDF_Format` is deprecated. "\
         "Please use `it_behaves_like 'an RDF::Format'`"
  end

  describe 'examples for' do
    include_examples 'an RDF::Format' do
      let(:format_class) { @format_class }

      before do
        raise '@format_class must be defined' unless defined?(format_class)
      end
    end
  end
end
