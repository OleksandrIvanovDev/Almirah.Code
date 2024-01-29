require_relative "doc_item"

class MarkdownList < DocItem

    attr_accessor :rows

    def initialize(first_row)
        @rows = Array.new
        @rows.append(first_row)
    end

    def addRow(row)
        @rows.append(row)
    end

    def to_html
        s = ''
        if @@htmlTableRenderInProgress
            s += "</table>/n/r"
            @@htmlTableRenderInProgress = false
        end

        s += "<ul>\n\r"
        @rows.each do |r|
            s += "\t<li>#{r}</li>\n\r"
        end
        s += "</ul>\n\r"

        return s
    end
end