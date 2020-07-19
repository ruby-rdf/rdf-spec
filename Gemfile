source "https://rubygems.org"

gemspec

gem 'rdf',            github: "ruby-rdf/rdf",             branch: "develop"
gem 'rdf-isomorphic', github: "ruby-rdf/rdf-isomorphic",  branch: "develop"

group :debug do
  gem "byebug", platform: :mri
end

group :development, :test do
  gem 'simplecov',  platforms: :mri
  gem 'coveralls',  '~> 0.8', platforms: :mri
end