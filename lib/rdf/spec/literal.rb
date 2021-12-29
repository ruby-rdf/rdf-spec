##
# Shared examples for RDF::Literals are broken up into multiple example sets.
#
# To use the core example sets that apply to most RDF::Literal implementations
# include the examples for `RDF::Literal`, `RDF::Literal validation`,
# `RDF::Literal canonicalization`, and `RDF::Literal lookup`.

# @private
shared_examples 'RDF::Literal' do |value, datatype_uri|
  include_examples 'RDF::Literal with datatype and grammar', value, datatype_uri
  include_examples 'RDF::Literal equality', value, value
  include_examples 'RDF::Literal lexical values', value
end

shared_examples 'RDF::Literal with datatype and grammar' do |value, datatype_uri|
  include_examples 'RDF::Literal with grammar'
  include_examples 'RDF::Literal with datatype', value, datatype_uri
end

shared_examples 'RDF::Literal lexical values' do |value|
  subject { described_class.new(value) }

  describe '#humanize' do
    it 'gives a string representation' do
      expect(subject.humanize).to be_a String
    end
  end

  describe '#to_s' do
    it 'gives a string representation' do
      expect(subject.to_s).to be_a String
    end
  end
end

shared_examples 'RDF::Literal with grammar' do
  it 'has a GRAMMAR' do
    expect(described_class::GRAMMAR).to respond_to :=~
  end
end

shared_examples 'RDF::Literal equality' do |value, other|
  subject { described_class.new(value) }

  describe '#==' do
    it { is_expected.to eq subject }
    it { expect(subject.object).to eq (other || value) }
    it { is_expected.not_to eq described_class.new('OTHER') }
    it { is_expected.not_to eq nil }
  end
end

shared_examples 'RDF::Literal with datatype' do |value, datatype_uri|
  subject { described_class.new(value) }

  it { is_expected.to be_literal }
  it { is_expected.to be_typed }
  it { is_expected.not_to be_plain }
  it { is_expected.not_to be_anonymous }

  it 'has a DATATYPE' do
    expect(described_class::DATATYPE).to be_a RDF::URI
  end

  it 'has correct datatype' do
    expect(subject.datatype).to eq datatype_uri
  end
end

shared_examples 'RDF::Literal lookup' do |uri_hash|
  uri_hash.each do |uri, klass|
    it "finds #{klass} for #{uri}" do
      expect(RDF::Literal("0", datatype: uri).class).to eq klass
    end
  end
end

shared_examples 'RDF::Literal canonicalization' do |datatype, pairs|
  pairs.each do |value, str, human = nil|
    human ||= value
    klass = RDF::Literal.datatyped_class(datatype.to_s)

    it "does not normalize '#{value}' by default" do
      expect(RDF::Literal.new(value,
                              datatype: datatype ,
                              canonicalize: false).to_s)
        .to eq value
    end

    it "normalizes '#{value}' to '#{str}'" do
      expect(RDF::Literal.new(value,
                              datatype: datatype,
                              canonicalize: true).to_s)
        .to eq str
    end

    it "humanizes '#{value}' to '#{str}'" do
      expect(RDF::Literal.new(value,
                              datatype: datatype,
                              canonicalize: false).humanize)
        .to eq human
    end

    it "instantiates '#{value}' as #{klass}" do
      expect(RDF::Literal.new(value,
                              datatype: datatype,
                              canonicalize: true))
        .to be_a(klass)
    end

    it "causes normalized '#{value}' to be == '#{str}'" do
      expect(RDF::Literal.new(value,
                              datatype: datatype,
                              canonicalize: true))
        .to eq RDF::Literal.new(str, datatype: datatype, canonicalize: false)
    end
  end
end

shared_examples 'RDF::Literal validation' do |datatype,
                                              valid_values,
                                              invalid_values|

  klass = RDF::Literal.datatyped_class(datatype.to_s)

  valid_values.each do |value|
    it "validates #{klass} '#{value}'" do
      expect(RDF::Literal.new(value, datatype: datatype)).to be_valid
    end

    it "does not invalidate #{klass} '#{value}'" do
      expect(RDF::Literal.new(value, datatype: datatype)).not_to be_invalid
    end
  end

  invalid_values.each do |value|
    it "invalidates #{klass} '#{value}'" do
      expect(RDF::Literal.new(value, datatype: datatype)).to be_invalid
    end

    it "does not validate #{klass} '#{value}'" do
      expect(RDF::Literal.new(value, datatype: datatype)).not_to be_valid
    end
  end
end
