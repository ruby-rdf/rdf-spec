source "https://rubygems.org"

gemspec

gem 'rdf',            github: "ruby-rdf/rdf",             branch: "develop"
gem 'rdf-isomorphic', github: "ruby-rdf/rdf-isomorphic",  branch: "develop"

group :debug do
  gem "byebug", platform: :mri
end

group :development, :test do
  gem 'simplecov', require: false,  platforms: :mri
  gem 'coveralls', require: false, platforms: :mri
end