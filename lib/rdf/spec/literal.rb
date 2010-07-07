# coding: utf-8
require 'rdf'
require 'rdf/spec'

share_as :RDF_Literal do
  XSD = RDF::XSD

  before :each do
    raise '+@new+ must be defined in a before(:each) block' unless instance_variable_get('@new')
  end

  context "plain literals" do
    before :each do
      @empty = @new.call('')
      @hello = @new.call('Hello')
      @all   = [@empty, @hello]
    end

    it "should be instantiable" do
      lambda { @new.call('') }.should_not raise_error
      @all.each do |literal|
        literal.plain?.should be_true
      end
    end

    it "should not have a language" do
      @all.each do |literal|
        literal.language.should be_nil
      end
    end

    it "should not have a datatype" do
      @all.each do |literal|
        literal.typed?.should be_false
        literal.datatype.should be_nil
      end
    end

    it "should support equality comparisons" do
      @all.each do |literal|
        copy = @new.call(literal.value)
        literal.should eql(copy)
        literal.should == copy

        literal.should_not eql(literal.value)
        literal.should == literal.value # FIXME
      end
    end

    it "should have a string representation" do
      @empty.to_s.should eql("")
      @hello.to_s.should eql("Hello")
    end

    it "should not be #anonymous?" do
      @hello.should_not be_anonymous
    end
  end

  context "languaged-tagged literals" do
    before :each do
      @empty = @new.call('', :language => :en)
      @hello = @new.call('Hello', :language => :en)
      @all   = [@empty, @hello]
    end

    it "should be instantiable" do
      lambda { @new.call('', :language => :en) }.should_not raise_error
    end

    it "should have a language" do
      @all.each do |literal|
        literal.language.should_not be_nil
        literal.language.should == :en
      end
    end

    it "should not have a datatype" do
      @all.each do |literal|
        literal.typed?.should be_false
        literal.datatype.should be_nil
      end
    end

    it "should support equality comparisons" do
      @all.each do |literal|
        copy = @new.call(literal.value, :language => literal.language)
        literal.should eql(copy)
        literal.should == copy
      end
    end

    it "should have a string representation" do
      @empty.to_s.should eql("")
      @hello.to_s.should eql("Hello")
    end
    
    context "c18n" do
      it "should normalize language to lower-case" do
        @new.call('Upper', :language => :EN, :canonicalize => true).language.should == :en
      end
    
      it "should support sub-taged language specification" do
        @new.call('Hi', :language => :"en-us", :canonicalize => true).language.should == :"en-us"
      end
    end
  end

  context "datatyped literals" do
    require 'date'

    before :each do
      @string   = @new.call('')
      @false    = @new.call(false)
      @true     = @new.call(true)
      @int      = @new.call(123)
      @long     = @new.call(9223372036854775807)
      @double   = @new.call(3.1415)
      @date     = @new.call(Date.new(2010))
      @datetime = @new.call(DateTime.new(2010))
      @time     = @new.call(Time.parse('01:02:03Z'))
      @all      = [@false, @true, @int, @long, @double, @time, @date, @datetime]
    end

    it "should be instantiable" do
      lambda { @new.call(123) }.should_not raise_error
      lambda { @new.call(123, :datatype => XSD.int) }.should_not raise_error
    end

    it "should not have a language" do
      @all.each do |literal|
        literal.language.should be_nil
      end
    end

    it "should have a datatype" do
      @all.each do |literal|
        literal.typed?.should be_true
        literal.datatype.should_not be_nil
      end
    end

    it "should support implicit datatyping" do
      @string.datatype.should == nil
      @false.datatype.should == XSD.boolean
      @true.datatype.should == XSD.boolean
      @int.datatype.should == XSD.integer
      @long.datatype.should == XSD.integer
      @double.datatype.should == XSD.double
      @date.datatype.should == XSD.date
      @datetime.datatype.should == XSD.dateTime
      @time.datatype.should == XSD.time
    end

    it "should support equality comparisons" do
      @all.each do |literal|
        copy = @new.call(literal.value, :datatype => literal.datatype)
        literal.should eql(copy)
        literal.should == copy
      end
    end

    it "should have a string representation" do
      @false.to_s.should eql("false")
      @true.to_s.should eql("true")
      @int.to_s.should eql("123")
      @long.to_s.should eql("9223372036854775807")
      @double.to_s.should eql("3.1415")
      @date.to_s.should eql("2010-01-01Z")
      @datetime.to_s.should eql("2010-01-01T00:00:00Z")
      @time.to_s.should eql("01:02:03Z")
    end
    
    it "should have an object representation" do
      @false.object.should eql(false)
      @true.object.should eql(true)
      @int.object.should eql(123)
      @long.object.should eql(9223372036854775807)
      @double.object.should eql(3.1415)
      @date.object.should eql(Date.new(2010))
      @datetime.object.should eql(DateTime.new(2010))
      @time.object.should eql(Time.parse('01:02:03Z'))
    end
  end

  #require 'nokogiri' rescue nil
  describe "XML Literal" do
    describe "with no namespace" do
      subject { @new.call("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral) }
      it "should indicate xmlliteral?" do
        subject.xmlliteral?.should == true
      end
      
      describe "encodings" do
        it "should return n3" do subject.to_s.should == "\"foo <sup>bar</sup> baz!\"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>" end
      end
      
      it "should be equal if they have the same contents" do
        should == @new.call("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral)
      end

      it "should be a XMLLiteral encoding" do
        subject.datatype.should == RDF.XMLLiteral
      end
    end
      
    describe "with a namespace" do
      subject {
        @new.call("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral,
                      :namespaces => {"dc" => RDF::DC.to_s})
      }
    
      describe "encodings" do
        it "should return n3" do subject.to_s.should == "\"foo <sup>bar</sup> baz!\"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>" end
      end
      
      describe "and language" do
        subject {
          @new.call("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral,
                        :namespaces => {"dc" => RDF::DC.to_s},
                        :language => :fr)
        }

        describe "encodings" do
          it "should return n3" do subject.to_s.should == "\"foo <sup xml:lang=\\\"fr\\\">bar</sup> baz!\"\^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>" end
        end
      end
      
      describe "and language with an existing language embedded" do
        subject {
          @new.call("foo <sup>bar</sup><sub xml:lang=\"en\">baz</sub>",
                        :datatype => RDF.XMLLiteral,
                        :language => :fr)
        }

        describe "encodings" do
          it "should return n3" do subject.to_s.should == "\"foo <sup xml:lang=\\\"fr\\\">bar</sup><sub xml:lang=\\\"en\\\">baz</sub>\"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>" end
        end
      end
    end
    
    describe "with a default namespace" do
      subject {
        R@new.call("foo <sup>bar</sup> baz!", :datatype => RDF.XMLLiteral,
                      :namespaces => {"" => RDF::DC.to_s})
      }
    
      describe "encodings" do
        it "should return n3" do subject.to_s.should == "\"foo <sup xmlns=\\\"http://purl.org/dc/terms/\\\">bar</sup> baz!\"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral>" end
      end
    end
    
    describe "with multiple namespaces" do
      subject {
        @new.call("foo <sup xmlns:dc=\"http://purl.org/dc/terms/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">bar</sup> baz!", :datatype => RDF.XMLLiteral)
      }
      it "should ignore namespace order" do
        g = @new.call("foo <sup xmlns:dc=\"http://purl.org/dc/terms/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">bar</sup> baz!", :datatype => RDF.XMLLiteral)
        should == g
      end
    end
  end if defined?(::Nokogiri)
  
  context "validation and c18n" do
    {
      "true"  => "true",
      "false" => "false",
      "tRuE"  => "true",
      "FaLsE" => "false",
      "1"     => "true",
      "0"     => "false",
    }.each_pair do |lit, str|
      it "should validate boolean '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.boolean).valid?.should be_true
      end

      it "should not canonicalize boolean '#{lit}' by default" do
        @new.call(lit, :datatype => RDF::XSD.boolean, :canonicalize => false).to_s.should == lit
      end

      it "should canonicalize boolean '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.boolean, :canonicalize => true).to_s.should == str
      end
    end

    {
      "01" => "1",
      "1"  => "1",
      "-1" => "-1",
      "+1" => "1",
    }.each_pair do |lit, str|
      it "should validate integer '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.integer).valid?.should be_true
      end

      it "should not canonicalize integer '#{lit}' by default" do
        @new.call(lit, :datatype => RDF::XSD.integer, :canonicalize => false).to_s.should == lit
      end

      it "should canonicalize integer '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.integer, :canonicalize => true).to_s.should == str
      end
    end

    {
      "1"                              => "1.0",
      "-1"                             => "-1.0",
      "1."                             => "1.0",
      "1.0"                            => "1.0",
      "1.00"                           => "1.0",
      "+001.00"                        => "1.0",
      "123.456"                        => "123.456",
      "2.345"                          => "2.345",
      "1.000000000"                    => "1.0",
      "2.3"                            => "2.3",
      "2.234000005"                    => "2.234000005",
      "2.2340000000000005"             => "2.2340000000000005",
      "2.23400000000000005"            => "2.234",
      "2.23400000000000000000005"      => "2.234",
      "1.2345678901234567890123457890" => "1.2345678901234567",
    }.each_pair do |lit, str|
      it "should validate decimal '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.decimal).valid?.should be_true
      end

      it "should not canonicalize decimal '#{lit}' by default" do
        @new.call(lit, :datatype => RDF::XSD.decimal, :canonicalize => false).to_s.should == lit
      end

      it "should canonicalize decimal '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.decimal, :canonicalize => true).to_s.should == str
      end
    end
  
    {
      "1"         => "1.0E0",
      "-1"        => "-1.0E0",
      "+01.000"   => "1.0E0",
      #"1."        => "1.0E0",
      "1.0"       => "1.0E0",
      "123.456"   => "1.23456E2",
      "1.0e+1"    => "1.0E1",
      "1.0e-10"   => "1.0E-10",
      "123.456e4" => "1.23456E6",
    }.each_pair do |lit, str|
      it "should validate double '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.double).valid?.should be_true
      end

      it "should not canonicalize double '#{lit}' by default" do
        @new.call(lit, :datatype => RDF::XSD.double, :canonicalize => false).to_s.should == lit
      end

      it "should canonicalize double '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.double, :canonicalize => true).to_s.should == str
      end
    end
    
    # DateTime
    {
      "2010-01-01T00:00:00Z"      => "2010-01-01T00:00:00Z",
      "2010-01-01T00:00:00.0000Z" => "2010-01-01T00:00:00Z",
      "2010-01-01T00:00:00"       => "2010-01-01T00:00:00Z",
      "2010-01-01T00:00:00+00:00" => "2010-01-01T00:00:00Z",
      "2010-01-01T01:00:00+01:00" => "2010-01-01T01:00:00+01:00",
      "2009-12-31T23:00:00-01:00" => "2009-12-31T23:00:00-01:00",
      "-2010-01-01T00:00:00Z"     => "-2010-01-01T00:00:00Z",
    }.each_pair do |lit, str|
      it "should validate dateTime '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.dateTime).valid?.should be_true
      end

      it "should not canonicalize dateTime '#{lit}' by default" do
        @new.call(lit, :datatype => RDF::XSD.dateTime, :canonicalize => false).to_s.should == lit
      end

      it "should canonicalize dateTime '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.dateTime, :canonicalize => true).to_s.should == str
      end
    end
    
    # Date
    {
      "2010-01-01Z"      => "2010-01-01Z",
      "2010-01-01"       => "2010-01-01Z",
      "2010-01-01+00:00" => "2010-01-01Z",
      "2010-01-01+01:00" => "2010-01-01Z",
      "2009-12-31-01:00" => "2009-12-31Z",
      "-2010-01-01Z"     => "-2010-01-01Z",
    }.each_pair do |lit, str|
      it "should validate date '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.date).valid?.should be_true
      end

      it "should not canonicalize date '#{lit}' by default" do
        @new.call(lit, :datatype => RDF::XSD.date, :canonicalize => false).to_s.should == lit
      end

      it "should canonicalize date '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.date, :canonicalize => true).to_s.should == str
      end
    end
    
    
    # Time
    {
      "00:00:00Z"      => "00:00:00Z",
      "00:00:00.0000Z" => "00:00:00Z",
      "00:00:00"       => "00:00:00Z",
      "00:00:00+00:00" => "00:00:00Z",
      "01:00:00+01:00" => "00:00:00Z",
      "23:00:00-01:00" => "00:00:00Z",
    }.each_pair do |lit, str|
      it "should validate time '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.time).valid?.should be_true
      end

      it "should not canonicalize dateTime '#{lit}' by default" do
        @new.call(lit, :datatype => RDF::XSD.time, :canonicalize => false).to_s.should == lit
      end

      it "should canonicalize dateTime '#{lit}'" do
        @new.call(lit, :datatype => RDF::XSD.time, :canonicalize => true).to_s.should == str
      end
    end
    
    # Invalid
    {
      "foo"                    => RDF::XSD.boolean,
      "xyz"                    => RDF::XSD.integer,
      "12xyz"                  => RDF::XSD.integer,
      "12.xyz"                 => RDF::XSD.decimal,
      "xy.z"                   => RDF::XSD.double,
      "+1.0z"                  => RDF::XSD.double,

      "+2010-01-01T00:00:00Z"  => RDF::XSD.dateTime,
      "2010-01-01T00:00:00FOO" => RDF::XSD.dateTime,
      "02010-01-01T00:00:00"   => RDF::XSD.dateTime,
      "2010-01-01"            => RDF::XSD.dateTime,
      "2010-1-1T00:00:00"     => RDF::XSD.dateTime,
      "0000-01-01T00:00:00" => RDF::XSD.dateTime,

      "+2010-01-01Z"  => RDF::XSD.date,
      "2010-01-01TFOO" => RDF::XSD.date,
      "02010-01-01"   => RDF::XSD.date,
      "2010-1-1"     => RDF::XSD.date,
      "0000-01-01" => RDF::XSD.date,

      "+00:00:00Z" => RDF::XSD.time,
      "-00:00:00Z" => RDF::XSD.time,
    }.each_pair do |value, datatype|
      it "should detect invalid encoding for '#{value}'" do
        @new.call(value, :datatype => datatype).valid?.should be_false
      end
    end
  end
end
