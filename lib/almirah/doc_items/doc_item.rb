# frozen_string_literal: true

require_relative 'text_line'

class DocItem < TextLine
  attr_accessor :parent_doc, :parent_heading

  @parent_doc = nil
  @parent_heading = nil

  @@html_table_render_in_progress = false

  def initialize(doc)
    super()
    @parent_doc = doc
    @parent_heading = doc.headings[-1]
  end

  def get_url
    ''
  end

  # Splits a Markdown table row into its cell strings, treating a backslash-escaped
  # pipe (\|) as a literal character within a cell rather than a column separator
  # (e.g. a "|" inside an inline code span such as `[[target\|alias]]`). The escaping
  # backslash is dropped so the cell renders the intended literal pipe.
  def split_table_cells(row)
    row.split(/(?<!\\)\|/).map { |cell| cell.gsub('\\|', '|') }
  end

  def owner_document
    @parent_doc
  end
end
