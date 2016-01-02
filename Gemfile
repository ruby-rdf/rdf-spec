source "http://rubygems.org"

gemspec

gem "rdf", git: "git://github.com/ruby-rdf/rdf.git", branch: "feature/keyword-arguments"

group :development do
  gem "wirble"
end

group :development, :test do
  gem 'simplecov',  require: false, platform: :mri_21 # Travis doesn't understand 22 yet.
  gem 'coveralls',  require: false, platform: :mri_21 # Travis doesn't understand 22 yet.
end