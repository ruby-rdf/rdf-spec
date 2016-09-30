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

    @supports_named_graphs = enumerable.supports?(:graph_name) rescue true
  end

  let(:subject_count) {@statements.map(&:subject).uniq.length}
  let(:bnode_subject_count) {@statements.map(&:subject).uniq.select(&:node?).length}
  let(:non_bnode_statements) {@statements.reject(&:node?)}
  let(:non_bnode_terms) {@statements.map(&:to_quad).flatten.compact.reject(&:node?).uniq}

  subject { enumerable }
  it {is_expected.to respond_to(:supports?)}

  describe "valid?" do
    it "reports validity" do
      if subject.supports?(:validity)
        is_expected.to be_valid
      else
        expect {subject.valid?}.to raise_error(NotImplementedError)
      end
    end

    it "returns false if any statement is invalid" do
      if subject.respond_to?(:<<) && (subject.writable? rescue true)
        s = RDF::Statement(RDF::URI("http://rubygems.org/gems/rdf"), RDF::Literal("literal"), RDF::URI("http://ar.to/#self"))
        if subject.supports?(:validity)
          expect(s).not_to  be_valid
          subject << s
          is_expected.not_to  be_valid
        else
          expect {subject.valid?}.to raise_error(NotImplementedError)
        end
      end
    end
  end

  context "when counting statements" do
    it {is_expected.to respond_to(:empty?)}
    it {is_expected.to_not be_empty}
    it {is_expected.to respond_to(:count)}
    its(:count) {is_expected.to eq @statements.size}
    it {is_expected.to respond_to(:size)}
    its(:size) {is_expected.to eq @statements.size}

    context "and empty" do
      subject {[].extend(RDF::Enumerable)}
      it {is_expected.to be_empty}
      its(:count) {is_expected.to eq 0}
      its(:size) {is_expected.to eq 0}
    end
  end

  context "when enumerating statements" do
    it {is_expected.to respond_to(:statements)}
    its(:statements) {is_expected.to be_a(Array)}

    context "#statements" do
      specify {expect(subject.statements.size).to eq @statements.size}
      specify {expect(subject.statements).to all(be_a_statement)}
    end

    it {is_expected.to respond_to(:has_statement?)}
    context "#has_statement?" do
      let(:unknown_statement) {RDF::Statement.new(RDF::Node.new, RDF::URI.new("http://example.org/unknown"), RDF::Node.new)}
      it "should have all statements" do
        # Don't check for BNodes, as equivalence depends on their being exactly the same, not just the same identifier. If subject is loaded separately, these won't match.
        non_bnode_statements.each do |statement|
          is_expected.to have_statement(statement)
        end
      end

      it "does not have statement in different named graph" do
        if @supports_named_graphs
          graph_name = RDF::URI.new("urn:graph_name:1")
          non_bnode_statements.each do |statement|
            s = statement.dup
            s.graph_name = graph_name
            is_expected.not_to have_statement(s)
          end
        end
      end

      it "does not have an unknown statement" do
        is_expected.not_to have_statement(unknown_statement)
      end
    end

    it {is_expected.to respond_to(:each_statement)}
    its(:each_statement) {is_expected.to be_an_enumerator}
    its(:each_statement) {expect(subject.each_statement).to all(be_a_statement)}

    it {is_expected.to respond_to(:enum_statement)}
    its(:enum_statement) {is_expected.to be_an_enumerator}
    its(:enum_statement) {is_expected.to be_countable}
    its(:enum_statement) {is_expected.to be_enumerable}
    its(:enum_statement) {is_expected.to be_queryable}
    context "#enum_statement" do
      it "should enumerate all statements" do
        expect(subject.enum_statement.count).to eq enumerable.each_statement.count
        subject.enum_statement.each do |s|
          expect(s).to be_a_statement
          expect(enumerable.each_statement.to_a).to include(s) unless s.node?
        end
      end
    end
  end

  context "when enumerating triples" do
    it {is_expected.to respond_to(:triples)}
    it {is_expected.to respond_to(:has_triple?)}
    it {is_expected.to respond_to(:each_triple)}
    it {is_expected.to respond_to(:enum_triple)}

    its(:triples) {is_expected.to be_a(Array)}
    context "#triples" do
      specify {expect(subject.triples.size).to eq @statements.size}
      specify {expect(subject.triples).to all(be_a_triple)}
    end

    context "#has_triple?" do
      specify do
        non_bnode_statements.each do |statement|
          is_expected.to have_triple(statement.to_triple)
        end
      end
    end

    its(:each_triple) {is_expected.to be_an_enumerator}
    context "#each_triple" do
      specify {expect(subject.each_triple).to all(be_a_triple)}
      it "should iterate over all triples" do
        subject.each_triple do |*triple|
          expect(triple.each).to all(be_a_term)
          expect(enumerable).to have_triple(triple) unless triple.any?(&:node?)
        end
      end
    end

    its(:enum_triple) {is_expected.to be_an_enumerator}
    its(:enum_triple) {is_expected.to be_countable}
    context "#enum_triple" do
      it "should enumerate all triples" do
        expect(subject.enum_triple.count).to eq enumerable.each_triple.count
        subject.enum_triple.each do |s, p, o|
          expect([s, p, o]).to all(be_a_term)
          expect(enumerable).to have_triple([s, p, o]) unless [s, p, o].any?(&:node?)
        end
      end
    end
  end

  context "when enumerating quads" do
    it {is_expected.to respond_to(:quads)}
    it {is_expected.to respond_to(:has_quad?)}
    it {is_expected.to respond_to(:each_quad)}
    it {is_expected.to respond_to(:enum_quad)}

    its(:quads) {is_expected.to be_a(Array)}
    context "#quads" do
      specify {expect(subject.quads.size).to eq @statements.size}
      specify {expect(subject.quads).to all(be_a_quad)}
    end

    context "#has_quad?" do
      specify do
        if @supports_named_graphs
          non_bnode_statements.each do |statement|
            is_expected.to have_quad(statement.to_quad)
          end
        end
      end
    end

    its(:each_quad) {is_expected.to be_an_enumerator}
    context "#each_quad" do
      specify {expect(subject.each_quad).to all(be_a_quad)}
      it "should iterate over all quads" do
        subject.each_quad do |*quad|
          expect(quad.compact).to all(be_a_term)
          expect(enumerable).to have_quad(quad) unless quad.compact.any?(&:node?)
        end
      end
    end

    its(:enum_quad) {is_expected.to be_an_enumerator}
    its(:enum_quad) {is_expected.to be_countable}
    context "#enum_quad" do
      it "should enumerate all quads" do
        expect(subject.enum_quad.count).to eq enumerable.each_quad.count
        subject.enum_quad.each do |s, p, o, c|
          expect([s, p, o, c].compact).to all(be_a_term)
          expect(enumerable).to have_quad([s, p, o, c]) unless [s, p, o].any?(&:node?)
        end
      end
    end
  end

  context "when enumerating subjects" do
    let(:subjects) {subject.map { |s| s.subject }.reject(&:node?).uniq}
    it {is_expected.to respond_to(:subjects)}
    it {is_expected.to respond_to(:has_subject?)}
    it {is_expected.to respond_to(:each_subject)}
    it {is_expected.to respond_to(:enum_subject)}

    context "#subjects" do
      subject { enumerable.subjects }
      specify {is_expected.to be_a(Array)}
      specify {is_expected.to all(be_a_resource)}
      context "unique: false" do
        subject { enumerable.subjects(unique: false) }
        specify {is_expected.to be_a(Array)}
        specify {is_expected.to all(be_a_resource)}
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

    its(:each_subject) {is_expected.to be_an_enumerator}
    context "#each_subject" do
      specify {expect(subject.each_subject.reject(&:node?).size).to eq subjects.reject(&:node?).size}
      specify {expect(subject.each_subject).to all(be_a_resource)}
      specify {subject.each_subject {|value| expect(subjects).to include(value) unless value.node?}}
    end

    its(:enum_subject) {is_expected.to be_an_enumerator}
    its(:enum_subject) {is_expected.to be_countable}
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
    it {is_expected.to respond_to(:predicates)}
    it {is_expected.to respond_to(:has_predicate?)}
    it {is_expected.to respond_to(:each_predicate)}
    it {is_expected.to respond_to(:enum_predicate)}

    context "#predicates" do
      subject { enumerable.predicates }
      specify {is_expected.to be_a(Array)}
      specify {is_expected.to all(be_a_uri)}
      context "unique: false" do
        subject { enumerable.predicates(unique: false) }
        specify {is_expected.to be_a(Array)}
        specify {is_expected.to all(be_a_uri)}
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

    its(:each_predicate) {is_expected.to be_an_enumerator}
    context "#each_predicate" do
      specify {expect(subject.each_predicate.to_a.size).to eq predicates.size}
      specify {expect(subject.each_predicate).to all(be_a_uri)}
      specify {subject.each_predicate {|value| expect(predicates).to include(value)}}
    end

    its(:enum_predicate) {is_expected.to be_an_enumerator}
    its(:enum_predicate) {is_expected.to be_countable}
    context "#enum_predicate" do
      it "should enumerate all predicates" do
        expect(subject.enum_predicate.to_a).to include(*predicates)
      end
    end
  end

  context "when enumerating objects" do
    let(:objects) {subject.map(&:object).reject(&:node?).uniq}
    it {is_expected.to respond_to(:objects)}
    it {is_expected.to respond_to(:has_object?)}
    it {is_expected.to respond_to(:each_object)}
    it {is_expected.to respond_to(:enum_object)}

    context "#objects" do
      subject { enumerable.objects }
      specify {is_expected.to be_a(Array)}
      specify {is_expected.to all(be_a_term)}
      context "unique: false" do
        subject { enumerable.objects(unique: false) }
        specify {is_expected.to be_a(Array)}
        specify {is_expected.to all(be_a_term)}
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

    its(:each_object) {is_expected.to be_an_enumerator}
    context "#each_object" do
      specify {expect(subject.each_object.reject(&:node?).size).to eq objects.size}
      specify {expect(subject.each_object).to all(be_a_term)}
      specify {subject.each_object {|value| expect(objects).to include(value) unless value.node?}}
    end

    its(:enum_object) {is_expected.to be_an_enumerator}
    its(:enum_object) {is_expected.to be_countable}
    context "#enum_object" do
      it "should enumerate all objects" do
        subject.enum_object.each do |o|
          expect(o).to be_a_term
          expect(objects.to_a).to include(o) unless o.node?
        end
      end
    end
  end

  context "when enumerating terms" do
    let(:terms) {subject.map(&:to_quad).flatten.compact.reject(&:node?).uniq}
    it {is_expected.to respond_to(:terms)}
    it {is_expected.to respond_to(:has_term?)}
    it {is_expected.to respond_to(:each_term)}
    it {is_expected.to respond_to(:enum_term)}

    context "#terms" do
      subject { enumerable.terms }
      specify {is_expected.to be_a(Array)}
      specify {is_expected.to all(be_a_term)}
      context "unique: false" do
        subject { enumerable.terms(unique: false) }
        specify {is_expected.to be_a(Array)}
        specify {is_expected.to all(be_a_term)}
      end
    end

    context "#has_term?" do
      specify do
        checked = {}
        non_bnode_terms.each do |term|
          expect(enumerable).to have_term(term) unless checked.has_key?(term.hash)
          checked[term.hash] = true
        end
        uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
        expect(enumerable).not_to have_term(uri)
      end
    end

    its(:each_term) {is_expected.to be_an_enumerator}
    context "#each_term" do
      it 'has correct number of terms' do
        expected_count = non_bnode_terms.length
        expected_count = expected_count - 3 unless 
          subject.supports?(:literal_equality)

        expect(subject.each_term.reject(&:node?).size).to eq expected_count
      end

      specify { expect(subject.each_term).to all(be_a_term) }
      specify { subject.each_term {|value| expect(non_bnode_terms).to include(value) unless value.node?} }
    end

    its(:enum_term) {is_expected.to be_an_enumerator}
    its(:enum_term) {is_expected.to be_countable}
    context "#enum_term" do
      it "should enumerate all terms" do
        subject.enum_term.each do |o|
          expect(o).to be_a_term
          expect(non_bnode_terms.to_a).to include(o) unless o.node?
        end
      end
    end
  end

  context "when enumerating graphs" do
    it {is_expected.to respond_to(:graph_names)}
    it {is_expected.to respond_to(:has_graph?)}
    it {is_expected.to respond_to(:each_graph)}
    it {is_expected.to respond_to(:enum_graph)}

    its(:graph_names) {is_expected.to be_a(Array)}
    describe "#graph_names" do
      subject { enumerable.graph_names }
      specify {is_expected.to be_a(Array)}
      specify {is_expected.to all(be_a_resource)}
      context "unique: false" do
        subject { enumerable.graph_names(unique: false) }
        specify {is_expected.to be_a(Array)}
        specify {is_expected.to all(be_a_resource)}
      end
    end

    it "should implement #has_graph?" do
      if @supports_named_graphs
        @statements.each do |statement|
          if statement.has_graph?
            expect(enumerable).to have_graph(statement.graph_name)
          end
        end
        uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
        expect(enumerable).not_to have_graph(uri)
      end
    end

    describe "#project_graph" do
      it {is_expected.to respond_to(:project_graph)}

      context "default graph" do
        let(:graph_name) {nil}
        specify {expect(subject.project_graph(graph_name)).to all(be_a_statement)}

        it "should return default triples" do
          expect(subject.project_graph(graph_name).count).to eql(subject.reject(&:graph_name).count)
        end

        it "should iterate over default triples" do
          subject.project_graph(graph_name) do |statement|
            expect(statement.graph_name).to be_nil
          end
        end
      end

      context "named graph" do
        let(:graph_name) {enumerable.graph_names.first}
        specify {expect(subject.project_graph(graph_name)).to all(be_a_statement)}

        it "should return named triples" do
          expect(subject.project_graph(graph_name).count).to eql(subject.select {|s| s.graph_name == graph_name}.count)
        end

        it "should iterate over named triples" do
          subject.project_graph(graph_name) do |statement|
            expect(statement.graph_name).to eql graph_name
          end
        end
      end

      context "non-existing graph" do
        let(:graph_name) {RDF::URI.new('http://example.org/does/not/have/this/uri')}
        specify {expect(subject.project_graph(graph_name)).to be_empty if @supports_named_graphs}
      end
    end

    its(:each_graph) {is_expected.to be_an_enumerator}

    describe "#each_graph" do
      let(:graph_names) {@statements.map { |s| s.graph_name }.uniq.compact}
      subject { enumerable.each_graph }
      it {is_expected.to be_an_enumerator}
      specify {is_expected.to all(be_a_graph) if @supports_named_graphs}
 
      it "has appropriate number of graphs" do
        if @supports_named_graphs
          graph_names = @statements.map { |s| s.graph_name }.uniq.compact
          expect(subject.to_a.size).to eq (graph_names.size + 1)
        end
      end
    end

    describe "#enum_graph" do
      subject { enumerable.enum_graph }
      it {is_expected.to be_an_enumerator}
      it {is_expected.to be_countable}
      it "enumerates the same as #each_graph" do
        expect(subject.to_a).to include(*enumerable.each_graph.to_a) if @supports_named_graphs # expect with match problematic
      end
    end
  end


  context "when converting" do
    it {is_expected.to respond_to(:to_hash)}
    its(:to_hash) {is_expected.to be_instance_of(Hash)}
    context "#to_hash" do
      it "should have as many keys as subjects" do
        expect(subject.to_hash.keys.size).to eq enumerable.subjects.to_a.size
      end
    end
  end

  context "when dumping" do
    it {is_expected.to respond_to(:dump)}

    it "should implement #dump" do
      expect(subject.dump(:ntriples)).to eq RDF::NTriples::Writer.buffer() {|w| w << enumerable}
    end

    it "raises error on unknown format" do
      expect {subject.dump(:foobar)}.to raise_error(RDF::WriterError, /No writer found/)
    end
  end
end
