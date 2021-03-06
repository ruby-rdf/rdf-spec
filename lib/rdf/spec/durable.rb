require 'rdf/spec'

# To use RDF::Durable to check that a repository maintains information between
# instantiations, add a Proc that creates a repository before each item, and
# clean that up after every run.  Example:
#describe RDF::DataObjects::Repository do
#  context "The SQLite adapter" do
#    before :each do
#      @load_durable = lambda { RDF::DataObjects::Repository.new uri: "sqlite3:test.db" }
#    end
#
#    after :each do
#      File.delete('test.db') if File.exists?('test.db')
#    end
#
#    it_behaves_like 'an RDF::Repository'
#  end
#end
RSpec.shared_examples 'an RDF::Durable' do
  include RDF::Spec::Matchers

  before :each do
    raise '+@load_durable+ must be defined in a before(:each) block' unless
      instance_variable_get('@load_durable')
  end

  subject {@load_durable.call}

  it { is_expected.to respond_to(:durable?) }

  it "supports #durable?" do
    expect([true,false]).to be_member(subject.durable?)
  end

  it {is_expected.to respond_to(:nondurable?)}

  it "supports #nondurable?" do
    expect([true,false]).to be_member(@load_durable.call.nondurable?)
  end

  its(:nondurable?) {is_expected.to_not eq subject.durable?}

  it "saves contents between instantiations" do
    if subject.durable?
      subject.insert RDF::Statement(RDF::RDFS.Resource, RDF.value, "string") if subject.empty?
      subject.close if subject.respond_to?(:close)
      new_instance = @load_durable.call
      expect(new_instance).not_to be_empty
    end
  end
end
