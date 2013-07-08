require 'rdf/spec'

module RDF_Enumerable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@enumerable+ must be defined in a before(:each) block' unless instance_variable_get('@enumerable')

    @statements ||= RDF::Spec.quads

    if @enumerable.empty?
      if @enumerable.respond_to?(:<<) && (@enumerable.writable? rescue true)
        @statements.each { |statement| @enumerable << statement }
      else
        raise "@enumerable must respond to #<< or be pre-populated with the statements in #{RDF::Spec::TRIPLES_FILE} in a before(:each) block"
      end
    end

    @supports_context = @enumerable.supports?(:context) rescue true
  end

  describe RDF::Enumerable do
    let(:subject_count) {@statements.map(&:subject).uniq.length}
    let(:bnode_subject_count) {@statements.map(&:subject).uniq.select(&:node?).length}
    let(:non_bnode_statements) {@statements.reject {|s| s.subject.node? || s.object.node?}}

    subject {@enumerable}
    it {should respond_to(:supports?)}

    describe "valid?" do
      it {should be_valid}
      
      it "returns false if any statement is invalid" do
        if subject.respond_to?(:<<) && (subject.writable? rescue true)
          s = RDF::Statement.from([nil, nil, nil])
          s.should_not be_valid
          subject << s
          subject.should_not be_valid
        else
          pending("can't add statement to immutable enumerable")
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
        specify {subject.statements.to_a.size.should == @statements.size}
        specify {subject.statements.each { |statement| statement.should be_a_statement }}
      end

      it {should respond_to(:has_statement?)}
      context "#has_statement?" do
        let(:unknown_statement) {RDF::Statement.new(RDF::Node.new, RDF::URI.new("http://example.org/unknown"), RDF::Node.new)}
        it "should have all statements" do
          # Don't check for BNodes, as equivalence depends on their being exactly the same, not just the same identifier. If subject is loaded separately, these won't match.
          non_bnode_statements.each do |statement|
            subject.has_statement?(statement).should be_true
          end
        end

        it "does not have statement in different context" do
          if @supports_context
            context = RDF::URI.new("urn:context:1")
            non_bnode_statements.each do |statement|
              s = statement.dup
              s.context = context
              subject.has_statement?(s).should be_false
            end
          end
        end

        it "does not have an unknown statement" do
          subject.has_statement?(unknown_statement).should be_false
        end
      end

      it {should respond_to(:each_statement)}
      its(:each_statement) {should be_an_enumerator}
      it "should implement #each_statement" do
        subject.each_statement { |statement| statement.should be_a_statement }
      end

      it {should respond_to(:enum_statement)}
      its(:enum_statement) {should be_an_enumerator}
      its(:enum_statement) {should be_countable}
      its(:enum_statement) {should be_enumerable}
      its(:enum_statement) {should be_queryable}
      context "#enum_statement" do
        it "should enumerate all statements" do
          subject.enum_statement.to_a.should =~ @enumerable.each_statement.to_a
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
        specify {subject.triples.to_a.size.should == @statements.size}
        specify {subject.triples.each { |triple| triple.should be_a_triple }}
      end

      context "#has_triple?" do
        specify do
          non_bnode_statements.each do |statement|
            subject.has_triple?(statement.to_triple).should be_true
          end
        end
      end

      its(:each_triple) {should be_an_enumerator}
      context "#each_triple" do
        specify {subject.each_triple { |*triple| triple.should be_a_triple }}
      end

      its(:enum_triple) {should be_an_enumerator}
      its(:enum_triple) {should be_countable}
      context "#enum_triple" do
        it "should enumerate all triples" do
          subject.enum_triple.to_a.should =~ @enumerable.each_triple.to_a
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
        specify {subject.quads.to_a.size.should == @statements.size}
        specify {subject.quads.each { |quad| quad.should be_a_quad }}
      end

      context "#has_quad?" do
        specify do
          if @supports_context
            non_bnode_statements.each do |statement|
              subject.has_quad?(statement.to_quad).should be_true
            end
          end
        end
      end

      its(:each_quad) {should be_an_enumerator}
      context "#each_quad" do
        specify {subject.each_quad {|*quad| quad.should be_a_quad }}
      end

      its(:enum_quad) {should be_an_enumerator}
      its(:enum_quad) {should be_countable}
      context "#enum_quad" do
        it "should enumerate all quads" do
          subject.enum_quad.to_a.should =~ @enumerable.each_quad.to_a
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
        subject {@enumerable.subjects}
        specify {subject.should be_an_enumerator}
        specify {subject.each { |value| value.should be_a_resource }}
        context ":unique => false" do
          subject {@enumerable.subjects(:unique => false)}
          specify {subject.should be_an_enumerator}
          specify {subject.each { |value| value.should be_a_resource }}
        end
      end

      context "#has_subject?" do
        specify do
          checked = []
          non_bnode_statements.each do |statement|
            @enumerable.has_subject?(statement.subject).should be_true unless checked.include?(statement.subject)
            checked << statement.subject
          end
          uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
          @enumerable.has_subject?(uri).should be_false
        end
      end

      its(:each_subject) {should be_an_enumerator}
      context "#each_subject" do
        specify {subject.each_subject.reject(&:node?).size.should == subjects.size}
        specify {subject.each_subject {|value| value.should be_a_resource}}
        specify {subject.each_subject {|value| subjects.should include(value) unless value.node?}}
      end

      its(:enum_subject) {should be_an_enumerator}
      its(:enum_subject) {should be_countable}
      context "#enum_subject" do
        it "should enumerate all subjects" do
          subject.enum_subject.reject(&:node?).should =~ subjects
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
        subject {@enumerable.predicates}
        specify {subject.should be_an_enumerator}
        specify {subject.each { |value| value.should be_a_uri }}
        context ":unique => false" do
          subject {@enumerable.predicates(:unique => false)}
          specify {subject.should be_an_enumerator}
          specify {subject.each { |value| value.should be_a_uri }}
        end
      end

      context "#has_predicate?" do
        specify do
          checked = []
          @statements.each do |statement|
            @enumerable.has_predicate?(statement.predicate).should be_true unless checked.include?(statement.predicate)
            checked << statement.predicate
          end
          uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
          @enumerable.has_predicate?(uri).should be_false
        end
      end

      its(:each_predicate) {should be_an_enumerator}
      context "#each_predicate" do
        specify {subject.each_predicate.to_a.size.should == predicates.size}
        specify {subject.each_predicate {|value| value.should be_a_uri}}
        specify {subject.each_predicate {|value| predicates.should include(value)}}
      end

      its(:enum_predicate) {should be_an_enumerator}
      its(:enum_predicate) {should be_countable}
      context "#enum_predicate" do
        it "should enumerate all predicates" do
          subject.enum_predicate.to_a.should =~ predicates
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
        subject {@enumerable.objects}
        specify {subject.should be_an_enumerator}
        specify {subject.each { |value| value.should be_a_term }}
        context ":unique => false" do
          subject {@enumerable.objects(:unique => false)}
          specify {subject.should be_an_enumerator}
          specify {subject.each { |value| value.should be_a_term }}
        end
      end

      context "#has_object?" do
        specify do
          checked = []
          non_bnode_statements.each do |statement|
            @enumerable.has_object?(statement.object).should be_true unless checked.include?(statement.object)
            checked << statement.object
          end
          uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
          @enumerable.has_object?(uri).should be_false
        end
      end

      its(:each_object) {should be_an_enumerator}
      context "#each_object" do
        specify {subject.each_object.reject(&:node?).size.should == objects.size}
        specify {subject.each_object {|value| value.should be_a_term}}
        specify {subject.each_object {|value| objects.should include(value) unless value.node?}}
      end

      its(:enum_object) {should be_an_enumerator}
      its(:enum_object) {should be_countable}
      context "#enum_object" do
        it "should enumerate all objects" do
          subject.enum_object.reject(&:node?).should =~ objects
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
        subject {@enumerable.contexts}
        specify {subject.should be_an_enumerator}
        it "values should be resources" do
          subject.each { |value| value.should be_a_resource }
        end
        context ":unique => false" do
          subject {@enumerable.contexts(:unique => false)}
          specify {subject.should be_an_enumerator}
          it "values should be resources" do
            subject.each { |value| value.should be_a_resource }
          end
        end
      end

      it "should implement #has_context?" do
        if @supports_context
          @statements.each do |statement|
            if statement.has_context?
              @enumerable.has_context?(statement.context).should be_true
            end
          end
          uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
          @enumerable.has_context?(uri).should be_false
        end
      end

      its(:each_context) {should be_an_enumerator}
      context "#each_context" do
        let(:contexts) {@statements.map { |s| s.context }.uniq.compact}
        it "has appropriate number of contexts" do
          if @supports_context
            subject.each_context.to_a.size.should == contexts.size
          end
        end
        it "values should be resources" do
          subject.each_context {|value| value.should be_a_resource}
        end
        it "should have all contexts" do
          subject.each_context {|value| contexts.should include(value)}
        end
      end

      its(:enum_context) {should be_an_enumerator}
      its(:enum_context) {should be_countable}
      context "#enum_context" do
        it "should enumerate all contexts" do
          subject.enum_context.to_a.should =~ @enumerable.each_context.to_a
        end
      end
    end

    context "when enumerating graphs" do
      it {should respond_to(:each_graph)}
      it {should respond_to(:enum_graph)}

      describe "#each_graph" do
        subject {@enumerable.each_graph}
        it {should be_an_enumerator}
        specify {subject.each { |value| value.should be_a_graph }}
      end

      describe "#enum_graph" do
        subject {@enumerable.enum_graph}
        it {subject.should be_an_enumerator}
        it {subject.should be_countable}
        it "enumerates the same as #each_graph" do
          subject.to_a.should =~ @enumerable.each_graph.to_a
        end
      end
    end

    context "when converting" do
      it {should respond_to(:to_hash)}
      its(:to_hash) {should be_instance_of(Hash)}
      context "#to_hash" do
        it "should have as many keys as subjects" do
          subject.to_hash.keys.size.should == @enumerable.subjects.to_a.size
        end
      end
    end
  
    context "when dumping" do
      it {should respond_to(:dump)}
    
      it "should implement #dump" do
        subject.dump(:ntriples).should == RDF::NTriples::Writer.buffer() {|w| w << @enumerable}
      end
    
      it "raises error on unknown format" do
        expect {subject.dump(:foobar)}.to raise_error(RDF::WriterError, /No writer found/)
      end
    end
  end
end
