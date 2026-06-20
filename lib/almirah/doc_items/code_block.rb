require_relative 'doc_item'

class CodeBlock < DocItem
  attr_accessor :suggested_format, :code_lines

  def initialize(suggested_format)
    @suggested_format = suggested_format
    @code_lines = []
  end

  def to_html
    s = ''

    if @@html_table_render_in_progress
      s += "</table>\n"
      @@html_table_render_in_progress = false
    end
    s += '<code>'
    @code_lines.each do |l|
      s += escape_text(l) + ' </br>' # ADR-188/SRS-096: code content is inert text
    end
    s += "</code>\n"
    s
  end
end
