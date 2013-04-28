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

desc "Build etc files"
task :etc => %w(etc/triples.nt etc/quads.nq)

desc "Clean etc files"
task :clean do
  require 'fileutils'
  Dir.glob("etc/*.n?").each {|f| FileUtils.rm(f) unless f =~ /test-data/}
end

file "etc/doap.nt" do
  sh "rdf serialize http://ruby-rdf.github.com/rdf/etc/doap.ttl --output etc/doap.nt"
end

FOAF_SUBJECTS = {
  "bendiken" => "<http://ar.to/#self>",
  "bhuga"    => "<http://bhuga.net/#ben>",
  "gkellogg" => "<http://greggkellogg.net/foaf#me>"
}
FOAF_SUBJECTS.each do |n, u|
  nt, nq = "etc/#{n}.nt", "etc/#{n}.nq"

  desc "Build #{nt} from etc/doap.nt"
  file nt => "etc/doap.nt" do
    File.open(nt, "w") do |output|
      output.write File.readlines("etc/doap.nt").
        select {|l| l.start_with?(u)}.
        join
    end
  end

  desc "Build #{nq} from etc/doap.nt"
  file nq => "etc/doap.nt" do |t|
    File.open(nq, "w") do |output|
      output.write File.readlines("etc/doap.nt").
        select {|l| l.start_with?(u)}.
        map {|l| l.sub(/\.$/, "#{u} .")}.
        join
    end
  end
end

desc "Build etc/quads.nq from component files"
file "etc/quads.nq" => %w(etc/doap.nt etc/bendiken.nq etc/bhuga.nq etc/gkellogg.nq etc/test-data.nt) do |t|
  File.open("etc/quads.nq", "w") do |output|
    t.prerequisites.each do |input_file|
      lines = File.readlines(input_file)
      if input_file == "etc/doap.nt"
        FOAF_SUBJECTS.values.each do |u|
          lines.reject! {|l| l.start_with?(u)}
        end
      end
      output.puts lines.join
    end
  end
end

desc "Build etc/triples.nt from component files"
file "etc/triples.nt" => %w(etc/doap.nt etc/test-data.nt) do |t|
  File.open("etc/triples.nt", "w") do |output|
    t.prerequisites.each do |input_file|
      lines = File.readlines(input_file)
      output.puts lines.join
    end
  end
end
