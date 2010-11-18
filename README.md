RSpec Extensions for RDF.rb
===========================

This is an [RDF.rb][] plugin that provides RDF-specific [RSpec][] matchers
and shared examples for Ruby projects that use RDF.rb and RSpec.

* <http://github.com/bendiken/rdf-spec>

Documentation
-------------

* {RDF::Spec}
  * {RDF::Spec::Matchers}

Dependencies
------------

* [RDF.rb](http://gemcutter.org/gems/rdf) (>= 0.2.3)
* [RSpec](http://gemcutter.org/gems/rspec) (>= 1.3.0)

Installation
------------

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of `RDF::Spec`, do:

    % [sudo] gem install rdf-spec

Download
--------

To get a local working copy of the development repository, do:

    % git clone git://github.com/bendiken/rdf-spec.git

Alternatively, you can download the latest development version as a tarball
as follows:

    % wget http://github.com/bendiken/rdf-spec/tarball/master

Authors
-------

* [Arto Bendiken](http://github.com/bendiken) - <http://ar.to/>
* [Ben Lavender](http://github.com/bhuga) - <http://bhuga.net/>
* [Gregg Kellogg](http://github.com/gkellogg) - <http://kellogg-assoc.com/>

Contributors
------------

* [John Fieber](http://github.com/jfieber) - <http://github.com/jfieber>

Contributing
------------
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

`RDF::Spec` is free and unencumbered public domain software. For more
information, see <http://unlicense.org/> or the accompanying UNLICENSE file.

[RDF.rb]:    http://rdf.rubyforge.org/
[RSpec]:     http://rspec.info/
[RubySpec]:  http://rubyspec.org/wiki/rubyspec/Style_Guide
[PDD]:       http://lists.w3.org/Archives/Public/public-rdf-ruby/2010May/0013.html
