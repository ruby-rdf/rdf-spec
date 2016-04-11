require 'rdf'
# override several inspect functions to improve output for what we're doing

class RDF::Literal
  def inspect
    "\"#{escape(value)}\" R:L:(#{self.class.to_s.match(/([^:]*)$/)})"
  end
end

class RDF::URI
  def inspect
    "RDF::URI(#{to_base})"
  end
end

class RDF::Node
  def inspect
    "RDF::Node(#{to_base})"
  end
end

class RDF::Graph
  def inspect
    "RDF::Graph(graph_name: #{self.graph_name || 'nil'})"
  end
end

class RDF::Query
  def inspect
    "RDF::Query(#{graph_name ? graph_name.to_sxp : 'nil'})#{patterns.inspect}"
  end
end

class Array
  alias_method :inspect_without_formatting, :inspect
  def inspect_with_formatting
    if all? { |item| item.is_a?(Hash) }
      string = "[\n"
      each do |item|
        string += "  {\n"
          item.keys.sort_by(&:to_s).each do |key|
            string += "      #{key.inspect}: #{item[key].inspect}\n"
          end
        string += "  },\n"
      end
      string += "]"
      string
    elsif all? { |item| item.is_a?(RDF::Query::Solution)}
      string = "[\n"
      each do |item|
        string += "  {\n"
          item.bindings.keys.sort_by(&:to_s).each do |key|
            string += "      #{key.inspect}: #{item.bindings[key].inspect}\n"
          end
        string += "  },\n"
      end
      string += "]"
      string
    else
      inspect_without_formatting
    end
  end
  alias_method :inspect, :inspect_with_formatting
end

class RDF::Query::Solutions
  def inspect
    string = "vars: #{variable_names.join(",")}\n#{to_a.inspect}"
  end
end
