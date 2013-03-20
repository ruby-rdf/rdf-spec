require 'rdf/spec'

module RDF_Enumerable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@enumerable+ must be defined in a before(:each) block' unless instance_variable_get('@enumerable')

    @filename   = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'doap.nt'))
    @statements ||= RDF::NTriples::Reader.new(File.open(@filename)).to_a

    if @enumerable.empty?
      if @enumerable.respond_to?(:<<)
        @statements.each { |statement| @enumerable << statement }
      else
        raise "@enumerable must respond to #<< or be pre-populated with the statements in #{@filename} in a before(:each) block"
      end
    end

    @supports_context = @enumerable.respond_to?(:supports?) && @enumerable.supports?(:context)
  end

  describe RDF::Enumerable do
    subject {@enumerable}
    it {should respond_to(:supports?)}
    it {should respond_to(:count)}
    it {should respond_to(:size)}

    it {should respond_to(:statements)}
    it {should respond_to(:has_statement?)}
    it {should respond_to(:each_statement)}
    it {should respond_to(:enum_statement)}

    it {should respond_to(:triples)}
    it {should respond_to(:has_triple?)}
    it {should respond_to(:each_triple)}
    it {should respond_to(:enum_triple)}

    it {should respond_to(:quads)}
    it {should respond_to(:has_quad?)}
    it {should respond_to(:each_quad)}
    it {should respond_to(:enum_quad)}

    it {should respond_to(:subjects)}
    it {should respond_to(:has_subject?)}
    it {should respond_to(:each_subject)}
    it {should respond_to(:enum_subject)}

    it {should respond_to(:predicates)}
    it {should respond_to(:has_predicate?)}
    it {should respond_to(:each_predicate)}
    it {should respond_to(:enum_predicate)}

    it {should respond_to(:objects)}
    it {should respond_to(:has_object?)}
    it {should respond_to(:each_object)}
    it {should respond_to(:enum_object)}

    it {should respond_to(:contexts)}
    it {should respond_to(:has_context?)}
    it {should respond_to(:each_context)}
    it {should respond_to(:enum_context)}

    it {should respond_to(:each_graph)}
    it {should respond_to(:enum_graph)}

    it {should respond_to(:to_hash)}
    it {should respond_to(:dump)}

    it {should be_valid}
    it {should_not be_empty}
    its(:size) {should == @statements.size}
    its(:count) {should == @statements.size}

    it "returns is_invalid if any statement is invalid" do
      if subject.respond_to?(:<<)
        s = RDF::Statement.from([nil, nil, nil])
        s.should_not be_valid
        subject << s
        subject.should_not be_valid
      end
    end

    context "when extending an empty array" do
      subject {[].extend(RDF::Enumerable)}
      it {should be_empty}
      its(:size) {should == 0}
      its(:count) {should == 0}
    end

    describe "#statements" do
      subject {@enumerable.statements}
      it {should be_an_enumerator}
      its(:size) {should == @statements.size}
      it "should iterrate statements" do
        subject.statements.each { |statement| statement.should be_a_statement }
      end
      it "should have all statements" do
        @statements.each do |statement|
          subject.should have_statement(statement)
        end
      end

      it "should not have statements in a different context" do
        if @supports_context
          context = RDF::URI.new("urn:context:1")
          @statements.each do |statement|
            s = statement.dup
            s.context = context
            subject.should_not have_statement(s)
          end
        end
      end

      it "should not have an unknown statement" do
        unknown_statement = RDF::Statement.new(RDF::Node.new, RDF::URI.new("http://example.org/unknown"), RDF::Node.new)
        subject.has_statement?(unknown_statement).should be_false
      end
    end

    describe "#has_statement?" do
      it "has all statements" do
        @statements.each do |statement|
          subject.should have_statement(statement)
        end
      end
    end

    describe "#each_statement" do
      subject {@enumerable.each_statement}
      it {should be_an_enumerator}
      it "should all be statements" do
        subject { |statement| statement.should be_a_statement }
      end
    end

    describe "#enum_statement" do
      subject {@enumerable.enum_statement}
      it {should be_an_enumerator}
      it {should be_countable}
      it {should be_enumerable}
      it {should be_queryable}
      it "should all be statements" do
        subject { |statement| statement.should be_a_statement }
      end
      it "should have all statements" do
        subject.to_a.should == @statements.to_a
      end
    end

    describe "#triples" do
      subject {@enumerable.triples}
      it {should be_an_enumerator}
      it {subject.to_a.size.should == @statements.size}
      it "should all be triples" do
        subject.each {|triple| triple.should be_a_triple}
      end
    end

    describe "#has_triple?" do
      it "has all triples" do
        @statements.each do |statement|
          subject.should have_triple(statement.to_triple)
        end
      end
    end

    describe "#each_triple" do
      subject {@enumerable.each_triple}
      it {should be_an_enumerator}
      it "has all triples" do
        subject do |*triple|
          triple.should be_a_triple
        end
      end
    end

    describe "#enum_triple" do
      subject {@enumerable.enum_triple}
      it {should be_an_enumerator}
      it {should be_countable}
      it "should have all triples" do
        subject.to_a.should == @statements.each_triple.to_a
      end
    end

    describe "#quads" do
      subject {@enumerable.quads}
      it {should be_an_enumerator}
      it {subject.to_a.size.should == @statements.size}
      it "should all be quads" do
        subject.each {|quad| quad.should be_a_quad}
      end
    end

    describe "#has_quad?" do
      it "has all quads" do
        @statements.each do |statement|
          subject.should have_quad(statement.to_quad)
        end
      end
    end

    describe "#each_quad" do
      subject {@enumerable.each_quad}
      it {should be_an_enumerator}
      it "has all quads" do
        subject do |*quad|
          quad.should be_a_quad
        end
      end
    end

    describe "#enum_quad" do
      subject {@enumerable.enum_quad}
      it {should be_an_enumerator}
      it {should be_countable}
      it "should have all triples" do
        subject.to_a.should == @statements.each_quad.to_a
      end
    end

    describe "#subjects" do
      subject {@enumerable.subjects}
      specify {subject.should be_an_enumerator}
      specify {subject.each { |value| value.should be_a_resource }}
      context ":unique => false" do
        subject {@enumerable.subjects(:unique => false)}
        specify {subject.should be_an_enumerator}
        specify {subject.each { |value| value.should be_a_resource }}
      end
    end

    describe "#has_subject?" do
      it "has all subjects" do
        checked = []
        @statements.each do |statement|
          subject.should have_subject(statement.subject) unless checked.include?(statement.subject)
          checked << statement.subject
        end
        uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
        subject.should_not have_subject(uri)
      end
    end

    describe "#each_subject" do
      subject {@enumerable.each_subject}
      it {should be_an_enumerator}
      it "has all subjects" do
        subjects = @statements.map { |s| s.subject }.uniq
        subject.to_a.size.should == subjects.size
        subject do |term|
          term.should be_a_term
          subjects.should include(term)
        end
      end
    end

    describe "#enum_subject" do
      subject {@enumerable.enum_subject}
      it {should be_an_enumerator}
      it {should be_countable}
      it "should have all subjects" do
        subject.to_a.should == @statements.each_subject.to_a
      end
    end

    describe "#predicates" do
      subject {@enumerable.predicates}
      specify {subject.should be_an_enumerator}
      specify {subject.each { |value| value.should be_a_resource }}
      context ":unique => false" do
        subject {@enumerable.predicates(:unique => false)}
        specify {subject.should be_an_enumerator}
        specify {subject.each { |value| value.should be_a_resource }}
      end
    end

    describe "#has_predicate?" do
      it "has all predicates" do
        checked = []
        @statements.each do |statement|
          subject.should have_predicate(statement.predicate) unless checked.include?(statement.predicate)
          checked << statement.predicate
        end
        uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
        subject.should_not have_predicate(uri)
      end
    end

    describe "#each_predicate" do
      subject {@enumerable.each_predicate}
      it {should be_an_enumerator}
      it "has all predicates" do
        predicates = @statements.map { |s| s.predicate }.uniq
        subject.to_a.size.should == predicates.size
        subject do |term|
          term.should be_a_term
          predicates.should include(term)
        end
      end
    end

    describe "#enum_predicate" do
      subject {@enumerable.enum_predicate}
      it {should be_an_enumerator}
      it {should be_countable}
      it "should have all predicates" do
        subject.to_a.should == @statements.each_predicate.to_a
      end
    end

    describe "#objects" do
      subject {@enumerable.objects}
      specify {subject.should be_an_enumerator}
      specify {subject.each { |value| value.should be_a_term }}
      context ":unique => false" do
        subject {@enumerable.objects(:unique => false)}
        specify {subject.should be_an_enumerator}
        specify {subject.each { |value| value.should be_a_term }}
      end
    end

    describe "#has_object?" do
      it "has all objects" do
        checked = []
        @statements.each do |statement|
          subject.should have_object(statement.object) unless checked.include?(statement.object)
          checked << statement.object
        end
        uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
        subject.should_not have_object(uri)
      end
    end

    describe "#each_object" do
      subject {@enumerable.each_object}
      it {should be_an_enumerator}
      it "has all objects" do
        objects = @statements.map { |s| s.object }.uniq
        subject.to_a.size.should == objects.size
        subject do |term|
          term.should be_a_term
          objects.should include(term)
        end
      end
    end

    describe "#enum_object" do
      subject {@enumerable.enum_object}
      it {should be_an_enumerator}
      it {should be_countable}
      it "should have all objects" do
        subject.to_a.should == @statements.each_object.to_a
      end
    end

    describe "#contexts" do
      subject {@enumerable.contexts}
      specify {subject.should be_an_enumerator}
      specify {subject.each { |value| value.should be_a_resource }}
      context ":unique => false" do
        subject {@enumerable.contexts(:unique => false)}
        specify {subject.should be_an_enumerator}
        specify {subject.each { |value| value.should be_a_resource }}
      end
    end

    describe "#has_context?" do
      it "has all contexts" do
        checked = []
        @statements.each do |statement|
          subject.should have_context(statement.context) if statement.has_context?
        end
        uri = RDF::URI.new('http://example.org/does/not/have/this/uri')
        subject.should_not have_context(uri)
      end
    end

    describe "#each_context" do
      subject {@enumerable.each_context}
      it {should be_an_enumerator}
      it "has all contexts" do
        contexts = @statements.map { |s| s.context }.uniq
        contexts.delete nil
        subject.to_a.size.should == contexts.size
        subject do |term|
          term.should be_a_resource
          contexts.should include(term)
        end
      end
    end

    describe "#enum_context" do
      subject {@enumerable.enum_context}
      it {should be_an_enumerator}
      it {should be_countable}
      it "should have all contexts" do
        subject.to_a.should == @statements.each_context.to_a
      end
    end

    describe "#each_graph" do
      subject {@enumerable.each_graph}
      it {should be_an_enumerator}
      it "has all graphs" do
        subject {|value| value.should be_a_graph}
      end
    end

    describe "#enum_graph" do
      subject {@enumerable.enum_graph}
      it {should be_an_enumerator}
      it {should be_countable}
      it "should have all contexts" do
        subject.to_a.should == @statements.each_graph.to_a
      end
    end

    describe "#to_hash" do
      subject {@enumerable.to_hash}
      it {should be_a(Hash)}
      it "should have keys for each subject" do
        subject.keys.size.should == @enumerable.subjects.to_a.size
      end
    end
  
    describe "#dump" do
      subject {@enumerable.dump(:ntriples)}
      it "has N-Triples representation" do
        subject.should == RDF::NTriples::Writer.buffer() {|w| w << @enumerable}
      end
      
      it "raises error on unknown format" do
        lambda {@enumerable.dump(:foobar)}.should raise_error(RDF::WriterError, /No writer found/)
      end
    end

    context "#to_{writer}" do
      it "should write to a writer" do
        writer = mock("writer")
        writer.should_receive(:buffer)
        RDF::Writer.should_receive(:for).with(:a_writer).and_return(writer)
        subject.send(:to_a_writer)
      end
    end

  end
end
