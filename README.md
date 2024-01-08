# RSpec Extensions for RDF.rb

This is an [RDF.rb][] extension that provides RDF-specific [RSpec][] matchers
and shared examples for Ruby projects that use RDF.rb and RSpec.

[![Gem Version](https://badge.fury.io/rb/rdf-spec.svg)](https://badge.fury.io/rb/rdf-spec)
[![Build Status](https://github.com/ruby-rdf/rdf-spec/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-spec/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-spec/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/rdf-spec?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

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

* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.3)
* [RSpec](https://rubygems.org/gems/rspec) (~> 3.12)

## Change Log

See [Release Notes on GitHub](https://github.com/ruby-rdf/rdf-spec/releases)

## Installation

The recommended installation method is via [RubyGems](https://rubygems.org/).
To install the latest official release of the `RDF::Spec` gem, do:

    % [sudo] gem install rdf-spec

## Download

To get a local working copy of the development repository, do:

    % git clone git://github.com/ruby-rdf/rdf-spec.git

Alternatively, download the latest development version as a tarball as
follows:

    % wget https://github.com/ruby-rdf/rdf-spec/tarball/master

## Authors

* [Arto Bendiken](https://github.com/artob) - <https://ar.to/>
* [Ben Lavender](https://github.com/bhuga) - <https://bhuga.net/>
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## Contributors

* [John Fieber](https://github.com/jfieber) - <https://github.com/jfieber>
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
  explicit [public domain dedication][PDD] on record from you,
  which you will be asked to agree to on the first commit to a repo within the organization.
  Note that the agreement applies to all repos in the [Ruby RDF](https://github.com/ruby-rdf/) organization.

License
-------

This is free and unencumbered public domain software. For more information,
see <https://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[RDF.rb]:    https://rubygems.org/gems/rdf
[RSpec]:     https://rspec.info/
[RubySpec]:  https://rubyspec.org/wiki/rubyspec/Style_Guide
[PDD]:              https://unlicense.org/#unlicensing-contributions
