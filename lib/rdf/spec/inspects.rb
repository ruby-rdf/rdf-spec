require 'rdf'
# override several inspect functions to improve output for what we're doing

class RDF::Literal
  def inspect
    "\"#{escape(value)}\"#{('@' + self.language.to_s) if self.language?} R:L:(#{self.class.to_s.match(/([^:]*)$/)})"
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

class RDF::Query::Solutions
  def inspect
    string = "vars: #{variable_names.join(",")}\n#{to_a.inspect}"
  end
end
