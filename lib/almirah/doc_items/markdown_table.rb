# frozen_string_literal: true

require_relative 'doc_item'

class MarkdownTable < DocItem
  attr_accessor :column_names, :rows, :heading_row, :is_separator_detected

  def initialize(doc, heading_row)
    super(doc)
    @heading_row = heading_row

    res = /^[|](.*[|])/.match(heading_row)
    @column_names = if res
                      res[1].split('|')
                    else
                      ['# ERROR# ']
                    end
    @rows = []
    @is_separator_detected = false
  end

  def add_row(row)
    columns = row.split('|')
    @rows.append(columns.map!(&:strip))
    true
  end

  def to_html
    s = ''
    if @@html_table_render_in_progress
      s += "</table>\n"
      @@html_table_render_in_progress = false
    end

    s += "<table class=\"markdown_table\">\n"
    s += "\t<thead>"

    @column_names.each do |h|
      s += " <th>#{h}</th>"
    end

    s += " </thead>\n"

    @rows.each do |row|
      s += "\t<tr>\n"
      row.each do |col|
        if col.to_i.positive? && col.to_i.to_s == col  # autoalign cells with numbers
          s += "\t\t<td style=\"text-align: center;\">#{col}</td>\n"
        else
          f_text = format_string(col)
          s += "\t\t<td>#{f_text}</td>\n"
        end
      end
      s += "\t</tr>\n"
    end

    s += "</table>\n"

    s
  end
end
