source "http://rubygems.org"

gemspec

gem "rdf",            git: "git://github.com/ruby-rdf/rdf.git",            branch: "develop"
gem "rdf-isomorphic", git: "git://github.com/ruby-rdf/rdf-isomorphic.git", branch: "develop"

group :development do
  gem "wirble"
end

group :debug do
  gem "byebug", platform: :mri
end

group :development, :test do
  gem 'simplecov',  require: false, platform: :mri
  gem 'coveralls',  require: false, platform: :mri
end