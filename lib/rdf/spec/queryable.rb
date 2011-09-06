require 'rdf/spec'

share_as :RDF_Queryable do
  include RDF::Spec::Matchers

  before :each do
    raise '+@queryable+ must be defined in a before(:each) block' unless instance_variable_get('@queryable')

    @doap = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'doap.nq'))
    @doaps = RDF::NQuads::Reader.new(File.open(@doap)).to_a
    @statements = @doaps

    if @queryable.empty?
      if @queryable.respond_to?(:<<)
        @doaps.each { |statement| @queryable << statement }
      else
        raise "@queryable must respond to #<< or be pre-populated with the statements in #{@doap} in a before(:each) block"
      end
    end

    @subject = RDF::URI('http://rubygems.org/gems/rdf')
  end

  ##
  # @see RDF::Queryable#query
  describe "#query" do
    it "should respond to #query" do
      @queryable.should respond_to(:query)
    end

    context "when called" do
      it "requires an argument" do
        lambda { @queryable.query }.should raise_error(ArgumentError)
      end

      it "accepts a pattern argument" do
        lambda { @queryable.query(RDF::Query::Pattern.new(nil, nil, nil)) }.should_not raise_error(ArgumentError)
        lambda { @queryable.query(RDF::Query::Pattern.new(:s, :p, :o)) }.should_not raise_error(ArgumentError)
      end

      it "accepts a statement argument" do
        lambda { @queryable.query(RDF::Statement.new(nil, nil, nil)) }.should_not raise_error(ArgumentError)
      end

      it "accepts a triple argument" do
        lambda { @queryable.query([nil, nil, nil]) }.should_not raise_error(ArgumentError)
      end

      it "accepts a quad argument" do
        lambda { @queryable.query([nil, nil, nil, nil]) }.should_not raise_error(ArgumentError)
      end

      it "accepts a hash argument" do
        lambda { @queryable.query({}) }.should_not raise_error(ArgumentError)
      end

      it "does not alter a given hash argument" do
        query = {:subject => @subject, :predicate => RDF::DOAP.name, :object => RDF::FOAF.Person}
        original_query = query.dup
        @queryable.query(query)
        query.should == original_query
      end

      it "rejects other kinds of arguments" do
        lambda { @queryable.query(nil) }.should raise_error(ArgumentError)
      end

      context "with a block" do
        it "yields statements" do
          @queryable.query([nil, nil, nil]) do |statement|
            statement.should be_a_statement
          end
        end
      end

      context "without a block" do
        it "returns an enumerator" do
          @queryable.query([nil, nil, nil]).should be_an_enumerator
        end

        it "returns an enumerable enumerator" do
          @queryable.query([nil, nil, nil]).should be_enumerable
        end

        it "returns a queryable enumerator" do
          @queryable.query([nil, nil, nil]).should be_queryable
        end

        it "returns statements" do
          @queryable.query([nil, nil, nil]).each do |statement|
            statement.should be_a_statement
          end
        end

        it "returns the correct number of results for array queries" do
          @queryable.query([nil, nil, nil]).size.should == @statements.size
          @queryable.query([@subject, nil, nil]).size.should == File.readlines(@doap).grep(/^<http:\/\/rubygems\.org\/gems\/rdf>/).size
          @queryable.query([RDF::URI("http://ar.to/#self"), nil, nil]).size.should == File.readlines(@doap).grep(/^<http:\/\/ar.to\/\#self>/).size
          @queryable.query([@subject, RDF::DOAP.name, nil]).size.should == 1
          #@queryable.query([@subject, RDF::DOAP.developer, nil]).size.should == @queryable.query([nil, nil, RDF::FOAF.Person]).size # FIXME: assumes too much about the doap.nt data
          @queryable.query([nil, nil, RDF::DOAP.Project]).size.should == 1
        end

        it "returns the correct number of results for hash queries" do
          @queryable.query({}).size.should == @statements.size
          @queryable.query(:subject => @subject) .size.should == File.readlines(@doap).grep(/^<http:\/\/rubygems\.org\/gems\/rdf>/).size
          @queryable.query(:subject => @subject, :predicate => RDF::DOAP.name).size.should == 1
          #@queryable.query(:subject => @subject, :predicate => RDF::DOAP.developer).size.should == @queryable.query(:object => RDF::FOAF.Person).size # FIXME: assumes too much about the doap.nt data
          @queryable.query(:object => RDF::DOAP.Project).size.should == 1
        end
      end

      context "with specific patterns from SPARQL", :pending => true do
        context "triple pattern combinations" do
          it "?s p o" do
            @queryable.query(:predicate => RDF::URI("http://example.org/p"), :object => RDF::Literal.new(1)).to_a.should ==
              [RDF::Statement.new(RDF::URI("http://example.org/xi1"), RDF::URI("http://example.org/p"), 1), RDF::Statement.new(RDF::URI("http://example.org/xi2"), RDF::URI("http://example.org/p"), 1)]
          end

          it "s ?p o" do
            @queryable.query(:subject => RDF::URI("http://example.org/xi2"), :object => RDF::Literal.new(1)).to_a.should ==
              [RDF::Statement.new(RDF::URI("http://example.org/xi2"), RDF::URI("http://example.org/p"), 1)]
          end
        end

        # From data-r2/expr-equals
        context "data/r2/expr-equals" do
          context "graph-1" do
            before(:each) do
              @solutions = @queryable.query(:predicate => RDF::URI("http://example.org/p"), :object => RDF::Literal::Integer.new(1)).to_a
            end

            it "has two solutions" do
              @solutions.count.should == 2
            end

            it "has xi1 as a solution" do
              @solutions.any? {|s| s.subject == RDF::URI("http://example.org/xi1")}.should be_true
            end

            it "has xi2 as a solution" do
              @solutions.any? {|s| s.subject == RDF::URI("http://example.org/xi2")}.should be_true
            end
          end


          context "graph-2" do
            before(:each) do
              @solutions = @queryable.query(:predicate => RDF::URI("http://example.org/p"), :object => RDF::Literal::Double.new("1.0e0")).to_a
            end

            it "has one solution" do
              @solutions.count.should == 1
            end

            it "has xd1 as a solution" do
              @solutions.any? {|s| s.subject == RDF::URI("http://example.org/xd1")}.should be_true
            end
          end
        end
      end
    end
  end

  ##
  # @see RDF::Queryable#query_pattern
  describe "#query_pattern" do
    it "responds to #query_pattern" do
      @queryable.should respond_to(:query_pattern)
    end

    context "when called" do
      it "requires an argument" do
        lambda { @queryable.send(:query_pattern) }.should raise_error(ArgumentError)
      end

      it "yields to the given block" do
        called = false
        @queryable.send(:query_pattern, RDF::Query::Pattern.new) do |statement|
          called = true
          break
        end
        called.should be_true
      end

      it "yields statements" do
        @queryable.send(:query_pattern, RDF::Query::Pattern.new) do |statement|
          statement.should be_a_statement
        end
      end
    
      context "with specific patterns", :pending => true do
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
            @queryable.send(:query_pattern, pattern) {|s| solutions << s}
            solutions.should == result
          end
        end
      end

      context "with context" do
        it "returns statements from all contexts with no context" do
          pattern = RDF::Query::Pattern.new(nil, nil, nil, :context => nil)
          solutions = []
          @queryable.send(:query_pattern, pattern) {|s| solutions << s}
          solutions.size.should == @statements.size
        end

        it "returns statements from named contexts with variable context", :pending => true do
          pattern = RDF::Query::Pattern.new(nil, nil, nil, :context => :c)
          solutions = []
          @queryable.send(:query_pattern, pattern) {|s| solutions << s}
          context_statements = @queryable.statements.select {|st| st.has_context?}.length
          solutions.size.should == context_statements
        end

        it "returns statements from specific context with URI context" do
          pattern = RDF::Query::Pattern.new(nil, nil, nil, :context => RDF::URI("http://ar.to/#self"))
          solutions = []
          @queryable.send(:query_pattern, pattern) {|s| solutions << s}
          solutions.size.should == File.readlines(@doap).grep(/^<http:\/\/ar.to\/\#self>/).size
        end
      end
    end
  end

  ##
  # @see RDF::Queryable#first
  describe "#first" do
    before :all do
      @failing_pattern = [RDF::Node.new] * 3
    end

    it "should respond to #first" do
      @queryable.should respond_to(:first)
    end

    it "returns enumerator without a pattern" do
      lambda { @queryable.first }.should_not raise_error(ArgumentError)
      @queryable.first.should == @queryable.each.first # uses an Enumerator
    end

    it "returns the correct value when the pattern matches" do
      matching_patterns = [[nil, nil, nil], @queryable.each.first]
      matching_patterns.each do |matching_pattern|
        @queryable.first(matching_pattern).should == @queryable.query(matching_pattern).each.first
      end
    end

    it "returns nil when the pattern fails to match anything" do
      @queryable.first(@failing_pattern).should be_nil
    end

    it "returns nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first.should be_nil
      queryable.first(@failing_pattern).should be_nil
    end
  end

  ##
  # @see RDF::Queryable#first_subject
  describe "#first_subject" do
    before :all do
      @failing_pattern = [RDF::Node.new, nil, nil]
    end

    it "should respond to #first_subject" do
      @queryable.should respond_to(:first_subject)
    end

    it "returns enumerator without a pattern" do
      lambda { @queryable.first_subject }.should_not raise_error(ArgumentError)
      @queryable.first_subject.should == @queryable.first.subject
    end

    it "returns the correct value when the pattern matches" do
      matching_patterns = [[nil, nil, nil], [@queryable.first.subject, nil, nil]]
      matching_patterns.each do |matching_pattern|
        @queryable.first_subject(matching_pattern).should == @queryable.query(matching_pattern).first.subject
      end
    end

    it "returns nil when the pattern fails to match anything" do
      @queryable.first_subject(@failing_pattern).should be_nil
    end

    it "returns nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first_subject.should be_nil
      queryable.first_subject(@failing_pattern).should be_nil
    end
  end

  ##
  # @see RDF::Queryable#first_predicate

  describe "#first_predicate" do
    before :all do
      @failing_pattern = [nil, RDF::Node.new, nil]
    end

    it "should respond to #first_predicate" do
      @queryable.should respond_to(:first_predicate)
    end

    it "returns enumerator without a pattern" do
      lambda { @queryable.first_predicate }.should_not raise_error(ArgumentError)
      @queryable.first_predicate.should == @queryable.first.predicate
    end

    it "returns the correct value when the pattern matches" do
      matching_patterns = [[nil, nil, nil], [nil, @queryable.first.predicate, nil]]
      matching_patterns.each do |matching_pattern|
        @queryable.first_predicate(matching_pattern).should == @queryable.query(matching_pattern).first.predicate
      end
    end

    it "returns nil when the pattern fails to match anything" do
      @queryable.first_predicate(@failing_pattern).should be_nil
    end

    it "returns nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first_predicate.should be_nil
      queryable.first_predicate(@failing_pattern).should be_nil
    end
  end

  ##
  # @see RDF::Queryable#first_object

  describe "#first_object" do
    before :all do
      @failing_pattern = [nil, nil, RDF::Node.new]
    end

    it "should respond to #first_object" do
      @queryable.should respond_to(:first_object)
    end

    it "returns enurator without a pattern" do
      lambda { @queryable.first_object }.should_not raise_error(ArgumentError)
      @queryable.first_object.should == @queryable.first.object
    end

    it "returns the correct value when the pattern matches" do
      matching_patterns = [[nil, nil, nil], [nil, nil, @queryable.first.object]]
      matching_patterns.each do |matching_pattern|
        @queryable.first_object(matching_pattern).should == @queryable.query(matching_pattern).first.object
      end
    end

    it "returns nil when the pattern fails to match anything" do
      @queryable.first_object(@failing_pattern).should be_nil
    end

    it "returns nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first_object.should be_nil
      queryable.first_object(@failing_pattern).should be_nil
    end
  end

  ##
  # @see RDF::Queryable#first_literal

  it "returns to #first_literal" do
    @queryable.should respond_to(:first_literal)
  end

  describe "#first_literal" do
    before :each do
      # FIXME: these tests should be using the provided @queryable, if possible.
      @queryable = RDF::Graph.new do |graph|
        @subject = RDF::Node.new
        graph << [@subject, RDF.type, RDF::DOAP.Project]
        graph << [@subject, RDF::DC.creator, RDF::URI.new('http://example.org/#jhacker')]
        graph << [@subject, RDF::DC.creator, @literal = RDF::Literal.new('J. Random Hacker')]
      end
      @failing_pattern = [nil, nil, RDF::Node.new]
    end

    it "returns a literal without a pattern" do
      lambda { @queryable.first_literal }.should_not raise_error(ArgumentError)
      @queryable.first_literal.should == @literal
    end

    it "returns the correct value when the pattern matches" do
      matching_patterns = [[nil, nil, nil], [@subject, nil, nil], [nil, RDF::DC.creator, nil], [nil, nil, @literal]]
      matching_patterns.each do |matching_pattern|
        @queryable.first_literal(matching_pattern).should == @literal
      end
    end

    it "returns nil when the pattern fails to match anything" do
      @queryable.first_literal(@failing_pattern).should be_nil
    end

    it "returns nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first_literal.should be_nil
      queryable.first_literal(@failing_pattern).should be_nil
    end
  end

  ##
  # @see RDF::Queryable#first_value

  describe "#first_value" do
    before :all do
      @failing_pattern = [nil, nil, RDF::Node.new]
    end

    it "should respond to #first_value" do
      @queryable.should respond_to(:first_value)
    end

    it "returns first literal without a pattern" do
      lambda { @queryable.first_value }.should_not raise_error(ArgumentError)
      @queryable.first_value.should == @queryable.first_literal.value
    end

    it "returns the correct value when the pattern matches" do
      matching_patterns = []
      @queryable.each do |statement|
        if statement.object.is_a?(RDF::Literal)
          matching_pattern = [statement.subject, statement.predicate, nil]
          unless matching_patterns.include?(matching_pattern)
            matching_patterns << matching_pattern
            @queryable.first_value(matching_pattern).should == @queryable.first_literal(matching_pattern).value
          end
        end
      end
    end

    it "returns nil when the pattern fails to match anything" do
      @queryable.first_value(@failing_pattern).should be_nil
    end

    it "returns nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first_value.should be_nil
      queryable.first_value(@failing_pattern).should be_nil
    end
  end
end
