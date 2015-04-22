require 'rdf/spec'

RSpec.shared_examples 'an RDF::Enumerable' do
  include RDF::Spec::Matchers

  before do
    raise 'enumerable must be set with `let(:enumerable)' unless
      defined? enumerable

    @statements ||= RDF::Spec.quads

    if enumerable.empty?
      if (enumerable.writable? rescue false)
        enumerable.insert(*@statements)
      elsif enumerable.respond_to?(:<<)
        @statements.each { |statement| enumerable << statement }
      else
        raise "@enumerable must respond to #<< or be pre-populated with the statements in #{RDF::Spec::TRIPLES_FILE} in a before(:each) block"
      end
    end

    @supports_context = enumerable.supports?(:context) rescue true
  end

  let(:subject_count) {@statements.map(&:subject).uniq.length}
  let(:bnode_subject_count) {@statements.map(&:subject).uniq.select(&:node?).length}
  let(:non_bnode_statements) {@statements.reject {|s| s.subject.node? || s.object.node?}}

  subject { enumerable }
  it {should respond_to(:supports?)}

  describe "valid?" do
    it "reports validity" do
      if subject.supports?(:validity)
        should be_valid
      else
        expect {subject.valid?}.to raise_error(NotImplementedError)
      end
    end

    it "returns false if any statement is invalid" do
      if subject.respond_to?(:<<) && (subject.writable? rescue true)
        s = RDF::Statement.from([nil, nil, nil])
        if subject.supports?(:validity)
          expect(s).not_to  be_valid
          subject << s
          expect(subject).not_to  be_valid
        else
          expect {subject.valid?}.to raise_error(NotImplementedError)
        end
      else
        skip("can't add statement to immutable enumerable")
      end
    end
  end

  context "when counting statements" do
    it {should respond_to(:empty?)}
    it {should_not be_empty}
    it {should respond_to(:count)}
    its(:count) {should == @statements.size}
    it {should respond_to(:size)}
    its(:size) {should == @statements.size}

    context "and empty" do
      subject {[].extend(RDF::Enumerable)}
      it {should be_empty}
      its(:count) {should == 0}
      its(:size) {should == 0}
    end
  end

  context "when enumerating statements" do
    it {should respond_to(:statements)}
    its(:statements) {should be_an_enumerator}

    context "#statements" do
      specify {expect(subject.statements.to_a.size).to eq @statements.size}
      specify {subject.statements.each { |statement| expect(statement).to be_a_statement }}
    end

    it {should respond_to(:has_statement?)}
    context "#has_statement?" do
      let(:unknown_statement) {RDF::Statement.new(RDF::Node.new, RDF::URI.new("http://example.org/unknown"), RDF::Node.new)}
      it "should have all statements" do
        # Don't check for BNodes, as equivalence depends on their being exactly the same, not just the same identifier. If subject is loaded separately, these won't match.
        non_bnode_statements.each do |statement|
          expect(subject).to have_statement(statement)
        end
      end

      it "does not have statement in different context" do
        if @supports_context
          context = RDF::URI.new("urn:context:1")
          non_bnode_statements.each do |statement|
            s = statement.dup
            s.context = context
            expect(subject).not_to have_statement(s)
          end
        end
      end

      it "does not have an unknown statement" do
        expect(subject).not_to have_statement(unknown_statement)
      end
    end

    it {should respond_to(:each_statement)}
    its(:each_statement) {should be_an_enumerator}
    it "should implement #each_statement" do
      subject.each_statement { |statement| expect(statement).to be_a_statement }
    end

    it {should respond_to(:enum_statement)}
    its(:enum_statement) {should be_an_enumerator}
    its(:enum_statement) {should be_countable}
    its(:enum_statement) {should be_enumerable}
    its(:enum_statement) {should be_queryable}
    context "#enum_statement" do
      it "should enumerate all statements" do
        expect(subject.enum_statement.count).to eq enumerable.each_statement.count
        subject.enum_statement.each do |s|
          expect(s).to be_a_statement
          expect(enumerable.each_statement.to_a).to include(s) unless s.has_blank_nodes?
        end
      end
    end
  end

  context "when enumerating triples" do
    it {should respond_to(:triples)}
    it {should respond_to(:has_triple?)}
    it {should respond_to(:each_triple)}
    it {should respond_to(:enum_triple)}

    its(:triples) {should be_an_enumerator}
    context "#triples" do
      specify {expect(subject.triples.to_a.size).to eq @statements.size}
      specify {subject.triples.each { |triple| expect(triple).to be_a_triple }}
    end

    context "#has_triple?" do
      specify do
        non_bnode_statements.each do |statement|
          expect(subject).to have_triple(statement.to_triple)
        end
      end
    end

    its(:each_triple) {should be_an_enumerator}
    context "#each_triple" do
      specify {subject.each_triple { |*triple| expect(triple).to be_a_triple }}
      it "should iterate over all triples" do
        subject.each_triple do |*triple|
          triple.each {|r| expect(r).to be_a_term}
          expect(enumerable).to have_triple(triple) unless triple.any?(&:node?)
        end
      end
    end

    its(:enum_triple) {should be_an_enumerator}
    its(:enum_triple) {should be_countable}
    context "#enum_triple" do
      it "should enumerate all triples" do
        expect(subject.enum_triple.count).to eq enumerable.each_triple.count
        subject.enum_triple.each do |s, p, o|
          [s, p, o].each {|r| expect(r).to be_a_term}
          expect(enumerable).to have_triple([s, p, o]) unless [s, p, o].any?(&:node?)
        end
      end
    end
  end

  context "when enumerating quads" do
    it {should respond_to(:quads)}
    it {should respond_to(:has_quad?)}
    it {should respond_to(:each_quad)}
    it {should respond_to(:enum_quad)}

    its(:quads) {should be_an_enumerator}
    context "#quads" do
      specify {expect(subject.quads.to_a.size).to eq @statements.size}
      specify {subject.quads.each { |quad| expect(quad).to be_a_quad }}
    end

    context "#has_quad?" do
      specify do
        if @supports_context
          non_bnode_statements.each do |statement|
            expect(subject).to have_quad(statement.to_quad)
          end
        end
      end
    end

    its(:each_quad) {should be_an_enumerator}
    context "#each_quad" do
      specify {subject.each_quad {|*quad| expect(quad).to be_a_quad }}
      it "should iterate over all quads" do
        subject.each_quad do |*quad|
          quad.compact.each {|r| expect(r).to be_a_term}
          expect(enumerable).to have_quad(quad) unless quad.compact.any?(&:node?)
        end
      end
    end

    its(:enum_quad) {should be_an_enumerator}
    its(:enum_quad) {should be_countable}
    context "#enum_quad" do
      it "should enumerate all quads" do
        expect(subject.enum_quad.count).to eq enumerable.each_quad.count
        subject.enum_quad.each do |s, p, o, c|
          [s, p, o, c].compact.each {|r| expect(r).to be_a_term}
          expect(enumerable).to have_quad([s, p, o, c]) unless [s, p, o].any?(&:node?)
        end
      end
    end
  end

  context "when enumerating subjects" do
    let(:subjects) {subject.map { |s| s.subject }.reject(&:node?).uniq}
    it {should respond_to(:subjects)}
    it {should respond_to(:has_subject?)}
    it {should respond_to(:each_subject)}
    it {should respond_to(:enum_subject)}

    its(:subjects) {should be_an_enumerator}
    context "#subjects" do
      subject { enumerable.subjects }
      specify {expect(subject).to be_an_enumerator}
      specify {subject.each { |value| expect(value).to be_a_resource }}
      context ":unique => false" do
        subject { enumerable.subjects(:unique => false) }
        specify {expect(subject).to be_an_enumerator}
        specify {subject.each { |value| expect(value).to be_a_resource }}
      end
    end

    context "#has_subject?" do
      specify do
        checked = []
        non_bnode_statements.each do |statement|
          expect(enumerable).to have_subject(statement.subject) unless checked.include?(statement.subject)
          checked << statement.subject
        end
        uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
        expect(enumerable).not_to have_subject(uri)
      end
    end

    its(:each_subject) {should be_an_enumerator}
    context "#each_subject" do
      specify {expect(subject.each_subject.reject(&:node?).size).to eq subjects.reject(&:node?).size}
      specify {subject.each_subject {|value| expect(value).to be_a_resource}}
      specify {subject.each_subject {|value| expect(subjects).to include(value) unless value.node?}}
    end

    its(:enum_subject) {should be_an_enumerator}
    its(:enum_subject) {should be_countable}
    context "#enum_subject" do
      specify {expect(subject.enum_subject.to_a.reject(&:node?).size).to eq subjects.reject(&:node?).size}
      it "should enumerate all subjects" do
        subject.enum_subject.each do |s|
          expect(s).to be_a_resource
          expect(subjects.to_a).to include(s) unless s.node?
        end
      end
    end
  end

  context "when enumerating predicates" do
    let(:predicates) {@statements.map { |s| s.predicate }.uniq}
    it {should respond_to(:predicates)}
    it {should respond_to(:has_predicate?)}
    it {should respond_to(:each_predicate)}
    it {should respond_to(:enum_predicate)}

    its(:predicates) {should be_an_enumerator}
    context "#predicates" do
      subject { enumerable.predicates }
      specify {expect(subject).to be_an_enumerator}
      specify {subject.each { |value| expect(value).to be_a_uri }}
      context ":unique => false" do
        subject { enumerable.predicates(:unique => false) }
        specify {expect(subject).to be_an_enumerator}
        specify {subject.each { |value| expect(value).to be_a_uri }}
      end
    end

    context "#has_predicate?" do
      specify do
        checked = []
        @statements.each do |statement|
          expect(enumerable).to have_predicate(statement.predicate) unless checked.include?(statement.predicate)
          checked << statement.predicate
        end
        uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
        expect(enumerable).not_to have_predicate(uri)
      end
    end

    its(:each_predicate) {should be_an_enumerator}
    context "#each_predicate" do
      specify {expect(subject.each_predicate.to_a.size).to eq predicates.size}
      specify {subject.each_predicate {|value| expect(value).to be_a_uri}}
      specify {subject.each_predicate {|value| expect(predicates).to include(value)}}
    end

    its(:enum_predicate) {should be_an_enumerator}
    its(:enum_predicate) {should be_countable}
    context "#enum_predicate" do
      it "should enumerate all predicates" do
        expect(subject.enum_predicate.to_a).to include(*predicates)
      end
    end
  end

  context "when enumerating objects" do
    let(:objects) {subject.map(&:object).reject(&:node?).uniq}
    it {should respond_to(:objects)}
    it {should respond_to(:has_object?)}
    it {should respond_to(:each_object)}
    it {should respond_to(:enum_object)}

    its(:objects) {should be_an_enumerator}
    context "#objects" do
      subject { enumerable.objects }
      specify {expect(subject).to be_an_enumerator}
      specify {subject.each { |value| expect(value).to be_a_term }}
      context ":unique => false" do
        subject { enumerable.objects(:unique => false) }
        specify {expect(subject).to be_an_enumerator}
        specify {subject.each { |value| expect(value).to be_a_term }}
      end
    end

    context "#has_object?" do
      specify do
        checked = []
        non_bnode_statements.each do |statement|
          expect(enumerable).to have_object(statement.object) unless checked.include?(statement.object)
          checked << statement.object
        end
        uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
        expect(enumerable).not_to have_object(uri)
      end
    end

    its(:each_object) {should be_an_enumerator}
    context "#each_object" do
      specify {expect(subject.each_object.reject(&:node?).size).to eq objects.size}
      specify {subject.each_object {|value| expect(value).to be_a_term}}
      specify {subject.each_object {|value| expect(objects).to include(value) unless value.node?}}
    end

    its(:enum_object) {should be_an_enumerator}
    its(:enum_object) {should be_countable}
    context "#enum_object" do
      it "should enumerate all objects" do
        subject.enum_object.each do |o|
          expect(o).to be_a_term
          expect(objects.to_a).to include(o) unless o.node?
        end
      end
    end
  end

  context "when enumerating contexts" do
    it {should respond_to(:contexts)}
    it {should respond_to(:has_context?)}
    it {should respond_to(:each_context)}
    it {should respond_to(:enum_context)}

    its(:contexts) {should be_an_enumerator}
    describe "#contexts" do
      subject { enumerable.contexts }
      specify {expect(subject).to be_an_enumerator}
      it "values should be resources" do
        subject.each { |value| expect(value).to be_a_resource }
      end
      context ":unique => false" do
        subject { enumerable.contexts(:unique => false) }
        specify {expect(subject).to be_an_enumerator}
        it "values should be resources" do
          subject.each { |value| expect(value).to be_a_resource }
        end
      end
    end

    it "should implement #has_context?" do
      if @supports_context
        @statements.each do |statement|
          if statement.has_context?
            expect(enumerable).to have_context(statement.context)
          end
        end
        uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
        expect(enumerable).not_to have_context(uri)
      end
    end

    its(:each_context) {should be_an_enumerator}
    context "#each_context" do
      let(:contexts) {@statements.map { |s| s.context }.uniq.compact}
      it "has appropriate number of contexts" do
        if @supports_context
          expect(subject.each_context.to_a.size).to eq contexts.size
        end
      end
      it "values should be resources" do
        subject.each_context {|value| expect(value).to be_a_resource}
      end
      it "should have all contexts" do
        subject.each_context {|value| expect(contexts).to include(value)}
      end
    end

    its(:enum_context) {should be_an_enumerator}
    its(:enum_context) {should be_countable}
    context "#enum_context" do
      it "should enumerate all contexts" do
        expect(subject.enum_context.to_a).to include(*enumerable.each_context.to_a)
      end
    end
  end

  context "when enumerating graphs" do
    it {should respond_to(:each_graph)}
    it {should respond_to(:enum_graph)}

    describe "#each_graph" do
      subject { enumerable.each_graph }
      it {should be_an_enumerator}
      it "are all graphs" do
        subject.each { |value| expect(value).to be_a_graph } if @supports_context
      end
    end

    describe "#enum_graph" do
      subject { enumerable.enum_graph }
      it {should be_an_enumerator}
      it {should be_countable}
      it "enumerates the same as #each_graph" do
        expect(subject.to_a).to include(*enumerable.each_graph.to_a) if @supports_context # expect with match problematic
      end
    end
  end

  context "when converting" do
    it {should respond_to(:to_hash)}
    its(:to_hash) {should be_instance_of(Hash)}
    context "#to_hash" do
      it "should have as many keys as subjects" do
        expect(subject.to_hash.keys.size).to eq enumerable.subjects.to_a.size
      end
    end
  end

  context "when dumping" do
    it {should respond_to(:dump)}

    it "should implement #dump" do
      expect(subject.dump(:ntriples)).to eq RDF::NTriples::Writer.buffer() {|w| w << enumerable}
    end

    it "raises error on unknown format" do
      expect {subject.dump(:foobar)}.to raise_error(RDF::WriterError, /No writer found/)
    end
  end
end
