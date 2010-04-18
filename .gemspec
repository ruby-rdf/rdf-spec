#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

GEMSPEC = Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'rdf-spec'
  gem.homepage           = 'http://rdf.rubyforge.org/'
  gem.license            = 'Public Domain' if gem.respond_to?(:license=)
  gem.summary            = 'RSpec extensions for RDF.rb.'
  gem.description        = 'RDF.rb plugin that provides RSpec matchers and shared examples for RDF objects.'
  gem.rubyforge_project  = 'rdf'

  gem.authors            = ['Arto Bendiken', 'Ben Lavender']
  gem.email              = 'arto.bendiken@gmail.com'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS README UNLICENSE VERSION etc/doap.nt) + Dir.glob('lib/**/*.rb') + Dir.glob('spec/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w()
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = %w()
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 1.8.2'
  gem.requirements               = []
  gem.add_development_dependency 'rdf',   '>= 0.1.8'
  gem.add_development_dependency 'rspec', '>= 1.3.0'
  gem.add_development_dependency 'yard' , '>= 0.5.3'
  gem.add_runtime_dependency     'rspec', '>= 1.3.0'
  gem.post_install_message       = nil
end
