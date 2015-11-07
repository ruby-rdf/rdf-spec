require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/literal'

describe RDF::Literal do
  describe RDF::Literal::Boolean do
    it_behaves_like 'RDF::Literal with datatype and grammar', "true", RDF::XSD.boolean
    it_behaves_like 'RDF::Literal equality', "true", true
    it_behaves_like 'RDF::Literal lexical values', "true"
    it_behaves_like 'RDF::Literal canonicalization', RDF::XSD.boolean, [
      %w(true true),
      %w(false false),
      %w(tRuE true),
      %w(FaLsE false),
      %w(1 true),
      %w(0 false)
    ]
    it_behaves_like 'RDF::Literal validation', RDF::XSD.boolean,
      %w(true false tRuE FaLsE 1 0),
      %w(foo 10)
  end

  describe RDF::Literal::Integer do
    it_behaves_like 'RDF::Literal with datatype and grammar', "1", RDF::XSD.integer
    it_behaves_like 'RDF::Literal equality', "1", 1
    it_behaves_like 'RDF::Literal lexical values', "1"
    it_behaves_like 'RDF::Literal canonicalization', RDF::XSD.integer, [
      %w(01 1),
      %w(1  1),
      %w(-1 -1),
      %w(+1 1)
    ]
    it_behaves_like 'RDF::Literal validation', RDF::XSD.integer,
      %w(1 10 100 01 +1 -1),
      %w(foo 10.1 12xyz)
  end

  describe RDF::Literal::DateTime do
    it_behaves_like 'RDF::Literal with datatype and grammar', "2010-01-01T00:00:00Z", RDF::XSD.dateTime
    it_behaves_like 'RDF::Literal equality', "2010-01-01T00:00:00Z", DateTime.parse("2010-01-01T00:00:00Z")
    it_behaves_like 'RDF::Literal lexical values', "2010-01-01T00:00:00Z"
    it_behaves_like 'RDF::Literal canonicalization', RDF::XSD.dateTime, [
      ["2010-01-01T00:00:00Z",      "2010-01-01T00:00:00Z", "12:00:00 AM UTC on Friday, 01 January 2010"],
      ["2010-01-01T00:00:00.0000Z", "2010-01-01T00:00:00Z", "12:00:00 AM UTC on Friday, 01 January 2010"],
      ["2010-01-01T00:00:00",       "2010-01-01T00:00:00", "12:00:00 AM on Friday, 01 January 2010"],
      ["2010-01-01T00:00:00+00:00", "2010-01-01T00:00:00Z", "12:00:00 AM UTC on Friday, 01 January 2010"],
      ["2010-01-01T01:00:00+01:00", "2010-01-01T00:00:00Z", "01:00:00 AM +01:00 on Friday, 01 January 2010"],
      ["2009-12-31T23:00:00-01:00", "2010-01-01T00:00:00Z", "11:00:00 PM -01:00 on Thursday, 31 December 2009"],
      ["-2010-01-01T00:00:00Z",     "-2010-01-01T00:00:00Z","12:00:00 AM UTC on Friday, 01 January -2010"],
      #["2014-09-01T12:13:14.567",   "2014-09-01T12:13:14",  "12:13:14 PM on Monday, 01 September 2014"],
      #["2014-09-01T12:13:14.567Z",   "2014-09-01T12:13:14Z", "12:13:14 PM UTC on Monday, 01 September 2014"],
      #["2014-09-01T12:13:14.567-08:00","2014-09-01T20:13:14Z","12:13:14 PM -08:00 on Monday, 01 September 2014"],
    ]
    it_behaves_like 'RDF::Literal validation', RDF::XSD.dateTime,
      %w(
        2010-01-01T00:00:00Z
        2010-01-01T00:00:00.0000Z
        2010-01-01T00:00:00
        2010-01-01T00:00:00+00:00
        2010-01-01T01:00:00+01:00
        2009-12-31T23:00:00-01:00
        -2010-01-01T00:00:00Z
      ),
      %w(
        foo
        +2010-01-01T00:00:00Z
        2010-01-01T00:00:00FOO
        02010-01-01T00:00:00
        2010-01-01
        2010-1-1T00:00:00
        0000-01-01T00:00:00
        2010-07
        2010
      )
  end
end
