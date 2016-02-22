require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'RDF::Spec::VERSION' do
  it "is_expected.to match the VERSION file" do
    expect(RDF::Spec::VERSION.to_s).to eq File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).chomp
    expect(RDF::Spec::VERSION.to_str).to eq File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).chomp
    expect(RDF::Spec::VERSION.to_a).to eq RDF::Spec::VERSION.to_s.split('.')
  end
end
