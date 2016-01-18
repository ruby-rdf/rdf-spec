require 'rdf/spec'

# To use RDF::Durable to check that a repository maintains information between
# instantiations, add a Proc that creates a repository before each item, and
# clean that up after every run.  Example:
#describe RDF::DataObjects::Repository do
#  context "The SQLite adapter" do
#    before :each do
#      @repository = RDF::DataObjects::Repository.new "sqlite3://:memory:"
#      @load_durable = lambda { RDF::DataObjects::Repository.new "sqlite3:test.db" }
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

  it "is_expected.to support #durable?" do
    expect([true,false]).to be_member(subject.durable?)
  end

  it {is_expected.to respond_to(:nondurable?)}

  it "is_expected.to support #nondurable?" do
    expect([true,false]).to be_member(@load_durable.call.nondurable?)
  end

  its(:nondurable?) {is_expected.to_not eq subject.durable?}

  it "is_expected.to save contents between instantiations" do
    if subject.durable?
      subject.load(RDF::Spec::TRIPLES_FILE)
      expect(subject.count).to eq File.readlines(RDF::Spec::TRIPLES_FILE).size
    end
  end
end
