# frozen_string_literal: true

require_relative 'doc_item'

class MarkdownTable < DocItem
  attr_accessor :column_names, :rows, :heading_row, :is_separator_detected, :column_aligns

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
    @column_aligns = []
  end

  def add_separator(line)
    res = /^[|](.*[|])/.match(line)
    columns = if res
                res[1].split('|')
              else
                ['# ERROR# ']
              end

    columns.each do |c|
      res = /(:?)(-{3,})(:?)/.match(c)
      @column_aligns << if res.length == 4
                          if (res[1] != '') && (res[2] != '') && (res[3] != '')
                            'center'
                          elsif (res[1] != '') && (res[2] != '') && (res[3] == '')
                            'left'
                          elsif (res[1] == '') && (res[2] != '') && (res[3] != '')
                            'right'
                          else
                            'default'
                          end
                        else
                          'default'
                        end
    end
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
      row.each_with_index do |col, index|
        if col.to_i.positive? && col.to_i.to_s == col  # autoalign cells with numbers
          s += "\t\t<td style=\"text-align: center;\">#{col}</td>\n"
        else
          align = ''
          case @column_aligns[index]
          when 'left'
            align = 'style="text-align: left;"'
          when 'right'
            align = 'style="text-align: right;"'
          when 'center'
            align = 'style="text-align: center;"'
          end
          f_text = format_string(col)
          s += "\t\t<td #{align}>#{f_text}</td>\n"
        end
      end
      s += "\t</tr>\n"
    end

    s += "</table>\n"

    s
  end
end
