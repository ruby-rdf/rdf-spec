#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'rdf-spec'
  gem.homepage           = 'http://ruby-rdf.github.com/rdf-spec/'
  gem.license            = 'Public Domain' if gem.respond_to?(:license=)
  gem.summary            = 'RSpec extensions for RDF.rb.'
  gem.description        = 'RDF.rb extension that provides RSpec matchers and shared examples for RDF objects.'
  gem.rubyforge_project  = 'rdf'

  gem.authors            = ['Arto Bendiken', 'Ben Lavender', 'Gregg Kellogg']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS README UNLICENSE VERSION) + Dir.glob('etc/*') + Dir.glob('lib/**/*.rb') + Dir.glob('spec/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w()
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = %w()
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 1.9.2'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',       '~> 1.99'
  gem.add_runtime_dependency     'rspec',     '~> 3.0'
  gem.add_runtime_dependency     'rspec-its', '~> 1.0'
  gem.add_runtime_dependency     'webmock',   '~> 1.17'
  gem.add_development_dependency 'yard' ,     '~> 0.8'
  gem.post_install_message       = nil
end
