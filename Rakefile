#!/usr/bin/env ruby
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))
require 'rubygems'
begin
  require 'rakefile' # @see http://github.com/bendiken/rakefile
rescue LoadError => e
end

require 'rdf/spec'

desc "Build the rdf-spec-#{File.read('VERSION').chomp}.gem file"
task :build do
  sh "gem build .gemspec"
end

desc "Build etc/doap.nq from component files"
file "etc/doap.nq" => %w(etc/bendiken.nq etc/bhuga.nq etc/gkellogg.nq etc/doap.nt etc/test-data.nt) do |t|
  `cat #{t.prerequisites.join(' ')} > #{t.name}`
end

%w(bendiken bhuga gkellogg).each do |n|
  nt, nq = "etc/#{n}.nt", "etc/#{n}.nq"

  desc "Build #{nq} from #{nt}"
  file nq => nt do |t|
    `cat #{t.prerequisites.join(' ')} | awk '{print substr($0, 1, length($0)-1), $1, "."}' > #{t.name}`
  end
end
