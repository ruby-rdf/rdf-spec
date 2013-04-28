require 'rdf/spec'

module RDF_Writable
  extend RSpec::SharedContext
  include RDF::Spec::Matchers

  before :each do
    raise '+@writable+ must be defined in a before(:each) block' unless instance_variable_get('@writable')

    @filename = RDF::Spec::TRIPLES_FILE
    @statements = RDF::NTriples::Reader.new(File.open(@filename)).to_a

    @supports_context = @writable.respond_to?(:supports?) && @writable.supports?(:context)
  end

  describe RDF::Writable do
    subject {@writable}
    let(:statement) {@statements.detect {|s| s.to_a.all? {|r| r.uri?}}}
    let(:count) {@statements.size}

    it {should be_respond_to(:writable?)}
    its(:writable?) {should == !!subject.writable?}
  
    describe "#<<" do
      it "inserts a reader" do
        pending("writability", :unless => subject.writable?) do
          reader = RDF::NTriples::Reader.new(File.open(@filename)).to_a
          subject << reader
          subject.should have_statement(statement)
          subject.count.should == count
        end
      end

      it "inserts a graph" do
        pending("writability", :unless => subject.writable?) do
          graph = RDF::Graph.new << @statements
          subject << graph
          subject.should have_statement(statement)
          subject.count.should == count
        end
      end

      it "inserts an enumerable" do
        pending("writability", :unless => subject.writable?) do
          enumerable = @statements.dup.extend(RDF::Enumerable)
          subject << enumerable
          subject.should have_statement(statement)
          subject.count.should == count
        end
      end

      it "inserts data responding to #to_rdf" do
        pending("writability", :unless => subject.writable?) do
          mock = double('mock')
          mock.stub(:to_rdf).and_return(@statements)
          subject << mock
          subject.should have_statement(statement)
          subject.count.should == count
        end
      end

      it "inserts a statement" do
        pending("writability", :unless => subject.writable?) do
          subject << statement
          subject.should have_statement(statement)
          subject.count.should == 1
        end
      end

      it "inserts an invalid statement" do
        pending("writability", :unless => subject.writable?) do
          s = RDF::Statement.from([nil, nil, nil])
          s.should_not be_valid
          subject << s
          subject.count.should == 1
        end
      end
    end

    context "when inserting statements" do
      it "should support #insert" do
        pending("writability", :unless => subject.writable?) do
          subject.should respond_to(:insert)
        end
      end

      it "should not raise errors" do
        pending("writability", :unless => subject.writable?) do
          lambda { subject.insert(statement) }.should_not raise_error
        end
      end

      it "should support inserting one statement at a time" do
        pending("writability", :unless => subject.writable?) do
          subject.insert(statement)
          subject.should have_statement(statement)
        end
      end

      it "should support inserting multiple statements at a time" do
        pending("writability", :unless => subject.writable?) do
          subject.insert(*@statements)
        end
      end

      it "should insert statements successfully" do
        pending("writability", :unless => subject.writable?) do
          subject.insert(*@statements)
          subject.count.should == count
        end
      end

      it "should not insert a statement twice" do
        pending("writability", :unless => subject.writable?) do
          subject.insert(statement)
          subject.insert(statement)
          subject.count.should == 1
        end
      end

      it "should treat statements with a different context as distinct" do
        pending("writability", :unless => subject.writable?) do
          s1 = statement.dup
          s1.context = nil
          s2 = statement.dup
          s2.context = RDF::URI.new("urn:context:1")
          s3 = statement.dup
          s3.context = RDF::URI.new("urn:context:2")
          subject.insert(s1)
          subject.insert(s2)
          subject.insert(s3)
          # If contexts are not suported, all three are redundant
          subject.count.should == (@supports_context ? 3 : 1)
        end
      end
    end
  end
end
