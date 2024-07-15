require_relative 'doc_item'

class Paragraph < DocItem
  attr_accessor :text

  def initialize(doc, text)
    super(doc)
    @text = text.strip
  end

  def getTextWithoutSpaces
    @text.split.join('-').downcase
  end

  def to_html
    s = ''
    if @@html_table_render_in_progress
      s += '</table>'
      @@html_table_render_in_progress = false
    end

    s += "<p>#{format_string(@text)}"
    s
  end
end
