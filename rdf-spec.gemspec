#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'rdf-spec'
  gem.homepage           = 'https://github.com/ruby-rdf/rdf-spec/'
  gem.license            = 'Unlicense'
  gem.summary            = 'RSpec extensions for RDF.rb.'
  gem.description        = 'RDF.rb extension that provides RSpec matchers and shared examples for RDF objects.'

  gem.authors            = ['Arto Bendiken', 'Ben Lavender', 'Gregg Kellogg']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS README.md UNLICENSE VERSION) + Dir.glob('etc/*') + Dir.glob('lib/**/*.rb') + Dir.glob('spec/*.rb')
  gem.require_paths      = %w(lib)

  gem.required_ruby_version      = '>= 2.6'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',             '~> 3.2'
  gem.add_runtime_dependency     'amazing_print',   '~> 1.4'
  gem.add_runtime_dependency     'rdf-isomorphic',  '~> 3.1'
  gem.add_runtime_dependency     'rspec',           '~> 3.10'
  gem.add_runtime_dependency     'rspec-its',       '~> 1.3'
  gem.add_runtime_dependency     'rexml',           '~> 3.2'  # For Webmock
  gem.add_runtime_dependency     'webmock',         '~> 3.14'
  gem.add_development_dependency 'yard' ,           '~> 0.9'
  gem.post_install_message        = nil
end
