require_relative 'doc_types/base_document'
require_relative 'doc_types/specification'
require_relative 'doc_types/protocol'
require_relative 'doc_parser'
require_relative 'dom/document'

class DocFabric
  @@color_index = 0
  @@spec_colors = %w[cff4d2 fbeee6 ffcad4 bce6ff e4dfd9 f9e07f cbe54e d3e7ee eab595 86e3c3
                     ffdca2 ffffff ffdd94 d0e6a5 ffb284 f3dbcf c9bbc8 c6c09c]

  def self.add_lazy_doc_id(path)
    if res = /(\w+)[.]md$/.match(path)
      TextLine.add_lazy_doc_id(res[1])
    end
  end

  def self.create_specification(path)
    color = @@spec_colors[@@color_index]
    @@color_index += 1
    @@color_index = 0 if @@color_index >= @@spec_colors.length
    doc = Specification.new path
    DocFabric.parse_document doc
    doc.color = color
    doc
  end

  def self.create_protocol(path)
    doc = Protocol.new path
    DocFabric.parse_document doc
    doc
  end

  def self.parse_document(doc)

    file = File.open(doc.path)
    file_lines = file.readlines
    file.close

    DocParser.parse(doc, file_lines)

    # Build dom
    doc.dom = Document.new(doc.headings) if doc.is_a?(Specification) || doc.is_a?(Protocol)
  end
end
