require 'rdf/spec'
require 'spec'

share_as :RDF_Queryable do
  include RDF::Spec::Matchers

  before :each do
    # RDF::Queryable specs care about the contents of this file too much to let someone set it
    @filename = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'etc', 'doap.nt'))
    raise '+@queryable+ must be defined in a before(:each) block' unless instance_variable_get('@queryable')
    raise '+@subject+ must be defined in a before(:each) block' unless instance_variable_get('@subject')
    if @queryable.empty?
      if @queryable.respond_to?(:insert)
        @queryable.insert(*(RDF::NTriples::Reader.new(File.open(@filename)).to_a))
      else
        raise "@queryable must be mutable or pre-populated with the statements in #{@filename} in a before(:each)"
      end
    end
  end

  ##
  # @see RDF::Queryable#query

  it "should respond to #query" do
    @queryable.should respond_to(:query)
  end

  context "#query when called" do
    it "should require an argument" do
      lambda { @queryable.query }.should raise_error(ArgumentError)
    end

    it "should accept a pattern argument" do
      lambda { @queryable.query(RDF::Query::Pattern.new(nil, nil, nil)) }.should_not raise_error(ArgumentError)
      lambda { @queryable.query(RDF::Query::Pattern.new(:s, :p, :o)) }.should_not raise_error(ArgumentError)
    end

    it "should accept a statement argument" do
      lambda { @queryable.query(RDF::Statement.new(nil, nil, nil)) }.should_not raise_error(ArgumentError)
    end

    it "should accept a triple argument" do
      lambda { @queryable.query([nil, nil, nil]) }.should_not raise_error(ArgumentError)
    end

    it "should accept a quad argument" do
      lambda { @queryable.query([nil, nil, nil, nil]) }.should_not raise_error(ArgumentError)
    end

    it "should accept a hash argument" do
      lambda { @queryable.query({}) }.should_not raise_error(ArgumentError)
    end

    it "should not alter a given hash argument" do
      query = {:subject => @subject, :predicate => RDF::DOAP.name, :object => RDF::FOAF.Person}
      original_query = query.dup
      @queryable.query(query)
      query.should == original_query
    end

    it "should reject other kinds of arguments" do
      lambda { @queryable.query(nil) }.should raise_error(ArgumentError)
    end
  end

  context "#query when called with a block" do
    it "should yield statements" do
      @queryable.query([nil, nil, nil]) do |statement|
        statement.should be_a_statement
      end
    end
  end

  context "#query when called without a block" do
    it "should return an enumerator" do
      @queryable.query([nil, nil, nil]).should be_a_kind_of(RDF::Enumerator)
    end

    it "should return an enumerable enumerator" do
      @queryable.query([nil, nil, nil]).should be_a_kind_of(RDF::Enumerable)
    end

    it "should return a queryable enumerator" do
      @queryable.query([nil, nil, nil]).should be_a_kind_of(RDF::Queryable)
    end

    it "should return statements" do
      @queryable.query([nil, nil, nil]).each do |statement|
        statement.should be_a_statement
      end
    end

    it "should return the correct number of results for array queries" do
      @queryable.query([nil, nil, nil]).size.should == File.readlines(@filename).size
      @queryable.query([@subject, nil, nil]).size.should == File.readlines(@filename).grep(/^<http:\/\/rubygems\.org\/gems\/rdf>/).size
      @queryable.query([@subject, RDF::DOAP.name, nil]).size.should == 1
      @queryable.query([@subject, RDF::DOAP.developer, nil]).size.should == @queryable.query([nil, nil, RDF::FOAF.Person]).size
      @queryable.query([nil, nil, RDF::DOAP.Project]).size.should == 1
    end

    it "should return the correct number of results for hash queries" do
      @queryable.query({}).size.should == File.readlines(@filename).size
      @queryable.query(:subject => @subject) .size.should == File.readlines(@filename).grep(/^<http:\/\/rubygems\.org\/gems\/rdf>/).size
      @queryable.query(:subject => @subject, :predicate => RDF::DOAP.name).size.should == 1
      @queryable.query(:subject => @subject, :predicate => RDF::DOAP.developer).size.should == @queryable.query(:object => RDF::FOAF.Person).size
      @queryable.query(:object => RDF::DOAP.Project).size.should == 1
    end
  end

  ##
  # @see RDF::Queryable#query_pattern

  it "should respond to #query_pattern" do
    @queryable.should respond_to(:query_pattern)
  end

  context "#query_pattern when called" do
    it "should require an argument" do
      lambda { @queryable.send(:query_pattern) }.should raise_error(ArgumentError)
    end

    it "should call the given block" do
      called = false
      @queryable.send(:query_pattern, RDF::Query::Pattern.new) do |statement|
        called = true
        break
      end
      called.should be_true
    end

    it "should yield statements" do
      @queryable.send(:query_pattern, RDF::Query::Pattern.new) do |statement|
        statement.should be_a_statement
      end
    end
  end

  ##
  # @see RDF::Queryable#first

  it "should respond to #first" do
    @queryable.should respond_to(:first)
  end

  context "#first" do
    before :all do
      @failing_pattern = [RDF::Node.new] * 3
    end

    it "should be callable without a pattern" do
      lambda { @queryable.first }.should_not raise_error(ArgumentError)
      @queryable.first.should == @queryable.each.first # uses an Enumerator
    end

    it "should return the correct value when the pattern matches" do
      matching_patterns = [[nil, nil, nil], @queryable.each.first]
      matching_patterns.each do |matching_pattern|
        @queryable.first(matching_pattern).should == @queryable.query(matching_pattern).each.first
      end
    end

    it "should return nil when the pattern fails to match anything" do
      @queryable.first(@failing_pattern).should be_nil
    end

    it "should return nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first.should be_nil
      queryable.first(@failing_pattern).should be_nil
    end
  end

  ##
  # @see RDF::Queryable#first_subject

  it "should respond to #first_subject" do
    @queryable.should respond_to(:first_subject)
  end

  context "#first_subject" do
    before :all do
      @failing_pattern = [RDF::Node.new, nil, nil]
    end

    it "should be callable without a pattern" do
      lambda { @queryable.first_subject }.should_not raise_error(ArgumentError)
      @queryable.first_subject.should == @queryable.first.subject
    end

    it "should return the correct value when the pattern matches" do
      matching_patterns = [[nil, nil, nil], [@queryable.first.subject, nil, nil]]
      matching_patterns.each do |matching_pattern|
        @queryable.first_subject(matching_pattern).should == @queryable.query(matching_pattern).first.subject
      end
    end

    it "should return nil when the pattern fails to match anything" do
      @queryable.first_subject(@failing_pattern).should be_nil
    end

    it "should return nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first_subject.should be_nil
      queryable.first_subject(@failing_pattern).should be_nil
    end
  end

  ##
  # @see RDF::Queryable#first_predicate

  it "should respond to #first_predicate" do
    @queryable.should respond_to(:first_predicate)
  end

  context "#first_predicate" do
    before :all do
      @failing_pattern = [nil, RDF::Node.new, nil]
    end

    it "should be callable without a pattern" do
      lambda { @queryable.first_predicate }.should_not raise_error(ArgumentError)
      @queryable.first_predicate.should == @queryable.first.predicate
    end

    it "should return the correct value when the pattern matches" do
      matching_patterns = [[nil, nil, nil], [nil, @queryable.first.predicate, nil]]
      matching_patterns.each do |matching_pattern|
        @queryable.first_predicate(matching_pattern).should == @queryable.query(matching_pattern).first.predicate
      end
    end

    it "should return nil when the pattern fails to match anything" do
      @queryable.first_predicate(@failing_pattern).should be_nil
    end

    it "should return nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first_predicate.should be_nil
      queryable.first_predicate(@failing_pattern).should be_nil
    end
  end

  ##
  # @see RDF::Queryable#first_object

  it "should respond to #first_object" do
    @queryable.should respond_to(:first_object)
  end

  context "#first_object" do
    before :all do
      @failing_pattern = [nil, nil, RDF::Node.new]
    end

    it "should be callable without a pattern" do
      lambda { @queryable.first_object }.should_not raise_error(ArgumentError)
      @queryable.first_object.should == @queryable.first.object
    end

    it "should return the correct value when the pattern matches" do
      matching_patterns = [[nil, nil, nil], [nil, nil, @queryable.first.object]]
      matching_patterns.each do |matching_pattern|
        @queryable.first_object(matching_pattern).should == @queryable.query(matching_pattern).first.object
      end
    end

    it "should return nil when the pattern fails to match anything" do
      @queryable.first_object(@failing_pattern).should be_nil
    end

    it "should return nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first_object.should be_nil
      queryable.first_object(@failing_pattern).should be_nil
    end
  end

  ##
  # @see RDF::Queryable#first_literal

  it "should respond to #first_literal" do
    @queryable.should respond_to(:first_literal)
  end

  context "#first_literal" do
    before :each do
      # FIXME: these tests should be using the provided @queryable, if possible.
      @queryable = RDF::Graph.new do |graph|
        @subject = RDF::Node.new
        graph << [subject, RDF.type, RDF::DOAP.Project]
        graph << [subject, RDF::DC.creator, RDF::URI.new('http://example.org/#jhacker')]
        graph << [subject, RDF::DC.creator, @literal = RDF::Literal.new('J. Random Hacker')]
      end
      @failing_pattern = [nil, nil, RDF::Node.new]
    end

    it "should be callable without a pattern" do
      lambda { @queryable.first_literal }.should_not raise_error(ArgumentError)
      @queryable.first_literal.should == @literal
    end

    it "should return the correct value when the pattern matches" do
      matching_patterns = [[nil, nil, nil], [@subject, nil, nil], [nil, RDF::DC.creator, nil], [nil, nil, @literal]]
      matching_patterns.each do |matching_pattern|
        @queryable.first_literal(matching_pattern).should == @literal
      end
    end

    it "should return nil when the pattern fails to match anything" do
      @queryable.first_literal(@failing_pattern).should be_nil
    end

    it "should return nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first_literal.should be_nil
      queryable.first_literal(@failing_pattern).should be_nil
    end
  end

  ##
  # @see RDF::Queryable#first_value

  it "should respond to #first_value" do
    @queryable.should respond_to(:first_value)
  end

  context "#first_value" do
    before :all do
      @failing_pattern = [nil, nil, RDF::Node.new]
    end

    it "should be callable without a pattern" do
      lambda { @queryable.first_value }.should_not raise_error(ArgumentError)
      @queryable.first_value.should == @queryable.first_literal.value
    end

    it "should return the correct value when the pattern matches" do
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

    it "should return nil when the pattern fails to match anything" do
      @queryable.first_value(@failing_pattern).should be_nil
    end

    it "should return nil when self is empty" do
      queryable = [].extend(RDF::Queryable)
      queryable.first_value.should be_nil
      queryable.first_value(@failing_pattern).should be_nil
    end
  end
end
