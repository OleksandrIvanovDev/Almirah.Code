require_relative "doc_item"

class CodeBlock < DocItem

    attr_accessor :suggested_format
    attr_accessor :code_lines

    def initialize(suggested_format)
        @suggested_format = suggested_format
        @code_lines = Array.new
    end

    def to_html
        s = ''

        if @@html_table_render_in_progress
            s += "</table>\n"
            @@html_table_render_in_progress = false
        end
        s += "<code>"
        @code_lines.each do |l|
            s += l + " </br>"
        end
        s += "</code>\n"
        return s
    end
end