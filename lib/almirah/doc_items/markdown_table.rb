require_relative "doc_item"

class MarkdownTable < DocItem

    attr_accessor :column_names
    attr_accessor :rows

    def initialize(heading_row)
        @column_names = heading_row.split('|')
        @rows = Array.new
    end

    def addRow(row)
        columns = row.split('|')
        @rows.append(columns)
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>"
            @@htmlTableRenderInProgress = false
        end
                   
        s += "<table>\n\r"
        s += "\t<thead>" 

        @column_names.each do |h|
            s += " <th>#{h}</th>"
        end

        s += " </thead>\n\r"

        @rows.each do |row|
            s += "\t<tr>\n\r"
            row.each do |col|
                s += "\t\t<td>#{col}</td>\n\r"
            end
            s += "\t</tr>\n\r"
        end

        s += "</table>\n\r"

        return s
    end

end