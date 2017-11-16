source "http://rubygems.org"

gemspec

gem 'rdf',            github: "ruby-rdf/rdf",             branch: "feature/3.0-dev"
gem 'rdf-isomorphic', github: "ruby-rdf/rdf-isomorphic",  branch: "develop"

group :debug do
  gem "byebug", platform: :mri
end

group :development, :test do
  gem 'simplecov',  require: false, platform: :mri
  gem 'coveralls',  require: false, platform: :mri
end