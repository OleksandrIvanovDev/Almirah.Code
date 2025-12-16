require_relative 'doc_items/doc_item'
require_relative 'doc_items/heading'

class SourceFileParser # rubocop:disable Style/Documentation
  def self.parse(doc, file_lines)
    # restart section numbering for each new document
    Heading.reset_global_section_number

    # There is no document without heading
    title = doc.id
    item = Heading.new(doc, title, 0)
    doc.items.append(item)
    doc.headings.append(item)
    doc.title = title

    # main loop
    file_lines.each do |s|
      doc.items.append(s)
    end
  end
end
