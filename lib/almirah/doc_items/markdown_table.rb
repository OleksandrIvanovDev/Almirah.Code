require_relative "doc_item"

class MarkdownTable < DocItem

    attr_accessor :column_names
    attr_accessor :rows
    attr_accessor :heading_row
    attr_accessor :is_separator_detected

    def initialize(doc, heading_row)
        @parent_doc = doc
        @parent_heading = doc.headings[-1]
        @heading_row = heading_row

        res = /^[|](.*[|])/.match(heading_row)
        @column_names = if res
                          res[1].split('|')
                        else
                          ['# ERROR# ']
                        end
        @rows = Array.new
        @is_separator_detected = false
    end

    def addRow(row)
        columns = row.split('|')
        @rows.append(columns.map!{ |x| x.strip })
        return true
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>\n"
            @@htmlTableRenderInProgress = false
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
                if col.to_i > 0 && col.to_i.to_s == col  # autoalign cells with numbers
                    s += "\t\t<td style=\"text-align: center;\">#{col}</td>\n"
                else
                    f_text = format_string(col)
                    s += "\t\t<td>#{f_text}</td>\n"
                end
            end
            s += "\t</tr>\n"
        end

        s += "</table>\n"

        return s
    end

end