require 'rdf/spec'

module RDF_Queryable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@queryable+ must be defined in a before(:each) block' unless instance_variable_get('@queryable')

    @doap = RDF::Spec::QUADS_FILE
    @statements = RDF::Spec.quads

    if @queryable.empty?
      if @queryable.respond_to?(:<<) && (@queryable.writable? rescue true)
        @statements.each { |statement| @queryable << statement }
      else
        raise "@queryable must respond to #<< or be pre-populated with the statements in #{@doap} in a before(:each) block"
      end
    end
  end
  let(:resource) {RDF::URI('http://rubygems.org/gems/rdf')}
  let(:literal) {RDF::Literal.new('J. Random Hacker')}

  describe RDF::Queryable do
    subject {@queryable}
    ##
    # @see RDF::Queryable#query
    describe "#query" do
      it {should respond_to(:query)}

      context "when called" do
        it "requires an argument" do
          expect { subject.query }.to raise_error(ArgumentError)
        end

        it "accepts a pattern argument" do
          expect { subject.query(RDF::Query::Pattern.new(nil, nil, nil)) }.not_to raise_error
          expect { subject.query(RDF::Query::Pattern.new(:s, :p, :o)) }.not_to raise_error
        end

        it "accepts a statement argument" do
          expect { subject.query(RDF::Statement.new(nil, nil, nil)) }.not_to raise_error
        end

        it "accepts a triple argument" do
          expect { subject.query([nil, nil, nil]) }.not_to raise_error
        end

        it "accepts a quad argument" do
          expect { subject.query([nil, nil, nil, nil]) }.not_to raise_error
        end

        it "accepts a hash argument" do
          expect { subject.query({}) }.not_to raise_error
        end

        it "does not alter a given hash argument" do
          query = {:subject => resource, :predicate => RDF::DOAP.name, :object => RDF::FOAF.Person}
          original_query = query.dup
          subject.query(query)
          query.should == original_query
        end

        it "rejects other kinds of arguments" do
          expect { subject.query(nil) }.to raise_error(ArgumentError)
        end

        context "with a block" do
          it "yields statements" do
            subject.query([nil, nil, nil]) do |statement|
              statement.should be_a_statement
            end
          end
        end

        context "without a block" do
          it "returns an enumerator" do
            subject.query([nil, nil, nil]).should be_an_enumerator
          end

          it "returns an enumerable enumerator" do
            subject.query([nil, nil, nil]).should be_enumerable
          end

          it "returns a queryable enumerator" do
            subject.query([nil, nil, nil]).should be_queryable
          end

          it "returns statements" do
            subject.query([nil, nil, nil]).each do |statement|
              statement.should be_a_statement
            end
          end

          it "returns the correct number of results for array queries" do
            subject.query([nil, nil, nil]).size.should == @statements.size
            subject.query([resource, nil, nil]).size.should == File.readlines(@doap).grep(/^<http:\/\/rubygems\.org\/gems\/rdf>/).size
            subject.query([RDF::URI("http://ar.to/#self"), nil, nil]).size.should == File.readlines(@doap).grep(/^<http:\/\/ar.to\/\#self>/).size
            subject.query([resource, RDF::DOAP.name, nil]).size.should == 1
            subject.query([nil, nil, RDF::DOAP.Project]).size.should == 1
          end

          it "returns the correct number of results for hash queries" do
            subject.query({}).size.should == @statements.size
            subject.query(:subject => resource) .size.should == File.readlines(@doap).grep(/^<http:\/\/rubygems\.org\/gems\/rdf>/).size
            subject.query(:subject => resource, :predicate => RDF::DOAP.name).size.should == 1
            subject.query(:object => RDF::DOAP.Project).size.should == 1
          end
        end

        context "with specific patterns from SPARQL" do
          context "triple pattern combinations" do
            it "?s p o" do
              subject.query(:predicate => RDF::URI("http://example.org/p"), :object => RDF::Literal.new(1)).to_a.should ==
                [RDF::Statement.new(RDF::URI("http://example.org/xi1"), RDF::URI("http://example.org/p"), 1), RDF::Statement.new(RDF::URI("http://example.org/xi2"), RDF::URI("http://example.org/p"), 1)]
            end

            it "s ?p o" do
              subject.query(:subject => RDF::URI("http://example.org/xi2"), :object => RDF::Literal.new(1)).to_a.should ==
                [RDF::Statement.new(RDF::URI("http://example.org/xi2"), RDF::URI("http://example.org/p"), 1)]
            end
          end

          # From data-r2/expr-equals
          context "data/r2/expr-equals" do
            context "graph-1" do
              subject {@queryable.query(:predicate => RDF::URI("http://example.org/p"), :object => RDF::Literal::Integer.new(1)).to_a}
              its(:count) {should == 2}

              it "has two solutions" do
                subject.any? {|s| s.subject == RDF::URI("http://example.org/xi1")}.should be_true
              end

              it "has xi2 as a solution" do
                subject.any? {|s| s.subject == RDF::URI("http://example.org/xi2")}.should be_true
              end
            end

            context "graph-2" do
              subject {@queryable.query(:predicate => RDF::URI("http://example.org/p"), :object => RDF::Literal::Double.new("1.0e0")).to_a}
              its(:count) {should == 1}

              it "has xd1 as a solution" do
                subject.any? {|s| s.subject == RDF::URI("http://example.org/xd1")}.should be_true
              end
            end
          end
        end
      end
    end

    ##
    # @see RDF::Queryable#query_pattern
    describe "#query_pattern" do
      it "defines a protected #query_pattern method" do
        subject.class.protected_method_defined?(:query_pattern).should be_true
      end

      context "when called" do
        it "requires an argument" do
          expect { subject.send(:query_pattern) }.to raise_error(ArgumentError)
        end

        it "yields to the given block" do
          called = false
          subject.send(:query_pattern, RDF::Query::Pattern.new) do |statement|
            called = true
            break
          end
          called.should be_true
        end

        it "yields statements" do
          subject.send(:query_pattern, RDF::Query::Pattern.new) do |statement|
            statement.should be_a_statement
          end
        end
    
        context "with specific patterns" do
          # Note that "01" should not match 1, per data-r2/expr-equal/sameTerm
          {
            [RDF::URI("http://example.org/xi1"), RDF::URI("http://example.org/p"), 1] => [RDF::Statement.from([RDF::URI("http://example.org/xi1"), RDF::URI("http://example.org/p"), 1])],
            [RDF::URI("http://example.org/xi1"), RDF::URI("http://example.org/p"), nil] => [RDF::Statement.from([RDF::URI("http://example.org/xi1"), RDF::URI("http://example.org/p"), 1])],
            [RDF::URI("http://example.org/xi1"), nil, 1] => [RDF::Statement.from([RDF::URI("http://example.org/xi1"), RDF::URI("http://example.org/p"), 1])],
            [nil, RDF::URI("http://example.org/p"), 1] => [RDF::Statement.from([RDF::URI("http://example.org/xi1"), RDF::URI("http://example.org/p"), 1]), RDF::Statement.from([RDF::URI("http://example.org/xi2"), RDF::URI("http://example.org/p"), 1])],
            [nil, nil, 1] => [RDF::Statement.from([RDF::URI("http://example.org/xi1"), RDF::URI("http://example.org/p"), 1]), RDF::Statement.from([RDF::URI("http://example.org/xi2"), RDF::URI("http://example.org/p"), 1])],
            [nil, RDF::URI("http://example.org/p"), RDF::Literal::Double.new("1.0e0")] => [RDF::Statement.from([RDF::URI("http://example.org/xd1"), RDF::URI("http://example.org/p"), RDF::Literal::Double.new("1.0e0")])],
          }.each do |pattern, result|
            pattern = RDF::Query::Pattern.from(pattern)
            it "returns #{result.inspect} given #{pattern.inspect}" do
              solutions = []
              subject.send(:query_pattern, pattern) {|s| solutions << s}
              solutions.should == result
            end
          end
        end

        context "with context" do
          it "returns statements from all contexts with no context" do
            pattern = RDF::Query::Pattern.new(nil, nil, nil, :context => nil)
            solutions = []
            subject.send(:query_pattern, pattern) {|s| solutions << s}
            solutions.size.should == @statements.size
          end

          it "returns statements from unnamed contexts with false context" do
            pattern = RDF::Query::Pattern.new(nil, nil, nil, :context => false)
            solutions = []
            subject.send(:query_pattern, pattern) {|s| solutions << s}
            context_statements = subject.statements.reject {|st| st.has_context?}.length
            solutions.size.should == context_statements
          end

          it "returns statements from named contexts with variable context" do
            unless subject.contexts.to_a.empty?
              pattern = RDF::Query::Pattern.new(nil, nil, nil, :context => :c)
              solutions = []
              subject.send(:query_pattern, pattern) {|s| solutions << s}
              context_statements = subject.statements.select {|st| st.has_context?}.length
              solutions.size.should == context_statements
            end
          end

          it "returns statements from specific context with URI context" do
            unless subject.contexts.to_a.empty?
              pattern = RDF::Query::Pattern.new(nil, nil, nil, :context => RDF::URI("http://ar.to/#self"))
              solutions = []
              subject.send(:query_pattern, pattern) {|s| solutions << s}
              solutions.size.should == File.readlines(@doap).grep(/^<http:\/\/ar.to\/\#self>/).size
            end
          end
        end
      end
    end

    ##
    # @see RDF::Queryable#first
    describe "#first" do
      let(:failing_pattern) {[RDF::Node.new] * 3}

      it "should respond to #first" do
        subject.should respond_to(:first)
      end

      it "returns enumerator without a pattern" do
        expect { subject.first }.not_to raise_error
        subject.first.should == subject.each.first # uses an Enumerator
      end

      it "returns the correct value when the pattern matches", :pending => (defined?(RUBY_PLATFORM) && RUBY_PLATFORM == 'java') do
        matching_patterns = [[nil, nil, nil], subject.each.first]
        matching_patterns.each do |matching_pattern|
          subject.first(matching_pattern).should == subject.query(matching_pattern).each.first
        end
      end

      it "returns nil when the pattern fails to match anything" do
        subject.first(failing_pattern).should be_nil
      end

      it "returns nil when self is empty" do
        queryable = [].extend(RDF::Queryable)
        queryable.first.should be_nil
        queryable.first(failing_pattern).should be_nil
      end
    end

    ##
    # @see RDF::Queryable#first_subject
    describe "#first_subject" do
      let(:failing_pattern) {[RDF::Node.new, nil, nil]}

      it "should respond to #first_subject" do
        subject.should respond_to(:first_subject)
      end

      it "returns enumerator without a pattern", :pending => (defined?(RUBY_PLATFORM) && RUBY_PLATFORM == 'java') do
        expect { subject.first_subject }.not_to raise_error
        subject.first_subject.should == subject.first.subject
      end

      it "returns the correct value when the pattern matches", :pending => (defined?(RUBY_PLATFORM) && RUBY_PLATFORM == 'java') do
        matching_patterns = [[nil, nil, nil], [subject.first.subject, nil, nil]]
        matching_patterns.each do |matching_pattern|
          subject.first_subject(matching_pattern).should == subject.query(matching_pattern).first.subject
        end
      end

      it "returns nil when the pattern fails to match anything" do
        subject.first_subject(failing_pattern).should be_nil
      end

      it "returns nil when self is empty" do
        queryable = [].extend(RDF::Queryable)
        queryable.first_subject.should be_nil
        queryable.first_subject(failing_pattern).should be_nil
      end
    end

    ##
    # @see RDF::Queryable#first_predicate

    describe "#first_predicate" do
      let(:failing_pattern) {[nil, RDF::Node.new, nil]}

      it {should respond_to(:first_predicate)}

      it "returns enumerator without a pattern", :pending => (defined?(RUBY_PLATFORM) && RUBY_PLATFORM == 'java') do
        expect { subject.first_predicate }.not_to raise_error
        subject.first_predicate.should == subject.first.predicate
      end

      it "returns the correct value when the pattern matches", :pending => (defined?(RUBY_PLATFORM) && RUBY_PLATFORM == 'java') do
        matching_patterns = [[nil, nil, nil], [nil, subject.first.predicate, nil]]
        matching_patterns.each do |matching_pattern|
          subject.first_predicate(matching_pattern).should == subject.query(matching_pattern).first.predicate
        end
      end

      it "returns nil when the pattern fails to match anything" do
        subject.first_predicate(failing_pattern).should be_nil
      end

      it "returns nil when self is empty" do
        queryable = [].extend(RDF::Queryable)
        queryable.first_predicate.should be_nil
        queryable.first_predicate(failing_pattern).should be_nil
      end
    end

    ##
    # @see RDF::Queryable#first_object

    describe "#first_object" do
      let(:failing_pattern) {[nil, nil, RDF::Node.new]}
      it {should respond_to(:first_object)}

      it "returns enurator without a pattern", :pending => (defined?(RUBY_PLATFORM) && RUBY_PLATFORM == 'java') do
        expect { subject.first_object }.not_to raise_error
        subject.first_object.should == subject.first.object
      end

      it "returns the correct value when the pattern matches", :pending => (defined?(RUBY_PLATFORM) && RUBY_PLATFORM == 'java') do
        matching_patterns = [[nil, nil, nil], [nil, nil, subject.first.object]]
        matching_patterns.each do |matching_pattern|
          subject.first_object(matching_pattern).should == subject.query(matching_pattern).first.object
        end
      end

      it "returns nil when the pattern fails to match anything" do
        subject.first_object(failing_pattern).should be_nil
      end

      it "returns nil when self is empty" do
        queryable = [].extend(RDF::Queryable)
        queryable.first_object.should be_nil
        queryable.first_object(failing_pattern).should be_nil
      end
    end

    ##
    # @see RDF::Queryable#first_literal

    describe "#first_literal" do
      let(:failing_pattern) {[nil, nil, RDF::Node.new]}
      let(:resource) {RDF::Node.new}
      subject {
        RDF::Graph.new do |graph|
          graph << [resource, RDF.type, RDF::DOAP.Project]
          graph << [resource, RDF::DC.creator, RDF::URI.new('http://example.org/#jhacker')]
          graph << [resource, RDF::DC.creator, literal]
        end
      }
      it {should respond_to(:first_literal)}

      it "returns a literal without a pattern" do
        expect { subject.first_literal }.not_to raise_error
        subject.first_literal.should == literal
      end

      it "returns the correct value when the pattern matches" do
        matching_patterns = [[nil, nil, nil], [resource, nil, nil], [nil, RDF::DC.creator, nil], [nil, nil, literal]]
        matching_patterns.each do |matching_pattern|
          subject.first_literal(matching_pattern).should == literal
        end
      end

      it "returns nil when the pattern fails to match anything" do
        subject.first_literal(failing_pattern).should be_nil
      end

      it "returns nil when self is empty" do
        queryable = [].extend(RDF::Queryable)
        queryable.first_literal.should be_nil
        queryable.first_literal(failing_pattern).should be_nil
      end
    end

    ##
    # @see RDF::Queryable#first_value

    describe "#first_value" do
      let(:failing_pattern) {[nil, nil, RDF::Node.new]}
      it {should respond_to(:first_value)}

      it "returns first literal without a pattern" do
        expect { subject.first_value }.not_to raise_error
        subject.first_value.should == subject.first_literal.value
      end

      it "returns the correct value when the pattern matches" do
        matching_patterns = []
        subject.each do |statement|
          if statement.object.is_a?(RDF::Literal)
            matching_pattern = [statement.subject, statement.predicate, nil]
            unless matching_patterns.include?(matching_pattern)
              matching_patterns << matching_pattern
              subject.first_value(matching_pattern).should == subject.first_literal(matching_pattern).value
            end
          end
        end
      end

      it "returns nil when the pattern fails to match anything" do
        subject.first_value(failing_pattern).should be_nil
      end

      it "returns nil when self is empty" do
        queryable = [].extend(RDF::Queryable)
        queryable.first_value.should be_nil
        queryable.first_value(failing_pattern).should be_nil
      end
    end
  end
end
