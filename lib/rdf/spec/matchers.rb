require 'rspec/matchers' # @see http://rubygems.org/gems/rspec

module RDF; module Spec
  ##
  # RDF matchers for RSpec.
  #
  # @see http://rubydoc.info/gems/rspec-expectations/frames
  module Matchers
    RSpec::Matchers.define :be_countable do
      match do |countable|
        expect(countable).to be_a_kind_of(RDF::Countable)
        true
      end
    end

    RSpec::Matchers.define :be_enumerable do
      match do |enumerable|
        expect(enumerable).to be_a_kind_of(RDF::Enumerable)
        true
      end
    end

    RSpec::Matchers.define :be_an_enumerator do
      match do |enumerator|
        expect(enumerator).to be_a_kind_of(Enumerator)
        true
      end
    end

    RSpec::Matchers.define :be_queryable do
      match do |enumerable|
        expect(enumerable).to be_a_kind_of(RDF::Queryable)
        true
      end
    end

    RSpec::Matchers.define :match_triple_pattern do |*pattern|
      match { |queryable| not queryable.first(pattern).nil? }
    end

    RSpec::Matchers.define :be_mutable do
      match do |enumerable|
        expect(enumerable).to be_a_kind_of(RDF::Mutable)
        true
      end
    end

    RSpec::Matchers.define :be_a_statement do
      match do |statement|
        expect(statement).to be_instance_of(RDF::Statement)
        expect(statement.subject).to be_a_kind_of(RDF::Resource)
        expect(statement.predicate).to be_a_kind_of(RDF::URI)
        expect(statement.object).to be_a_kind_of(RDF::Value)
        true
      end
    end

    RSpec::Matchers.define :be_a_triple do
      match do |triple|
        expect(triple).to be_instance_of(Array)
        expect(triple.size).to eq 3
        expect(triple[0]).to be_a_kind_of(RDF::Resource)
        expect(triple[1]).to be_a_kind_of(RDF::URI)
        expect(triple[2]).to be_a_kind_of(RDF::Value)
        true
      end
    end

    RSpec::Matchers.define :be_a_quad do
      match do |quad|
        expect(quad).to be_instance_of(Array)
        expect(quad.size).to eq 4
        expect(quad[0]).to be_a_kind_of(RDF::Resource)
        expect(quad[1]).to be_a_kind_of(RDF::URI)
        expect(quad[2]).to be_a_kind_of(RDF::Value)
        expect(quad[3]).to be_a_kind_of(RDF::Resource) unless quad[3].nil?
        true
      end
    end

    RSpec::Matchers.define :be_a_term do
      match do |value|
        expect(value).to be_a_kind_of(RDF::Term)
        true
      end
    end

    RSpec::Matchers.define :be_a_resource do
      match do |value|
        expect(value).to be_a_kind_of(RDF::Resource)
        true
      end
    end

    RSpec::Matchers.define :be_a_node do
      match do |value|
        expect(value).to be_a_kind_of(RDF::Node)
        true
      end
    end

    RSpec::Matchers.define :be_a_uri do
      match do |value|
        expect(value).to be_a_kind_of(RDF::URI)
        true
      end
    end

    RSpec::Matchers.define :be_a_value do
      match do |value|
        expect(value).to be_a_kind_of(RDF::Value)
        true
      end
    end

    RSpec::Matchers.define :be_a_list do
      match do |value|
        expect(value).to be_an(RDF::List)
        true
      end
    end

    RSpec::Matchers.define :be_a_vocabulary do |base_uri|
      match do |vocabulary|
        expect(vocabulary).to be_a_kind_of(Module)
        expect(vocabulary).to respond_to(:to_uri)
        expect(vocabulary.to_uri.to_s).to eq base_uri
        expect(vocabulary).to respond_to(:[])
        true
      end
    end

    RSpec::Matchers.define :have_properties do |base_uri, properties|
      match do |vocabulary|
        properties.map { |p| p.to_sym }.each do |property|
          expect(vocabulary[property]).to be_a_uri
          expect(vocabulary[property].to_s).to eq "#{base_uri}#{property}"
          expect(vocabulary).to respond_to(property)
          expect { vocabulary.send(property) }.not_to raise_error
          expect(vocabulary.send(property)).to be_a_uri
          expect(vocabulary.send(property.to_s)).to be_a_uri
          expect(vocabulary.send(property).to_s).to eq "#{base_uri}#{property}"
        end
        true
      end
    end

    RSpec::Matchers.define :have_terms do |base_uri, klasses|
      match do |vocabulary|
        klasses.map { |k| k.to_sym }.each do |klass|
          expect(vocabulary[klass]).to be_a_uri
          expect(vocabulary[klass].to_s).to eq "#{base_uri}#{klass}"
          expect(vocabulary).to respond_to(klass)
          expect { vocabulary.send(klass) }.not_to raise_error
          expect(vocabulary.send(klass)).to be_a_uri
          expect(vocabulary.send(klass.to_s)).to be_a_uri
          expect(vocabulary.send(klass).to_s).to eq "#{base_uri}#{klass}"
        end
        true
      end
    end

    RSpec::Matchers.define :be_a_repository do
      match do |repository|
        expect(repository).to be_a_kind_of(RDF::Repository)
        true
      end
    end

    RSpec::Matchers.define :be_a_repository_of_size do |size|
      match do |repository|
        expect(repository).to be_a_repository
        repository.size == size
      end
    end

    RSpec::Matchers.define :have_predicate do |predicate, count|
      match do |queryable|
        if count.nil?
          queryable.has_predicate?(predicate)
        else
          queryable.query([nil, predicate, nil]).size == count
        end
      end
    end

    RSpec::Matchers.define :write_each do |*messages|
      supports_block_expectations { true }

      match do |block|
        messages.each { |message| expect(&block).to write(message) }
      end
    end

    RSpec::Matchers.define :write do |message|
      chain(:to) { |io| @io = io }

      supports_block_expectations { true }

      match do |block|
        @output =
          case io
          when :output then fake_stdout(&block)
          when :error  then fake_stderr(&block)
          else raise("Allowed values for `to` are :output and :error, got `#{io.inspect}`")
          end
        case message
        when nil, :something, :anything
          !@output.empty?
        when Regexp
          message.match(@output)
        else
          @output.include? message
        end
      end

      description do
        "write \"#{message}\" #{io_name}"
      end

      failure_message do
        @exception ? @exception.message :
          "expected to include #{description.inspect} in #{@output.inspect}"
      end

      failure_message_when_negated do
        @exception ? @exception.message :
          "expected to not include #{description.inspect} in #{@output.inspect}"
      end

      # Fake $stderr and return a string written to it.
      def fake_stderr
        original_stderr = $stderr
        $stderr = StringIO.new
        yield
        $stderr.string
      rescue RSpec::Expectations::ExpectationNotMetError => e
        @exception = e
        raise
      ensure
        $stderr = original_stderr
      end

      # Fake $stdout and return a string written to it.
      def fake_stdout
        original_stdout = $stdout
        $stdout = StringIO.new
        yield
        $stdout.string
      rescue RSpec::Expectations::ExpectationNotMetError => e
        @exception = e
        raise
      ensure
        $stdout = original_stdout
      end

      # default IO is standard output
      def io
        @io ||= :output
      end

      # IO name is used for description message
      def io_name
        {:output => "standard output", :error => "standard error"}[io]
      end
    end

    Info = Struct.new(:id, :logger, :action, :result)

    RSpec::Matchers.define :be_equivalent_graph do |expected, info|
      match do |actual|
        @info = if (info.id rescue false)
          info
        elsif info.is_a?(Logger)
          Info.new("", info)
        elsif info.is_a?(Hash)
          Info.new(info[:id], info[:logger], info[:action], info[:result])
        else
          Info.new(info)
        end
        @expected = normalize(expected)
        @actual = normalize(actual)
        @actual.isomorphic_with?(@expected) rescue false
      end

      failure_message do |actual|
        format = case
        when RDF.const_defined?(:TriG) then :trig
        when RDF.const_defined?(:Turtle) then :ttl
        else :nquads
        end
        info = @info.respond_to?(:information) ? @info.information : @info.inspect
        if @expected.is_a?(RDF::Enumerable) && @actual.size != @expected.size
          "Graph entry counts differ:\nexpected: #{@expected.size}\nactual:   #{@actual.size}\n"
        else
          "Graphs differ\n"
        end +
        "\n#{info + "\n" unless info.empty?}" +
        "Expected:\n#{@expected.dump(format, standard_prefixes: true, literal_shorthand: false, validate: false) rescue @expected.inspect}" +
        "Results:\n#{@actual.dump(format, standard_prefixes: true, literal_shorthand: false, validate: false) rescue @actual.inspect}" +
        "\nDebug:\n#{@info.logger}"
      end

      failure_message_when_negated do |actual|
        format = case
        when RDF.const_defined?(:TriG) then :trig
        when RDF.const_defined?(:Turtle) then :ttl
        else :nquads
        end
        info = @info.respond_to?(:information) ? @info.information : @info.inspect
        "Graphs identical\n" +
        "\n#{info + "\n" unless info.empty?}" +
        "Results:\n#{actual.dump(format, standard_prefixes: true, literal_shorthand: false, validate: false) rescue @actual.inspect}" +
        "\nDebug:\n#{@info.logger}"
      end

      def normalize(graph)
        case graph
        when RDF::Enumerable then graph
        when IO, StringIO
          RDF::Repository.new(graph, base_uri: @info.action)
        else
          # Figure out which parser to use
          r = RDF::Repository.new
          reader_class = RDF::Reader.for() {graph}
          reader_class.new(graph, base_uri: @info.action).each {|s| r << s}
          r
        end
      end
    end

    require 'json'
    JSON_STATE = ::JSON::State.new(
       indent:        "  ",
       space:         " ",
       space_before:  "",
       object_nl:     "\n",
       array_nl:      "\n"
     )

    RSpec::Matchers.define :produce do |expected, info|
      match do |actual|
        @info = if (info.id rescue false)
          info
        elsif info.is_a?(Logger)
          Info.new("", info)
        elsif info.is_a?(Hash)
          Info.new(info[:id], info[:logger], info[:action], info[:result])
        else
          Info.new(info)
        end
        expect(actual).to eq expected
      end

      failure_message do |actual|
        info = @info.respond_to?(:information) ? @info.information : @info.inspect

        "Expected: #{expected.is_a?(String) ? expected : expected.to_json(JSON_STATE) rescue 'malformed json'}\n" +
        "Actual  : #{actual.is_a?(String) ? actual : actual.to_json(JSON_STATE) rescue 'malformed json'}\n" +
        "\n#{info + "\n" unless info.empty?}" +
        "\nDebug:\n#{@info.logger}"
      end

      failure_message_when_negated do |actual|
        info = @info.respond_to?(:information) ? @info.information : @info.inspect

        "Expected not to produce the following:\n" + 
        "Actual  : #{actual.is_a?(String) ? actual : actual.to_json(JSON_STATE) rescue 'malformed json'}\n" +
        "\n#{info + "\n" unless info.empty?}" +
        "\nDebug:\n#{@info.logger}"
      end
    end

  end # Matchers
end; end # RDF::Spec


module RSpec
  module Matchers
    class MatchArray
      private
      def safe_sort(array)
        case
          when array.all?{|item| item.respond_to?(:<=>) && !item.is_a?(Hash)}
            array.sort
          else
            array
        end
      end
    end
  end
end
