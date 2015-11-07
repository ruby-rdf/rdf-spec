# RSpec Extensions for RDF.rb

This is an [RDF.rb][] extension that provides RDF-specific [RSpec][] matchers
and shared examples for Ruby projects that use RDF.rb and RSpec.

* <http://github.com/ruby-rdf/rdf-spec>

[![Gem Version](https://badge.fury.io/rb/rdf-spec.png)](http://badge.fury.io/rb/rdf-spec)
[![Build Status](https://travis-ci.org/ruby-rdf/rdf-spec.png?branch=master)](http://travis-ci.org/ruby-rdf/rdf-spec)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-spec/badge.svg)](https://coveralls.io/r/ruby-rdf/rdf-spec)

## Documentation

* {RDF::Spec}
  * {RDF::Spec::Matchers}

Shared specs are implemented in modules which typically require that an instance be defined in a class variable in a `before(:each)` block. For example, an class implementing `RDF::Countable` could test this behavior by defining `@countable` as an instance variable and including `RDF_Countable` as follows:

    describe RDF::Enumerable do
      before :each do
        # The available reference implementations are `RDF::Repository` and
        # `RDF::Graph`, but a plain Ruby array will do fine as well:
        @enumerable = RDF::Spec.quads.dup.extend(RDF::Enumerable)
      end

      # @see lib/rdf/spec/enumerable.rb in rdf-spec
      include RDF_Enumerable
    end

Note that in most cases, if the instance is empty and mutable, the appropriate statements will be added. When testing a non-mutable instance, the data must be pre-loaded.

## Dependencies

* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.3.1)
* [RSpec](http://rubygems.org/gems/rspec) (>= 2.1.0)

## Installation

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of the `RDF::Spec` gem, do:

    % [sudo] gem install rdf-spec

## Download

To get a local working copy of the development repository, do:

    % git clone git://github.com/ruby-rdf/rdf-spec.git

Alternatively, download the latest development version as a tarball as
follows:

    % wget http://github.com/ruby-rdf/rdf-spec/tarball/master

## Authors

* [Arto Bendiken](http://github.com/bendiken) - <http://ar.to/>
* [Ben Lavender](http://github.com/bhuga) - <http://bhuga.net/>
* [Gregg Kellogg](http://github.com/gkellogg) - <http://greggkellogg.net/>

## Contributors

* [John Fieber](http://github.com/jfieber) - <http://github.com/jfieber>
* [Tom Johnson](https://github.com/no-reply) - <https://github.com/no-reply>

## Contributing

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do refer to the [RubySpec Style Guide][RubySpec] for best practices.
* Don't touch the `.gemspec` or `VERSION` files. If you need to change them,
  do so on your private branch only.
* Do feel free to add yourself to the `CONTRIBUTORS` file and the
  corresponding list in the the `README`. Alphabetical order applies.
* Don't touch the `AUTHORS` file. If your contributions are significant
  enough, be assured we will eventually add you in there.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you.

License
-------

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[RDF.rb]:    http://rubygems.org/gems/rdf
[RSpec]:     http://rspec.info/
[RubySpec]:  http://rubyspec.org/wiki/rubyspec/Style_Guide
[PDD]:       http://lists.w3.org/Archives/Public/public-rdf-ruby/2010May/0013.html
