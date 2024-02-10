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
            s += "</table>\n"
            @@htmlTableRenderInProgress = false
        end

        s += "<ul>\n"
        @rows.each do |r|
            s += "\t<li>#{r}</li>\n"
        end
        s += "</ul>\n"

        return s
    end
end