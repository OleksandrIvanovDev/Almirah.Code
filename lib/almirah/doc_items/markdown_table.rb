require_relative "doc_item"

class MarkdownTable < DocItem

    attr_accessor :column_names
    attr_accessor :rows

    def initialize(heading_row)
        @column_names = heading_row.split('|')
        @rows = Array.new
    end

    def addRow(row)
        #check if row contains a link
        if tmp = /(.*)\s+>\[(\S*)\]/.match(row)
            return false # this is not a regular Markdown table.
            # so the table type shall be changed and this row shall be passed one more time
        end

        columns = row.split('|')
        @rows.append(columns.map!{ |x| x.strip })
        return true
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>"
            @@htmlTableRenderInProgress = false
        end
                   
        s += "<table class=\"markdown_table\">\n\r"
        s += "\t<thead>" 

        @column_names.each do |h|
            s += " <th>#{h}</th>"
        end

        s += " </thead>\n\r"

        @rows.each do |row|
            s += "\t<tr>\n\r"
            row.each do |col|
                if col.to_i > 0 && col.to_i.to_s == col  # autoalign cells with numbers
                    s += "\t\t<td style='text-align: center;>#{col}</td>\n\r"
                else
                    s += "\t\t<td>#{col}</td>\n\r"
                end
            end
            s += "\t</tr>\n\r"
        end

        s += "</table>\n\r"

        return s
    end

end